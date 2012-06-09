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

#import "ScLogging.h"
#import "ScMeta.h"
#import "ScServerConnection.h"
#import "ScStrings.h"
#import "ScTableViewCell.h"

#import "ScMember.h"
#import "ScScola.h"

#import "ScScola+ScScolaExtensions.h"


@implementation ScMemberViewController

@synthesize member;

@synthesize isForHousehold;
@synthesize isEditing;


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dark_linen-640x960.png"]];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
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

    if (isEditing) {
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
    
    if (isValidInput) {
        if (!member) {
            NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
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
        
        [self dismissModalViewControllerAnimated:YES];
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
    return [ScTableViewCell heightForNumberOfLabels:4];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ScTableViewCell *cell = [ScTableViewCell defaultCellForTableView:tableView];
    
    dateOfBirthPicker = [[UIDatePicker alloc] init];
    dateOfBirthPicker.datePickerMode = UIDatePickerModeDate;
    [dateOfBirthPicker setEarlistValidBirthDate];
    [dateOfBirthPicker setTo01April1976];
    [dateOfBirthPicker addTarget:self action:@selector(dateOfBirthDidChange) forControlEvents:UIControlEventValueChanged];
    
    emailField = [cell addLabel:[ScStrings stringForKey:strEmail] withEditableDetail:nil];
    emailField.placeholder = [ScStrings stringForKey:strEmailPlaceholder];
    emailField.keyboardType = UIKeyboardTypeEmailAddress;
    emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    emailField.delegate = self;
    
    nameField = [cell addLabel:[ScStrings stringForKey:strName] withEditableDetail:nil];
    nameField.placeholder = [ScStrings stringForKey:strNamePlaceholder];
    nameField.keyboardType = UIKeyboardTypeDefault;
    nameField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    nameField.delegate = self;
    
    bornField = [cell addLabel:[ScStrings stringForKey:strBorn] withEditableDetail:nil];
    bornField.placeholder = [ScStrings stringForKey:strBornPlaceholder];
    bornField.inputView = dateOfBirthPicker;
    bornField.delegate = self;
    
    mobileField = [cell addLabel:[ScStrings stringForKey:strMobile] withEditableDetail:nil];
    mobileField.placeholder = [ScStrings stringForKey:strMobilePlaceholder];
    mobileField.keyboardType = UIKeyboardTypeNumberPad;
    mobileField.delegate = self;
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES; // TODO: Probably not needed
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell.backgroundView addShadow];
    
    [emailField becomeFirstResponder];
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    if (!member && (textField == emailField) && (emailField.text.length > 0)) {
        if ([ScMeta isEmailValid:emailField.text silent:YES]) {
            [[[ScServerConnection alloc] init] fetchMemberWithId:emailField.text usingDelegate:self];
        }
    }
    
    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == emailField) {
        [nameField becomeFirstResponder];
    } else if (textField == nameField) {
        [bornField becomeFirstResponder];
    }
    
    return YES;
}


#pragma mark - ScServerConnectionDelegate methods

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    if (response.statusCode == kHTTPStatusCodeOK) {
        ScLogDebug(@"Got data: %@", data);
    }
}


- (void)didFailWithError:(NSError *)error
{
    
}

@end
