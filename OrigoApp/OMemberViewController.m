//
//  OMemberViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMemberViewController.h"

static NSString * const kSegueToOrigoView = @"segueFromMemberToOrigoView";

static NSInteger const kSectionKeyMember = 0;
static NSInteger const kSectionKeyGuardian = 1;
static NSInteger const kSectionKeyAddress = 2;

static NSInteger const kActionSheetTagActionSheet = 0;
static NSInteger const kButtonTagAddAddress = 0;
static NSInteger const kButtonTagChangePassword = 1;
static NSInteger const kButtonTagEdit = 2;
static NSInteger const kButtonTagEditRelations = 3;
static NSInteger const kButtonTagCorrectGender = 4;

static NSInteger const kActionSheetTagResidence = 1;
static NSInteger const kButtonTagNewAddress = 100;

static NSInteger const kActionSheetTagExistingResidence = 2;
static NSInteger const kButtonTagInviteToHousehold = 0;
static NSInteger const kButtonTagMergeHouseholds = 1;

static NSInteger const kAlertTagEmailChange = 0;
static NSInteger const kButtonTagContinue = 1;


@implementation OMemberViewController

#pragma mark - Auxiliary methods

- (BOOL)isRegisteringJuvenileOrigoGuardian
{
    return [self actionIs:kActionRegister] && [_origo isJuvenile] && [self.meta isEqualToString:kMemberTypeGuardian];
}


- (BOOL)emailIsEligible
{
    BOOL emailIsEligible = [_emailField hasValidValue];
    
    if (emailIsEligible && [self actionIs:kActionRegister] && ![self targetIs:kTargetUser]) {
        _candidate = [[OMeta m].context memberEntityWithEmail:[_emailField textValue]];
        
        if (_candidate) {
            if ([_origo hasMember:_candidate]) {
                _emailField.text = @"";
                [_emailField becomeFirstResponder];
                
                NSString *alertTitle = [OStrings stringForKey:strAlertTitleMemberExists];
                NSString *alertMessage = [NSString stringWithFormat:[OStrings stringForKey:strAlertTextMemberExists], _candidate.name, _emailField.text, [_origo displayName]];
                [OAlert showAlertWithTitle:alertTitle text:alertMessage];
                
                _candidate = nil;
                emailIsEligible = NO;
            } else {
                _mobilePhoneField.text = _candidate.mobilePhone;
                _dateOfBirthField.date = _candidate.dateOfBirth;
                
                if ([_candidate isActive]) {
                    self.detailCell.editing = NO;
                }
            }
        }
    }
    
    return emailIsEligible;
}


- (void)persistMember
{
    [self.detailCell writeEntity];
    
    if ([self actionIs:kActionRegister]) {
        if ([self targetIs:kTargetUser]) {
            if (![_origo.address hasValue]) {
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo data:_membership meta:kOrigoTypeResidence];
            } else {
                [self.dismisser dismissModalViewController:self reload:YES];
            }
        } else /* if (![self targetIs:kTargetHousehold]) */ {
            [self.dismisser dismissModalViewController:self reload:YES]; // Work in progress
        }
    }
}


#pragma mark - Action sheets & alerts

- (void)presentCandidateResidencesSheet:(NSSet *)residences
{
    _candidateResidences = [residences sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:kPropertyKeyAddress ascending:YES]]];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagResidence];
    
    for (OOrigo *residence in _candidateResidences) {
        [actionSheet addButtonWithTitle:[residence shortAddress]];
    }
    
    [actionSheet addButtonWithTitle:[OStrings stringForKey:strButtonNewAddress] tag:kButtonTagNewAddress];
    
    [actionSheet show];
}


- (void)presentExistingResidenceActionSheet
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:[OStrings stringForKey:strSheetTitleExistingResidence], _candidate.name, [_candidate givenName]] delegate:self tag:kActionSheetTagExistingResidence];
    
    [actionSheet addButtonWithTitle:[OStrings stringForKey:strButtonInviteToHousehold] tag:kButtonTagInviteToHousehold];
    [actionSheet addButtonWithTitle:[OStrings stringForKey:strButtonMergeHouseholds] tag:kButtonTagMergeHouseholds];
    
    [actionSheet show];
}


- (void)presentUserEmailChangeAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleUserEmailChange] message:[NSString stringWithFormat:[OStrings stringForKey:strAlertTextUserEmailChange], _member.email, _emailField.text] delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonCancel] otherButtonTitles:[OStrings stringForKey:strButtonContinue], nil];
    alert.tag = kAlertTagEmailChange;
    
    [alert show];
}


- (void)presentMemberEmailChangeAlert
{
    // TODO
}


