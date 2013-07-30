//
//  OMemberViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMemberViewController.h"

static NSString * const kSegueToMemberListView = @"segueFromMemberToMemberListView";

static NSInteger const kSectionKeyMember = 0;
static NSInteger const kSectionKeyAddresses = 1;

static NSInteger const kGenderSheetTag = 0;
static NSInteger const kGenderSheetButtonFemale = 0;
static NSInteger const kGenderSheetButtonCancel = 2;

static NSInteger const kResidenceSheetTag = 1;

static NSInteger const kExistingResidenceSheetTag = 2;
static NSInteger const kExistingResidenceButtonInviteToHousehold = 0;
static NSInteger const kExistingResidenceButtonMergeHouseholds = 1;
static NSInteger const kExistingResidenceButtonCancel = 2;

static NSInteger const kEmailChangeAlertTag = 3;
static NSInteger const kEmailChangeButtonContinue = 1;


@implementation OMemberViewController

#pragma mark - Auxiliary methods

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
                NSString *alertMessage = [NSString stringWithFormat:[OStrings stringForKey:strAlertTextMemberExists], _candidate.name, _emailField.text, _origo.name];
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
        if ([self targetIs:kTargetUser] && ![_origo hasValueForKey:kPropertyKeyAddress]) {
            [self presentModalViewControllerWithIdentifier:kViewControllerOrigo data:_membership];
        } else {
            [self.dismisser dismissModalViewController:self reload:YES];
        }
    }
}


#pragma mark - Alerts & action sheets

- (void)promptForResidence:(NSSet *)housemateResidences
{
    _candidateResidences = [housemateResidences sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:kPropertyKeyAddress ascending:YES]]];
    
    UIActionSheet *residenceSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    for (OOrigo *residence in _candidateResidences) {
        [residenceSheet addButtonWithTitle:[residence shortAddress]];
    }
    
    [residenceSheet addButtonWithTitle:[OStrings stringForKey:strButtonNewAddress]];
    [residenceSheet addButtonWithTitle:[OStrings stringForKey:strButtonCancel]];
    residenceSheet.cancelButtonIndex = [housemateResidences count] + 1;
    residenceSheet.tag = kResidenceSheetTag;
    
    [residenceSheet showInView:self.view];
}


- (void)promptForExistingResidenceAction
{
    NSString *sheetQuestion = [NSString stringWithFormat:[OStrings stringForKey:strSheetTitleExistingResidence], _candidate.name, [_candidate givenName]];
    
    UIActionSheet *existingResidenceSheet = [[UIActionSheet alloc] initWithTitle:sheetQuestion delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonCancel] destructiveButtonTitle:nil otherButtonTitles:[OStrings stringForKey:strButtonInviteToHousehold], [OStrings stringForKey:strButtonMergeHouseholds], nil];
    existingResidenceSheet.tag = kExistingResidenceSheetTag;
    
    [existingResidenceSheet showInView:self.view];
}


- (void)promptForUserEmailChangeConfirmation
{
    UIAlertView *emailChangeAlert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleUserEmailChange] message:[NSString stringWithFormat:[OStrings stringForKey:strAlertTextUserEmailChange], _member.email, _emailField.text] delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonCancel] otherButtonTitles:[OStrings stringForKey:strButtonContinue], nil];
    emailChangeAlert.tag = kEmailChangeAlertTag;
    
    [emailChangeAlert show];
}


- (void)promptForMemberEmailChangeConfirmation
{
    // TODO
}


#pragma mark - Selector implementations

- (void)addResidence
{
    NSSet *housemateResidences = [_member housemateResidences];
    
    if ([housemateResidences count]) {
        [self promptForResidence:housemateResidences];
    } else {
        [self presentModalViewControllerWithIdentifier:kViewControllerOrigo data:_member meta:kOrigoTypeResidence];
    }
}


- (void)signOut
{
    [[OMeta m] userDidSignOut];
    
    [self.dismisser dismissModalViewController:self reload:YES];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([self targetIs:kTargetUser]) {
        self.title = [OStrings stringForKey:strViewTitleAboutMe];
    } else if (_member) {
        self.title = [_member givenName];
    } else if ([self actionIs:kActionRegister]) {
        if ([_origo isOfType:kOrigoTypeResidence]) {
            self.title = [OStrings stringForKey:strViewTitleNewHouseholdMember];
        } else {
            self.title = [OStrings stringForKey:strViewTitleNewMember];
        }
    }
    
    if ([self actionIs:kActionDisplay]) {
        if (self.canEdit) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem addButtonWithTarget:self];
            self.navigationItem.rightBarButtonItem.action = @selector(addResidence);
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _nameField = [self.detailCell textFieldForKey:kPropertyKeyName];
    _dateOfBirthField = [self.detailCell textFieldForKey:kPropertyKeyDateOfBirth];
    _mobilePhoneField = [self.detailCell textFieldForKey:kPropertyKeyMobilePhone];
    _emailField = [self.detailCell textFieldForKey:kPropertyKeyEmail];
}


#pragma mark - OTableViewController custom accessors

- (BOOL)canEdit
{
    return [_member isManagedByUser] || [self actionIs:kActionRegister];
}


#pragma mark - UIViewController custom accessors

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}


