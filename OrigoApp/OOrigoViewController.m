//
//  OOrigoViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OOrigoViewController.h"

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


@interface OOrigoViewController () <OTableViewController, OInputCellDelegate, UIActionSheetDelegate> {
@private
    id<OOrigo> _origo;
    id<OMember> _member;
    id<OMembership> _membership;
    
    NSArray *_housemateCandidates;
}

@end


@implementation OOrigoViewController

#pragma mark - Auxiliary methods

- (NSString *)nameKey
{
    NSString *nameKey = nil;
    
    if ([_origo isOfType:kOrigoTypeResidence]) {
        nameKey = kMappedKeyResidenceName;
    } else if ([_origo isOfType:kOrigoTypeSchoolClass]) {
        nameKey = kMappedKeyClass;
    } else {
        nameKey = kPropertyKeyName;
    }
    
    return nameKey;
}


- (void)addNewMemberButtonsToActionSheet:(OActionSheet *)actionSheet
{
    [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddMemberButton) tag:kButtonTagAddMember];
    
    if (![_origo isOfType:kOrigoTypeResidence] && [[_member peersNotInOrigo:_origo] count]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Add from other groups", @"") tag:kButtonTagAddFromOrigo];
    }
    
    if ([_origo isOrganised]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddContactButton) tag:kButtonTagAddContact];
        
        if ([_origo isJuvenile]) {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Add parent contact", @"") tag:kButtonTagAddParentContact];
        }
    }
}


- (void)addMember
{
    if ([_origo isOfType:kOrigoTypeResidence]) {
        _housemateCandidates = [_member housematesNotInResidence:_origo];
    }
    
    if ([_housemateCandidates count]) {
        [self presentHousemateCandidatesSheet];
    } else {
        id target = kTargetMember;
        
        if ([_origo isJuvenile]) {
            target = kTargetJuvenile;
        } else if ([_origo isOfType:kOrigoTypeResidence] && [self aspectIs:kAspectJuvenile]) {
            target = kTargetGuardian;
        }
        
        [self presentModalViewControllerWithIdentifier:kIdentifierMember target:target];
    }
}


#pragma mark - Actions sheets

- (void)presentHousemateCandidatesSheet
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagHousemate];
    
    for (id<OMember> candidate in _housemateCandidates) {
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
    
    if ([_origo userCanEdit]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit", @"") tag:kButtonTagEdit];
        
        if ([_origo isOrganised] && [_origo hasContacts]) {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit roles", @"") tag:kButtonTagEditRoles];
        }
        
        [self addNewMemberButtonsToActionSheet:actionSheet];
    }
        
    if ([_origo hasAddress]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Show in map", @"") tag:kButtonTagShowInMap];
    }
    
    NSString *displayName = nil;
    
    if (![_origo isOfType:kOrigoTypeResidence] || [self aspectIs:kAspectHousehold]) {
        displayName = _origo.name;
    } else if ([_origo hasAddress]) {
        displayName = [_origo shortAddress];
    } else {
        displayName = NSLocalizedString(@"About this household", @"");
    }
    
    [actionSheet addButtonWithTitle:[NSString stringWithFormat:NSLocalizedString(@"About %@", @""), displayName] tag:kButtonTagAbout];
    
    [actionSheet show];
}


- (void)addItem
{
    if (![_origo isOfType:kOrigoTypeResidence]) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagActionSheet];
        
        [self addNewMemberButtonsToActionSheet:actionSheet];
        
        if ([actionSheet numberOfButtons] > 2) {
            [actionSheet show];
        } else {
            [self addMember];
        }
    } else {
        [self addMember];
    }
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    _origo = [self.entity proxy];
    _member = [self.entity ancestorConformingToProtocol:@protocol(OMember)];
    _membership = [_origo membershipForMember:_member];
    
    if ([self actionIs:kActionRegister]) {
        self.title = NSLocalizedString(_origo.type, kStringPrefixNewOrigoTitle);
        
        if ([_origo isOfType:kOrigoTypeResidence]) {
            id<OOrigo> residence = [_member residence];
            
            if (![residence hasAddress] || ![residence isCommitted]) {
                self.title = NSLocalizedString(_origo.type, kStringPrefixOrigoTitle);
            }
            
            if ([_origo hasAddress]) {
                [self.state toggleAction:@[kActionRegister, kActionDisplay]];
                
                self.navigationItem.leftBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
                self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
            } else {
                self.cancelImpliesSkip = ![_origo hasAddress] && ![_member isCommitted];
            }
        }
    } else {
        if ([_origo isOfType:kOrigoTypeResidence] && ![self aspectIs:kAspectHousehold]) {
            self.title = NSLocalizedString(kOrigoTypeResidence, kStringPrefixOrigoTitle);
        } else {
            self.title = _origo.name;
        }
        
        if ([self actionIs:kActionDisplay]) {
            if ([_origo isCommitted] && [_member isCommitted]) {
                self.navigationItem.rightBarButtonItem = [UIBarButtonItem actionButtonWithTarget:self];
            } else if (![_origo isReplicated]) {
                self.navigationItem.rightBarButtonItem = [UIBarButtonItem editButtonWithTarget:self];
            }
        }
    }
}


