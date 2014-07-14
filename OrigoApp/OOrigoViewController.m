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
static NSInteger const kButtonTagAddFromGroups = 3;
static NSInteger const kButtonTagAddContact = 4;
static NSInteger const kButtonTagAddParentContact = 5;
static NSInteger const kButtonTagShowInMap = 6;
static NSInteger const kButtonTagAbout = 7;

static NSInteger const kActionSheetTagCoHabitants = 1;
static NSInteger const kButtonTagCoHabitantsAll = 0;
static NSInteger const kButtonTagCoHabitantsWards = 1;
static NSInteger const kButtonTagCoHabitantsNew = 2;
static NSInteger const kButtonTagCoHabitantsGuardian = 3;


@interface OOrigoViewController () <OTableViewController, OInputCellDelegate, UIActionSheetDelegate> {
@private
    id<OOrigo> _origo;
    id<OMember> _member;
    id<OMembership> _membership;
    
    NSArray *_coHabitantCandidates;
    NSMutableDictionary *_candidatesByTag;
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
    _candidatesByTag = [NSMutableDictionary dictionary];
    
    [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddMemberButton) tag:kButtonTagAddMember];
    
    NSSet *groupCandidates = nil;
    
    if ([_origo isOfType:kOrigoTypeResidence]) {
        groupCandidates = [[OMeta m].user peersNotInOrigo:_origo];
    } else {
        groupCandidates = [[self.entity ancestorConformingToProtocol:@protocol(OMember)] peersNotInOrigo:_origo];
    }
    
    if ([groupCandidates count]) {
        _candidatesByTag[@(kButtonTagAddFromGroups)] = groupCandidates;
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Add from other groups", @"") tag:kButtonTagAddFromGroups];
    }
    
    if ([_origo isOrganised]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddContactButton) tag:kButtonTagAddContact];
        
        if ([_origo isJuvenile]) {
            _candidatesByTag[@(kButtonTagAddParentContact)] = [_origo guardians];
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Add parent contact", @"") tag:kButtonTagAddParentContact];
        }
    }
}