#pragma mark - Selector implementations

- (void)presentActionSheet
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagActionSheet];
    
    if ([_member isUser]) {
        [actionSheet addButtonWithTitle:[OStrings stringForKey:strButtonChangePassword] tag:kButtonTagChangePassword];
    }
    
    [actionSheet addButtonWithTitle:[OStrings stringForKey:strButtonEdit] tag:kButtonTagEdit];
    
    if ([_member isWardOfUser]) {
        [actionSheet addButtonWithTitle:[OStrings stringForKey:strButtonEditRelations] tag:kButtonTagEditRelations];
    }
    
    [actionSheet addButtonWithTitle:[OStrings stringForKey:strButtonAddAddress] tag:kButtonTagAddAddress];
    [actionSheet addButtonWithTitle:[OStrings stringForKey:strButtonCorrectGender] tag:kButtonTagCorrectGender];
    
    [actionSheet show];
}


#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    _nameField = [self.detailCell textFieldForKey:kPropertyKeyName];
    _dateOfBirthField = [self.detailCell textFieldForKey:kPropertyKeyDateOfBirth];
    _mobilePhoneField = [self.detailCell textFieldForKey:kPropertyKeyMobilePhone];
    _emailField = [self.detailCell textFieldForKey:kPropertyKeyEmail];
    
    if ([self actionIs:kActionRegister] && [_origo isJuvenile]) {
        if (!self.wasHidden && ![self.meta isEqualToString:kMemberTypeGuardian]) {
            [self presentModalViewControllerWithIdentifier:kIdentifierMember data:_origo meta:kMemberTypeGuardian];
        }
    }
    
    [super viewDidAppear:animated];
}


#pragma mark - OTableViewController custom accessors

- (BOOL)canEdit
{
    return [_member isManagedByUser];
}


#pragma mark - UIViewController overrides

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToOrigoView]) {
        if ([self actionIs:kActionRegister]) {
            [self prepareForPushSegue:segue data:_membership];
            [segue.destinationViewController setDismisser:self.dismisser];
        } else {
            [self prepareForPushSegue:segue];
        }
    }
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialiseState
{
    if ([self.data isKindOfClass:[OMember class]]) {
        _member = self.data;
    } else if ([self.data isKindOfClass:[OMembership class]]) {
        _membership = self.data;
        _member = _membership.member;
        _origo = _membership.origo;
    } else if ([self.data isKindOfClass:[OOrigo class]]) {
        _origo = self.data;
    }
    
    self.state.target = _member ? _member : (self.meta ? self.meta : _origo);
    
    if ([self targetIs:kTargetUser]) {
        self.title = [OStrings stringForKey:strViewTitleAboutMe];
    } else if (_member) {
        self.title = [_member isHousemateOfUser] ? [_member givenName] : _member.name;
    } else if ([self isRegisteringJuvenileOrigoGuardian]) {
        self.title = [[OLanguage nouns][_guardian_][singularIndefinite] capitalizedString];
    } else if ([self actionIs:kActionRegister]) {
        self.title = [OStrings stringForKey:_origo.type withKeyPrefix:kKeyPrefixNewMemberTitle];
    }
    
    if ([self actionIs:kActionDisplay]) {
        if (self.canEdit) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem actionButtonWithTarget:self];
        }
    }
}


- (void)initialiseData
{
    id memberDataSource = _member ? _member : kEntityRegistrationCell;
    
    [self setData:memberDataSource forSectionWithKey:kSectionKeyMember];
    
    if ([self actionIs:kActionDisplay]) {
        if ([_member isMinor]) {
            [self setData:[_member guardians] forSectionWithKey:kSectionKeyGuardian];
        }
        
        [self setData:[_member residencies] forSectionWithKey:kSectionKeyAddress];
    }
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return [self actionIs:kActionRegister] && ![self targetIs:kTargetUser] && ![_origo isJuvenile];
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kSectionKeyGuardian) {
        NSSet *guardians = [_member guardians];
        
        if ([guardians count] == 1) {
            OMember *guardian = [guardians anyObject];
            
            if ([_member hasParent:guardian]) {
                text = [guardian parentNoun][singularIndefinite];
            } else {
                text = [OLanguage nouns][_contact_][singularIndefinite];
            }
        } else {
            if ([_member guardiansAreParents]) {
                text = [OLanguage nouns][_parent_][pluralIndefinite];
            } else {
                text = [OLanguage nouns][_contact_][pluralIndefinite];
            }
        }
    } else if (sectionKey == kSectionKeyAddress) {
        if ([[_member residencies] count] == 1) {
            text = [OLanguage nouns][_address_][singularIndefinite];
        } else if ([[_member residencies] count] > 1) {
            text = [OLanguage nouns][_address_][pluralIndefinite];
        }
    }
    
    return [text capitalizedString];
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = [OStrings stringForKey:strFooterOrigoInviteAlert];
    
    if ([self isRegisteringJuvenileOrigoGuardian]) {
        text = [NSString stringWithFormat:@"%@\n\n%@", [OStrings stringForKey:strFooterJuvenileOrigoGuardian], text];
    }
    
    return text;
}