- (void)loadData
{
    if ([self actionIs:kActionRegister]) {
        [self setDataForInputSection];
        [self setData:@[_member] forSectionWithKey:kSectionKeyMembers];
    } else {
        if (![_origo isOfType:kOrigoTypeResidence] || [_origo hasAddress]) {
            [self setDataForInputSection];
        } else {
            [self setData:[NSSet set] forSectionWithKey:kSectionKeyOrigo];
        }
        
        if ([_origo isOfType:kOrigoTypeResidence] && ![_origo userIsMember]) {
            NSMutableSet *wardPeers = [NSMutableSet setWithSet:[[OMeta m].user wards]];
            NSMutableSet *visibleMembers = [NSMutableSet set];
            
            for (id<OMember> ward in [[OMeta m].user wards]) {
                [wardPeers unionSet:[ward peers]];
            }
            
            for (id<OMember> member in [_origo members]) {
                if (![member isJuvenile] || [wardPeers containsObject:member]) {
                    [visibleMembers addObject:member];
                }
            }
            
            [self setData:visibleMembers forSectionWithKey:kSectionKeyMembers];
        } else if ([_origo isJuvenile]) {
            [self setData:[_origo contacts] forSectionWithKey:kSectionKeyContacts];
            [self setData:[_origo regulars] forSectionWithKey:kSectionKeyMembers];
        } else {
            [self setData:[_origo members] forSectionWithKey:kSectionKeyMembers];
        }
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    id<OMember> member = [self dataAtIndexPath:indexPath];
    
    cell.textLabel.text = [member publicName];
    cell.imageView.image = [OUtil smallImageForMember:member];
    cell.destinationId = kIdentifierMember;
    
    if ([member isJuvenile] && ![_origo isOfType:kOrigoTypeResidence]) {
        if (![member isWardOfUser]) {
            NSSet *guardians = [member parents];
            
            if (![guardians count]) {
                guardians = [member guardians];
            }
            
            cell.detailTextLabel.text = [NSString stringWithFormat:@"(%@)", [OUtil commaSeparatedListOfItems:guardians conjoinLastItem:NO]];
        }
    } else {
        cell.detailTextLabel.text = [OUtil contactInfoForMember:member];
    }
}


- (NSArray *)toolbarButtons
{
    return [_origo isCommitted] ? [[OMeta m].switchboard toolbarButtonsForOrigo:_origo presenter:self] : nil;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasFooter = NO;
    
    if (self.isModal && ![self actionIs:kActionRegister]) {
        hasFooter = [self isBottomSectionKey:sectionKey] && [_origo userCanEdit];
    }
    
    return hasFooter;
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kSectionKeyContacts) {
        text = [[OLanguage nouns][_contact_][pluralIndefinite] capitalizedString];
    } else if (sectionKey == kSectionKeyMembers) {
        text = NSLocalizedString(_origo.type, kStringPrefixMemberListTitle);
    }
    
    return text;
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    return NSLocalizedString(_origo.type, kStringPrefixFooter);
}


- (void)willDisplayInputCell:(OTableViewCell *)cell
{
    if ([self actionIs:kActionRegister] && [_origo isOfType:kOrigoTypeResidence]) {
        if ([_member isUser] && ![_member hasAddress]) {
            [[cell inputFieldForKey:kMappedKeyResidenceName] setValue:NSLocalizedString(kMappedKeyResidenceName, kStringPrefixDefault)];
        }
    }
}


