//
//  ScRegistrationView1Controller.m
//  ScolaApp
//
//  Created by Anders Blehr on 28.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScRegistrationView1Controller.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "UIDatePicker+ScDatePickerExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScLogging.h"
#import "ScMeta.h"
#import "ScRegistrationView2Controller.h"
#import "ScStrings.h"

#import "ScMember.h"
#import "ScMemberResidency.h"
#import "ScScola.h"

#import "ScMember+ScMemberExtensions.h"
#import "ScMemberResidency+ScMemberResidencyExtensions.h"
#import "ScScola+ScScolaExtensions.h"


static NSString * const kSegueToRegistrationView2 = @"registrationView1ToRegistrationView2";


@implementation ScRegistrationView1Controller

@synthesize darkLinenView;
@synthesize addressUserHelpLabel;
@synthesize addressLine1Field;
@synthesize addressLine2Field;
@synthesize postCodeAndCityField;
@synthesize dateOfBirthUserHelpLabel;
@synthesize dateOfBirthField;
@synthesize dateOfBirthPicker;

@synthesize member;
@synthesize homeScola;

@synthesize isUserListed;


#pragma mark - Auxiliary methods

- (void)dateOfBirthDidChange
{
    dateOfBirthField.text = [NSDateFormatter localizedStringFromDate:dateOfBirthPicker.date dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
}


#pragma mark - View lifecycle

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [darkLinenView addGradientLayer];
    
    self.title = [ScStrings stringForKey:strRegistrationView1Title];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] init];
    self.navigationItem.backBarButtonItem.title = [ScStrings stringForKey:strRegistrationView1BackButtonTitle];

    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:[ScStrings stringForKey:strNext] style:UIBarButtonItemStyleDone target:self action:@selector(goToNext)];
    
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = nextButton;
    
    ScMemberResidency *residency = [ScMemberResidency residencyForMember:[ScMeta m].userId];
    BOOL isAddressEditable = [[residency isAdmin] boolValue];
    
    if (isUserListed && isAddressEditable && [homeScola hasAddress]) {
        addressUserHelpLabel.text = [ScStrings stringForKey:strVerifyAddressUserHelp];
    } else if (isAddressEditable) {
        addressUserHelpLabel.text = [ScStrings stringForKey:strProvideAddressUserHelp];
    } else {
        addressUserHelpLabel.text = [ScStrings stringForKey:strAddressUserHelp];
    }

    if (isAddressEditable) {
        addressLine1Field.placeholder = [ScStrings stringForKey:strAddressLine1Prompt];
        addressLine1Field.autocorrectionType = UITextAutocorrectionTypeNo;
        addressLine1Field.returnKeyType = UIReturnKeyDefault;
        addressLine1Field.delegate = self;
        addressLine2Field.placeholder = [ScStrings stringForKey:strAddressLine2Prompt];
        addressLine2Field.autocorrectionType = UITextAutocorrectionTypeNo;
        addressLine2Field.returnKeyType = UIReturnKeyDefault;
        addressLine2Field.delegate = self;
        postCodeAndCityField.placeholder = [ScStrings stringForKey:strPostCodeAndCityPrompt];
        postCodeAndCityField.autocorrectionType = UITextAutocorrectionTypeNo;
        postCodeAndCityField.returnKeyType = UIReturnKeyDefault;
        postCodeAndCityField.delegate = self;
    } else {
        addressLine1Field.enabled = NO;
        addressLine1Field.textColor = [UIColor grayColor];
        addressLine2Field.enabled = NO;
        addressLine2Field.textColor = [UIColor grayColor];
        postCodeAndCityField.enabled = NO;
        postCodeAndCityField.textColor = [UIColor grayColor];
    }
    
    if (isUserListed && member.dateOfBirth) {
        dateOfBirthUserHelpLabel.text = [ScStrings stringForKey:strVerifyDateOfBirthUserHelp];
    } else {
        dateOfBirthUserHelpLabel.text = [ScStrings stringForKey:strDateOfBirthUserHelp];
    }
    
    dateOfBirthField.delegate = self;
    dateOfBirthField.placeholder = [ScStrings stringForKey:strDateOfBirthClickHerePrompt];
    dateOfBirthField.inputView = dateOfBirthPicker;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    addressLine1Field.text = homeScola.addressLine1;
    addressLine2Field.text = homeScola.addressLine2;
    postCodeAndCityField.text = homeScola.postCodeAndCity;
    
    [dateOfBirthPicker setEarlistValidBirthDate];
    [dateOfBirthPicker setLatestValidBirthDate];
    [dateOfBirthPicker addTarget:self action:@selector(dateOfBirthDidChange) forControlEvents:UIControlEventTouchUpInside | UIControlEventValueChanged];
    
    if (member.dateOfBirth) {
        [dateOfBirthPicker setDate:member.dateOfBirth animated:YES];
        [self dateOfBirthDidChange];
    } else {
        [dateOfBirthPicker setTo01April1976];
        dateOfBirthField.text = @"";
    }
    
    if (addressLine1Field.enabled) {
        [addressLine1Field becomeFirstResponder];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Selector implementations

- (void)goToNext
{
    BOOL isValid = [ScMeta isAddressValidWithLine1:addressLine1Field.text line2:addressLine2Field.text postCodeAndCity:postCodeAndCityField.text];
    
    if (isValid) {
        isValid = [ScMeta isDateOfBirthValid:dateOfBirthField.text];
        
        if (!isValid) {
            [dateOfBirthField becomeFirstResponder];
        }
    } else {
        [addressLine1Field becomeFirstResponder];
    }
    
    if (isValid) {
        homeScola.addressLine1 = addressLine1Field.text;
        homeScola.addressLine2 = addressLine2Field.text;
        homeScola.postCodeAndCity = postCodeAndCityField.text;
        member.dateOfBirth = dateOfBirthPicker.date;
        
        [self performSegueWithIdentifier:kSegueToRegistrationView2 sender:self];
    }
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToRegistrationView2]) {
        ScRegistrationView2Controller *nextViewController = segue.destinationViewController;

        nextViewController.member = member;
        nextViewController.homeScola = homeScola;
        nextViewController.isUserListed = isUserListed;
    }
}


#pragma mark - UITextFieldDelegate implementation

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    BOOL isDateOfBirthField = (textField == dateOfBirthField);
    
    if (isDateOfBirthField) {
        dateOfBirthField.placeholder = [ScStrings stringForKey:strDateOfBirthPrompt];
    } else {
        dateOfBirthField.placeholder = [ScStrings stringForKey:strDateOfBirthClickHerePrompt];
    }
    
    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == addressLine1Field) {
        [addressLine2Field becomeFirstResponder];
    } else if (textField == addressLine2Field) {
        [postCodeAndCityField becomeFirstResponder];
    } else if (textField == postCodeAndCityField) {
        [dateOfBirthField becomeFirstResponder];
    }
    
    return YES;
}

@end