- (void)addMember
{
    NSMutableSet *coHabitantCandidates = nil;
    
    if ([_origo isOfType:kOrigoTypeResidence]) {
        coHabitantCandidates = [[_member housematesNotInResidence:_origo] mutableCopy];
        
        for (id<OMember> housemate in [_member housemates]) {
            [coHabitantCandidates unionSet:[housemate housematesNotInResidence:_origo]];
        }
    }
    
    if ([coHabitantCandidates count]) {
        [self presentCoHabitantsSheetWithCandidates:[coHabitantCandidates allObjects]];
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

- (void)presentCoHabitantsSheetWithCandidates:(NSArray *)candidates
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagCoHabitants];
    
    _coHabitantCandidates = [OUtil sortedArraysOfResidents:candidates excluding:nil];
    
    if ([_coHabitantCandidates count] == 1) {
        if ([_coHabitantCandidates[kButtonTagCoHabitantsAll][0] isJuvenile]) {
            [actionSheet addButtonWithTitle:[OUtil commaSeparatedListOfItems:_coHabitantCandidates[kButtonTagCoHabitantsAll] conjoinLastItem:YES] tag:kButtonTagCoHabitantsAll];
        } else {
            for (id<OMember> candidate in _coHabitantCandidates[kButtonTagCoHabitantsAll]) {
                [actionSheet addButtonWithTitle:[candidate givenName]];
            }
        }
    } else {
        [actionSheet addButtonWithTitle:[OUtil commaSeparatedListOfItems:_coHabitantCandidates[kButtonTagCoHabitantsAll] conjoinLastItem:YES] tag:kButtonTagCoHabitantsAll];
        [actionSheet addButtonWithTitle:[OUtil commaSeparatedListOfItems:_coHabitantCandidates[kButtonTagCoHabitantsWards] conjoinLastItem:YES] tag:kButtonTagCoHabitantsWards];
    }
    
    if (![_origo userIsMember] && [_member isWardOfUser]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Other guardian", @"") tag:kButtonTagCoHabitantsGuardian];
    } else {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"New housemate", @"") tag:kButtonTagCoHabitantsNew];
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
            
            self.cancelImpliesSkip = ![_member hasAddress] && ![_origo isReplicated] && ![[_member housemates] count];
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
    [self setDataForInputSection];
    
    if ([self actionIs:kActionRegister]) {
        [self setData:[_origo members] forSectionWithKey:kSectionKeyMembers];
    } else {
        if ([_origo isOfType:kOrigoTypeResidence] && ![_origo userIsMember]) {
            [self setData:[_origo residents] forSectionWithKey:kSectionKeyMembers];
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
    
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyContacts) {
        // TODO: Pick up here after summer!
        
        NSString *contactRole = nil;
        id<OMembership> membership = [_origo membershipForMember:member];
        
        if ([membership.contactRole isEqualToString:@"Parent contact"]) {
            contactRole = NSLocalizedString(@"Parent contact", @"");
        } else {
            contactRole = NSLocalizedString(_origo.type, kStringPrefixContactTitle);
        }
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", contactRole, [OUtil contactInfoForMember:member]];
    } else if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyMembers) {
        if ([member isJuvenile] && ![_origo isOfType:kOrigoTypeResidence]) {
            cell.detailTextLabel.text = [OUtil guardianInfoForMember:member];
        } else {
            cell.detailTextLabel.text = [OUtil contactInfoForMember:member];
        }
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
            if ([viewController.target isEqualToString:kTargetMembers]) {
                for (id<OMember> member in viewController.returnData) {
                    [_origo addMember:member];
                }
            } else if ([viewController.target isEqualToString:kTargetParentContact]) {
                // TODO: Pick up here after summer!
                [_origo addMember:viewController.returnData].contactRole = @"Parent contact";
            }
        } else if ([viewController.identifier isEqualToString:kIdentifierMember]) {
            // TODO: Pick up here after summer!
            if ([viewController targetIs:kTargetContact]) {
                [_origo membershipForMember:viewController.returnData].contactRole = @"Contact";
            }
        }
        
        [[OMeta m].replicator replicateIfNeeded];
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
        if (!_membership) {
            _membership = [_origo addMember:_member];
        }
        
        if ([_member isUser] && ![_member isActive]) {
            [_member makeActive];
        }
        
        if ([_origo isOfType:kOrigoTypeResidence] && ![_origo hasAddress]) {
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
                } else if (buttonTag == kButtonTagAddFromGroups) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:kTargetMembers meta:_candidatesByTag[@(kButtonTagAddFromGroups)]];
                } else if (buttonTag == kButtonTagAddContact) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetContact];
                } else if (buttonTag == kButtonTagAddParentContact) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:kTargetParentContact meta:_candidatesByTag[@(kButtonTagAddParentContact)]];
                }
            }
            
            break;
            
        case kActionSheetTagCoHabitants:
            if (buttonTag == kButtonTagCoHabitantsNew) {
                [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetMember];
            } else if (buttonTag == kButtonTagCoHabitantsGuardian) {
                [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetGuardian];
            } else {
                NSArray *coHabitants = nil;
                
                if ([_coHabitantCandidates count] == 1) {
                    if ([_coHabitantCandidates[kButtonTagCoHabitantsAll][0] isJuvenile]) {
                        coHabitants = _coHabitantCandidates[kButtonTagCoHabitantsAll];
                    } else {
                        coHabitants = @[_coHabitantCandidates[kButtonTagCoHabitantsAll][buttonIndex]];
                    }
                } else if (buttonTag == kButtonTagCoHabitantsAll) {
                    coHabitants = _coHabitantCandidates[kButtonTagCoHabitantsAll];
                } else if (buttonTag == kButtonTagCoHabitantsWards) {
                    coHabitants = _coHabitantCandidates[kButtonTagCoHabitantsWards];
                }
                
                for (id<OMember> coHabitant in coHabitants) {
                    [_origo addMember:coHabitant];
                }
                
                [self reloadSections];
            }
            
            break;
            
        default:
            break;
    }
}

@end
