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
#import "ScMembership.h"
#import "ScScola.h"

#import "ScCachedEntity+ScCachedEntityExtensions.h"
#import "ScMember+ScMemberExtensions.h"
#import "ScScola+ScScolaExtensions.h"

static NSString * const kSegueToMembershipView = @"memberToMembershipView";

static NSInteger const kActionSheetButtonFemale = 0;
static NSInteger const kActionSheetButtonMale = 1;
static NSInteger const kActionSheetButtonCancel = 2;


@implementation ScMemberViewController

@synthesize delegate;
@synthesize membership;
@synthesize scola;


#pragma mark - Auxiliary methods

- (void)registerHousehold
{
    ScScolaViewController *scolaViewController = [self.storyboard instantiateViewControllerWithIdentifier:kScolaViewControllerId];
    scolaViewController.delegate = self;
    scolaViewController.scola = scola;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:scolaViewController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [ScMeta m].appState = ScAppStateHouseholdRegistration;
    
    [self.navigationController presentViewController:navigationController animated:YES completion:NULL];
}


- (void)lookUpExistingMember
{
    if ((emailField.text.length > 0) && [ScMeta isEmailValid:emailField]) {
        ScMember *memberCandidate = [[ScMeta m].managedObjectContext fetchEntityWithId:emailField.text];
        
        if (memberCandidate) {
            [self populateWithMember:memberCandidate];
        } else {
            [[[ScServerConnection alloc] init] fetchMemberWithId:emailField.text delegate:self];
        }
    }
}


#pragma mark - Populating fields

