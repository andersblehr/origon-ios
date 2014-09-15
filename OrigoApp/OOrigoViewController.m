//
//  OOrigoViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OOrigoViewController.h"

static NSInteger const kSectionKeyOrganisers = 1;
static NSInteger const kSectionKeyParentContacts = 2;
static NSInteger const kSectionKeyMembers = 3;

static NSInteger const kActionSheetTagAdd = 0;
static NSInteger const kButtonTagAddMember = 0;
static NSInteger const kButtonTagAddFromGroups = 1;
static NSInteger const kButtonTagAddOrganiser = 2;
static NSInteger const kButtonTagAddParentContact = 3;
static NSInteger const kButtonTagAddSubgroups = 4;

static NSInteger const kActionSheetTagEdit = 1;
static NSInteger const kButtonTagEditGroup = 0;
static NSInteger const kButtonTagEditRoles = 1;

static NSInteger const kActionSheetTagCoHabitants = 2;
static NSInteger const kButtonTagCoHabitantsAll = 0;
static NSInteger const kButtonTagCoHabitantsWards = 1;
static NSInteger const kButtonTagCoHabitantsNew = 2;
static NSInteger const kButtonTagCoHabitantsGuardian = 3;


@interface OOrigoViewController () <OTableViewController, OInputCellDelegate, UIActionSheetDelegate> {
@private
    id<OOrigo> _origo;
    id<OMember> _member;
    id<OMembership> _membership;
    
    NSArray *_eligibleCandidates;
}

@end


@implementation OOrigoViewController

#pragma mark - Auxiliary methods

- (NSString *)nameKey
{
    NSString *nameKey = nil;
    
    if ([_origo isOfType:kOrigoTypeResidence]) {
        nameKey = kMappedKeyResidenceName;
    } else if ([_origo isOfType:kOrigoTypeOrganisation]) {
        nameKey = kMappedKeyOrganisation;
    } else if ([_origo isOfType:kOrigoTypePreschoolClass]) {
        nameKey = kMappedKeyPreschoolClass;
    } else if ([_origo isOfType:kOrigoTypeSchoolClass]) {
        nameKey = kMappedKeySchoolClass;
    } else if ([_origo isOfType:kOrigoTypeTeam]) {
        nameKey = kMappedKeyTeam;
    } else if ([_origo isOfType:kOrigoTypeStudyGroup]) {
        nameKey = kMappedKeyStudyGroup;
    } else {
        nameKey = kPropertyKeyName;
    }
    
    return nameKey;
}


- (NSArray *)roleHoldersForRoleAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    NSString *role = [self dataAtIndexPath:indexPath];
    NSArray *roleHolders = nil;
    
    if (sectionKey == kSectionKeyOrganisers) {
        roleHolders = [_origo organisersWithRole:role];
    } else if (sectionKey == kSectionKeyParentContacts) {
        roleHolders = [_origo parentsWithRole:role];
    } else if (sectionKey == kSectionKeyMembers) {
        roleHolders = [_origo membersWithRole:role];
    }
    
    return roleHolders;
}


