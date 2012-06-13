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
#import "UIColor+ScColorExtensions.h"
#import "UIDatePicker+ScDatePickerExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScMembershipViewController.h"

#import "ScLogging.h"
#import "ScMeta.h"
#import "ScServerConnection.h"
#import "ScStrings.h"
#import "ScTableViewCell.h"

#import "ScMember.h"
#import "ScScola.h"

#import "ScMember+ScMemberExtensions.h"
#import "ScScola+ScScolaExtensions.h"


static NSInteger const kActionSheetButtonFemale = 0;
static NSInteger const kActionSheetButtonMale = 1;
static NSInteger const kActionSheetButtonCancel = 2;


@implementation ScMemberViewController

@synthesize membershipViewController;
@synthesize member;

@synthesize isForHousehold;
@synthesize isInserting;
@synthesize isEditing;


#pragma mark - Auxiliary methods

- (void)populateFields
{
    BOOL didMemberRegister = NO;
    
    if (member) {
        nameField.text = member.name;
        emailField.text = member.entityId;
        mobilePhoneField.text = member.mobilePhone;
        gender = member.gender;
        
        [dateOfBirthPicker setDate:member.dateOfBirth animated:YES];
        dateOfBirthField.text = [NSDateFormatter localizedStringFromDate:member.dateOfBirth dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
        
        didMemberRegister = [member.didRegister boolValue];
    } else {
        NSDictionary *memberDictionary = nil;
        
        for (NSDictionary *entityDictionary in entityDictionaries) {
            NSString *entityClass = [entityDictionary objectForKey:kKeyEntityClass];
            
            if ([entityClass isEqualToString:NSStringFromClass(ScMember.class)]) {
                memberDictionary = entityDictionary;
            }
        }
        
        nameField.text = [memberDictionary objectForKey:kKeyName];
        emailField.text = [memberDictionary objectForKey:kKeyEntityId];
        mobilePhoneField.text = [memberDictionary objectForKey:kKeyMobilePhone];
        gender = [memberDictionary objectForKey:kKeyGender];
        
        NSDate *dateOfBirth = [NSDate dateWithDeserialisedDate:[memberDictionary objectForKey:kKeyDateOfBirth]];
        [dateOfBirthPicker setDate:dateOfBirth animated:YES];
        dateOfBirthField.text = [NSDateFormatter localizedStringFromDate:dateOfBirth dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
        
        didMemberRegister = [[memberDictionary objectForKey:kKeyDidRegister] boolValue];
    }
    
    if (didMemberRegister) {
        UIFont *nonEditableDetailFont = [ScTableViewCell detailFont];
        UIColor *backgroundColour = [ScTableViewCell backgroundColour];
        
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
        
        numberOfLinesInDataEntryCell++;
        
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
        
        [dataEntryCell.backgroundView addShadow];
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
    
    NSString *sheetTitle = [NSString stringWithFormat:[ScStrings stringForKey:strGenderActionSheetTitle], nameField.text, [femaleLabel lowercaseString], [maleLabel lowercaseString]];
    UIActionSheet *genderSheet = [[UIActionSheet alloc] initWithTitle:sheetTitle delegate:self cancelButtonTitle:[ScStrings stringForKey:strCancel] destructiveButtonTitle:nil otherButtonTitles:femaleLabel, maleLabel, nil];
    
    [genderSheet showInView:self.view];
}


- (void)insertMemberAndDismissView
{
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    
    if (!member) {
        ScScola *homeScola = [context fetchEntityWithId:[ScMeta m].homeScolaId];
        
        if (entityDictionaries) {
            [context saveWithDictionaries:entityDictionaries];
            
            member = [context fetchEntityWithId:emailField.text];
        } else {
            if (emailField.text.length > 0) {
                member = [context entityForClass:ScMember.class inScola:homeScola withId:emailField.text];
            } else {
                member = [context entityForClass:ScMember.class inScola:homeScola];
            }
        }
        
        [homeScola addResident:member];
    }
    
    member.name = nameField.text;
    member.dateOfBirth = dateOfBirthPicker.date;
    member.mobilePhone = mobilePhoneField.text;
    member.gender = gender;
    
    [membershipViewController insertAddedMemberInTableView:member];
    
    [self dismissModalViewControllerAnimated:YES];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:kDarkLinenImageFile]];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    numberOfLinesInDataEntryCell = 4;
    
    editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(startEditing)];
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(endEditing)];
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEdit)];
    
    if (member) {
        self.title = member.name;
    } else {
        if (isForHousehold) {
            self.title = [ScStrings stringForKey:strUnderOurRoofViewTitle];
        } else {
            self.title = [ScStrings stringForKey:strNewMemberViewTitle];
        }
    }

    if (isEditing || isInserting) {
        self.navigationItem.leftBarButtonItem = cancelButton;
        self.navigationItem.rightBarButtonItem = saveButton;
    } else {
        self.navigationItem.rightBarButtonItem = editButton;
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    
    isValidInput = isValidInput && [ScMeta isNameValid:nameField.text];
    isValidInput = isValidInput && [ScMeta isDateOfBirthValid:dateOfBirthField.text];
    
    if (isValidInput && ![dateOfBirthPicker.date isBirthDateOfMinor]) {
        isValidInput = isValidInput && [ScMeta isEmailValid:emailField.text];
        isValidInput = isValidInput && [ScMeta isMobileNumberValid:mobilePhoneField.text];
    } else if (isValidInput) {
        if (emailField.text.length > 0) {
            isValidInput = isValidInput && [ScMeta isEmailValid:emailField.text];
        }
    }
    
    if (isValidInput && !gender) {
        [self promptForGender];
    } else if (isValidInput) {
        [self insertMemberAndDismissView];
    }
}


