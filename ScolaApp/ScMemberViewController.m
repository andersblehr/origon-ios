//
//  ScMemberViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 07.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMemberViewController.h"

#import "NSDate+ScDateExtensions.h"
#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "NSString+ScStringExtensions.h"
#import "UIColor+ScColorExtensions.h"
#import "UIDatePicker+ScDatePickerExtensions.h"
#import "UIFont+ScFontExtensions.h"
#import "UITableView+UITableViewExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScMembershipViewController.h"
#import "ScScolaViewController.h"

#import "ScAlert.h"
#import "ScLogging.h"
#import "ScMeta.h"
#import "ScServerConnection.h"
#import "ScState.h"
#import "ScStrings.h"
#import "ScTableViewCell.h"
#import "ScTextField.h"

#import "ScMember.h"
#import "ScMemberResidency.h"
#import "ScMembership.h"
#import "ScScola.h"

#import "ScCachedEntity+ScCachedEntityExtensions.h"
#import "ScMember+ScMemberExtensions.h"
#import "ScMemberResidency+ScMemberResidencyExtensions.h"
#import "ScScola+ScScolaExtensions.h"

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

static NSString * const kSegueToMembershipView = @"memberToMembershipView";


@implementation ScMemberViewController

#pragma mark - Auxiliary methods

- (void)registerHousehold
{
    [ScState s].target = ScStateTargetResidence;
    
    ScScolaViewController *scolaViewController = [self.storyboard instantiateViewControllerWithIdentifier:kScolaViewControllerId];
    scolaViewController.scola = _scola;
    scolaViewController.delegate = self;
    
    UINavigationController *modalController = [[UINavigationController alloc] initWithRootViewController:scolaViewController];
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
        if ([ScState s].aspectIsSelf) {
            titleQuestion = [ScStrings stringForKey:strGenderActionSheetTitleSelfMinor];
        } else {
            titleQuestion = [NSString stringWithFormat:[ScStrings stringForKey:strGenderActionSheetTitleMemberMinor], [NSString givenNameFromFullName:_nameField.text]];
        }
        
        femaleLabel = [ScStrings stringForKey:strFemaleMinor];
        maleLabel = [ScStrings stringForKey:strMaleMinor];
    } else {
        if ([ScState s].aspectIsSelf) {
            titleQuestion = [ScStrings stringForKey:strGenderActionSheetTitleSelf];
        } else {
            titleQuestion = [NSString stringWithFormat:[ScStrings stringForKey:strGenderActionSheetTitleMember], [NSString givenNameFromFullName:_nameField.text]];
        }
        
        femaleLabel = [ScStrings stringForKey:strFemale];
        maleLabel = [ScStrings stringForKey:strMale];
    }
        
    UIActionSheet *genderSheet = [[UIActionSheet alloc] initWithTitle:titleQuestion delegate:self cancelButtonTitle:[ScStrings stringForKey:strCancel] destructiveButtonTitle:nil otherButtonTitles:femaleLabel, maleLabel, nil];
    genderSheet.tag = kGenderSheetTag;
    [genderSheet showInView:self.view];
    
    //[_nameField becomeFirstResponder]; // TODO: Why is this here?
}


- (void)promptForExistingResidenceAction
{
    NSString *titleQuestion = [NSString stringWithFormat:[ScStrings stringForKey:strExistingResidenceAlert], _candidate.name, _candidate.givenName];
    
    UIActionSheet *existingResidenceSheet = [[UIActionSheet alloc] initWithTitle:titleQuestion delegate:self cancelButtonTitle:[ScStrings stringForKey:strCancel] destructiveButtonTitle:nil otherButtonTitles:[ScStrings stringForKey:strInviteToHousehold], [ScStrings stringForKey:strMergeHouseholds], nil];
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
                _member = [[ScMeta m].context entityForClass:ScMember.class inScola:_scola entityId:_emailField.text];
            } else {
                _member = [[ScMeta m].context entityForClass:ScMember.class inScola:_scola];
            }
        }
        
        if ([_scola isResidence]) {
            _membership = [_scola addResident:_member];
        } else {
            _membership = [_scola addMember:_member];
        }
    }
    
    [self updateMember];
    
    if ([ScState s].aspectIsSelf && [_membership.isAdmin boolValue]) { // TODO: Additional cases
        [self registerHousehold];
    } else {
        [_delegate shouldDismissViewControllerWithIdentitifier:kMemberViewControllerId];
        [_delegate insertMembershipInTableView:_membership];
    }
}


- (void)updateMember
{
    _member.name = _nameField.text;
    _member.dateOfBirth = _dateOfBirthPicker.date;
    _member.mobilePhone = _mobilePhoneField.text;
    
    if (![_member isPersisted]) {
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
        for (ScCachedEntity *entity in _candidateEntities) {
            [[ScMeta m].context deleteObject:entity];
        }
        
        _candidateEntities = nil;
        _candidate = nil;
    }
    
    [_delegate shouldDismissViewControllerWithIdentitifier:kMemberViewControllerId];
}