- (void)addMember
{
    NSMutableSet *coHabitantCandidates = nil;
    
    if ([_origo isOfType:kOrigoTypeResidence]) {
        coHabitantCandidates = [NSMutableSet setWithArray:[_member housematesNotInResidence:_origo]];
        
        for (id<OMember> housemate in [_member housemates]) {
            [coHabitantCandidates unionSet:[NSSet setWithArray:[housemate housematesNotInResidence:_origo]]];
        }
    }
    
    if ([coHabitantCandidates count]) {
        [self presentCoHabitantsSheetWithCandidates:[coHabitantCandidates allObjects]];
    } else {
        id target = kTargetMember;
        
        if ([_origo isJuvenile]) {
            self.presentStealthilyOnce = YES;
            
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
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:NSLocalizedString(@"Add household member", @"") delegate:self tag:kActionSheetTagCoHabitants];
    
    _eligibleCandidates = [OUtil sortedGroupsOfResidents:candidates excluding:nil];
    
    if ([_eligibleCandidates count] == 1) {
        if ([_eligibleCandidates[kButtonTagCoHabitantsAll][0] isJuvenile]) {
            [actionSheet addButtonWithTitle:[OUtil commaSeparatedListOfItems:_eligibleCandidates[kButtonTagCoHabitantsAll] conjoinLastItem:YES] tag:kButtonTagCoHabitantsAll];
        } else {
            for (id<OMember> candidate in _eligibleCandidates[kButtonTagCoHabitantsAll]) {
                [actionSheet addButtonWithTitle:[candidate givenName]];
            }
        }
    } else {
        [actionSheet addButtonWithTitle:[OUtil commaSeparatedListOfItems:_eligibleCandidates[kButtonTagCoHabitantsAll] conjoinLastItem:YES] tag:kButtonTagCoHabitantsAll];
        [actionSheet addButtonWithTitle:[OUtil commaSeparatedListOfItems:_eligibleCandidates[kButtonTagCoHabitantsWards] conjoinLastItem:YES] tag:kButtonTagCoHabitantsWards];
    }
    
    if (![_origo userIsMember] && [_member isWardOfUser]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Other guardian", @"") tag:kButtonTagCoHabitantsGuardian];
    } else {
        [actionSheet addButtonWithTitle:NSLocalizedString(kOrigoTypeResidence, kStringPrefixAddMemberButton) tag:kButtonTagCoHabitantsNew];
    }
    
    [actionSheet show];
}


#pragma mark - Selector implementations

- (void)performAddAction
{
    if ([_origo isOfType:kOrigoTypeResidence]) {
        [self addMember];
    } else {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagAdd];
        
        [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddMemberButton) tag:kButtonTagAddMember];
        
        _eligibleCandidates = [self.state eligibleCandidates];
        
        if ([_eligibleCandidates count]) {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Add from other groups", @"") tag:kButtonTagAddFromGroups];
        }
        
        if ([_origo isOrganised]) {
            [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddOrganiserButton) tag:kButtonTagAddOrganiser];
            
            if ([_origo isJuvenile]) {
                [actionSheet addButtonWithTitle:NSLocalizedString(@"Add parent contact", @"") tag:kButtonTagAddParentContact];
            }
        }
        
        if (![_origo isOfType:@[kOrigoTypeResidence, kOrigoTypeFriends]]) {
            if (![[_origo groups] count]) {
                [actionSheet addButtonWithTitle:NSLocalizedString(@"Add subgroups", @"") tag:kButtonTagAddSubgroups];
            }
        }
        
        if ([actionSheet numberOfButtons] > 1) {
            [actionSheet show];
        } else {
            [self addMember];
        }
    }
}


- (void)performEditAction
{
    if ([_origo isOfType:@[kOrigoTypeResidence, kOrigoTypeFriends]]) {
        [self scrollToTopAndToggleEditMode];
    } else {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagEdit];
        
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit", @"") tag:kButtonTagEditGroup];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit responsibilities", @"") tag:kButtonTagEditRoles];
        
        [actionSheet show];
    }
}


- (void)performGroupsAction
{
    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetGroups];
}


- (void)performMapAction
{
    
}


