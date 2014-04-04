//
//  OOrigoViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OOrigoViewController.h"

static NSString * const kSegueToMemberView = @"segueFromOrigoToMemberView";

static NSInteger const kSectionKeyOrigo = 0;
static NSInteger const kSectionKeyContacts = 1;
static NSInteger const kSectionKeyMembers = 2;

static NSInteger const kActionSheetTagActionSheet = 0;
static NSInteger const kButtonTagEdit = 0;
static NSInteger const kButtonTagEditRoles = 1;
static NSInteger const kButtonTagAddMember = 2;
static NSInteger const kButtonTagAddFromOrigo = 3;
static NSInteger const kButtonTagAddContact = 4;
static NSInteger const kButtonTagAddParentContact = 5;
static NSInteger const kButtonTagShowInMap = 6;
static NSInteger const kButtonTagAbout = 7;

static NSInteger const kActionSheetTagHousemate = 1;
static NSInteger const kButtonTagHousemate = 100;
static NSInteger const kButtonTagGuardian = 101;


@implementation OOrigoViewController

#pragma mark - Auxiliary methods

- (void)addNewMemberButtonsToActionSheet:(OActionSheet *)actionSheet
{
    [actionSheet addButtonWithTitle:NSLocalizedString([_origo facade].type, kKeyPrefixAddMemberButton) tag:kButtonTagAddMember];
    
    if ([[[OState s].pivotMember peersNotInOrigo:_origo] count] > 0) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Add from other origos", @"") tag:kButtonTagAddFromOrigo];
    }
    
    if ([_origo isOrganised]) {
        [actionSheet addButtonWithTitle:NSLocalizedString([_origo facade].type, kKeyPrefixAddContactButton) tag:kButtonTagAddContact];
        
        if ([_origo isJuvenile]) {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Add parent contact", @"") tag:kButtonTagAddParentContact];
        }
    }
}


- (void)addMember
{
    NSSet *housemateCandidates = nil;
    
    if ([_origo isOfType:kOrigoTypeResidence]) {
        housemateCandidates = [_member housematesNotInResidence:_origo];
    }
    
    if (housemateCandidates && [housemateCandidates count]) {
        [self presentHousemateCandidatesSheet:housemateCandidates];
    } else {
        [self presentModalViewControllerWithIdentifier:kIdentifierMember target:[_origo facade].type];
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
    
    if (![_origo userIsMember] && [_member isWardOfUser]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Other guardian", @"") tag:kButtonTagGuardian];
    } else {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"New housemate", @"") tag:kButtonTagHousemate];
    }
    
    [actionSheet show];
}


#pragma mark - Selector implementations

- (void)presentActionSheet
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagActionSheet];
    
    if ([self canEdit]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit", @"") tag:kButtonTagEdit];
        
        if ([_origo isOrganised] && [_origo hasContacts]) {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit roles", @"") tag:kButtonTagEditRoles];
        }
        
        [self addNewMemberButtonsToActionSheet:actionSheet];
    }
        
    if ([[_origo facade].address hasValue]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Show in map", @"") tag:kButtonTagShowInMap];
    }
    
    [actionSheet addButtonWithTitle:[NSString stringWithFormat:NSLocalizedString(@"About %@", @""), [_origo displayName]] tag:kButtonTagAbout];
    
    [actionSheet show];
}


- (void)addItem
{
    if (![_origo isOfType:kOrigoTypeResidence]) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagActionSheet];
        
        [self addNewMemberButtonsToActionSheet:actionSheet];
        
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
    _origo = [self.entityProxy facade];
    _member = [[self.entityProxy parentWithClass:[OMember class]] facade];
    
    if ([self actionIs:kActionRegister]) {
        if (self.isModal) {
            self.title = NSLocalizedString([_origo facade].type, kKeyPrefixNewOrigoTitle);
            self.cancelImpliesSkip = ([_origo isInstantiated] && ![self aspectIsHousehold]);
        }
    } else {
        _membership = [_origo membershipForMember:_member];
        
        if ([_origo isOfType:kOrigoTypeResidence] && ![[OState s] aspectIsHousehold]) {
            self.title = NSLocalizedString([_origo facade].type, kKeyPrefixOrigoTitle);
        } else {
            self.title = [_origo displayName];
        }
        
        if ([self actionIs:kActionDisplay]) {
            if ([_origo isInstantiated]) {
                self.navigationItem.rightBarButtonItem = [UIBarButtonItem actionButton];
            } else {
                self.navigationItem.rightBarButtonItem = [UIBarButtonItem editButton];
            }
        }
    }
}


