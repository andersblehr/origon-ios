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
#import "UIColor+OColorExtensions.h"
#import "UIDatePicker+ODatePickerExtensions.h"
#import "UIFont+OFontExtensions.h"
#import "UITableView+OTableViewExtensions.h"
#import "UIView+OViewExtensions.h"

#import "OMemberListViewController.h"
#import "OOrigoViewController.h"

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

#import "OCachedEntity+OCachedEntityExtensions.h"
#import "OMember+OMemberExtensions.h"
#import "OMemberResidency+OMemberResidencyExtensions.h"
#import "OMembership+OMembershipExtensions.h"
#import "OOrigo+OOrigoExtensions.h"

static NSInteger const kMemberSection = 0;
static NSInteger const kAddressSection = 1;

static NSInteger const kNumberOfInputSections = 1;
static NSInteger const kNumberOfDisplaySections = 2;
static NSInteger const kNumberOfMemberRows = 1;

static NSInteger const kGenderSheetTag = 0;
static NSInteger const kGenderSheetButtonFemale = 0;
static NSInteger const kGenderSheetButtonCancel = 2;

static NSInteger const kExistingResidenceSheetTag = 1;
static NSInteger const kExistingResidenceButtonInviteToHousehold = 0;
static NSInteger const kExistingResidenceButtonMergeHouseholds = 1;
static NSInteger const kExistingResidenceButtonCancel = 2;

static NSString * const kSegueToMemberListView = @"memberToMemberListView";


@implementation OMemberViewController

#pragma mark - Auxiliary methods

- (void)registerHousehold
{
    [OState s].targetIsOrigo = YES;
    
    OOrigoViewController *origoViewController = [self.storyboard instantiateViewControllerWithIdentifier:kOrigoViewControllerId];
    origoViewController.origo = _origo;
    origoViewController.delegate = self;
    
    UINavigationController *modalController = [[UINavigationController alloc] initWithRootViewController:origoViewController];
    modalController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [self.navigationController presentViewController:modalController animated:YES completion:NULL];
}


- (void)populateWithCandidate
{
    if (![_candidate.name isEqualToString:_candidate.entityId]) {
        _nameField.text = _candidate.name;
    }
    
    _emailField.text = _candidate.entityId;
    _mobilePhoneField.text = _candidate.mobilePhone;
    [_dateOfBirthPicker setDate:_candidate.dateOfBirth animated:YES];
    _dateOfBirthField.text = [_candidate.dateOfBirth localisedDateString];
    _gender = _candidate.gender;
    
    if (_candidate.activeSince) {
        _memberCell.editing = NO;
    }
}


- (void)promptForGender
{
    NSString *titleQuestion = nil;
    NSString *femaleLabel = nil;
    NSString *maleLabel = nil;
    
    if ([_dateOfBirthPicker.date isBirthDateOfMinor]) {
        if ([OState s].aspectIsSelf) {
            titleQuestion = [OStrings stringForKey:strGenderSheetTitleSelfMinor];
        } else {
            titleQuestion = [NSString stringWithFormat:[OStrings stringForKey:strGenderSheetTitleMemberMinor], [NSString givenNameFromFullName:_nameField.text]];
        }
        
        femaleLabel = [OStrings stringForKey:strFemaleMinor];
        maleLabel = [OStrings stringForKey:strMaleMinor];
    } else {
        if ([OState s].aspectIsSelf) {
            titleQuestion = [OStrings stringForKey:strGenderSheetTitleSelf];
        } else {
            titleQuestion = [NSString stringWithFormat:[OStrings stringForKey:strGenderSheetTitleMember], [NSString givenNameFromFullName:_nameField.text]];
        }
        
        femaleLabel = [OStrings stringForKey:strFemale];
        maleLabel = [OStrings stringForKey:strMale];
    }
        
    UIActionSheet *genderSheet = [[UIActionSheet alloc] initWithTitle:titleQuestion delegate:self cancelButtonTitle:[OStrings stringForKey:strCancel] destructiveButtonTitle:nil otherButtonTitles:femaleLabel, maleLabel, nil];
    genderSheet.tag = kGenderSheetTag;
    [genderSheet showInView:self.view];
}


- (void)promptForExistingResidenceAction
{
    NSString *titleQuestion = [NSString stringWithFormat:[OStrings stringForKey:strExistingResidenceAlert], _candidate.name, _candidate.givenName];
    
    UIActionSheet *existingResidenceSheet = [[UIActionSheet alloc] initWithTitle:titleQuestion delegate:self cancelButtonTitle:[OStrings stringForKey:strCancel] destructiveButtonTitle:nil otherButtonTitles:[OStrings stringForKey:strInviteToHousehold], [OStrings stringForKey:strMergeHouseholds], nil];
    existingResidenceSheet.tag = kExistingResidenceSheetTag;
    [existingResidenceSheet showInView:self.view];
}


