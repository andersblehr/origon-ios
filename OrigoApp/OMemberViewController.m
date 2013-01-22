//
//  OMemberViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMemberViewController.h"

#import "NSDate+OrigoExtensions.h"
#import "NSManagedObjectContext+OrigoExtensions.h"
#import "NSString+OrigoExtensions.h"
#import "UIBarButtonItem+OrigoExtensions.h"
#import "UITableView+OrigoExtensions.h"

#import "OEntityObservingDelegate.h"

#import "OAlert.h"
#import "OLogging.h"
#import "OMeta.h"
#import "OServerConnection.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextField.h"

#import "OMember+OrigoExtensions.h"
#import "OMemberResidency+OrigoExtensions.h"
#import "OMembership+OrigoExtensions.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"

#import "OAuthViewController.h"
#import "OMemberListViewController.h"
#import "OOrigoViewController.h"
#import "OTabBarController.h"

static NSString * const kModalSegueToAuthView = @"modalFromMemberToAuthView";
static NSString * const kModalSegueToOrigoView1 = @"modalFromMemberToOrigoView1";
static NSString * const kModalSegueToOrigoView2 = @"modalFromMemberToOrigoView2";
static NSString * const kPushSegueToMemberListView = @"pushFromMemberToMemberListView";

static NSInteger const kMemberSection = 0;
static NSInteger const kAddressSection = 1;

static NSInteger const kGenderSheetTag = 0;
static NSInteger const kGenderSheetButtonFemale = 0;
static NSInteger const kGenderSheetButtonCancel = 2;

static NSInteger const kExistingResidenceSheetTag = 1;
static NSInteger const kExistingResidenceButtonInviteToHousehold = 0;
static NSInteger const kExistingResidenceButtonMergeHouseholds = 1;
static NSInteger const kExistingResidenceButtonCancel = 2;

static NSInteger const kEmailChangeAlertTag = 2;
static NSInteger const kEmailChangeButtonContinue = 1;


@implementation OMemberViewController

#pragma mark - Auxiliary methods

- (BOOL)emailIsEligible
{
    BOOL emailIsEligible = [_emailField holdsValidEmail];
    
    if (emailIsEligible && self.state.actionIsRegister && !self.state.aspectIsSelf) {
        NSString *email = [_emailField finalText];
        
        _candidate = [[OMeta m].context memberEntityWithEmail:email];
        
        if (_candidate) {
            if ([_origo hasMemberWithEmail:email]) {
                _emailField.text = @"";
                [_emailField becomeFirstResponder];
                
                NSString *alertTitle = [OStrings stringForKey:strAlertTitleMemberExists];
                NSString *alertMessage = [NSString stringWithFormat:[OStrings stringForKey:strAlertTextMemberExists], _candidate.name, email, _origo.name];
                [OAlert showAlertWithTitle:alertTitle message:alertMessage];
                
                _candidate = nil;
                emailIsEligible = NO;
            } else {
                _mobilePhoneField.text = _candidate.mobilePhone;
                [_dateOfBirthPicker setDate:_candidate.dateOfBirth animated:YES];
                _dateOfBirthField.text = [_candidate.dateOfBirth localisedDateString];
                _gender = _candidate.gender;
                
                if (_candidate.activeSince) {
                    _memberCell.editing = NO;
                }
            }
        }
    }
    
    return emailIsEligible;
}


- (void)registerMember
{
    if (!_member) {
        if (_candidate) {
            _member = _candidate;
        } else {
            _member = [[OMeta m].context insertMemberEntityWithEmail:[_emailField finalText]];
        }
    }
    
    if (!_membership) {
        if ([_origo isResidence]) {
            _membership = [_origo addResident:_member];
        } else {
            _membership = [_origo addMember:_member];
        }
    }
    
    [self updateMember];
}


