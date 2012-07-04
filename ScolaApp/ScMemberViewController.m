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
    [ScMeta pushAppState:ScAppStateRegisterUserHousehold];
    
    ScScolaViewController *scolaViewController = [self.storyboard instantiateViewControllerWithIdentifier:kScolaViewControllerId];
    scolaViewController.delegate = self;
    scolaViewController.scola = scola;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:scolaViewController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [self.navigationController presentViewController:navigationController animated:YES completion:NULL];
}


#pragma mark - Populating fields

- (void)populateWithMember:(ScMember *)memberCandidate
{
    if (![memberCandidate.name isEqualToString:memberCandidate.entityId]) {
        nameField.text = memberCandidate.name;
    }
    
    emailField.text = memberCandidate.entityId;
    mobilePhoneField.text = memberCandidate.mobilePhone;
    gender = memberCandidate.gender;
    [dateOfBirthPicker setDate:memberCandidate.dateOfBirth animated:YES];
    dateOfBirthField.text = [memberCandidate.dateOfBirth localisedDateString];
    
    if (memberCandidate.activeSince) {
        nameField.enabled = NO;
        emailField.enabled = NO;
        dateOfBirthField.enabled = NO;
        mobilePhoneField.enabled = NO;
        
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
    
    if (isRegisteringUser) {
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
    
    if (isRegisteringMember) {
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
        
        if ([ScMeta appState] == ScAppStateRegisterUserHouseholdMember) {
            membership = [scola addResident:member];
        } else {
            membership = [scola addMember:member];
        }
    }
    
    member.name = nameField.text;
    member.dateOfBirth = dateOfBirthPicker.date;
    member.mobilePhone = mobilePhoneField.text;
    member.gender = gender;

    if (isRegisteringUser || isRegisteringMember) {
        member.givenName = [NSString givenNameFromFullName:nameField.text];
    }

    if (isRegisteringUser) {
        [self registerHousehold];
    } else if (isRegisteringMember) {
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
        [self updateOrCreateMembership];
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
    
    isRegisteringUser = ([ScMeta appState] == ScAppStateRegisterUser);
    
    isRegisteringMember = ([ScMeta appState] == ScAppStateRegisterUserHouseholdMember);
    isRegisteringMember = isRegisteringMember || ([ScMeta appState] == ScAppStateRegisterScolaMember);
    
    isDisplaying = ([ScMeta appState] == ScAppStateDisplayUser);
    isDisplaying = isDisplaying || ([ScMeta appState] == ScAppStateDisplayHouseholdMember);
    isDisplaying = isDisplaying || ([ScMeta appState] == ScAppStateDisplayScolaMember);
    
    editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(startEditing)];
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditing)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didFinishEditing)];
    
    if (membership) {
        member = membership.member;
        scola = membership.scola;
    }
    
    if (isRegisteringUser) {
        self.title = [member about];
        self.navigationItem.hidesBackButton = YES;
        self.navigationItem.rightBarButtonItem = doneButton;
    } else if (isRegisteringMember) {
        if ([ScMeta appState] == ScAppStateRegisterUserHouseholdMember) {
            self.title = [ScStrings stringForKey:strMemberViewTitleNewHouseholdMember];
        } else if ([ScMeta appState] == ScAppStateRegisterScolaMember) {
            self.title = [ScStrings stringForKey:strMemberViewTitleNewMember];
        }
        
        self.navigationItem.leftBarButtonItem = cancelButton;
        self.navigationItem.rightBarButtonItem = doneButton;
    } else if (isDisplaying) {
        self.title = [member about];
        self.navigationItem.rightBarButtonItem = editButton;
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
            [ScMeta pushAppState:ScAppStateRegisterUserHouseholdMember];
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
    
    if (isRegisteringMember) {
        height = [ScTableViewCell heightForEntityClass:ScMember.class];
    } else {
        height = [ScTableViewCell heightForEntity:member editing:!isDisplaying];
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (isDisplaying) {
        memberCell = [tableView cellForEntity:member];
    } else if (isRegisteringUser || isEditing) {
        memberCell = [tableView cellForEntity:member editing:YES delegate:self];
    } else if (isRegisteringMember) {
        memberCell = [tableView cellForEntityClass:ScMember.class delegate:self];
    }
    
    nameField = [memberCell textFieldWithKey:kTextFieldKeyName];
    emailField = [memberCell textFieldWithKey:kTextFieldKeyEmail];
    mobilePhoneField = [memberCell textFieldWithKey:kTextFieldKeyMobilePhone];
    dateOfBirthField = [memberCell textFieldWithKey:kTextFieldKeyDateOfBirth];
    dateOfBirthPicker = (UIDatePicker *)dateOfBirthField.inputView;
    
    if (!isDisplaying) {
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

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if ((textField == emailField) && isRegisteringMember && (emailField.text.length > 0)) {
        if ([ScMeta isEmailValid:emailField]) {
            ScMember *memberCandidate = [[ScMeta m].managedObjectContext fetchEntityWithId:emailField.text];
            
            if (memberCandidate) {
                [self populateWithMember:memberCandidate];
            } else {
                [[[ScServerConnection alloc] init] fetchMemberWithId:emailField.text delegate:self];
            }
        }
    }
    
    return YES;
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
    }
}


- (void)didFailWithError:(NSError *)error
{
    
}

@end