- (void)performInfoAction
{
    
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    _origo = [self.entity proxy];
    _member = self.state.pivotMember;
    _membership = [_origo membershipForMember:_member];
    
    if ([self actionIs:kActionRegister]) {
        self.title = NSLocalizedString(_origo.type, kStringPrefixNewOrigoTitle);
        
        if ([_origo isOfType:kOrigoTypeResidence]) {
            id<OOrigo> residence = [_member residence];
            
            if (![residence hasAddress] || ![residence isCommitted]) {
                self.title = NSLocalizedString(kOrigoTypeResidence, kStringPrefixOrigoTitle);
            } else {
                self.title = NSLocalizedString(kOrigoTypeResidence, kStringPrefixNewOrigoTitle);
            }
            
            self.cancelImpliesSkip = ![_member hasAddress] && ![_origo isReplicated] && ![[_member housemates] count];
        }
    } else if ([self actionIs:kActionDisplay]) {
        if ([_origo isOfType:kOrigoTypeResidence] && ![self aspectIs:kAspectHousehold]) {
            self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:NSLocalizedString(kOrigoTypeResidence, kStringPrefixOrigoTitle)];
        } else {
            self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:_origo.name];
        }
        
        if ([_origo isCommitted] && [_member isCommitted]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem infoButtonWithTarget:self];
            
            if ([_origo hasAddress]) {
                [self.navigationItem addRightBarButtonItem:[UIBarButtonItem mapButtonWithTarget:self]];
            }
            
            if ([[_origo groups] count]) {
                [self.navigationItem addRightBarButtonItem:[UIBarButtonItem groupsButtonWithTarget:self]];
            }
            
            if ([_origo userCanEdit]) {
                [self.navigationItem addRightBarButtonItem:[UIBarButtonItem editButtonWithTarget:self]];
                [self.navigationItem addRightBarButtonItem:[UIBarButtonItem plusButtonWithTarget:self]];
            }
        } else if (![_origo isReplicated]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem editButtonWithTarget:self];
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
        } else {
            [self setData:[_origo organiserRoles] forSectionWithKey:kSectionKeyOrganisers];
            [self setData:[_origo parentRoles] forSectionWithKey:kSectionKeyParentContacts];
            [self setData:[_origo regulars] forSectionWithKey:kSectionKeyMembers];
        }
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyMembers) {
        id<OMember> member = [self dataAtIndexPath:indexPath];
        id<OMembership> membership = [_origo membershipForMember:member];
        
        cell.textLabel.text = [member publicName];
        cell.detailTextLabel.text = [OUtil memberInfoFromMembership:membership];
        [OUtil setImageForMember:member inTableViewCell:cell];
        cell.destinationId = kIdentifierMember;
    } else {
        NSString *role = [self dataAtIndexPath:indexPath];
        NSArray *roleHolders = [self roleHoldersForRoleAtIndexPath:indexPath];
        
        cell.textLabel.text = role;
        
        if ([roleHolders count] == 1) {
            cell.detailTextLabel.text = [[roleHolders[0] appellationUseGivenName:NO] stringByCapitalisingFirstLetter];
            [OUtil setImageForMember:roleHolders[0] inTableViewCell:cell];
            cell.destinationId = kIdentifierMember;
        } else {
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfItems:roleHolders conjoinLastItem:NO];
            [OUtil setTonedDownIconWithFileName:kIconFileRoleHolders inTableViewCell:cell];
            cell.destinationId = kIdentifierValueList;
            cell.destinationMeta = role;
        }
    }
}


- (id)destinationTargetForIndexPath:(NSIndexPath *)indexPath
{
    id target = nil;
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyMembers) {
        target = [self dataAtIndexPath:indexPath];
    } else {
        NSArray *roleHolders = [self roleHoldersForRoleAtIndexPath:indexPath];
        
        if ([roleHolders count] == 1) {
            target = roleHolders[0];
        } else {
            NSString *role = [self dataAtIndexPath:indexPath];
            
            if (sectionKey == kSectionKeyOrganisers) {
                target = @{role: kAspectOrganiserRole};
            } else if (sectionKey == kSectionKeyParentContacts) {
                target = @{role: kAspectParentRole};
            }
        }
    }
    
    return target;
}


- (NSArray *)toolbarButtons
{
    NSArray *toolbarButtons = nil;
    
    if ([_origo isCommitted]) {
        toolbarButtons = [[OMeta m].switchboard toolbarButtonsForOrigo:_origo presenter:self];
    }
    
    return toolbarButtons;
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
    NSInteger number;
    
    if (sectionKey == kSectionKeyOrganisers) {
        NSString *contactTitle = nil;
        
        if ([_origo isOfType:kOrigoTypePreschoolClass]) {
            contactTitle = _preschoolTeacher_;
        } else if ([_origo isOfType:kOrigoTypeSchoolClass]) {
            contactTitle = _teacher_;
        } else if ([_origo isOfType:kOrigoTypeTeam]) {
            contactTitle = _coach_;
        } else if ([_origo isOfType:kOrigoTypeStudyGroup]) {
            contactTitle = _lecturer_;
        }
        
        number = ([[_origo organisers] count] > 1) ? pluralIndefinite : singularIndefinite;
        text = [[OLanguage nouns][contactTitle][number] capitalizedString];
    } else if (sectionKey == kSectionKeyParentContacts) {
        number = ([[_origo parentContacts] count] > 1) ? pluralIndefinite : singularIndefinite;
        text = [[OLanguage nouns][_parentContact_][number] capitalizedString];
    } else if (sectionKey == kSectionKeyMembers) {
        text = NSLocalizedString(_origo.type, kStringPrefixMembersTitle);
    }
    
    return text;
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    return NSLocalizedString(_origo.type, kStringPrefixFooter);
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
    
    BOOL isMinor1 = [member1 isJuvenile];
    BOOL isMinor2 = [member2 isJuvenile];
    
    if (isMinor1 != isMinor2) {
        if (isMinor1 && !isMinor2) {
            result = NSOrderedDescending;
        } else {
            result = NSOrderedAscending;
        }
    } else {
        result = [member1.name localizedCaseInsensitiveCompare:member2.name];
    }
    
    return result;
}


