//
//  OMemberViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMemberViewController.h"

#import "NSDate+ODateExtensions.h"
#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"
#import "NSString+OStringExtensions.h"
#import "UIBarButtonItem+OBarButtonItemExtensions.h"
#import "UIColor+OColorExtensions.h"
#import "UIDatePicker+ODatePickerExtensions.h"
#import "UIFont+OFontExtensions.h"
#import "UITableView+OTableViewExtensions.h"
#import "UIView+OViewExtensions.h"

#import "OEntityObservingDelegate.h"

#import "OAlert.h"
#import "OLogging.h"
#import "OMeta.h"
#import "OServerConnection.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextField.h"

#import "OMember.h"
#import "OMemberResidency.h"
#import "OMembership.h"
#import "OOrigo.h"

#import "OMember+OMemberExtensions.h"
#import "OMemberResidency+OMemberResidencyExtensions.h"
#import "OMembership+OMembershipExtensions.h"
#import "OOrigo+OOrigoExtensions.h"
#import "OReplicatedEntity+OReplicatedEntityExtensions.h"

#import "OMemberListViewController.h"
#import "OOrigoViewController.h"

static NSString * const kModalSegueToOrigoView = @"modalFromMemberToOrigoView";
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


@implementation OMemberViewController

#pragma mark - Auxiliary methods

- (BOOL)emailIsEligible
{
    BOOL emailIsEligible = [_emailField holdsValidEmail];
    
    if (emailIsEligible && [OState s].actionIsRegister && ![OState s].aspectIsSelf) {
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
    
    if ([OState s].actionIsRegister) {
        _member.givenName = [NSString givenNameFromFullName:_member.name];
        _member.gender = _gender;
        
        if (![_origo isResidence] || [_origo hasAddress]) {
            if ([_origo isResidence] && [OState s].aspectIsSelf) {
                [OMeta m].user.activeSince = [NSDate date];
            }
            
            [_delegate dismissModalViewControllerWithIdentitifier:kMemberViewControllerId];
            
            if ([_delegate isKindOfClass:OMemberListViewController.class]) {
                [_delegate insertEntityInTableView:_membership];
            }
        } else {
            [self performSegueWithIdentifier:kModalSegueToOrigoView sender:self];
        }
    } else {
        [[OMeta m].context replicateIfNeeded];
        [_entityObservingDelegate refresh];
    }
}


- (void)toggleEditMode
{
    static UIBarButtonItem *editButton = nil;
    static UIBarButtonItem *backButton = nil;
    
    [_memberCell toggleEditMode];
    
    if ([OState s].actionIsEdit) {
        editButton = self.navigationItem.rightBarButtonItem;
        backButton = self.navigationItem.leftBarButtonItem;
        
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
        
        [_nameField becomeFirstResponder];
    } else if ([OState s].actionIsDisplay) {
        self.navigationItem.rightBarButtonItem = editButton;
        self.navigationItem.leftBarButtonItem = backButton;
    }
    
    OLogState;
}


#pragma mark - State handling

- (void)setState
{
    [OState s].targetIsMember = YES;
    [OState s].actionIsDisplay = ![OState s].actionIsInput;
    
    if (![OState s].actionIsRegister) {
        [[OState s] setAspectForMember:_member];
    }
}


- (void)restoreStateIfNeeded
{
    if (![self isBeingPresented] && ![self isMovingToParentViewController]) {
        [self setState];
    }
}


#pragma mark - Action sheets

- (void)promptForGender
{
    NSString *titleQuestion = nil;
    NSString *femaleLabel = nil;
    NSString *maleLabel = nil;
    
    if ([_dateOfBirthPicker.date isBirthDateOfMinor]) {
        if ([OState s].aspectIsSelf) {
            titleQuestion = [OStrings stringForKey:strSheetTitleGenderSelfMinor];
        } else {
            titleQuestion = [NSString stringWithFormat:[OStrings stringForKey:strSheetTitleGenderMinor], [NSString givenNameFromFullName:[_nameField finalText]]];
        }
        
        femaleLabel = [OStrings stringForKey:strTermFemaleMinor];
        maleLabel = [OStrings stringForKey:strTermMaleMinor];
    } else {
        if ([OState s].aspectIsSelf) {
            titleQuestion = [OStrings stringForKey:strSheetTitleGenderSelf];
        } else {
            titleQuestion = [NSString stringWithFormat:[OStrings stringForKey:strSheetTitleGenderMember], [NSString givenNameFromFullName:[_nameField finalText]]];
        }
        
        femaleLabel = [OStrings stringForKey:strTermFemale];
        maleLabel = [OStrings stringForKey:strTermMale];
    }
    
    UIActionSheet *genderSheet = [[UIActionSheet alloc] initWithTitle:titleQuestion delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonCancel] destructiveButtonTitle:nil otherButtonTitles:femaleLabel, maleLabel, nil];
    genderSheet.tag = kGenderSheetTag;
    [genderSheet showInView:self.view];
}


