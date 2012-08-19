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

static NSInteger const kActionSheetButtonFemale = 0;
static NSInteger const kActionSheetButtonMale = 1;
static NSInteger const kActionSheetButtonCancel = 2;

static NSString * const kSegueToMembershipView = @"memberToMembershipView";


@implementation ScMemberViewController

#pragma mark - Auxiliary methods

- (void)registerHousehold
{
    [ScMeta state].target = ScStateTargetHousehold;
    
    ScScolaViewController *scolaViewController = [self.storyboard instantiateViewControllerWithIdentifier:kScolaViewControllerId];
    scolaViewController.scola = _scola;
    scolaViewController.delegate = self;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:scolaViewController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [self.navigationController presentViewController:navigationController animated:YES completion:NULL];
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
    NSString *femaleLabel = nil;
    NSString *maleLabel = nil;
    
    if ([_dateOfBirthPicker.date isBirthDateOfMinor]) {
        femaleLabel = [ScStrings stringForKey:strFemaleMinor];
        maleLabel = [ScStrings stringForKey:strMaleMinor];
    } else {
        femaleLabel = [ScStrings stringForKey:strFemale];
        maleLabel = [ScStrings stringForKey:strMale];
    }
    
    NSString *questionVerb = nil;
    NSString *questionSubject = nil;
    
    if ([ScMeta state].actionIsRegister && [ScMeta state].targetIsUser) {
        questionVerb = [ScStrings stringForKey:strToBe2ndPSg];
        questionSubject = [ScStrings lowercaseStringForKey:strYouNom];
    } else {
        questionVerb = [ScStrings stringForKey:strToBe3rdPSg];
        questionSubject = [NSString givenNameFromFullName:_nameField.text];
    }
        
    NSString *genderQuestion = [NSString stringWithFormat:[ScStrings stringForKey:strGenderActionSheetTitle], questionVerb, questionSubject, [femaleLabel lowercaseString], [maleLabel lowercaseString]];
    
    UIActionSheet *genderSheet = [[UIActionSheet alloc] initWithTitle:genderQuestion delegate:self cancelButtonTitle:[ScStrings stringForKey:strCancel] destructiveButtonTitle:nil otherButtonTitles:femaleLabel, maleLabel, nil];
    
    [genderSheet showInView:self.view];
    [_nameField becomeFirstResponder];
}