- (void)registerMember
{
    if (!_member) {
        if (_candidate) {
            _member = _candidate;
        } else {
            if (_emailField.text.length > 0) {
                _member = [[OMeta m].context memberEntityWithId:_emailField.text];
            } else {
                _member = [[OMeta m].context memberEntity];
            }
        }
    }
    
    [self updateMember];

    if (!_membership) {
        if ([_origo isResidence]) {
            _membership = [_origo addResident:_member];
        } else {
            _membership = [_origo addMember:_member];
        }
    }
    
    if ([OState s].aspectIsSelf && _membership.isAdmin_) { // TODO: Additional cases
        [self registerHousehold];
    } else {
        [_delegate dismissViewControllerWithIdentitifier:kMemberViewControllerId];
        [_delegate insertEntityInTableView:_membership];
    }
}


- (void)updateMember
{
    _member.name = _nameField.text;
    _member.dateOfBirth = _dateOfBirthPicker.date;
    _member.mobilePhone = _mobilePhoneField.text;
    
    if ([OState s].actionIsRegister) {
        _member.givenName = [NSString givenNameFromFullName:_member.name];
        _member.gender = _gender;
    }
}


#pragma mark - Selector implementations

- (void)dateOfBirthDidChange
{
    _dateOfBirthField.text = [_dateOfBirthPicker.date localisedDateString];
}


- (void)startEditing
{
    
}


- (void)cancelEditing
{
    if (_candidate) {
        for (OCachedEntity *entity in _candidateEntities) {
            [[OMeta m].context deleteObject:entity];
        }
        
        _candidateEntities = nil;
        _candidate = nil;
    }
    
    [_delegate dismissViewControllerWithIdentitifier:kMemberViewControllerId];
}


- (void)didFinishEditing
{
    BOOL isValidInput = YES;
    
    isValidInput = isValidInput && [OMeta isNameValid:_nameField];
    isValidInput = isValidInput && [OMeta isDateOfBirthValid:_dateOfBirthField];
    
    if (isValidInput && ![_dateOfBirthPicker.date isBirthDateOfMinor]) {
        isValidInput = isValidInput && [OMeta isEmailValid:_emailField];
        isValidInput = isValidInput && [OMeta isMobileNumberValid:_mobilePhoneField];
    } else if (isValidInput) {
        if (_emailField.text.length > 0) {
            isValidInput = isValidInput && [OMeta isEmailValid:_emailField];
        }
    }
    
    if (isValidInput) {
        [self.view endEditing:YES];
        
        if ([OState s].actionIsRegister) {
            if (_candidate) {
                if ([_origo isResidence]) {
                    [self promptForExistingResidenceAction];
                } else {
                    [self registerMember];
                }
            } else {
                [self promptForGender];
            }
        } else {
            [self updateMember];
        }
    } else {
        [_memberCell shake];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView setBackground];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    _editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(startEditing)];
    _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditing)];
    _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didFinishEditing)];
    
    if (_membership) {
        _member = _membership.member;
        _origo = _membership.origo;
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [OState s].targetIsMember = YES;
    [OState s].actionIsDisplay = ![OState s].actionIsInput;
    
    OLogState;
    
    if ([OState s].actionIsRegister) {
        self.navigationItem.rightBarButtonItem = _doneButton;
        
        if ([OState s].aspectIsSelf) {
            self.title = [OStrings stringForKey:strAboutMe];
        } else {
            self.navigationItem.leftBarButtonItem = _cancelButton;
            
            if ([_origo isResidence]) {
                self.title = [OStrings stringForKey:strViewTitleNewHouseholdMember];
            } else {
                self.title = [OStrings stringForKey:strViewTitleNewMember];
            }
        }
    } else if ([OState s].actionIsDisplay) {
        self.navigationItem.rightBarButtonItem = _editButton;
        
        if ([OState s].aspectIsSelf) {
            self.title = [OStrings stringForKey:strAboutMe];
        } else {
            self.title = _member.givenName;
        }
        
        NSMutableSet *residences = [[NSMutableSet alloc] init];
        
        for (OMemberResidency *residency in _member.residencies) {
            [residences addObject:residency.residence];
        }
        
        _sortedResidences = [[residences allObjects] sortedArrayUsingSelector:@selector(compare:)];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToMemberListView]) {
        OMemberListViewController *memberListViewController = segue.destinationViewController;
        memberListViewController.delegate = _delegate;
        memberListViewController.origo = _origo;
        
        [OState s].actionIsList = YES;
    }
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ([OState s].actionIsDisplay ? kNumberOfDisplaySections : kNumberOfInputSections);
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    if (section == kMemberSection) {
        numberOfRows = kNumberOfMemberRows;
    } else if (section == kAddressSection) {
        numberOfRows = [_member.residencies count];
    }
    
    return numberOfRows;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.f;
    
    if (indexPath.section == kMemberSection) {
        if ([OState s].actionIsInput) {
            height = [OTableViewCell heightForEntityClass:OMember.class];
        } else {
            height = [OTableViewCell heightForEntity:_member];
        }
    } else if (indexPath.section == kAddressSection) {
        height = [OTableViewCell defaultHeight];
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.section == kMemberSection) {
        if ([OState s].actionIsDisplay) {
            _memberCell = [tableView cellForEntity:_member];
        } else if ([OState s].actionIsInput) {
            if ([OState s].aspectIsSelf) {
                _memberCell = [tableView cellForEntity:_member delegate:self];
            } else if ([OState s].actionIsInput) {
                _memberCell = [tableView cellForEntityClass:OMember.class delegate:self];
            }
            
            _nameField = [_memberCell textFieldWithKey:kTextFieldKeyName];
            _emailField = [_memberCell textFieldWithKey:kTextFieldKeyEmail];
            _mobilePhoneField = [_memberCell textFieldWithKey:kTextFieldKeyMobilePhone];
            _dateOfBirthField = [_memberCell textFieldWithKey:kTextFieldKeyDateOfBirth];
            _dateOfBirthPicker = (UIDatePicker *)_dateOfBirthField.inputView;
            
            if (_member.dateOfBirth) {
                _dateOfBirthPicker.date = _member.dateOfBirth;
                _gender = _member.gender;
            }
            
            [_nameField becomeFirstResponder];
        }
        
        cell = _memberCell;
    } else if (indexPath.section == kAddressSection) {
        OOrigo *residence = _sortedResidences[indexPath.row];
        
        cell = [tableView cellWithReuseIdentifier:kReuseIdentifierDefault];
        cell.textLabel.text = residence.addressLine1;
        cell.detailTextLabel.text = residence.telephone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = kDefaultSectionHeaderHeight;
    
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
            headerView = [tableView headerViewWithTitle:[OStrings stringForKey:strAddressLabel]];
        } else {
            headerView = [tableView headerViewWithTitle:[OStrings stringForKey:strAddressesLabel]];
        }
    }
    
    return headerView;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kMemberSection) {
        [cell.backgroundView addShadowForBottomTableViewCell];
        
        if ([OState s].actionIsInput) {
            [_nameField becomeFirstResponder];
        }
    } else {
        if (indexPath.row == [_sortedResidences count] - 1) {
            [cell.backgroundView addShadowForBottomTableViewCell];
        } else {
            [cell.backgroundView addShadowForContainedTableViewCell];
        }
    }
}