- (void)populateWithMember:(ScMember *)memberInstance
{
    if (![memberInstance.name isEqualToString:memberInstance.entityId]) {
        nameField.text = memberInstance.name;
    }
    
    emailField.text = memberInstance.entityId;
    mobilePhoneField.text = memberInstance.mobilePhone;
    gender = memberInstance.gender;
    
    [dateOfBirthPicker setDate:memberInstance.dateOfBirth animated:YES];
    dateOfBirthField.text = [NSDateFormatter localizedStringFromDate:memberInstance.dateOfBirth dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
    
    if ([memberInstance.didRegister boolValue]) {
        UIFont *nonEditableDetailFont = [UIFont detailFont];
        UIColor *backgroundColour = [UIColor cellBackgroundColor];
        
        nameField.enabled = NO;
        nameField.font = nonEditableDetailFont;
        nameField.backgroundColor = backgroundColour;
        emailField.enabled = NO;
        emailField.font = nonEditableDetailFont;
        emailField.backgroundColor = backgroundColour;
        dateOfBirthField.enabled = NO;
        dateOfBirthField.font = nonEditableDetailFont;
        dateOfBirthField.backgroundColor = backgroundColour;
        mobilePhoneField.enabled = NO;
        mobilePhoneField.font = nonEditableDetailFont;
        mobilePhoneField.backgroundColor = backgroundColour;
        
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
}


#pragma mark - Adding new members

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
    
    if (isRegistering) {
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


- (void)updateOrCreateMembership
{
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    
    if (isAdding) {
        if (memberEntityDictionaries) {
            [context saveWithDictionaries:memberEntityDictionaries];
            member = [context fetchEntityWithId:emailField.text];
        } else {
            if (emailField.text.length > 0) {
                member = [context entityForClass:ScMember.class inScola:scola withId:emailField.text];
            } else {
                member = [context entityForClass:ScMember.class inScola:scola];
            }
        }
        
        if ([ScMeta m].appState == ScAppStateHouseholdMemberRegistration) {
            membership = [scola addResident:member];
        } else {
            membership = [scola addMember:member];
        }
    }
    
    member.name = nameField.text;
    member.dateOfBirth = dateOfBirthPicker.date;
    member.mobilePhone = mobilePhoneField.text;
    member.gender = gender;

    if (isRegistering || isAdding) {
        member.givenName = [NSString givenNameFromFullName:nameField.text];
    }

    if (isRegistering) {
        [self registerHousehold];
    } else if (isAdding) {
        [delegate insertMembershipInTableView:membership];
        [delegate shouldDismissViewControllerWithIdentitifier:kMemberViewControllerId];
    } else if (isEditing) {
        // TODO
    }
}


#pragma mark - Selector implementations

- (void)dateOfBirthDidChange
{
    dateOfBirthField.text = [NSDateFormatter localizedStringFromDate:dateOfBirthPicker.date dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
}


- (void)startEditing
{
    
}


- (void)endEditing
{
    if ([ScMeta m].appState == ScAppStateScolaMemberRegistrationLookup) {
        [self lookUpExistingMember];
    } else {
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
            [self updateOrCreateMembership];
        } else {
            [memberCell shake];
        }
    }
}


- (void)cancelEditing
{
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:kDarkLinenImageFile]];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    isRegistering = ([ScMeta m].appState == ScAppStateUserRegistration);
    
    isAdding = ([ScMeta m].appState == ScAppStateHouseholdMemberRegistration);
    isAdding = isAdding || ([ScMeta m].appState == ScAppStateScolaMemberRegistration);
    
    isDisplaying = ([ScMeta m].appState == ScAppStateDisplayUser);
    isDisplaying = isDisplaying || ([ScMeta m].appState == ScAppStateDisplayMember);
    
    editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(startEditing)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(endEditing)];
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditing)];
    
    if (membership) {
        member = membership.member;
        scola = membership.scola;
    }
    
    if (isRegistering) {
        self.title = [member about];
        self.navigationItem.hidesBackButton = YES;
        self.navigationItem.rightBarButtonItem = doneButton;
    } else if (isAdding) {
        if ([ScMeta m].appState == ScAppStateHouseholdMemberRegistration) {
            self.title = [ScStrings stringForKey:strMemberViewTitleNewHouseholdMember];
        } else if ([ScMeta m].appState == ScAppStateScolaMemberRegistration) {
            self.title = [ScStrings stringForKey:strMemberViewTitleNewMember];
        }
        
        self.navigationItem.leftBarButtonItem = cancelButton;
        self.navigationItem.rightBarButtonItem = doneButton;
    } else if (isDisplaying) {
        self.title = [member about];
        self.navigationItem.rightBarButtonItem = editButton;
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
        ScMembershipViewController *nextViewController = segue.destinationViewController;
        nextViewController.delegate = delegate;
        nextViewController.scola = scola;
    
        if ([ScMeta m].appState == ScAppStateHouseholdRegistration) {
            [ScMeta m].appState = ScAppStateHouseholdMemberRegistration;
        } else if ([ScMeta m].appState == ScAppStateScolaRegistration) {
            [ScMeta m].appState = ScAppStateScolaMemberRegistration;
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
    
    if (isAdding) {
        height = [ScTableViewCell heightForEntityClass:ScMember.class];
    } else {
        height = [ScTableViewCell heightForEntity:member whenEditing:!isDisplaying];
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (isDisplaying) {
        memberCell = [tableView cellForEntity:member];
    } else if (isRegistering || isEditing) {
        memberCell = [tableView cellForEntity:member editing:YES delegate:self];
    } else if (isAdding) {
        memberCell = [tableView cellForEntityClass:ScMember.class delegate:self];
    }
    
    nameField = [memberCell textFieldWithKey:kTextFieldKeyName];
    emailField = [memberCell textFieldWithKey:kTextFieldKeyEmail];
    mobilePhoneField = [memberCell textFieldWithKey:kTextFieldKeyMobilePhone];
    dateOfBirthField = [memberCell textFieldWithKey:kTextFieldKeyDateOfBirth];
    dateOfBirthPicker = (UIDatePicker *)dateOfBirthField.inputView;
    
    if ([ScMeta m].appState == ScAppStateHouseholdMemberRegistration) {
        nameField.enabled = NO;
        emailField.returnKeyType = UIReturnKeyGo;
        mobilePhoneField.enabled = NO;
        dateOfBirthField.enabled = NO;
        
        [ScMeta m].appState = ScAppStateScolaMemberRegistrationLookup;
        [emailField becomeFirstResponder];
    } else if (!isDisplaying) {
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == nameField) {
        if (emailField.enabled) {
            [emailField becomeFirstResponder];
        } else {
            [mobilePhoneField becomeFirstResponder];
        }
    } else if (textField == emailField) {
        if ([ScMeta m].appState == ScAppStateScolaMemberRegistrationLookup) {
            [self lookUpExistingMember];
        } else {
            [mobilePhoneField becomeFirstResponder];
        }
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
        
        [self updateOrCreateMembership];
    }
}


#pragma mark - ScModalViewControllerDelegate methods

- (void)shouldDismissViewControllerWithIdentitifier:(NSString *)identitifier
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self performSegueWithIdentifier:kSegueToMembershipView sender:self];
}


#pragma mark - ScServerConnectionDelegate methods

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(NSArray *)data
{
    if (response.statusCode == kHTTPStatusCodeOK) {
        memberEntityDictionaries = data;
        NSDictionary *memberDictionary = nil;
        
        for (NSDictionary *entityDictionary in memberEntityDictionaries) {
            NSString *entityClass = [entityDictionary objectForKey:kPropertyEntityClass];
            
            if ([entityClass isEqualToString:NSStringFromClass(ScMember.class)]) {
                memberDictionary = entityDictionary;
            }
        }
        
        ScMember *memberCandidate = [ScCachedEntity entityWithDictionary:memberDictionary];
        [self populateWithMember:memberCandidate];
        [[ScMeta m].managedObjectContext deleteObject:memberCandidate];
    } else if (response.statusCode == kHTTPStatusCodeNotFound) {
        nameField.enabled = YES;
        emailField.returnKeyType = UIReturnKeyNext;
        mobilePhoneField.enabled = YES;
        dateOfBirthField.enabled = YES;
        
        [memberCell shakeWithVibration:NO];
        [nameField becomeFirstResponder];
    }
    
    [ScMeta m].appState = ScAppStateHouseholdMemberRegistration;
}


- (void)didFailWithError:(NSError *)error
{
    
}

@end