- (void)updateOrRegisterMember
{
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    
    if ([ScMeta state].actionIsRegister && [ScMeta state].targetIsMember) {
        if (_candidate) {
            _member = _candidate;
        } else {
            if (_emailField.text.length > 0) {
                _member = [context entityForClass:ScMember.class inScola:_scola withId:_emailField.text];
            } else {
                _member = [context entityForClass:ScMember.class inScola:_scola];
            }
        }
        
        if ([ScMeta state].aspectIsHome || [ScMeta state].aspectIsHousehold) {
            if (_candidateHousehold != nil) {
                // TODO: Alert that candidate is already member of a household
                self.membership = [_scola addResident:_member]; // TODO: Only for testing, remove!
            } else {
                self.membership = [_scola addResident:_member];
            }
        } else {
            self.membership = [_scola addMember:_member];
        }
    }
    
    _member.name = _nameField.text;
    _member.dateOfBirth = _dateOfBirthPicker.date;
    _member.mobilePhone = _mobilePhoneField.text;
    _member.gender = _gender;
    
    if ([ScMeta state].actionIsRegister) {
        _member.givenName = [NSString givenNameFromFullName:_nameField.text];
    }
    
    if ([ScMeta state].actionIsRegister) {
        if ([ScMeta state].targetIsUser && [_membership.isAdmin boolValue]) {
            [self registerHousehold];
        } else {
            [_delegate shouldDismissViewControllerWithIdentitifier:kMemberViewControllerId];
            [_delegate insertMembershipInTableView:_membership];
        }
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
    if (_candidateHousehold) {
        NSManagedObjectContext *context = [ScMeta m].managedObjectContext;

        [context deleteEntity:_candidateResidency];
        [context deleteEntity:_candidateHousehold];
        [context deleteEntity:_candidate];
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
    
    if (isValidInput && !_gender) {
        [self promptForGender];
    } else if (isValidInput) {
        [self updateOrRegisterMember];
    } else {
        [_memberCell shake];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    ScLogState;
    
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:kDarkLinenImageFile]];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    _editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(startEditing)];
    _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditing)];
    _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didFinishEditing)];
    
    if (_membership) {
        _member = _membership.member;
        _scola = _membership.scola;
    }
    
    if ([ScMeta state].actionIsRegister) {
        self.navigationItem.rightBarButtonItem = _doneButton;
        
        if ([ScMeta state].targetIsUser) {
            self.title = [_member about];
        } else {
            self.navigationItem.leftBarButtonItem = _cancelButton;
            
            if ([ScMeta state].aspectIsHome || [ScMeta state].aspectIsHousehold) {
                self.title = [ScStrings stringForKey:strMemberViewTitleNewHouseholdMember];
            } else {
                self.title = [ScStrings stringForKey:strMemberViewTitleNewMember];
            }
        }
    } else if ([ScMeta state].actionIsDisplay) {
        self.navigationItem.rightBarButtonItem = _editButton;
        self.title = [_member about];
        
        _residencies = [[NSMutableSet alloc] init];
        
        for (ScMemberResidency *residency in _member.residencies) {
            [_residencies addObject:residency];
        }
        
        _sortedResidencies = [[_residencies allObjects] sortedArrayUsingSelector:@selector(compare:)];
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
        
        [ScMeta state].target = ScStateTargetMemberships;
    }
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ([ScMeta state].actionIsDisplay ? kNumberOfDisplaySections : kNumberOfInputSections);
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
        if ([ScMeta state].actionIsRegister) {
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
        if ([ScMeta state].actionIsDisplay) {
            _memberCell = [tableView cellForEntity:_member];
        } else if ([ScMeta state].actionIsRegister && [ScMeta state].targetIsUser) {
            _memberCell = [tableView cellForEntity:_member delegate:self];
        } else if ([ScMeta state].actionIsRegister) {
            _memberCell = [tableView cellForEntityClass:ScMember.class delegate:self];
        }
        
        if (_memberCell.editing) {
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
        ScMemberResidency *residency = [_sortedResidencies objectAtIndex:indexPath.row];
        
        cell = [tableView cellWithReuseIdentifier:kReuseIdentifierDefault];
        cell.textLabel.text = residency.residence.addressLine1;
        cell.detailTextLabel.text = residency.residence.landline;
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
        
        if ([ScMeta state].actionIsInputAction) {
            [_nameField becomeFirstResponder];
        }
    } else {
        if (indexPath.row == [_residencies count] - 1) {
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
        if ([ScMeta state].actionIsRegister && [ScMeta state].targetIsMember) {
            _candidate = [[ScMeta m].managedObjectContext fetchEntityWithId:_emailField.text];
            
            if (_candidate) {
                [self populateWithCandidate];
            } else {
                [[[ScServerConnection alloc] init] fetchMemberWithId:_emailField.text delegate:self];
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
    if (buttonIndex != kActionSheetButtonCancel) {
        _gender = (buttonIndex == kActionSheetButtonFemale) ? kGenderFemale : kGenderMale;
        
        [self updateOrRegisterMember];
    }
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
        NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
        
        [context saveWithDictionaries:data];
        _candidate = [context fetchEntityWithId:_emailField.text];
        _candidateHousehold = [context fetchEntityWithId:_candidate.scolaId];
        _candidateResidency = [_candidateHousehold residencyForMember:_candidate];
        
        [self populateWithCandidate];
    }
}


- (void)didFailWithError:(NSError *)error
{
    
}

@end
