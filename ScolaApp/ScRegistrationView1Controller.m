//
//  ScRegistrationView1Controller.m
//  ScolaApp
//
//  Created by Anders Blehr on 28.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScRegistrationView1Controller.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
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

- (void)setDateOfBirthPickerToApril1st1976
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    NSDate *april1st1976 = [dateFormatter dateFromString:@"1976-04-01T20:00:00Z"];
    
    [dateOfBirthPicker setDate:april1st1976 animated:YES];
}


- (void)dateOfBirthDidChange
{
    dateOfBirthField.text = [NSDateFormatter localizedStringFromDate:dateOfBirthPicker.date dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
}


#pragma mark - Input validation

- (BOOL)isAddressValid
{
    homeScola.addressLine1 = addressLine1Field.text;
    homeScola.addressLine2 = addressLine2Field.text;
    homeScola.postCodeAndCity = postCodeAndCityField.text;
    
    BOOL isValid = [homeScola hasAddress];
    
    if (!isValid) {
        [addressLine1Field becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)isDateOfBirthValid
{
    BOOL isValid = (dateOfBirthField.text.length == 0);
    
    if (!isValid) {
        member.dateOfBirth = dateOfBirthPicker.date;
        
        isValid = [member hasValidBirthDate];
    }
    
    if (!isValid) {
        [self.view endEditing:YES];
        dateOfBirthField.placeholder = [ScStrings stringForKey:strDateOfBirthPrompt];
    }
    
    return isValid;
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
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title = [ScStrings stringForKey:strRegView1NavItemTitle];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] init];
    self.navigationItem.backBarButtonItem.title = [ScStrings stringForKey:strRegView1BackButtonTitle];

    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:[ScStrings stringForKey:strNext] style:UIBarButtonItemStyleDone target:self action:@selector(textFieldShouldReturn:)];
    
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
        addressLine1Field.delegate = self;
        addressLine1Field.placeholder = [ScStrings stringForKey:strAddressLine1Prompt];
        addressLine2Field.delegate = self;
        addressLine2Field.placeholder = [ScStrings stringForKey:strAddressLine2Prompt];
        postCodeAndCityField.delegate = self;
        postCodeAndCityField.placeholder = [ScStrings stringForKey:strPostCodeAndCityPrompt];
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
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    addressLine1Field.text = homeScola.addressLine1;
    addressLine2Field.text = homeScola.addressLine2;
    postCodeAndCityField.text = homeScola.postCodeAndCity;
    
    [dateOfBirthPicker addTarget:self action:@selector(dateOfBirthDidChange) forControlEvents:UIControlEventValueChanged];
    
    if (member.dateOfBirth) {
        [dateOfBirthPicker setDate:member.dateOfBirth animated:YES];
        [self dateOfBirthDidChange];
    } else {
        [self setDateOfBirthPickerToApril1st1976];
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
        [self.view endEditing:YES];
        dateOfBirthField.placeholder = [ScStrings stringForKey:strDateOfBirthPrompt];
    } else {
        dateOfBirthField.placeholder = [ScStrings stringForKey:strDateOfBirthClickHerePrompt];
    }
    
    return !isDateOfBirthField;
}


- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if (textField == dateOfBirthField) {
        [self setDateOfBirthPickerToApril1st1976];
    }
    
    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *alertMessage = nil;
    NSString *alertTitle = nil;
    
    if (![self isAddressValid]) {
        alertTitle = [ScStrings stringForKey:strNoAddressTitle];
        alertMessage = [ScStrings stringForKey:strNoAddressAlert];
    } else if (![self isDateOfBirthValid]) {
        alertTitle = [ScStrings stringForKey:strInvalidDateOfBirthTitle];
        alertMessage = [ScStrings stringForKey:strInvalidDateOfBirthAlert];
    }
    
    BOOL shouldReturn = !alertMessage;
    
    if (shouldReturn) {
        [self performSegueWithIdentifier:kSegueToRegistrationView2 sender:self];
    } else {
        UIAlertView *validationAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK]otherButtonTitles:nil];
        
        [validationAlert show];
    }
    
    return shouldReturn;
}

@end