- (void)initialiseData
{
    [self setDataForDetailSection];
    
    if ([_member isInstantiated]) {
        if ([self actionIs:kActionRegister]) {
            [self setData:@[_member] forSectionWithKey:kSectionKeyMembers];
        } else {
            if ([_member isJuvenile]) {
                [self setData:[_origo contacts] forSectionWithKey:kSectionKeyContacts];
                [self setData:[_origo regulars] forSectionWithKey:kSectionKeyMembers];
            } else {
                [self setData:[_origo members] forSectionWithKey:kSectionKeyMembers];
            }
        }
    }
}


- (NSArray *)toolbarButtons
{
    return [_origo isInstantiated] ? [[OMeta m].switchboard toolbarButtonsForOrigo:_origo] : nil;
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
        text = NSLocalizedString([_origo facade].type, kKeyPrefixMemberListTitle);
    }
    
    return text;
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    return NSLocalizedString([_origo facade].type, kKeyPrefixFooter);
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
        id member = [self dataAtIndexPath:indexPath];
        
        if ([member entityClass] == [OMember class]) {
            canDeleteRow = [_origo isInstantiated] && [_origo userIsAdmin] && ![member isUser];
        }
    }
    
    return canDeleteRow;
}


- (void)didDismissModalViewController:(OTableViewController *)viewController
{
    if (viewController.returnData) {
        if ([viewController.identifier isEqualToString:kIdentifierValuePicker]) {
            for (OMember *member in viewController.returnData) {
                [_origo addMember:member];
            }
            
            [[OMeta m].replicator replicate];
        } else if ([viewController.identifier isEqualToString:kIdentifierMember]) {
            // TODO:
        }
        
        [self reloadSections];
    }
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
        
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem doneButton];
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButton];
    } else if ([self actionIs:kActionEdit]) {
        [self toggleEditMode];
    }
}


- (id)inputEntity
{
    _origo = [[OMeta m].context insertOrigoEntityOfType:[_origo facade].type];
    
    return _origo;
}


#pragma mark - OTableViewListDelegate conformance

- (NSString *)sortKeyForSectionWithKey:(NSInteger)sectionKey
{
    return [OUtil sortKeyWithPropertyKey:kPropertyKeyName relationshipKey:nil];
}


- (BOOL)willCompareObjectsInSectionWithKey:(NSInteger)sectionKey
{
    return [self targetIs:kOrigoTypeResidence] && (sectionKey == kSectionKeyMembers);
}


- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2
{
    NSComparisonResult result = NSOrderedSame;
    
    OMember *member1 = object1;
    OMember *member2 = object2;
    
    BOOL member1IsMinor = [member1 isJuvenile];
    BOOL member2IsMinor = [member2 isJuvenile];
    
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
    OMember *member = [self dataAtIndexPath:indexPath];
    
    cell.textLabel.text = member.name;
    cell.detailTextLabel.text = [member shortDetails];
    cell.imageView.image = [member smallImage];
}


#pragma mark - UITableViewDataSource conformance

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NSLocalizedString(@"Remove", @"");
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
                } else if (buttonTag == kButtonTagAddFromOrigo) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:kTargetMembers meta:_origo];
                } else if (buttonTag == kButtonTagAddContact) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetContact];
                } else if (buttonTag == kButtonTagAddParentContact) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetParentContact];
                }
            }
            
            break;
            
        case kActionSheetTagHousemate:
            if (buttonTag == kButtonTagHousemate) {
                [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetMember];
            } else if (buttonTag == kButtonTagGuardian) {
                [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetGuardian];
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