- (void)updateMember
{
    _member.name = [_nameField finalText];
    _member.dateOfBirth = _dateOfBirthPicker.date;
    _member.mobilePhone = [_mobilePhoneField finalText];
    _member.email = [_emailField finalText];
    
    if (self.state.actionIsRegister) {
        _member.givenName = [NSString givenNameFromFullName:_member.name];
        _member.gender = _gender;
        
        if (![_origo isResidence] || [_origo hasAddress]) {
            if ([_origo hasAddress] && self.state.aspectIsSelf) {
                [OMeta m].user.activeSince = [NSDate date];
            }
            
            [_delegate dismissModalViewControllerWithIdentitifier:kMemberViewControllerId];
            
            if ([_delegate isKindOfClass:OMemberListViewController.class]) {
                [_delegate insertEntityInTableView:_membership];
            }
            
            [[OMeta m].context replicateIfNeeded];
        } else {
            [self performSegueWithIdentifier:kModalSegueToOrigoView1 sender:self];
        }
    } else {
        [[OMeta m].context replicateIfNeeded];
        [_entityObservingDelegate reloadEntity];
    }
}


- (BOOL)canEdit
{
    BOOL memberIsUserAndTeen = ([_member isUser] && [_member isTeenOrOlder]);
    BOOL memberIsWardOfUser = [[[OMeta m].user wards] containsObject:_member];
    BOOL membershipIsInactiveAndUserIsAdmin = ([_origo userIsAdmin] && ![_membership.isActive boolValue]);
    
    return (memberIsUserAndTeen || memberIsWardOfUser || membershipIsInactiveAndUserIsAdmin);
}


- (void)toggleEditMode
{
    static UIBarButtonItem *addButton = nil;
    static UIBarButtonItem *backButton = nil;
    
    [_memberCell toggleEditMode];
    
    if (self.state.actionIsEdit) {
        addButton = self.navigationItem.rightBarButtonItem;
        backButton = self.navigationItem.leftBarButtonItem;
        
        if (!_cancelButton) {
            _cancelButton = [UIBarButtonItem cancelButtonWithTarget:self];
            _nextButton = [UIBarButtonItem nextButtonWithTarget:self];
            _doneButton = [UIBarButtonItem doneButtonWithTarget:self];
        }
        
        self.navigationItem.rightBarButtonItem = _nextButton;
        self.navigationItem.leftBarButtonItem = _cancelButton;
    } else if (self.state.actionIsDisplay) {
        [self.view endEditing:YES];
        
        self.navigationItem.rightBarButtonItem = addButton;
        self.navigationItem.leftBarButtonItem = backButton;
    }
    
    OLogState;
}


#pragma mark - Action sheets

- (void)promptForGender
{
    NSString *sheetQuestion = nil;
    NSString *femaleLabel = nil;
    NSString *maleLabel = nil;
    
    if ([_dateOfBirthPicker.date isBirthDateOfMinor]) {
        if (self.state.aspectIsSelf) {
            sheetQuestion = [OStrings stringForKey:strSheetTitleGenderSelfMinor];
        } else {
            sheetQuestion = [NSString stringWithFormat:[OStrings stringForKey:strSheetTitleGenderMinor], [NSString givenNameFromFullName:[_nameField finalText]]];
        }
        
        femaleLabel = [OStrings stringForKey:strTermFemaleMinor];
        maleLabel = [OStrings stringForKey:strTermMaleMinor];
    } else {
        if (self.state.aspectIsSelf) {
            sheetQuestion = [OStrings stringForKey:strSheetTitleGenderSelf];
        } else {
            sheetQuestion = [NSString stringWithFormat:[OStrings stringForKey:strSheetTitleGenderMember], [NSString givenNameFromFullName:[_nameField finalText]]];
        }
        
        femaleLabel = [OStrings stringForKey:strTermFemale];
        maleLabel = [OStrings stringForKey:strTermMale];
    }
    
    UIActionSheet *genderSheet = [[UIActionSheet alloc] initWithTitle:sheetQuestion delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonCancel] destructiveButtonTitle:nil otherButtonTitles:femaleLabel, maleLabel, nil];
    genderSheet.tag = kGenderSheetTag;
    [genderSheet showInView:self.view];
}