- (NSArray *)toolbarButtons
{
    return [_member isUser] ? nil : [[OMeta m].switchboard toolbarButtonsWithEntity:_member];
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyGuardian) {
        OMemberViewController *memberViewController = [self.storyboard instantiateViewControllerWithIdentifier:kIdentifierMember];
        memberViewController.data = [self dataAtIndexPath:indexPath];
        memberViewController.observer = (OTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        
        [self.navigationController pushViewController:memberViewController animated:YES];
    } else if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyAddress) {
        [self performSegueWithIdentifier:kSegueToOrigoView sender:self];
    }
}


#pragma mark - OTableViewListDelegate conformance

- (NSString *)sortKeyForSectionWithKey:(NSInteger)sectionKey
{
    NSString *sortKey = nil;
    
    if (sectionKey == kSectionKeyAddress) {
        sortKey = [OUtil sortKeyWithPropertyKey:kPropertyKeyAddress relationshipKey:kRelationshipKeyOrigo];
    }
    
    return sortKey;
}


- (BOOL)willCompareObjectsInSectionWithKey:(NSInteger)sectionKey
{
    return (sectionKey == kSectionKeyGuardian);
}


- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2
{
    NSComparisonResult result = NSOrderedSame;
    
    OMember *guardian1 = (OMember *)object1;
    OMember *guardian2 = (OMember *)object2;
    
    if ([_member hasParent:guardian1] && ![_member hasParent:guardian2]) {
        result = NSOrderedAscending;
    } else if (![_member hasParent:guardian1] && [_member hasParent:guardian2]) {
        result = NSOrderedDescending;
    } else {
        NSString *address1 = [guardian1 shortAddress];
        NSString *address2 = [guardian2 shortAddress];
        
        if ([address1 isEqualToString:address2]) {
            result = [guardian1.name localizedCompare:guardian2.name];
        } else {
            result = [address1 localizedCompare:address2];
        }
    }
    
    return result;
}


- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyGuardian) {
        OMember *guardian = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = guardian.name;
        cell.imageView.image = [guardian smallImage];

        if ([[_member residencies] count] == 1) {
            cell.detailTextLabel.text = [guardian shortDetails];
        } else {
            cell.detailTextLabel.text = [guardian shortAddress];
        }
        
        if ([_member hasParent:guardian]) {
            cell.detailTextLabel.text = [[[guardian parentNoun][singularIndefinite] capitalizedString] stringByAppendingString:cell.detailTextLabel.text separator:kSeparatorComma];
        }
    } else if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyAddress) {
        OOrigo *residence = [[self dataAtIndexPath:indexPath] origo];
        
        cell.textLabel.text = [residence shortAddress];
        cell.imageView.image = [UIImage imageNamed:kIconFileHousehold];
        
        if ([residence.telephone hasValue]) {
            cell.detailTextLabel.text = residence.telephone;
        }
    }
}


#pragma mark - OTableViewInputDelegate conformance

- (BOOL)inputIsValid
{
    BOOL memberIsMinor = [_dateOfBirthField.date isBirthDateOfMinor];
    
    memberIsMinor = memberIsMinor || [self targetIs:kOrigoTypePreschoolClass];
    memberIsMinor = memberIsMinor || [self targetIs:kOrigoTypeSchoolClass];
    
    BOOL inputIsValid = [_nameField hasValidValue];
    
    if ([self aspectIsHousehold]) {
        inputIsValid = inputIsValid && [_dateOfBirthField hasValidValue];
    }
    
    if (inputIsValid) {
        if ([self targetIs:kTargetUser] || [_emailField hasValue] || !memberIsMinor) {
            inputIsValid = inputIsValid && [self emailIsEligible];
        }
        
        if ([self targetIs:kTargetUser] || ([self aspectIsHousehold] && !memberIsMinor)) {
            inputIsValid = inputIsValid && [_mobilePhoneField hasValidValue];
        }
    }
    
    return  inputIsValid;
}


