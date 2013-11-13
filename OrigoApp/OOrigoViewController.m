//
//  OOrigoViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OOrigoViewController.h"

static NSString * const kSegueToMemberView = @"segueFromOrigoToMemberView";

static NSInteger const kSectionKeyOrigo = 0;
static NSInteger const kSectionKeyContacts = 1;
static NSInteger const kSectionKeyMembers = 2;

static NSInteger const kActionSheetTagActionSheet = 0;
static NSInteger const kButtonTagEdit = 0;
static NSInteger const kButtonTagAddMember = 1;
static NSInteger const kButtonTagAddContact = 2;
static NSInteger const kButtonTagAddParentContact = 3;
static NSInteger const kButtonTagShowInMap = 4;
static NSInteger const kButtonTagAbout = 5;

static NSInteger const kActionSheetTagHousemate = 1;
static NSInteger const kButtonTagHousemate = 100;
static NSInteger const kButtonTagGuardian = 101;


@implementation OOrigoViewController

#pragma mark - Auxiliary methods

- (void)addMember
{
    NSMutableSet *housemateCandidates = nil;
    
    if ([_origo isOfType:kOrigoTypeResidence]) {
        housemateCandidates = [NSMutableSet set];
        
        for (OMember *housemate in [_membership.member housemates]) {
            if (![_origo hasMember:housemate]) {
                [housemateCandidates addObject:housemate];
            }
        }
    }
    
    if (housemateCandidates && [housemateCandidates count]) {
        [self presentHousemateCandidatesSheet:housemateCandidates];
    } else {
        [self presentModalViewControllerWithIdentifier:kIdentifierMember data:_origo];
    }
}


#pragma mark - Actions sheets

- (void)presentHousemateCandidatesSheet:(NSSet *)candidates
{
    _housemateCandidates = [candidates sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:kPropertyKeyName ascending:YES]]];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagHousemate];
    
    for (OMember *candidate in _housemateCandidates) {
        [actionSheet addButtonWithTitle:candidate.name];
    }
    
    if (![_origo userIsMember] && [_membership.member isWardOfUser]) {
        [actionSheet addButtonWithTitle:[OStrings stringForKey:strButtonOtherGuardian] tag:kButtonTagGuardian];
    } else {
        [actionSheet addButtonWithTitle:[OStrings stringForKey:strButtonNewHousemate] tag:kButtonTagHousemate];
    }
    
    [actionSheet show];
}


#pragma mark - Selector implementations

- (void)presentActionSheet
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagActionSheet];
    
    [actionSheet addButtonWithTitle:[OStrings stringForKey:strButtonEdit] tag:kButtonTagEdit];
    [actionSheet addButtonWithTitle:[OStrings stringForKey:_origoType withKeyPrefix:kKeyPrefixAddMemberButton] tag:kButtonTagAddMember];
    
    if ([_origo isOrganised]) {
        [actionSheet addButtonWithTitle:[OStrings stringForKey:_origoType withKeyPrefix:kKeyPrefixAddContactButton] tag:kButtonTagAddContact];
        
        if ([_origo isJuvenile]) {
            [actionSheet addButtonWithTitle:[OStrings stringForKey:strButtonAddParentContact] tag:kButtonTagAddParentContact];
        }
    }
    
    if ([_origo.address hasValue]) {
        [actionSheet addButtonWithTitle:[OStrings stringForKey:strButtonShowInMap] tag:kButtonTagShowInMap];
    }
    
    [actionSheet addButtonWithTitle:[NSString stringWithFormat:[OStrings stringForKey:strButtonAbout], [_origo displayName]] tag:kButtonTagAbout];
    
    [actionSheet show];
}


- (void)addItem
{
    if ([_origo isOrganised]) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagActionSheet];
        
        [actionSheet addButtonWithTitle:[OStrings stringForKey:_origoType withKeyPrefix:kKeyPrefixAddMemberButton] tag:kButtonTagAddMember];
        [actionSheet addButtonWithTitle:[OStrings stringForKey:_origoType withKeyPrefix:kKeyPrefixAddContactButton] tag:kButtonTagAddContact];
        
        [actionSheet show];
    } else {
        [self addMember];
    }
}


#pragma mark - OTableViewController custom accesors

- (BOOL)canEdit
{
    return [_origo userCanEdit];
}


#pragma mark - UIViewController overrides

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToMemberView]) {
        [self prepareForPushSegue:segue];
    }
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialiseState
{
    if ([self.data isKindOfClass:[OMembership class]]) {
        _membership = self.data;
        _member = _membership.member;
        _origo = _membership.origo;
        _origoType = _origo.type;
        
        if ([_origo isOfType:kOrigoTypeResidence]) {
            self.title = [OStrings stringForKey:_origoType withKeyPrefix:kKeyPrefixOrigoTitle];
        } else {
            self.title = [_origo displayName];
        }
        
        if ([self canEdit] && ![self actionIs:kActionRegister]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem actionButtonWithTarget:self];
        }

        [self.state setTarget:_origo];
    } else if ([self.data isKindOfClass:[OMember class]]) {
        _member = self.data;
        _origoType = self.meta;
        
        self.title = [OStrings stringForKey:_origoType withKeyPrefix:kKeyPrefixNewOrigoTitle];
        
        [self.state setTarget:_origoType aspectCarrier:_member];
    }
}


