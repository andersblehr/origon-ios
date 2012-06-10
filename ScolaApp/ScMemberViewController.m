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
        
        if (emailField.text.length > 0) {
            member = [context entityForClass:ScMember.class inScola:homeScola withId:emailField.text];
        } else {
            member = [context entityForClass:ScMember.class inScola:homeScola];
        }
        
        [homeScola addResident:member];
    }
    
    member.name = nameField.text;
    member.dateOfBirth = dateOfBirthPicker.date;
    member.mobilePhone = mobileField.text;
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
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(endEditing)];
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
        self.navigationItem.rightBarButtonItem = doneButton;
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
    bornField.text = [NSDateFormatter localizedStringFromDate:dateOfBirthPicker.date dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
}


- (void)startEditing
{
    
}


- (void)endEditing
{
    BOOL isValidInput = YES;
    
    isValidInput = isValidInput && [ScMeta isNameValid:nameField.text];
    isValidInput = isValidInput && [ScMeta isDateOfBirthValid:bornField.text];
    
    if (isValidInput && ![dateOfBirthPicker.date isBirthDateOfMinor]) {
        isValidInput = isValidInput && [ScMeta isEmailValid:emailField.text];
        isValidInput = isValidInput && [ScMeta isMobileNumberValid:mobileField.text];
    } else if (isValidInput) {
        if (emailField.text.length > 0) {
            isValidInput = isValidInput && [ScMeta isEmailValid:emailField.text];
        }
    }
    
    if (isValidInput && !gender) {
        [self promptForGender];
    } else {
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
    bornField = [dataEntryCell addLabel:[ScStrings stringForKey:strBorn] withEditableDetail:nil];
    mobileField = [dataEntryCell addLabel:[ScStrings stringForKey:strMobile] withEditableDetail:nil];
    
    nameField.placeholder = [ScStrings stringForKey:strNamePlaceholder];
    nameField.keyboardType = UIKeyboardTypeDefault;
    nameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    nameField.delegate = self;
    
    emailField.placeholder = [ScStrings stringForKey:strEmailPlaceholder];
    emailField.keyboardType = UIKeyboardTypeEmailAddress;
    emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    emailField.delegate = self;
    
    bornField.placeholder = [ScStrings stringForKey:strBornPlaceholder];
    bornField.inputView = dateOfBirthPicker;
    bornField.delegate = self;
    
    mobileField.placeholder = [ScStrings stringForKey:strMobilePlaceholder];
    mobileField.keyboardType = UIKeyboardTypeNumberPad;
    mobileField.delegate = self;
    
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
                // TODO: Populate fields from instance
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
        [bornField becomeFirstResponder];
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
        memberData = data;
        NSDictionary *memberDictionary = [data objectAtIndex:0];
        
        if (![[memberDictionary objectForKey:kKeyEntityClass] isEqualToString:NSStringFromClass(ScMember.class)]) {
            memberDictionary = [data objectAtIndex:1];
        }
        
        emailField.text = [memberDictionary objectForKey:kKeyEntityId];
        nameField.text = [memberDictionary objectForKey:kKeyName];
        mobileField.text = [memberDictionary objectForKey:kKeyMobilePhone];
        gender = [memberDictionary objectForKey:kKeyGender];
        
        NSDate *bornDate = [NSDate dateWithDeserialisedDate:[memberDictionary objectForKey:kKeyDateOfBirth]];
        [dateOfBirthPicker setDate:bornDate animated:YES];
        bornField.text = [NSDateFormatter localizedStringFromDate:bornDate dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
        
        if ([[memberDictionary objectForKey:kKeyDidRegister] boolValue]) {
            emailField.enabled = NO;
            emailField.textColor = [UIColor grayColor];
            nameField.enabled = NO;
            nameField.textColor = [UIColor grayColor];
            bornField.enabled = NO;
            bornField.textColor = [UIColor grayColor];
            mobileField.enabled = NO;
            mobileField.textColor = [UIColor grayColor];
            
            numberOfLinesInDataEntryCell++;
            
            [self.tableView beginUpdates];
            [self.tableView endUpdates];
            
            [dataEntryCell.backgroundView addShadow];
        }
    }
}


- (void)didFailWithError:(NSError *)error
{
    
}

@end