- (void)processInput
{
    if ([self actionIs:kActionRegister]) {
        if (_candidate) {
            if ([_origo isOfType:kOrigoTypeResidence] && [_candidate.residencies count]) {
                [self presentExistingResidenceActionSheet];
            } else {
                [self persistMember];
            }
        } else {
            _examiner = [[ORegistrantExaminer alloc] initWithResidence:_origo];
            
            if (_member) {
                [_examiner examineRegistrant:_member];
            } else if ([self.meta isEqualToString:kMemberTypeGuardian]) {
                [_examiner examineRegistrantWithName:_nameField.text isGuardian:YES];
            } else {
                [_examiner examineRegistrantWithName:_nameField.text dateOfBirth:_dateOfBirthField.date];
            }
        }
    } else if ([self actionIs:kActionEdit]) {
        if ([_member.email hasValue] && ![_emailField.text isEqualToString:_member.email]) {
            if ([self targetIs:kTargetUser]) {
                [self presentUserEmailChangeAlert];
            } else {
                [self presentMemberEmailChangeAlert];
            }
        } else {
            [self persistMember];
            [self toggleEditMode];
        }
    }
}


- (id)inputEntity
{
    if (_candidate) {
        _member = _candidate;
    } else {
        _member = [[OMeta m].context insertMemberEntityWithId:_examiner.registrantId];
    }
    
    if (!_membership) {
        _membership = [_origo addMember:_member];
    }
    
    return _member;
}


- (id)inputValueForIndirectKey:(NSString *)key
{
    id inputValue = nil;

    if ([key isEqualToString:kPropertyKeyIsJuvenile]) {
        inputValue = _member.dateOfBirth ? nil : @([_origo isJuvenile]);
    } else {
        if (_examiner) {
            inputValue = [_examiner valueForKey:key];
        } else {
            inputValue = [_member valueForKey:key];
        }
    }
    
    return inputValue;
}


- (BOOL)shouldEnableInputFieldWithKey:(NSString *)key
{
    BOOL shouldEnable = YES;
    
    if ([key isEqualToString:kPropertyKeyEmail]) {
        shouldEnable = ![self actionIs:kActionRegister] || ![self targetIs:kTargetUser];
    }
    
    return shouldEnable;
}


#pragma mark - ORegistrantExaminerDelegate conformance

- (void)examinerDidFinishExamination
{
    [self persistMember];
}


- (void)examinerDidCancelExamination
{
    [self resumeFirstResponder];
}


#pragma mark - OModalViewControllerDismisser conformance

- (BOOL)shouldRelayDismissalOfModalViewController:(OTableViewController *)viewController
{
    return [viewController.identifier isEqual:kIdentifierOrigo];
}


- (void)willDismissModalViewController:(OTableViewController *)viewController
{
    if ([viewController.identifier isEqualToString:kIdentifierAuth]) {
        if ([_member.email isEqualToString:_emailField.text]) {
            [self persistMember];
        } else {
            UIAlertView *failedEmailChangeAlert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleEmailChangeFailed] message:[NSString stringWithFormat:[OStrings stringForKey:strAlertTextEmailChangeFailed], _emailField.text] delegate:nil cancelButtonTitle:[OStrings stringForKey:strButtonOK] otherButtonTitles:nil];
            [failedEmailChangeAlert show];
            
            [self toggleEditMode];
            [_emailField becomeFirstResponder];
        }
    }
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
            if (buttonTag == kButtonTagAddAddress) {
                NSSet *housemateResidences = [_member housemateResidences];
                
                if ([housemateResidences count]) {
                    [self presentCandidateResidencesSheet:housemateResidences];
                } else {
                    [self presentModalViewControllerWithIdentifier:kIdentifierOrigo data:_member meta:kOrigoTypeResidence];
                }
            }
            
            break;
            
        case kActionSheetTagResidence:
            if (buttonTag == kButtonTagNewAddress) {
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo data:_member meta:kOrigoTypeResidence];
            } else if (buttonIndex < actionSheet.cancelButtonIndex) {
                [_candidateResidences[buttonIndex] addMember:_member];
                [self reloadSections];
            }
            
            break;
            
        case kActionSheetTagExistingResidence:
            if (buttonIndex < actionSheet.cancelButtonIndex) {
                if (buttonTag == kButtonTagInviteToHousehold) {
                    [self persistMember];
                } else if (buttonTag == kButtonTagMergeHouseholds) {
                    // TODO
                }
            } else {
                [self resumeFirstResponder];
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
        case kAlertTagEmailChange:
            if (buttonIndex == kButtonTagContinue) {
                [self toggleEditMode];
                [self presentModalViewControllerWithIdentifier:kIdentifierAuth data:_emailField.text];
            } else {
                [_emailField becomeFirstResponder];
            }
            
            break;
            
        default:
            break;
    }
}

@end