- (void)promptForExistingResidenceAction
{
    NSString *sheetQuestion = [NSString stringWithFormat:[OStrings stringForKey:strSheetTitleExistingResidence], _candidate.name, _candidate.givenName];
    
    UIActionSheet *existingResidenceSheet = [[UIActionSheet alloc] initWithTitle:sheetQuestion delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonCancel] destructiveButtonTitle:nil otherButtonTitles:[OStrings stringForKey:strButtonInviteToHousehold], [OStrings stringForKey:strButtonMergeHouseholds], nil];
    existingResidenceSheet.tag = kExistingResidenceSheetTag;
    [existingResidenceSheet showInView:self.view];
}


- (void)promptForUserEmailChangeConfirmation
{
    UIAlertView *emailChangeAlert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleUserEmailChange] message:[NSString stringWithFormat:[OStrings stringForKey:strAlertTextUserEmailChange], _member.email, [_emailField finalText]] delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonCancel] otherButtonTitles:[OStrings stringForKey:strButtonContinue], nil];
    emailChangeAlert.tag = kEmailChangeAlertTag;
    [emailChangeAlert show];
}


- (void)promptForMemberEmailChangeConfirmation
{
    
}


#pragma mark - Selector implementations

- (void)moveToNextInputField
{
    if (_currentField == _nameField) {
        [_dateOfBirthField becomeFirstResponder];
    } else if (_currentField == _dateOfBirthField) {
        [_mobilePhoneField becomeFirstResponder];
    } else if (_currentField == _mobilePhoneField) {
        [_emailField becomeFirstResponder];
    }
}


- (void)dateOfBirthDidChange
{
    _dateOfBirthField.text = [_dateOfBirthPicker.date localisedDateString];
}


- (void)didCancelEditing
{
    if (self.state.actionIsRegister) {
        [_delegate dismissModalViewControllerWithIdentitifier:kMemberViewControllerId];
    } else if (self.state.actionIsEdit) {
        _dateOfBirthField.text = [_member.dateOfBirth localisedDateString];
        _mobilePhoneField.text = _member.mobilePhone;
        _emailField.text = _member.email;
        
        [self toggleEditMode];
    }
}


- (void)didFinishEditing
{
    BOOL inputIsValid = ([_nameField holdsValidName] && [_dateOfBirthField holdsValidDate]);
    
    if (inputIsValid) {
        if (self.state.aspectIsSelf || ![_dateOfBirthPicker.date isBirthDateOfMinor]) {
            inputIsValid = inputIsValid && [self emailIsEligible];
            inputIsValid = inputIsValid && [_mobilePhoneField holdsValidPhoneNumber];
        } else if ([_dateOfBirthPicker.date isBirthDateOfMinor]) {
            if ([[_emailField finalText] length] > 0) {
                inputIsValid = inputIsValid && [_emailField holdsValidEmail];
            }
        }
    }
    
    if (inputIsValid) {
        if (self.state.actionIsRegister) {
            [self.view endEditing:YES];
            
            if (_candidate) {
                if ([_origo isResidence] && [_candidate.residencies count]) {
                    [self promptForExistingResidenceAction];
                } else {
                    [self registerMember];
                }
            } else {
                if (!_gender) {
                    [self promptForGender];
                } else {
                    [self updateMember];
                }
            }
        } else if (self.state.actionIsEdit) {
            if ([_member hasEmail] && ![[_emailField finalText] isEqualToString:_member.email]) {
                if (self.state.aspectIsSelf) {
                    [self promptForUserEmailChangeConfirmation];
                } else {
                    [self promptForMemberEmailChangeConfirmation];
                }
            } else {
                [self updateMember];
                [self toggleEditMode];
            }
        }
    } else {
        [_memberCell shakeCellVibrateDevice:NO];
    }
}


- (void)addAddress
{
    [self performSegueWithIdentifier:kModalSegueToOrigoView2 sender:self];
}