#pragma mark - UIViewController overrides

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToMemberListView]) {
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
    if ([self.data isKindOfClass:OMembership.class]) {
        _membership = self.data;
        _member = _membership.member;
        _origo = _membership.origo;
    } else if ([self.data isKindOfClass:OOrigo.class]) {
        _origo = self.data;
    }
    
    self.state.target = _member ? _member : _origo;
    
    self.hasToolbar = ![self targetIs:kTargetHousehold];
    self.cancelRegistrationImpliesSignOut = [self targetIs:kTargetUser];
    
    _examiner = [[ORegistrantExaminer alloc] initWithResidence:_origo];
}


- (void)initialiseDataSource
{
    id memberDataSource = _member ? _member : kEntityRegistrationCell;
    
    [self setData:memberDataSource forSectionWithKey:kSectionKeyMember];
    
    if ([self actionIs:kActionDisplay]) {
        [self setData:[_member residencies] forSectionWithKey:kSectionKeyAddresses];
    }
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return ([super hasFooterForSectionWithKey:sectionKey] && self.canEdit);
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kSectionKeyAddresses) {
        if ([[_member residencies] count] == 1) {
            text = [OStrings stringForKey:strHeaderAddress];
        } else {
            text = [OStrings stringForKey:strHeaderAddresses];
        }
    }
    
    return text;
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    return [[OStrings stringForKey:strFooterTapToEdit] stringByAppendingString:[OStrings stringForKey:strFooterTapToAddAddress] separator:kSeparatorNewline];
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:kSegueToMemberListView sender:self];
}


#pragma mark - OTableViewListDelegate conformance

- (NSString *)sortKeyForSectionWithKey:(NSInteger)sectionKey
{
    return [OUtil sortKeyWithPropertyKey:kPropertyKeyAddress relationshipKey:kRelationshipKeyOrigo];
}


- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    OOrigo *residence = [[self dataAtIndexPath:indexPath] origo];
    
    cell.textLabel.text = [residence shortAddress];
    cell.imageView.image = [UIImage imageNamed:kIconFileHousehold];
}


#pragma mark - OTableViewInputDelegate conformance

- (BOOL)inputIsValid
{
    BOOL memberIsMinor = [_dateOfBirthField.date isBirthDateOfMinor];
    
    memberIsMinor = memberIsMinor || [self targetIs:kOrigoTypePreschoolClass];
    memberIsMinor = memberIsMinor || [self targetIs:kOrigoTypeSchoolClass];
    
    BOOL inputIsValid = [_nameField hasValidValue];
    
    if ([self targetIs:kTargetHousehold]) {
        inputIsValid = inputIsValid && [_dateOfBirthField hasValidValue];
    }
    
    if (inputIsValid) {
        if ([self targetIs:kTargetUser] || [_emailField hasValue] || !memberIsMinor) {
            inputIsValid = inputIsValid && [self emailIsEligible];
        }
        
        if ([self targetIs:kTargetUser] || ([self targetIs:kTargetHousehold] && !memberIsMinor)) {
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
                [self promptForExistingResidenceAction];
            } else {
                [self persistMember];
            }
        } else {
            [_examiner examineRegistrantWithName:_nameField.text dateOfBirth:_dateOfBirthField.date];
        }
    } else if ([self actionIs:kActionEdit]) {
        if ([_member.email length] && ![_emailField.text isEqualToString:_member.email]) {
            if ([self targetIs:kTargetUser]) {
                [self promptForUserEmailChangeConfirmation];
            } else {
                [self promptForMemberEmailChangeConfirmation];
            }
        } else {
            [self persistMember];
            [self toggleEditMode];
        }
    }
}


- (id)targetEntity
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
    
    if ([key isEqualToString:kPropertyKeyGender]) {
        inputValue = _examiner.gender;
    } else if ([key isEqualToString:kPropertyKeyFatherId]) {
        inputValue = _examiner.fatherId;
    } else if ([key isEqualToString:kPropertyKeyMotherId]) {
        inputValue = _examiner.motherId;
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


#pragma mark - OHouseholdExaminerDelegate conformance

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
    BOOL shouldRelay = NO;
    
    if ([self actionIs:kActionRegister]) {
        NSString *identifier = viewController.identifier;
        
        shouldRelay = shouldRelay || [identifier isEqual:kViewControllerOrigo];
        shouldRelay = shouldRelay || [identifier isEqual:kViewControllerMemberList];
    }
    
    return shouldRelay;
}


- (void)willDismissModalViewController:(OTableViewController *)viewController
{
    if ([viewController.identifier isEqualToString:kViewControllerAuth]) {
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

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case kResidenceSheetTag:
            if (buttonIndex == actionSheet.numberOfButtons - 2) {
                [self presentModalViewControllerWithIdentifier:kViewControllerOrigo data:_member meta:kOrigoTypeResidence];
            } else if (buttonIndex < actionSheet.numberOfButtons - 2) {
                [_candidateResidences[buttonIndex] addMember:_member];
                [self reloadSections];
            }
            
            break;
            
        case kExistingResidenceSheetTag:
            if (buttonIndex == kExistingResidenceButtonInviteToHousehold) {
                [self persistMember];
            } else if (buttonIndex == kExistingResidenceButtonMergeHouseholds) {
                // TODO
            } else if (buttonIndex == kExistingResidenceButtonCancel) {
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
        case kEmailChangeAlertTag:
            if (buttonIndex == kEmailChangeButtonContinue) {
                [self toggleEditMode];
                [self presentModalViewControllerWithIdentifier:kViewControllerAuth data:_emailField.text];
            } else {
                [_emailField becomeFirstResponder];
            }
            
            break;
            
        default:
            break;
    }
}

@end
