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

static NSString * const kSegueToMembershipView = @"memberToMembershipView";

static NSInteger const kActionSheetButtonFemale = 0;
static NSInteger const kActionSheetButtonMale = 1;
static NSInteger const kActionSheetButtonCancel = 2;


@interface ScMemberViewController () {
    ScTableViewCell *_memberCell;
    ScMember *_member;
    
    ScMember *_candidate;
    ScScola *_candidateHousehold;
    ScMemberResidency *_candidateResidency;
    
    UIBarButtonItem *_editButton;
    UIBarButtonItem *_cancelButton;
    UIBarButtonItem *_doneButton;
    
    ScTextField *_nameField;
    ScTextField *_emailField;
    ScTextField *_mobilePhoneField;
    ScTextField *_dateOfBirthField;
    UIDatePicker *_dateOfBirthPicker;
    NSString *_gender;
    
    UITextField *_currentField;
}

- (void)registerHousehold;
- (void)populateWithCandidate;
- (void)promptForGender;
- (void)updateOrRegisterMember;

@end


@implementation ScMemberViewController

#pragma mark - State shorthands

- (BOOL)isDisplaying
{
    ScAppState_ appState = [ScMeta appState_];
    
    BOOL isDisplaying = 
        (appState == ScAppStateDisplayUser) ||
        (appState == ScAppStateDisplayUserHouseholdMember) ||
        (appState == ScAppStateDisplayScolaMember) ||
        (appState == ScAppStateDisplayScolaMemberHouseholdMember);
    
    return isDisplaying;
}


- (BOOL)isRegistering
{
    ScAppState_ appState = [ScMeta appState_];
    
    BOOL isRegistering =
        (appState == ScAppStateRegisterUser) ||
        (appState == ScAppStateRegisterUserHouseholdMember) ||
        (appState == ScAppStateRegisterScolaMember) ||
        (appState == ScAppStateRegisterScolaMemberHouseholdMember);
    
    return isRegistering;
}


- (BOOL)isForHousehold
{
    ScAppState_ appState = [ScMeta appState_];
    
    BOOL isForHousehold =
        (appState == ScAppStateDisplayUserHouseholdMember) ||
        (appState == ScAppStateDisplayScolaMemberHouseholdMember) ||
        (appState == ScAppStateRegisterUserHouseholdMember) ||
        (appState == ScAppStateRegisterScolaMemberHouseholdMember);
    
    return isForHousehold;
}


- (BOOL)isForUser
{
    ScAppState_ appState = [ScMeta appState_];
    
    BOOL isForUser =
        (appState == ScAppStateDisplayUser) ||
        (appState == ScAppStateRegisterUser);
    
    return isForUser;
}


#pragma mark - Private methods

- (void)registerHousehold
{
    if ([self isForUser]) {
        [ScMeta pushAppState:ScAppStateRegisterUserHousehold];
    } else {
        [ScMeta pushAppState:ScAppStateRegisterScolaMemberHousehold];
    }
    
    ScScolaViewController *scolaViewController = [self.storyboard instantiateViewControllerWithIdentifier:kScolaViewControllerId];
    scolaViewController.delegate = self;
    scolaViewController.scola = _scola;
    
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
    
    if ([self isRegistering] && [self isForUser]) {
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
    
    if ([self isRegistering] && ![self isForUser]) {
        if (_candidate) {
            _member = _candidate;
        } else {
            if (_emailField.text.length > 0) {
                _member = [context entityForClass:ScMember.class inScola:_scola withId:_emailField.text];
            } else {
                _member = [context entityForClass:ScMember.class inScola:_scola];
            }
        }
        
        if ([self isForHousehold]) {
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
    
    if ([self isRegistering]) {
        _member.givenName = [NSString givenNameFromFullName:_nameField.text];
    }
    
    if ([self isRegistering] && [self isForUser]) {
        [self registerHousehold];
    } else if ([self isRegistering]) {
        [_delegate insertMembershipInTableView:_membership];
        [_delegate shouldDismissViewControllerWithIdentitifier:kMemberViewControllerId];
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
    
    [ScMeta popAppState];
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

    if ([self isRegistering]) {
        self.navigationItem.rightBarButtonItem = _doneButton;
        
        if ([self isForUser]) {
            self.title = [_member about];
        } else {
            self.navigationItem.leftBarButtonItem = _cancelButton;
            
            if ([self isForHousehold]) {
                self.title = [ScStrings stringForKey:strMemberViewTitleNewHouseholdMember];
            } else {
                self.title = [ScStrings stringForKey:strMemberViewTitleNewMember];
            }
        }
    } else if ([self isDisplaying]) {
        self.navigationItem.rightBarButtonItem = _editButton;
        self.title = [_member about];
    }
}


- (void) viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        [ScMeta popAppState];
    }
    
    [super viewWillDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToMembershipView]) {
        ScMembershipViewController *nextViewController = segue.destinationViewController;
        nextViewController.delegate = _delegate;
        nextViewController.scola = _scola;
    
        if ([ScMeta appState_] == ScAppStateRegisterUserHousehold) {
            [ScMeta pushAppState:ScAppStateRegisterUserHouseholdMemberships];
        } else if ([ScMeta appState_] == ScAppStateRegisterScola) {
            [ScMeta pushAppState:ScAppStateRegisterScolaMember];
        }
    }
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.f;
    
    if ([self isRegistering]) {
        height = [ScTableViewCell heightForEntityClass:ScMember.class];
    } else {
        height = [ScTableViewCell heightForEntity:_member editing:![self isDisplaying]];
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isDisplaying]) {
        _memberCell = [tableView cellForEntity:_member];
    } else if ([self isRegistering] && [self isForUser]) {
        _memberCell = [tableView cellForEntity:_member editing:YES delegate:self];
    } else if ([self isRegistering]) {
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
    
    return _memberCell;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell.backgroundView addShadowForBottomTableViewCell];
    
    [_nameField becomeFirstResponder];
}


#pragma mark - UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ((_currentField == _emailField) && [ScMeta isEmailValid:_emailField]) {
        if ([self isRegistering] && ![self isForUser]) {
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
    [ScMeta popAppState];
    
    if ([self isRegistering] && [self isForUser]) {
        [ScMeta pushAppState:ScAppStateRegisterUserHouseholdMemberships];
    } else if ([self isRegistering] && [self isForHousehold]) {
        [ScMeta pushAppState:ScAppStateRegisterScolaMemberHouseholdMemberships];
    } else {
        [ScMeta pushAppState:ScAppStateRegisterScolaMemberships];
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self performSegueWithIdentifier:kSegueToMembershipView sender:self];
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
