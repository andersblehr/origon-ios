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

static NSInteger const kActionSheetTagActionSheet = 0;
static NSInteger const kButtonTagEdit = 0;
static NSInteger const kButtonTagEditRoles = 1;
static NSInteger const kButtonTagEditSubgroups = 2;
static NSInteger const kButtonTagAdd = 3;
static NSInteger const kButtonTagAddMember = 4;
static NSInteger const kButtonTagAddFromGroups = 5;
static NSInteger const kButtonTagAddContact = 6;
static NSInteger const kButtonTagAddParentContact = 7;
static NSInteger const kButtonTagShowInMap = 8;
static NSInteger const kButtonTagAbout = 9;

static NSInteger const kActionSheetTagCoHabitants = 1;
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
    } else if ([_origo isOfType:kOrigoTypeOrganisation]) {
        nameKey = kMappedKeyOrganisation;
    } else if ([_origo isOfType:kOrigoTypePreschoolClass]) {
        nameKey = kMappedKeyPreschoolClass;
    } else if ([_origo isOfType:kOrigoTypeSchoolClass]) {
        nameKey = kMappedKeySchoolClass;
    } else if ([_origo isOfType:kOrigoTypeTeam]) {
        nameKey = kMappedKeyTeam;
    } else if ([_origo isOfType:kOrigoTypeStudentGroup]) {
        nameKey = kMappedKeyStudentGroup;
    } else {
        nameKey = kPropertyKeyName;
    }
    
    return nameKey;
}


- (void)assembleOrigoCandidates
{
    _candidatesByTag = [NSMutableDictionary dictionary];
    
    if ([_origo isOfType:kOrigoTypeResidence]) {
        _candidatesByTag[@(kButtonTagAddFromGroups)] = [[OMeta m].user peersNotInOrigo:_origo];
    } else {
        _candidatesByTag[@(kButtonTagAddFromGroups)] = [[self.entity ancestorConformingToProtocol:@protocol(OMember)] peersNotInOrigo:_origo];
    }
}


