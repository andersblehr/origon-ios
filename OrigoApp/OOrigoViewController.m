//
//  OOrigoViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OOrigoViewController.h"

static NSInteger const kSectionKeyOrigo = 0;
static NSInteger const kSectionKeyOrganisers = 1;
static NSInteger const kSectionKeyParentContacts = 2;
static NSInteger const kSectionKeyMembers = 3;

static NSInteger const kActionSheetTagAdd = 0;
static NSInteger const kButtonTagAddMember = 0;
static NSInteger const kButtonTagAddFromGroups = 1;
static NSInteger const kButtonTagAddOrganiser = 2;
static NSInteger const kButtonTagAddParentContact = 3;

static NSInteger const kActionSheetTagEdit = 1;
static NSInteger const kButtonTagEditGroup = 0;
static NSInteger const kButtonTagEditRoles = 1;
static NSInteger const kButtonTagEditSubgroups = 2;

static NSInteger const kActionSheetTagCoHabitants = 2;
static NSInteger const kButtonTagCoHabitantsAll = 0;
static NSInteger const kButtonTagCoHabitantsWards = 1;
static NSInteger const kButtonTagCoHabitantsNew = 2;
static NSInteger const kButtonTagCoHabitantsGuardian = 3;

static NSInteger const kAlertTagParentContactRole = 0;
static NSInteger const kButtonIndexOK = 1;


@interface OOrigoViewController () <OTableViewController, OInputCellDelegate, UIActionSheetDelegate, UIAlertViewDelegate> {
@private
    id<OOrigo> _origo;
    id<OMember> _member;
    id<OMembership> _membership;
    id<OMember> _parentContact;
    
    NSArray *_coHabitantCandidates;
    NSArray *_peerCandidates;
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


- (void)assemblePeerCandidates
{
    if ([_origo isOfType:kOrigoTypeResidence]) {
        _peerCandidates = [[OMeta m].user peersNotInOrigo:_origo];
    } else {
        _peerCandidates = [[self.entity ancestorConformingToProtocol:@protocol(OMember)] peersNotInOrigo:_origo];
    }
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
        
        if ([_peerCandidates count]) {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Add from other groups", @"") tag:kButtonTagAddFromGroups];
        }
        
        if ([_origo isOrganised]) {
            [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddOrganiserButton) tag:kButtonTagAddOrganiser];
            
            if ([_origo isJuvenile]) {
                [actionSheet addButtonWithTitle:NSLocalizedString(@"Add parent contact", @"") tag:kButtonTagAddParentContact];
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
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit roles", @"") tag:kButtonTagEditRoles];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit subgroups", @"") tag:kButtonTagEditSubgroups];
        
        [actionSheet show];
    }
}


- (void)showMap
{
    
}


- (void)showInfo
{
    
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
                self.title = NSLocalizedString(kOrigoTypeResidence, kStringPrefixOrigoTitle);
            } else {
                self.title = NSLocalizedString(kOrigoTypeResidence, kStringPrefixNewOrigoTitle);
            }
            
            self.cancelImpliesSkip = ![_member hasAddress] && ![_origo isReplicated] && ![[_member housemates] count];
        }
    } else if ([self actionIs:kActionDisplay]) {
        if ([_origo isOfType:kOrigoTypeResidence] && ![self aspectIs:kAspectHousehold]) {
            self.navigationItem.backBarButtonItem = [UIBarButtonItem buttonWithTitle:NSLocalizedString(kOrigoTypeResidence, kStringPrefixOrigoTitle)];
        } else {
            self.navigationItem.backBarButtonItem = [UIBarButtonItem buttonWithTitle:_origo.name];
        }
        
        if ([_origo isCommitted] && [_member isCommitted]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem infoButtonWithTarget:self];
            
            if ([_origo hasAddress]) {
                [self.navigationItem addRightBarButtonItem:[UIBarButtonItem mapButtonWithTarget:self]];
            }
            
            if ([_origo userCanEdit]) {
                [self assemblePeerCandidates];
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
            [self setData:[_origo organisers] forSectionWithKey:kSectionKeyOrganisers];
            [self setData:[_origo parentContacts] forSectionWithKey:kSectionKeyParentContacts];
            [self setData:[_origo regulars] forSectionWithKey:kSectionKeyMembers];
        }
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    id<OMember> member = [self dataAtIndexPath:indexPath];
    
    cell.textLabel.text = [member publicName];
    cell.imageView.image = [OUtil smallImageForMember:member];
    cell.destinationId = kIdentifierMember;
    
    if (sectionKey == kSectionKeyOrganisers) {
        cell.detailTextLabel.text = [OUtil commaSeparatedListOfItems:[[_origo membershipForMember:member] organiserRoles] conjoinLastItem:NO];
    } else if (sectionKey == kSectionKeyParentContacts) {
        cell.detailTextLabel.text = [OUtil commaSeparatedListOfItems:[[_origo membershipForMember:member] parentRoles] conjoinLastItem:NO];
    } else if (sectionKey == kSectionKeyMembers) {
        NSString *details = nil;
        id<OMembership> membership = [_origo membershipForMember:member];
        
        if ([member isJuvenile] && ![_origo isOfType:kOrigoTypeResidence]) {
            details = [OUtil guardianInfoForMember:member];
        } else if ([membership hasRoleOfType:kRoleTypeMemberRole]) {
            details = [OUtil commaSeparatedListOfItems:[membership memberRoles] conjoinLastItem:NO];
        }
        
        if (details) {
            cell.detailTextLabel.text = details;
        }
    }
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
    
    if ([self sectionKeyForIndexPath:indexPath] != kSectionKeyOrigo) {
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


- (void)willDismissModalViewController:(OTableViewController *)viewController
{
    if (!viewController.didCancel) {
        if ([viewController.identifier isEqualToString:kIdentifierValueList]) {
            if ([viewController targetIs:kTargetRoles]) {
                [self.tableView reloadData];
                //[self reloadSections];
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
        blueprint.detailKeys = @[kMappedKeyPreschool];
    } else if ([_origo isOfType:kOrigoTypeSchoolClass]) {
        blueprint.detailKeys = @[kMappedKeySchool];
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
                    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetRoles meta:_origo];
                }
                
                break;
                
            case kActionSheetTagAdd:
                if (buttonTag == kButtonTagAddMember) {
                    [self addMember];
                } else if (buttonTag == kButtonTagAddFromGroups) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:kTargetMembers meta:_peerCandidates];
                } else if (buttonTag == kButtonTagAddOrganiser) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetOrganiser];
                } else if (buttonTag == kButtonTagAddParentContact) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:@{kTargetRole: kAspectParentRole} meta:_origo];
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
}


#pragma mark - UIAlertViewDelegate conformance

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertTagParentContactRole:
            if (buttonIndex == kButtonIndexOK) {
                id<OMembership> membership = [_origo addMember:_parentContact];
                NSString *parentContactRole = [alertView textFieldAtIndex:0].text;
                
                [membership addRole:parentContactRole ofType:kRoleTypeParentRole];
                
                [[OMeta m].replicator replicate];
                [self reloadSectionWithKey:kSectionKeyParentContacts];
            } else {
                [self.dismisser dismissModalViewController:self];
            }
            
            break;
            
        default:
            break;
    }
}

@end