- (void)willDisplayInputCell:(OTableViewCell *)inputCell
{
    if ([self actionIs:kActionRegister] && [_origo isOfType:kOrigoTypeResidence]) {
        if ([_member isUser] && ![_member hasAddress]) {
            [[inputCell inputFieldForKey:kMappedKeyResidenceName] setValue:NSLocalizedString(kMappedKeyResidenceName, kStringPrefixDefault)];
        }
    }
}


- (BOOL)canDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDeleteCell = NO;
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if ([_origo isCommitted] && [_origo userCanEdit]) {
        if (sectionKey == kSectionKeyMembers) {
            canDeleteCell = ![[self dataAtIndexPath:indexPath] isUser];
        } else {
            canDeleteCell = ([[self roleHoldersForRoleAtIndexPath:indexPath] count] == 1);
        }
    }
    
    return canDeleteCell;
}



- (void)willDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyMembers) {
        [[_origo membershipForMember:[self dataAtIndexPath:indexPath]] expire];
    } else {
        NSString *role = [self dataAtIndexPath:indexPath];
        id<OMember> member = [self roleHoldersForRoleAtIndexPath:indexPath][0];
        id<OMembership> membership = [_origo membershipForMember:member];
        
        if (sectionKey == kSectionKeyOrganisers) {
            [membership removeAffiliation:role ofType:kAffiliationTypeOrganiserRole];
        } else if (sectionKey == kSectionKeyParentContacts) {
            [membership removeAffiliation:role ofType:kAffiliationTypeParentRole];
        }
    }
}


- (void)willDismissModalViewController:(OTableViewController *)viewController
{
    if (!viewController.didCancel) {
        if ([viewController.identifier isEqualToString:kIdentifierMember]) {
            if ([viewController targetIs:kTargetOrganiser]) {
                [self reloadSectionWithKey:kSectionKeyOrganisers];
            }
        } if ([viewController.identifier isEqualToString:kIdentifierValueList]) {
            if ([viewController targetIs:kTargetRoles]) {
                if ([[_origo organiserRoles] count]) {
                    [self reloadSectionWithKey:kSectionKeyOrganisers];
                }
                
                if ([[_origo parentRoles] count]) {
                    [self reloadSectionWithKey:kSectionKeyParentContacts];
                }
                
                if ([[_origo memberRoles] count]) {
                    [self reloadSectionWithKey:kSectionKeyMembers];
                }
            } else if ([viewController targetIs:kTargetGroups]) {
                BOOL hasGroups = [[_origo groups] count] > 0;
                UIBarButtonItem *groupsButton = [self.navigationItem rightBarButtonItemWithTag:kBarButtonTagGroups];
                
                if (!groupsButton && hasGroups) {
                    [self.navigationItem insertRightBarButtonItem:[UIBarButtonItem groupsButtonWithTarget:self] atIndex:[_origo hasAddress] ? 2 : 1];
                } else if (groupsButton && !hasGroups) {
                    [self.navigationItem removeRightBarButtonItem:groupsButton];
                }
            }
        } else if ([viewController.identifier isEqualToString:kIdentifierValuePicker]) {
            if ([viewController targetIs:kTargetMembers]) {
                for (id<OMember> member in viewController.returnData) {
                    [_origo addMember:member];
                }
                
                [self reloadSections];
            } else if ([viewController aspectIs:kAspectParentRole]) {
                [self reloadSectionWithKey:kSectionKeyParentContacts];
            }
            
            [[OMeta m].replicator replicateIfNeeded];
        }
    }
}


#pragma mark - OInputCellDelegate conformance