- (void)addNewMemberButtonsToActionSheet:(OActionSheet *)actionSheet
{
    [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddMemberButton) tag:kButtonTagAddMember];
    
    if (!_candidatesByTag) {
        [self assembleOrigoCandidates];
    }
    
    if ([_candidatesByTag[@(kButtonTagAddFromGroups)] count]) {
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


#pragma mark - Input dialogues

- (void)presentParentContactRoleDialogue
{
    NSString *message = nil;
    
    if ([_parentContact isUser]) {
        message = NSLocalizedString(@"What is your contact role?", @"");
    } else {
        message = [NSString stringWithFormat:NSLocalizedString(@"What is %@'s contact role?", @""), [_parentContact givenName]];
    }
    
    UIAlertView *dialogueView = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
    dialogueView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [dialogueView textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
    [dialogueView textFieldAtIndex:0].placeholder = NSLocalizedString(@"Contact role", @"");
    dialogueView.tag = kAlertTagParentContactRole;
    
    [dialogueView show];
}


#pragma mark - Selector implementations

- (void)presentActionSheet
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagActionSheet];
    
    if ([_origo userCanEdit]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit", @"") tag:kButtonTagEdit];
        
        if (![_origo isOfType:kOrigoTypeResidence]) {
            [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixEditRolesButton) tag:kButtonTagEditRoles];
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit subgroups", @"") tag:kButtonTagEditSubgroups];
        }
        
        [self assembleOrigoCandidates];

        if ([_origo isOrganised] || [_candidatesByTag[@(kButtonTagAddFromGroups)] count]) {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Add...", @"") tag:kButtonTagAdd];
        } else {
            [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddMemberButton) tag:kButtonTagAddMember];
        }
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
        displayName = [OLanguage nouns][_household_][singularDefinite];
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
        NSString *organiserRoles = [OUtil commaSeparatedListOfItems:[[_origo membershipForMember:member] organiserRoles] conjoinLastItem:NO];
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ – %@", [OUtil contactInfoForMember:member], organiserRoles];
    } else if (sectionKey == kSectionKeyParentContacts) {
        NSString *parentContactRoles = [OUtil commaSeparatedListOfItems:[[_origo membershipForMember:member] parentContactRoles] conjoinLastItem:NO];
        
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ – %@", [OUtil contactInfoForMember:member], parentContactRoles];
    } else if (sectionKey == kSectionKeyMembers) {
        id<OMembership> membership = [_origo membershipForMember:member];
        NSString *details = nil;
        
        if ([member isJuvenile] && ![_origo isOfType:kOrigoTypeResidence]) {
            details = [OUtil guardianInfoForMember:member];
        } else {
            details = [OUtil contactInfoForMember:member];
        }
        
        if ([membership hasRoleOfType:kRoleTypeMemberContact]) {
            NSString *memberRoles = [OUtil commaSeparatedListOfItems:[membership memberRoles] conjoinLastItem:NO];
            
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ – %@", details, memberRoles];
        } else {
            cell.detailTextLabel.text = details;
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
    NSInteger number;
    
    if (sectionKey == kSectionKeyOrganisers) {
        NSString *contactTitle = nil;
        
        if ([_origo isOfType:kOrigoTypePreschoolClass]) {
            contactTitle = _preschoolTeacher_;
        } else if ([_origo isOfType:kOrigoTypeSchoolClass]) {
            contactTitle = _teacher_;
        } else if ([_origo isOfType:kOrigoTypeTeam]) {
            contactTitle = _coach_;
        } else if ([_origo isOfType:kOrigoTypeStudentGroup]) {
            contactTitle = _lecturer_;
        } else {
            contactTitle = _contact_;
        }
        
        number = ([[_origo organisers] count] > 1) ? pluralIndefinite : singularIndefinite;
        text = [[OLanguage nouns][contactTitle][number] capitalizedString];
    } else if (sectionKey == kSectionKeyParentContacts) {
        number = ([[_origo parentContacts] count] > 1) ? pluralIndefinite : singularIndefinite;
        text = [[OLanguage nouns][_parentContact_][number] capitalizedString];
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


- (void)didDismissModalViewController:(OTableViewController *)viewController
{
    if (!viewController.didCancel) {
        if ([viewController.identifier isEqualToString:kIdentifierValuePicker]) {
            if ([viewController targetIs:kTargetMembers]) {
                for (id<OMember> member in viewController.returnData) {
                    [_origo addMember:member];
                }
                
                [[OMeta m].replicator replicateIfNeeded];
                [self reloadSections];
            } else if ([viewController targetIs:kTargetParentContact]) {
                _parentContact = viewController.returnData;
                
                [self presentParentContactRoleDialogue];
            }
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
    } else if ([_origo isOfType:kOrigoTypeStudentGroup]) {
        blueprint.detailKeys = @[kMappedKeyUniversity];
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
                [self scrollToTopAndToggleEditMode];
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
                if (buttonTag == kButtonTagEditRoles) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetRoles meta:_origo];
                } else if (buttonTag == kButtonTagAdd) {
                    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagActionSheet];
                    
                    [self addNewMemberButtonsToActionSheet:actionSheet];
                    [actionSheet show];
                } else if (buttonTag == kButtonTagAddMember) {
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


#pragma mark - UIAlertViewDelegate conformance

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertTagParentContactRole:
            if (buttonIndex == kButtonIndexOK) {
                id<OMembership> membership = [_origo addMember:_parentContact];
                [membership addRole:[alertView textFieldAtIndex:0].text ofType:kRoleTypeParentContact];
                
                [[OMeta m].replicator replicate];
                [self reloadSectionWithKey:kSectionKeyParentContacts];
            }
            
            break;
            
        default:
            break;
    }
}

@end