- (void)signOut
{
    [[OMeta m] userDidSignOut];
    _memberCell.entity = nil;
    
    [_delegate dismissModalViewControllerWithIdentitifier:kMemberViewControllerId];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView setBackground];
    
    if (self.state.aspectIsSelf) {
        self.title = [OStrings stringForKey:strViewTitleAboutMe];
    } else if (_member) {
        self.title = _member.givenName;
    }
    
    if (self.state.actionIsDisplay) {
        if ([self canEdit]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem addButtonWithTarget:self];
            self.navigationItem.rightBarButtonItem.action = @selector(addAddress);
        }
        
        NSMutableSet *residences = [[NSMutableSet alloc] init];
        
        for (OMemberResidency *residency in _member.residencies) {
            [residences addObject:residency.residence];
        }
        
        _sortedResidences = [[residences allObjects] sortedArrayUsingSelector:@selector(compare:)];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.state.actionIsRegister) {
        if ([_origo isResidence] && !self.title) {
            self.title = [OStrings stringForKey:strViewTitleNewHouseholdMember];
        } else if (!self.title) {
            self.title = [OStrings stringForKey:strViewTitleNewMember];
        }
        
        _nextButton = [UIBarButtonItem nextButtonWithTarget:self];
        _doneButton = [UIBarButtonItem doneButtonWithTarget:self];
        
        self.navigationItem.rightBarButtonItem = _nextButton;
        
        if (self.state.aspectIsSelf) {
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem signOutButtonWithTarget:self];
        } else {
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.state.actionIsRegister) {
        [_nameField becomeFirstResponder];
    } else if ([self canEdit]) {
        _memberCell.editable = YES;
    }
    
    OLogState;
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kModalSegueToAuthView]) {
        OAuthViewController *authViewController = segue.destinationViewController;
        authViewController.emailToActivate = [_emailField finalText];
        authViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:kModalSegueToOrigoView1]) {
        UINavigationController *navigationController = segue.destinationViewController;
        OOrigoViewController *origoViewController = navigationController.viewControllers[0];
        origoViewController.membership = [_origo userMembership];
        origoViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:kModalSegueToOrigoView2]) {
        UINavigationController *navigationController = segue.destinationViewController;
        OOrigoViewController *origoViewController = navigationController.viewControllers[0];
        origoViewController.origo = [[OMeta m].context insertOrigoEntityOfType:kOrigoTypeResidence];
        origoViewController.member = _member;
        origoViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:kPushSegueToMemberListView]) {
        OMemberListViewController *memberListViewController = segue.destinationViewController;
        memberListViewController.origo = _origo;
        memberListViewController.delegate = _delegate;
    }
}


#pragma mark - Overrides

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}


#pragma mark - OStateDelegate conformance

- (void)setStatePrerequisites
{
    if (_membership) {
        _member = _membership.member;
        _origo = _membership.origo;
    }
}


- (void)setState
{
    self.state.targetIsMember = YES;
    self.state.actionIsDisplay = self.state.actionIsActivate ? YES : ![OState s].actionIsInput;
    
    if (_member) {
        [self.state setAspectForMember:_member];
    }
}


#pragma mark - UITableViewDataSource conformance

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.state.actionIsRegister ? 1 : 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (section == kMemberSection) ? 1 : [_member.residencies count];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.f;
    
    if (indexPath.section == kMemberSection) {
        height = _member ? [_member cellHeight] : [OMember defaultCellHeight];
    } else if (indexPath.section == kAddressSection) {
        height = kDefaultTableViewCellHeight;
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.section == kMemberSection) {
        if (_member) {
            _memberCell = [tableView cellForEntity:_member delegate:self];
            _gender = _member.gender;
        } else {
            _memberCell = [tableView cellForEntityClass:OMember.class delegate:self];
        }
        
        _nameField = [_memberCell textFieldForKeyPath:kKeyPathName];
        _dateOfBirthField = [_memberCell textFieldForKeyPath:kKeyPathDateOfBirth];
        _dateOfBirthPicker = (UIDatePicker *)_dateOfBirthField.inputView;
        _mobilePhoneField = [_memberCell textFieldForKeyPath:kKeyPathMobilePhone];
        _emailField = [_memberCell textFieldForKeyPath:kKeyPathEmail];
        
        cell = _memberCell;
    } else if (indexPath.section == kAddressSection) {
        OOrigo *residence = _sortedResidences[indexPath.row];
        
        cell = [tableView listCellForEntity:residence];
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate conformance

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = kDefaultPadding;
    
    if (section == kAddressSection) {
        height = [tableView standardHeaderHeight];
    }
    
    return height;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = nil;
    
    if (section == kAddressSection) {
        if ([_member.residencies count] == 1) {
            headerView = [tableView headerViewWithText:[OStrings stringForKey:strTermAddress]];
        } else {
            headerView = [tableView headerViewWithText:[OStrings stringForKey:strHeaderAddresses]];
        }
    }
    
    return headerView;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(OTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1) {
        [cell willAppearTrailing:YES];
    } else {
        [cell willAppearTrailing:NO];
    }
}