- (void)promptForExistingResidenceAction
{
    NSString *titleQuestion = [NSString stringWithFormat:[OStrings stringForKey:strSheetTitleExistingResidence], _candidate.name, _candidate.givenName];
    
    UIActionSheet *existingResidenceSheet = [[UIActionSheet alloc] initWithTitle:titleQuestion delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonCancel] destructiveButtonTitle:nil otherButtonTitles:[OStrings stringForKey:strButtonInviteToHousehold], [OStrings stringForKey:strButtonMergeHouseholds], nil];
    existingResidenceSheet.tag = kExistingResidenceSheetTag;
    [existingResidenceSheet showInView:self.view];
}


- (void)promptForUserEmailChangeConfirmation
{
    
}


- (void)promptForMemberEmailChangeConfirmation
{
    
}


#pragma mark - Selector implementations

- (void)dateOfBirthDidChange
{
    _dateOfBirthField.text = [_dateOfBirthPicker.date localisedDateString];
}


- (void)startEditing
{
    [self toggleEditMode];
}


- (void)cancelEditing
{
    if ([OState s].actionIsRegister) {
        [_delegate dismissModalViewControllerWithIdentitifier:kMemberViewControllerId];
    } else if ([OState s].actionIsEdit) {
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
        if ([OState s].aspectIsSelf || ![_dateOfBirthPicker.date isBirthDateOfMinor]) {
            inputIsValid = inputIsValid && [self emailIsEligible];
            inputIsValid = inputIsValid && [_mobilePhoneField holdsValidPhoneNumber];
        } else if ([_dateOfBirthPicker.date isBirthDateOfMinor]) {
            if ([[_emailField finalText] length] > 0) {
                inputIsValid = inputIsValid && [_emailField holdsValidEmail];
            }
        }
    }
    
    if (inputIsValid) {
        if ([OState s].actionIsRegister) {
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
        } else if ([OState s].actionIsEdit) {
            if (![[_emailField finalText] isEqualToString:_member.email]) {
                if ([OState s].aspectIsSelf) {
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


- (void)signOut
{
    [[OMeta m] userDidSignOut];
    
    [_delegate dismissModalViewControllerWithIdentitifier:kMemberViewControllerId];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView setBackground];
    
    if (_membership) {
        _member = _membership.member;
        _origo = _membership.origo;
    }
    
    [self setState];
    
    if ([OState s].aspectIsSelf) {
        self.title = [OStrings stringForKey:strViewTitleAboutMe];
    } else if ([OState s].actionIsRegister) {
        if ([_origo isResidence]) {
            self.title = [OStrings stringForKey:strViewTitleNewHouseholdMember];
        } else {
            self.title = [OStrings stringForKey:strViewTitleNewMember];
        }
    } else {
        self.title = _member.givenName;
    }
    
    if ([OState s].actionIsInput) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
        
        if ([OState s].actionIsRegister && [OState s].aspectIsSelf) {
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem signOutButtonWithTarget:self];
        } else {
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
        }
    } else if ([OState s].actionIsDisplay) {
        BOOL memberIsUserAndTeen = ([_member isUser] && [_member isTeenOrOlder]);
        BOOL memberIsWardOfUser = [[[OMeta m].user wards] containsObject:_member];
        BOOL membershipIsInactiveAndUserIsAdmin = ([_origo userIsAdmin] && !_membership.isActive_);
        
        if (memberIsUserAndTeen || memberIsWardOfUser || membershipIsInactiveAndUserIsAdmin) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem editButtonWithTarget:self];
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
    
    [self restoreStateIfNeeded];
    
    OLogState;
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([OState s].actionIsInput) {
        [_nameField becomeFirstResponder];
    }
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kModalSegueToOrigoView]) {
        UINavigationController *navigationController = segue.destinationViewController;
        OOrigoViewController *origoViewController = navigationController.viewControllers[0];
        origoViewController.membership = [_origo userMembership];
        origoViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:kPushSegueToMemberListView]) {
        OMemberListViewController *memberListViewController = segue.destinationViewController;
        memberListViewController.delegate = _delegate;
        memberListViewController.origo = _origo;
        
        [OState s].actionIsList = YES;
    }
}


#pragma mark - UITableViewDataSource conformance

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [OState s].actionIsRegister ? 1 : 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (section == kMemberSection) ? 1 : [_member.residencies count];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.f;
    
    if (indexPath.section == kMemberSection) {
        if ([OState s].actionIsInput) {
            height = [OMember defaultDisplayCellHeight];
        } else {
            height = [_member displayCellHeight];
        }
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
    [textField emphasise];
}


- (void)textFieldDidEndEditing:(OTextField *)textField
{
    [textField deemphasise];
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
            
        default:
            break;
    }
}


#pragma mark - OModalViewControllerDelegate conformance

- (void)dismissModalViewControllerWithIdentitifier:(NSString *)identitifier
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    if ([identitifier isEqualToString:kOrigoViewControllerId]) {
        [self performSegueWithIdentifier:kPushSegueToMemberListView sender:self];
    }
}

@end