- (void)didFinishEditing
{
    BOOL isValidInput = YES;
    
    isValidInput = isValidInput && [ScMeta isNameValid:_nameField];
    isValidInput = isValidInput && [ScMeta isDateOfBirthValid:_dateOfBirthField];
    
    if (isValidInput && ![_dateOfBirthPicker.date isBirthDateOfMinor]) {
        isValidInput = isValidInput && [ScMeta isEmailValid:_emailField];
        isValidInput = isValidInput && [ScMeta isMobileNumberValid:_mobilePhoneField];
    } else if (isValidInput) {
        if (_emailField.text.length > 0) {
            isValidInput = isValidInput && [ScMeta isEmailValid:_emailField];
        }
    }
    
    if (isValidInput) {
        [self.view endEditing:YES];
        
        if ([ScState s].actionIsRegister) {
            if (_candidate) {
                if ([_scola isResidence]) {
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

    ScLogState;
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    [self.tableView addBackground];
    
    _editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(startEditing)];
    _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditing)];
    _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didFinishEditing)];
    
    if (_membership) {
        _member = _membership.member;
        _scola = _membership.scola;
    }
    
    if ([ScState s].actionIsRegister) {
        self.navigationItem.rightBarButtonItem = _doneButton;
        
        if ([ScState s].targetIsMember && [ScState s].aspectIsSelf) {
            self.title = [_member about];
        } else {
            self.navigationItem.leftBarButtonItem = _cancelButton;
            
            if ([_scola isResidence]) {
                self.title = [ScStrings stringForKey:strMemberViewTitleNewHouseholdMember];
            } else {
                self.title = [ScStrings stringForKey:strMemberViewTitleNewMember];
            }
        }
    } else if ([ScState s].actionIsDisplay) {
        self.navigationItem.rightBarButtonItem = _editButton;
        self.title = [_member about];
        
        NSMutableSet *residences = [[NSMutableSet alloc] init];
        
        for (ScMemberResidency *residency in _member.residencies) {
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
    if ([segue.identifier isEqualToString:kSegueToMembershipView]) {
        ScMembershipViewController *membershipViewController = segue.destinationViewController;
        membershipViewController.delegate = _delegate;
        membershipViewController.scola = _scola;
    
        [ScState s].target = ScStateTargetMemberships;
    }
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ([ScState s].actionIsDisplay ? kNumberOfDisplaySections : kNumberOfInputSections);
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
        if ([ScState s].actionIsInput) {
            height = [ScTableViewCell heightForEntityClass:ScMember.class];
        } else {
            height = [ScTableViewCell heightForEntity:_member];
        }
    } else if (indexPath.section == kAddressSection) {
        height = [ScTableViewCell defaultHeight];
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.section == kMemberSection) {
        if ([ScState s].actionIsDisplay) {
            _memberCell = [tableView cellForEntity:_member];
        } else if ([ScState s].actionIsInput) {
            if ([ScState s].targetIsMember && [ScState s].aspectIsSelf) {
                _memberCell = [tableView cellForEntity:_member delegate:self];
            } else if ([ScState s].actionIsInput) {
                _memberCell = [tableView cellForEntityClass:ScMember.class delegate:self];
            }
        }
        
        if ([ScState s].actionIsInput) {
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
        ScScola *residence = [_sortedResidences objectAtIndex:indexPath.row];
        
        cell = [tableView cellWithReuseIdentifier:kReuseIdentifierDefault];
        cell.textLabel.text = residence.addressLine1;
        cell.detailTextLabel.text = residence.landline;
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
            headerView = [tableView headerViewWithTitle:[ScStrings stringForKey:strAddressLabel]];
        } else {
            headerView = [tableView headerViewWithTitle:[ScStrings stringForKey:strAddressesLabel]];
        }
    }
    
    return headerView;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kMemberSection) {
        [cell.backgroundView addShadowForBottomTableViewCell];
        
        if ([ScState s].actionIsInput) {
            [_nameField becomeFirstResponder];
        }
    } else {
        if (indexPath.row == [_sortedResidences count] - 1) {
            [cell.backgroundView addShadowForBottomTableViewCell];
        } else {
            [cell.backgroundView addShadowForNonBottomTableViewCell];
        }
    }
}


#pragma mark - UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ((_currentField == _emailField) && [ScMeta isEmailValid:_emailField]) {
        NSString *email = _emailField.text;
        
        if ([ScState s].actionIsRegister && [ScState s].targetIsMember) {
            if ([_scola hasMemberWithId:email]) {
                NSString *alertTitle = [ScStrings stringForKey:strMemberExistsTitle];
                NSString *alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strMemberExistsAlert], email, _scola.name];
                
                [ScAlert showAlertWithTitle:alertTitle message:alertMessage];
            } else {
                _candidate = [[ScMeta m].context fetchEntityFromCache:email];
                
                if (_candidate) {
                    [self populateWithCandidate];
                } else {
                    [[[ScServerConnection alloc] init] fetchMemberEntitiesFromServer:email delegate:self];
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


#pragma mark - ScModalViewControllerDelegate methods

- (void)shouldDismissViewControllerWithIdentitifier:(NSString *)identitifier
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    if ([identitifier isEqualToString:kScolaViewControllerId]) {
        [self performSegueWithIdentifier:kSegueToMembershipView sender:self];
    }
}


#pragma mark - ScServerConnectionDelegate methods

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(NSArray *)data
{
    if (response.statusCode == kHTTPStatusCodeOK) {
        _candidateEntities = [[ScMeta m].context saveServerEntitiesToCache:data];
        _candidate = [[ScMeta m].context fetchEntityFromCache:_emailField.text];
        
        [self populateWithCandidate];
    }
}


- (void)didFailWithError:(NSError *)error
{
    
}

@end
