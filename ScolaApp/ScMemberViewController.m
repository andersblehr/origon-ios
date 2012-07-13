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


@implementation ScMemberViewController

@synthesize delegate;

@synthesize scola;
@synthesize membership;


#pragma mark - State shorthands

- (BOOL)isDisplaying
{
    ScAppState appState = [ScMeta appState];
    
    BOOL isDisplaying = 
        (appState == ScAppStateDisplayUser) ||
        (appState == ScAppStateDisplayUserHouseholdMember) ||
        (appState == ScAppStateDisplayScolaMember) ||
        (appState == ScAppStateDisplayScolaMemberHouseholdMember);
    
    return isDisplaying;
}


- (BOOL)isRegistering
{
    ScAppState appState = [ScMeta appState];
    
    BOOL isRegistering =
        (appState == ScAppStateRegisterUser) ||
        (appState == ScAppStateRegisterUserHouseholdMember) ||
        (appState == ScAppStateRegisterScolaMember) ||
        (appState == ScAppStateRegisterScolaMemberHouseholdMember);
    
    return isRegistering;
}


- (BOOL)isForHousehold
{
    ScAppState appState = [ScMeta appState];
    
    BOOL isForHousehold =
        (appState == ScAppStateDisplayUserHouseholdMember) ||
        (appState == ScAppStateDisplayScolaMemberHouseholdMember) ||
        (appState == ScAppStateRegisterUserHouseholdMember) ||
        (appState == ScAppStateRegisterScolaMemberHouseholdMember);
    
    return isForHousehold;
}


- (BOOL)isForUser
{
    ScAppState appState = [ScMeta appState];
    
    BOOL isForUser =
        (appState == ScAppStateDisplayUser) ||
        (appState == ScAppStateRegisterUser);
    
    return isForUser;
}


#pragma mark - Auxiliary methods

- (void)registerHousehold
{
    if ([self isForUser]) {
        [ScMeta pushAppState:ScAppStateRegisterUserHousehold];
    } else {
        [ScMeta pushAppState:ScAppStateRegisterScolaMemberHousehold];
    }
    
    ScScolaViewController *scolaViewController = [self.storyboard instantiateViewControllerWithIdentifier:kScolaViewControllerId];
    scolaViewController.delegate = self;
    scolaViewController.scola = scola;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:scolaViewController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [self.navigationController presentViewController:navigationController animated:YES completion:NULL];
}


- (void)populateWithCandidate
{
    if (![candidate.name isEqualToString:candidate.entityId]) {
        nameField.text = candidate.name;
    }
    
    emailField.text = candidate.entityId;
    mobilePhoneField.text = candidate.mobilePhone;
    [dateOfBirthPicker setDate:candidate.dateOfBirth animated:YES];
    dateOfBirthField.text = [candidate.dateOfBirth localisedDateString];
    gender = candidate.gender;
    
    if (candidate.activeSince) {
        memberCell.editing = NO;
    }
}


- (void)promptForGender
{
    NSString *femaleLabel = nil;
    NSString *maleLabel = nil;
    
    if ([dateOfBirthPicker.date isBirthDateOfMinor]) {
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
        questionSubject = [NSString givenNameFromFullName:nameField.text];
    }
        
    NSString *genderQuestion = [NSString stringWithFormat:[ScStrings stringForKey:strGenderActionSheetTitle], questionVerb, questionSubject, [femaleLabel lowercaseString], [maleLabel lowercaseString]];
    
    UIActionSheet *genderSheet = [[UIActionSheet alloc] initWithTitle:genderQuestion delegate:self cancelButtonTitle:[ScStrings stringForKey:strCancel] destructiveButtonTitle:nil otherButtonTitles:femaleLabel, maleLabel, nil];
    
    [genderSheet showInView:self.view];
    [nameField becomeFirstResponder];
}


- (void)updateOrRegisterMember
{
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    
    if ([self isRegistering] && ![self isForUser]) {
        if (candidate) {
            member = candidate;
        } else {
            if (emailField.text.length > 0) {
                member = [context entityForClass:ScMember.class inScola:scola withId:emailField.text];
            } else {
                member = [context entityForClass:ScMember.class inScola:scola];
            }
        }
        
        if ([self isForHousehold]) {
            if (candidateHousehold != nil) {
                // TODO: Alert that candidate is already member of a household
                membership = [scola addResident:member]; // TODO: Only for testing, remove!
            } else {
                membership = [scola addResident:member];
            }
        } else {
            membership = [scola addMember:member];
        }
    }
    
    member.name = nameField.text;
    member.dateOfBirth = dateOfBirthPicker.date;
    member.mobilePhone = mobilePhoneField.text;
    member.gender = gender;
    
    if ([self isRegistering]) {
        member.givenName = [NSString givenNameFromFullName:nameField.text];
    }
    
    if ([self isRegistering] && [self isForUser]) {
        [self registerHousehold];
    } else if ([self isRegistering]) {
        [delegate insertMembershipInTableView:membership];
        [delegate shouldDismissViewControllerWithIdentitifier:kMemberViewControllerId];
    }
}


#pragma mark - Selector implementations