- (void)cancelEdit
{
    [self dismissModalViewControllerAnimated:YES];
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
    return [ScTableViewCell heightForNumberOfLabels:numberOfLinesInDataEntryCell];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    dataEntryCell = [ScTableViewCell defaultCellForTableView:tableView];
    
    dateOfBirthPicker = [[UIDatePicker alloc] init];
    dateOfBirthPicker.datePickerMode = UIDatePickerModeDate;
    [dateOfBirthPicker setEarlistValidBirthDate];
    [dateOfBirthPicker setTo01April1976];
    [dateOfBirthPicker addTarget:self action:@selector(dateOfBirthDidChange) forControlEvents:UIControlEventValueChanged];
    
    nameField = [dataEntryCell addLabel:[ScStrings stringForKey:strName] withEditableDetail:nil];
    emailField = [dataEntryCell addLabel:[ScStrings stringForKey:strEmail] withEditableDetail:nil];
    dateOfBirthField = [dataEntryCell addLabel:[ScStrings stringForKey:strBorn] withEditableDetail:nil];
    mobilePhoneField = [dataEntryCell addLabel:[ScStrings stringForKey:strMobile] withEditableDetail:nil];
    
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
    
    return dataEntryCell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES; // TODO: Probably not needed
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell.backgroundView addShadow];
    
    [nameField becomeFirstResponder];
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (!member && (textField == emailField) && (emailField.text.length > 0)) {
        if ([ScMeta isEmailValid:emailField.text silent:YES]) {
            member = [[ScMeta m].managedObjectContext fetchEntityWithId:emailField.text];
            
            if (member) {
                [self populateFields];
            } else {
                [[[ScServerConnection alloc] init] fetchMemberWithId:emailField.text usingDelegate:self];
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
        
        [self insertMemberAndDismissView];
    }
}


#pragma mark - ScServerConnectionDelegate methods

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(NSArray *)data
{
    if (response.statusCode == kHTTPStatusCodeOK) {
        entityDictionaries = data;
        
        [self populateFields];
    }
}


- (void)didFailWithError:(NSError *)error
{
    
}

@end
