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


static NSInteger const kActionSheetButtonFemale = 0;
static NSInteger const kActionSheetButtonMale = 1;
static NSInteger const kActionSheetButtonCancel = 2;


@implementation ScMemberViewController

@synthesize scenario;

@synthesize scola;
@synthesize membership;

@synthesize membershipViewController;


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
        UIFont *nonEditableDetailFont = [UIFont fontWithType:ScFontTypeDetail];
        UIColor *backgroundColour = [UIColor colorWithType:ScColorBackground];
        
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
        
        [memberCell.backgroundView addOnlyOrBottomCellShadow];
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
    
    NSString *memberRef = isRegistering ? [ScStrings lowercaseStringForKey:strYouSubject] : [NSString givenNameFromFullName:nameField.text];
    NSString *sheetTitle = [NSString stringWithFormat:[ScStrings stringForKey:strGenderActionSheetTitle], memberRef, [femaleLabel lowercaseString], [maleLabel lowercaseString]];
    UIActionSheet *genderSheet = [[UIActionSheet alloc] initWithTitle:sheetTitle delegate:self cancelButtonTitle:[ScStrings stringForKey:strCancel] destructiveButtonTitle:nil otherButtonTitles:femaleLabel, maleLabel, nil];
    
    [genderSheet showInView:self.view];
}


- (void)insertMembershipAndDismissView
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
        
        if (scenario == ScMemberScenarioAddHouseholdMember) {
            membership = [scola addResident:member];
        } else {
            membership = [scola addMember:member];
        }
    }
    
    membership.member.name = nameField.text;
    membership.member.dateOfBirth = dateOfBirthPicker.date;
    membership.member.mobilePhone = mobilePhoneField.text;
    membership.member.gender = gender;

    if (isRegistering || isAdding) {
        membership.member.givenName = [NSString givenNameFromFullName:nameField.text];
    }
    
    [membershipViewController insertMembershipInTableView:membership];
    
    [self dismissModalViewControllerAnimated:YES];
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
        [self insertMembershipAndDismissView];
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
    
    editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(startEditing)];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(endEditing)];
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditing)];
    
    if (membership) {
        member = membership.member;
        scola = membership.scola;
    }
    
    isRegistering = (scenario == ScMemberScenarioRegisterUser);
    
    isAdding = (scenario == ScMemberScenarioAddHouseholdMember);
    isAdding = isAdding || (scenario == ScMemberScenarioAddMember);
    
    isDisplaying = (scenario == ScMemberScenarioDisplayUser);
    isDisplaying = isDisplaying || (scenario == ScMemberScenarioDisplayMember);
    
    if (isRegistering) {
        self.title = [member about];
        self.navigationItem.hidesBackButton = YES;
        self.navigationItem.rightBarButtonItem = doneButton;
    } else if (isAdding) {
        if (scenario == ScMemberScenarioAddHouseholdMember) {
            self.title = [ScStrings stringForKey:strNewHouseholdMemberViewTitle];
        } else if (scenario == ScMemberScenarioAddMember) {
            self.title = [ScStrings stringForKey:strNewMemberViewTitle];
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
    return [ScTableViewCell heightForEntity:member];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (isDisplaying) {
        memberCell = [tableView cellForEntity:member];
    } else if (isRegistering || isEditing) {
        memberCell = [tableView cellForEntity:member delegate:self];
    } else if (isAdding) {
        memberCell = [tableView cellForEntityClass:ScMember.class delegate:self];
    }
    
    dateOfBirthPicker = [[UIDatePicker alloc] init];
    dateOfBirthPicker.datePickerMode = UIDatePickerModeDate;
    [dateOfBirthPicker setEarliestValidBirthDate];
    [dateOfBirthPicker setTo01April1976];
    [dateOfBirthPicker addTarget:self action:@selector(dateOfBirthDidChange) forControlEvents:UIControlEventValueChanged];
    
    nameField.placeholder = [ScStrings stringForKey:strNamePlaceholder];
    nameField.keyboardType = UIKeyboardTypeDefault;
    nameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    nameField.delegate = self;
    
    emailField.placeholder = [ScStrings stringForKey:strEmailPlaceholder];
    emailField.keyboardType = UIKeyboardTypeEmailAddress;
    emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    emailField.delegate = self;
    
    dateOfBirthField.placeholder = [ScStrings stringForKey:strBornPlaceholder];
    dateOfBirthField.inputView = dateOfBirthPicker;
    dateOfBirthField.delegate = self;
    
    mobilePhoneField.placeholder = [ScStrings stringForKey:strMobilePlaceholder];
    mobilePhoneField.keyboardType = UIKeyboardTypeNumberPad;
    mobilePhoneField.delegate = self;
    
    return memberCell;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell.backgroundView addOnlyOrBottomCellShadow];
    
    [nameField becomeFirstResponder];
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (isAdding && (textField == emailField) && (emailField.text.length > 0)) {
        if ([ScMeta isEmailValid:emailField silent:YES]) {
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
        [emailField becomeFirstResponder];
    } else if (textField == emailField) {
        [dateOfBirthField becomeFirstResponder];
    }
    
    return YES;
}


#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != kActionSheetButtonCancel) {
        gender = (buttonIndex == kActionSheetButtonFemale) ? kGenderFemale : kGenderMale;
        
        [self insertMembershipAndDismissView];
    }
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