- (void)dateOfBirthDidChange
{
    dateOfBirthField.text = [dateOfBirthPicker.date localisedDateString];
}


- (void)startEditing
{
    
}


- (void)cancelEditing
{
    if (candidateHousehold) {
        NSManagedObjectContext *context = [ScMeta m].managedObjectContext;

        [context deleteEntity:candidateResidency];
        [context deleteEntity:candidateHousehold];
        [context deleteEntity:candidate];
    }
    
    [ScMeta popAppState];
    [delegate shouldDismissViewControllerWithIdentitifier:kMemberViewControllerId];
}


- (void)didFinishEditing
{
    BOOL isValidInput = YES;
    
    isValidInput = isValidInput && [ScMeta isNameValid:nameField];
    isValidInput = isValidInput && [ScMeta isDateOfBirthValid:dateOfBirthField];
    
    if (isValidInput && ![dateOfBirthPicker.date isBirthDateOfMinor]) {
        isValidInput = isValidInput && [ScMeta isEmailValid:emailField];
        isValidInput = isValidInput && [ScMeta isMobileNumberValid:mobilePhoneField];
    } else if (isValidInput) {
        if (emailField.text.length > 0) {
            isValidInput = isValidInput && [ScMeta isEmailValid:emailField];
        }
    }
    
    if (isValidInput && !gender) {
        [self promptForGender];
    } else if (isValidInput) {
        [self updateOrRegisterMember];
    } else {
        [memberCell shake];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:kDarkLinenImageFile]];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(startEditing)];
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditing)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didFinishEditing)];
    
    if (membership) {
        member = membership.member;
        scola = membership.scola;
    }

    if ([self isRegistering]) {
        self.navigationItem.rightBarButtonItem = doneButton;
        
        if ([self isForUser]) {
            self.title = [member about];
        } else {
            self.navigationItem.leftBarButtonItem = cancelButton;
            
            if ([self isForHousehold]) {
                self.title = [ScStrings stringForKey:strMemberViewTitleNewHouseholdMember];
            } else {
                self.title = [ScStrings stringForKey:strMemberViewTitleNewMember];
            }
        }
    } else if ([self isDisplaying]) {
        self.navigationItem.rightBarButtonItem = editButton;
        self.title = [member about];
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
        nextViewController.delegate = delegate;
        nextViewController.scola = scola;
    
        if ([ScMeta appState] == ScAppStateRegisterUserHousehold) {
            [ScMeta pushAppState:ScAppStateRegisterUserHouseholdMemberships];
        } else if ([ScMeta appState] == ScAppStateRegisterScola) {
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
        height = [ScTableViewCell heightForEntity:member editing:![self isDisplaying]];
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isDisplaying]) {
        memberCell = [tableView cellForEntity:member];
    } else if ([self isRegistering] && [self isForUser]) {
        memberCell = [tableView cellForEntity:member editing:YES delegate:self];
    } else if ([self isRegistering]) {
        memberCell = [tableView cellForEntityClass:ScMember.class delegate:self];
    }
    
    if (memberCell.editing) {
        nameField = [memberCell textFieldWithKey:kTextFieldKeyName];
        emailField = [memberCell textFieldWithKey:kTextFieldKeyEmail];
        mobilePhoneField = [memberCell textFieldWithKey:kTextFieldKeyMobilePhone];
        dateOfBirthField = [memberCell textFieldWithKey:kTextFieldKeyDateOfBirth];
        dateOfBirthPicker = (UIDatePicker *)dateOfBirthField.inputView;
        
        if (member.dateOfBirth) {
            dateOfBirthPicker.date = member.dateOfBirth;
            gender = member.gender;
        }
        
        [nameField becomeFirstResponder];
    }
    
    return memberCell;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell.backgroundView addShadowForBottomTableViewCell];
    
    [nameField becomeFirstResponder];
}


#pragma mark - UITextFieldDelegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ((currentField == emailField) && [ScMeta isEmailValid:emailField]) {
        if ([self isRegistering] && ![self isForUser]) {
            candidate = [[ScMeta m].managedObjectContext fetchEntityWithId:emailField.text];
            
            if (candidate) {
                [self populateWithCandidate];
            } else {
                [[[ScServerConnection alloc] init] fetchMemberWithId:emailField.text delegate:self];
            }
        }
    }
    
    currentField = textField;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == nameField) {
        if (emailField.enabled) {
            [emailField becomeFirstResponder];
        } else {
            [mobilePhoneField becomeFirstResponder];
        }
    } else if (textField == emailField) {
        [mobilePhoneField becomeFirstResponder];
    } else if (textField == mobilePhoneField) {
        [dateOfBirthField becomeFirstResponder];
    }
    
    return YES;
}


#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != kActionSheetButtonCancel) {
        gender = (buttonIndex == kActionSheetButtonFemale) ? kGenderFemale : kGenderMale;
        
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
        candidate = [context fetchEntityWithId:emailField.text];
        candidateHousehold = [context fetchEntityWithId:candidate.scolaId];
        candidateResidency = [candidateHousehold residencyForMember:candidate];
        
        [self populateWithCandidate];
    }
}


- (void)didFailWithError:(NSError *)error
{
    
}

@end