#pragma mark - UITextFieldDelegate conformance

- (void)textFieldDidBeginEditing:(OTextField *)textField
{
    if (self.state.actionIsDisplay) {
        [self toggleEditMode];
    }
    
    if (textField == _emailField) {
        self.navigationItem.rightBarButtonItem = _doneButton;
    } else if (textField == _mobilePhoneField) {
        if (self.state.actionIsRegister && self.state.aspectIsSelf) {
            self.navigationItem.rightBarButtonItem = _doneButton;
        } else {
            self.navigationItem.rightBarButtonItem = _nextButton;
        }
    } else {
        self.navigationItem.rightBarButtonItem = _nextButton;
    }
    
    _currentField = textField;
    
    textField.hasEmphasis = YES;
}


- (void)textFieldDidEndEditing:(OTextField *)textField
{
    textField.hasEmphasis = NO;
}


- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    BOOL shouldEndEditing = YES;
    
    if (textField == _emailField) {
        shouldEndEditing = (![_emailField holdsValidEmail] || [self emailIsEligible]);
    }
    
    return shouldEndEditing;
}


- (BOOL)textFieldShouldReturn:(OTextField *)textField
{
    BOOL shouldReturn = YES;
    
    if (textField == _nameField) {
        [_dateOfBirthField becomeFirstResponder];
    } else if (textField == _emailField) {
        shouldReturn = [self textFieldShouldEndEditing:textField];
        
        if (shouldReturn) {
            [self didFinishEditing];
        }
    }
    
    return shouldReturn;
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case kGenderSheetTag:
            if (buttonIndex != kGenderSheetButtonCancel) {
                _gender = (buttonIndex == kGenderSheetButtonFemale) ? kGenderFemale : kGenderMale;
                [self registerMember];
            }
            
            break;
            
        case kExistingResidenceSheetTag:
            if (buttonIndex == kExistingResidenceButtonInviteToHousehold) {
                [self registerMember];
            } else if (buttonIndex == kExistingResidenceButtonMergeHouseholds) {
                // TODO
            }
            
            break;
            
        case kEmailChangeAlertTag:
            if (buttonIndex == kEmailChangeButtonContinue) {
                [self toggleEditMode];
                [self performSegueWithIdentifier:kModalSegueToAuthView sender:self];
            }
            
            break;
            
        default:
            break;
    }
}


#pragma mark - UIAlertViewDelegate conformance

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kEmailChangeAlertTag:
            if (buttonIndex == kEmailChangeButtonContinue) {
                [self toggleEditMode];
                [self performSegueWithIdentifier:kModalSegueToAuthView sender:self];
            } else {
                [_emailField becomeFirstResponder];
            }
            
            break;
            
        default:
            break;
    }
}


#pragma mark - OModalViewControllerDelegate conformance

- (void)dismissModalViewControllerWithIdentitifier:(NSString *)identitifier
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    if ([identitifier isEqualToString:kAuthViewControllerId]) {
        if ([_member.email isEqualToString:[_emailField finalText]]) {
            [OMeta m].userEmail = _member.email;
            [self updateMember];
        } else {
            UIAlertView *failedEmailChangeAlert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleEmailChangeFailed] message:[NSString stringWithFormat:[OStrings stringForKey:strAlertTextEmailChangeFailed], [_emailField finalText]] delegate:nil cancelButtonTitle:[OStrings stringForKey:strButtonOK] otherButtonTitles:nil];
            [failedEmailChangeAlert show];
            
            [self toggleEditMode];
            [_emailField becomeFirstResponder];
        }
    } else if ([identitifier isEqualToString:kOrigoViewControllerId]) {
        if (self.state.actionIsRegister) {
            [self performSegueWithIdentifier:kPushSegueToMemberListView sender:self];
        }
    }
}

@end