- (void)initialiseData
{
    if ([self actionIs:kActionRegister]) {
        [self setData:_origo ? _origo : kRegistrationCell forSectionWithKey:kSectionKeyOrigo];
        [self setData:@[_member] forSectionWithKey:kSectionKeyMembers];
    } else {
        [self setData:_origo forSectionWithKey:kSectionKeyOrigo];
        
        if ([_origo isJuvenile]) {
            [self setData:[_origo contactMemberships] forSectionWithKey:kSectionKeyContacts];
            [self setData:[_origo regularMemberships] forSectionWithKey:kSectionKeyMembers];
        } else {
            [self setData:[_origo fullMemberships] forSectionWithKey:kSectionKeyMembers];
        }
    }
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasFooter = NO;
    
    if (self.isModal && ![self actionIs:kActionRegister]) {
        hasFooter = [self isLastSectionKey:sectionKey] && [_origo userCanEdit];
    }
    
    return hasFooter;
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kSectionKeyContacts) {
        text = [[OLanguage nouns][_contact_][pluralIndefinite] capitalizedString];
    } else if (sectionKey == kSectionKeyMembers) {
        text = [OStrings stringForKey:_origoType withKeyPrefix:kKeyPrefixMemberListTitle];
    }
    
    return text;
}


- (NSArray *)toolbarButtons
{
    return [[OMeta m].switchboard toolbarButtonsForOrigo:_origo];
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    return [OStrings stringForKey:_origoType withKeyPrefix:kKeyPrefixFooter];
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if ((sectionKey == kSectionKeyContacts) || (sectionKey == kSectionKeyMembers)) {
        [self performSegueWithIdentifier:kSegueToMemberView sender:self];
    }
}


- (BOOL)canDeleteRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDeleteRow = NO;
    
    if (indexPath.section != kSectionKeyOrigo) {
        OMembership *membershipForRow = [self dataAtIndexPath:indexPath];
        
        if ([membershipForRow isKindOfClass:[OMembership class]]) {
            canDeleteRow = [_origo userIsAdmin] && ![membershipForRow.member isUser];
        }
    }
    
    return canDeleteRow;
}


#pragma mark - OTableViewInputDelegate conformance

- (BOOL)inputIsValid
{
    BOOL isValid = NO;
    
    if ([self targetIs:kOrigoTypeResidence]) {
        isValid = [self.detailCell hasValidValueForKey:kPropertyKeyAddress];
    } else {
        isValid = [self.detailCell hasValidValueForKey:kPropertyKeyName];
    }
    
    return isValid;
}


- (void)processInput
{
    [self.detailCell writeEntity];
    
    if ([self actionIs:kActionRegister]) {
        if (!_membership) {
            _membership = [_origo addMember:_member];
        }
        
        [self toggleEditMode];
        [self.detailCell readEntity];
        [self reloadSectionWithKey:kSectionKeyMembers];
        
        [[OMeta m].replicator replicate];
        
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
    } else if ([self actionIs:kActionEdit]) {
        [self toggleEditMode];
    }
}


- (id)inputEntity
{
    _origo = [[OMeta m].context insertOrigoEntityOfType:self.meta];
    
    return _origo;
}


#pragma mark - OTableViewListDelegate conformance

- (NSString *)sortKeyForSectionWithKey:(NSInteger)sectionKey
{
    return [OUtil sortKeyWithPropertyKey:kPropertyKeyName relationshipKey:kRelationshipKeyMember];
}


- (BOOL)willCompareObjectsInSectionWithKey:(NSInteger)sectionKey
{
    return [self targetIs:kOrigoTypeResidence] && (sectionKey == kSectionKeyMembers);
}


- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2
{
    NSComparisonResult result = NSOrderedSame;
    
    OMember *member1 = [object1 asMembership].member;
    OMember *member2 = [object2 asMembership].member;
    
    BOOL member1IsMinor = [member1 isMinor];
    BOOL member2IsMinor = [member2 isMinor];
    
    if (member1IsMinor != member2IsMinor) {
        if (member1IsMinor && !member2IsMinor) {
            result = NSOrderedDescending;
        } else {
            result = NSOrderedAscending;
        }
    } else {
        result = [member1.name localizedCaseInsensitiveCompare:member2.name];
    }
    
    return result;
}


- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    OMember *member = nil;
    
    if ([self actionIs:kActionRegister]) {
        member = [self dataAtIndexPath:indexPath];
    } else {
        member = [[self dataAtIndexPath:indexPath] asMembership].member;
    }
    
    cell.textLabel.text = member.name;
    cell.detailTextLabel.text = [member shortDetails];
    cell.imageView.image = [member smallImage];
}


#pragma mark - UITableViewDataSource conformance

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [OStrings stringForKey:strButtonDeleteMember];
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case kActionSheetTagActionSheet:
            if ([actionSheet tagForButtonIndex:buttonIndex] == kButtonTagEdit) {
                [self toggleEditMode];
            }
            
            break;
            
        default:
            break;
    }
}


- (void)actionSheet:(OActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
    
    switch (actionSheet.tag) {
        case kActionSheetTagActionSheet:
            if (buttonIndex < actionSheet.cancelButtonIndex) {
                if (buttonTag == kButtonTagAddMember) {
                    [self addMember];
                }
            }
            
            break;
            
        case kActionSheetTagHousemate:
            if (buttonTag == kButtonTagHousemate) {
                [self presentModalViewControllerWithIdentifier:kIdentifierMember data:_origo];
            } else if (buttonTag == kButtonTagGuardian) {
                [self presentModalViewControllerWithIdentifier:kIdentifierMember data:_origo meta:kMemberTypeGuardian];
            } else if (buttonIndex < actionSheet.cancelButtonIndex) {
                [_origo addMember:_housemateCandidates[buttonIndex]];
                [self reloadSections];
            }
            
            break;
            
        default:
            break;
    }
}

@end