- (OInputCellBlueprint *)inputCellBlueprint
{
    OInputCellBlueprint *blueprint = [[OInputCellBlueprint alloc] init];
    
    blueprint.titleKey = [self nameKey];

    if ([_origo isOfType:kOrigoTypeResidence]) {
        blueprint.detailKeys = @[kPropertyKeyAddress, kPropertyKeyTelephone];
        blueprint.multiLineTextKeys = @[kPropertyKeyAddress];
    } else if ([_origo isOfType:kOrigoTypeOrganisation]) {
        blueprint.detailKeys = @[kMappedKeyOrganisationDescription, kPropertyKeyAddress, kPropertyKeyTelephone];
        blueprint.multiLineTextKeys = @[kMappedKeyOrganisationDescription, kPropertyKeyAddress];
    } else if ([_origo isOfType:kOrigoTypePreschoolClass]) {
        blueprint.detailKeys = @[kMappedKeyPreschool, kPropertyKeyAddress];
        blueprint.multiLineTextKeys = @[kPropertyKeyAddress];
    } else if ([_origo isOfType:kOrigoTypeSchoolClass]) {
        blueprint.detailKeys = @[kMappedKeySchool, kPropertyKeyAddress];
        blueprint.multiLineTextKeys = @[kPropertyKeyAddress];
    } else if ([_origo isOfType:kOrigoTypeTeam]) {
        blueprint.detailKeys = @[kMappedKeyClub];
    } else if ([_origo isOfType:kOrigoTypeStudyGroup]) {
        blueprint.detailKeys = @[kMappedKeyInstitution];
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
            self.navigationItem.rightBarButtonItems = @[[UIBarButtonItem plusButtonWithTarget:self]];
        }
    } else {
        [self toggleEditMode];

        if ([self actionIs:kActionDisplay]) {
            UIBarButtonItem *mapButton = [self.navigationItem rightBarButtonItemWithTag:kBarButtonTagMap];
            
            if (!mapButton && [_origo hasAddress]) {
                [self.navigationItem insertRightBarButtonItem:[UIBarButtonItem mapButtonWithTarget:self] atIndex:1];
            } else if (mapButton && ![_origo hasAddress]) {
                [self.navigationItem removeRightBarButtonItem:mapButton];
            }
        }
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
        case kActionSheetTagEdit:
            if ([actionSheet tagForButtonIndex:buttonIndex] == kButtonTagEditGroup) {
                [self scrollToTopAndToggleEditMode];
            }
            
            break;
            
        default:
            break;
    }
}


- (void)actionSheet:(OActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex < actionSheet.cancelButtonIndex) {
        NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
        
        switch (actionSheet.tag) {
            case kActionSheetTagEdit:
                if (buttonTag == kButtonTagEditRoles) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetRoles];
                }
                
                break;
                
            case kActionSheetTagAdd:
                if (buttonTag == kButtonTagAddMember) {
                    [self addMember];
                } else if (buttonTag == kButtonTagAddFromGroups) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:kTargetMembers meta:_eligibleCandidates];
                } else if (buttonTag == kButtonTagAddOrganiser) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetOrganiser];
                } else if (buttonTag == kButtonTagAddParentContact) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:@{kTargetRole: kAspectParentRole}];
                } else if (buttonTag == kButtonTagAddSubgroups) {
                    self.presentStealthilyOnce = YES;
                    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetGroups];
                    
                }
                
                break;
                
            case kActionSheetTagCoHabitants:
                if (buttonTag == kButtonTagCoHabitantsNew) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetMember];
                } else if (buttonTag == kButtonTagCoHabitantsGuardian) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetGuardian];
                } else {
                    NSArray *coHabitants = nil;
                    
                    if ([_eligibleCandidates count] == 1) {
                        if ([_eligibleCandidates[kButtonTagCoHabitantsAll][0] isJuvenile]) {
                            coHabitants = _eligibleCandidates[kButtonTagCoHabitantsAll];
                        } else {
                            coHabitants = @[_eligibleCandidates[kButtonTagCoHabitantsAll][buttonIndex]];
                        }
                    } else if (buttonTag == kButtonTagCoHabitantsAll) {
                        coHabitants = _eligibleCandidates[kButtonTagCoHabitantsAll];
                    } else if (buttonTag == kButtonTagCoHabitantsWards) {
                        coHabitants = _eligibleCandidates[kButtonTagCoHabitantsWards];
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
}

@end