- (BOOL)canDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDeleteCell = NO;
    
    if (indexPath.section != kSectionKeyOrigo) {
        if ([_origo isCommitted] && [_origo userCanEdit]) {
            canDeleteCell = ![[self dataAtIndexPath:indexPath] isUser];
        }
    }
    
    return canDeleteCell;
}


- (BOOL)canCompareObjectsInSectionWithKey:(NSInteger)sectionKey
{
    return [self targetIs:kOrigoTypeResidence] && (sectionKey == kSectionKeyMembers);
}


- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2
{
    NSComparisonResult result = NSOrderedSame;
    
    id<OMember> member1 = object1;
    id<OMember> member2 = object2;
    
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


- (NSString *)sortKeyForSectionWithKey:(NSInteger)sectionKey
{
    return [OUtil sortKeyWithPropertyKey:kPropertyKeyName relationshipKey:nil];
}


- (void)didDismissModalViewController:(OTableViewController *)viewController
{
    if (!viewController.didCancel) {
        if ([viewController.identifier isEqualToString:kIdentifierValuePicker]) {
            for (id<OMember> member in viewController.returnData) {
                [_origo addMember:member];
            }
            
            [[OMeta m].replicator replicate];
        } else if ([viewController.identifier isEqualToString:kIdentifierMember]) {
            // TODO:
        }
        
        [self reloadSections];
    }
}


#pragma mark - OInputCellDelegate conformance

- (OInputCellBlueprint *)inputCellBlueprint
{
    OInputCellBlueprint *blueprint = [[OInputCellBlueprint alloc] init];

    if ([_origo isOfType:kOrigoTypeResidence]) {
        blueprint.titleKey = kMappedKeyResidenceName;
        blueprint.detailKeys = @[kPropertyKeyAddress, kPropertyKeyTelephone];
        blueprint.multiLineTextKeys = @[kPropertyKeyAddress];
    } else if ([_origo isOfType:kOrigoTypeOrganisation]) {
        blueprint.titleKey = kPropertyKeyName;
        blueprint.detailKeys = @[kMappedKeyPurpose, kPropertyKeyAddress, kPropertyKeyTelephone];
        blueprint.multiLineTextKeys = @[kMappedKeyPurpose, kPropertyKeyAddress];
    } else if ([_origo isOfType:kOrigoTypeSchoolClass]) {
        blueprint.titleKey = kMappedKeyClass;
        blueprint.detailKeys = @[kMappedKeySchool];
    } else {
        blueprint.titleKey = kPropertyKeyName;
        blueprint.detailKeys = @[kPropertyKeyDescriptionText];
        blueprint.multiLineTextKeys = @[kPropertyKeyDescriptionText];
    }
    
    return blueprint;
}


- (BOOL)isReceivingInput
{
    return [self actionIs:kActionInput];
}


- (BOOL)inputIsValid
{
    BOOL isValid = NO;
    
    if ([self targetIs:kOrigoTypeResidence]) {
        isValid = [self.inputCell hasValidValueForKey:kPropertyKeyAddress];
    } else {
        isValid = [self.inputCell hasValidValueForKey:[self nameKey]];
    }
    
    return isValid;
}


- (void)processInput
{
    [self.inputCell writeInput];
    
    if ([self actionIs:kActionRegister]) {
        _membership = [_origo addMember:_member];
        
        if ([_member isUser] && ![_member isActive]) {
            [_member makeActive];
        }
        
        if ([_origo isOfType:kOrigoTypeResidence] && [self aspectIs:kAspectJuvenile]) {
            [self.dismisser dismissModalViewController:self];
        } else {
            [self toggleEditMode];
            [self.inputCell readData];
            
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
        }
    } else {
        [self toggleEditMode];
    }
}


- (BOOL)isDisplayableFieldWithKey:(NSString *)key
{
    BOOL isVisible = ![key isEqualToString:kMappedKeyResidenceName];
    
    if (!isVisible && [_origo userIsMember]) {
        isVisible = YES;
    }
    
    return isVisible;
}


- (BOOL)shouldCommitEntity:(id)entity
{
    return [self.entity.ancestor isCommitted];
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