#pragma mark - UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (_currentField == _emailField) {
        if ((_emailField.text.length > 0) && [OMeta isEmailValid:_emailField]) {
            if ([OState s].aspectIsSelf) {
                // TODO: Handle user email change
            } else {
                if ([_origo hasMemberWithId:_emailField.text]) {
                    NSString *alertTitle = [OStrings stringForKey:strMemberExistsTitle];
                    NSString *alertMessage = [NSString stringWithFormat:[OStrings stringForKey:strMemberExistsAlert], _emailField.text, _origo.name];
                    
                    [OAlert showAlertWithTitle:alertTitle message:alertMessage];
                } else {
                    _candidate = [[OMeta m].context lookUpEntityInCache:_emailField.text];
                    
                    if (_candidate) {
                        [self populateWithCandidate];
                    } else {
                        [[[OServerConnection alloc] init] fetchMemberEntitiesFromServer:_emailField.text delegate:self];
                    }
                }
            }
        }
    }
    
    _currentField = textField;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _nameField) {
        if (_emailField.enabled) {
            [_emailField becomeFirstResponder];
        } else {
            [_mobilePhoneField becomeFirstResponder];
        }
    } else if (textField == _emailField) {
        [_mobilePhoneField becomeFirstResponder];
    } else if (textField == _mobilePhoneField) {
        [_dateOfBirthField becomeFirstResponder];
    }
    
    return YES;
}


#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
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


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    _emailField.text = @"";
    [_emailField becomeFirstResponder];
}


#pragma mark - OModalViewControllerDelegate methods

- (void)dismissViewControllerWithIdentitifier:(NSString *)identitifier
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    if ([identitifier isEqualToString:kOrigoViewControllerId]) {
        [self performSegueWithIdentifier:kSegueToMemberListView sender:self];
    }
}


#pragma mark - OServerConnectionDelegate methods

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(NSArray *)data
{
    if (response.statusCode == kHTTPStatusCodeOK) {
        _candidateEntities = [[OMeta m].context saveServerEntitiesToCache:data];
        _candidate = [[OMeta m].context lookUpEntityInCache:_emailField.text];
        
        [self populateWithCandidate];
    }
}


- (void)didFailWithError:(NSError *)error
{
    
}

@end