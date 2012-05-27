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
#import "ScScola.h"


static NSString * const kSegueToRegistrationView2 = @"registrationView1ToRegistrationView2";

static int const kMinimumRealisticAge = 5;
static int const kMaximumRealisticAge = 110;


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
    BOOL isValid = NO;
    
    isValid = isValid || (addressLine1Field.text.length > 0);
    isValid = isValid || (postCodeAndCityField.text.length > 0);
    
    if (!isValid) {
        [addressLine1Field becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)isDateOfBirthValid
{
    BOOL isValid = (dateOfBirthField.text.length == 0);
    
    if (!isValid) {
        NSDate *dateOfBirth = dateOfBirthPicker.date;
        NSDate *now = [NSDate date];
        
        isValid = ([dateOfBirth compare:now] == NSOrderedAscending);
        
        if (isValid) {
            NSDateComponents *ageComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:dateOfBirth toDate:now options:kNilOptions];
            NSInteger providedAge = ageComponents.year;
            
            isValid = isValid && (providedAge >= kMinimumRealisticAge);
            isValid = isValid && (providedAge <= kMaximumRealisticAge);
        }
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
    
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:[ScStrings stringForKey:strNext] style:UIBarButtonItemStyleDone target:self action:@selector(textFieldShouldReturn:)];
    
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = nextButton;
    
    if (isUserListed && ((homeScola.addressLine1.length > 0) || (homeScola.addressLine2.length > 0) || (homeScola.postCodeAndCity.length > 0))) {
        addressUserHelpLabel.text = [ScStrings stringForKey:strAddressListedUserHelp];
    } else {
        addressUserHelpLabel.text = [ScStrings stringForKey:strAddressUserHelp];
    }

    if (isUserListed && member.dateOfBirth) {
        dateOfBirthUserHelpLabel.text = [ScStrings stringForKey:strDateOfBirthListedUserHelp];
    } else {
        dateOfBirthUserHelpLabel.text = [ScStrings stringForKey:strDateOfBirthUserHelp];
    }
    
    addressLine1Field.delegate = self;
    addressLine2Field.delegate = self;
    postCodeAndCityField.delegate = self;
    dateOfBirthField.delegate = self;
    
    addressLine1Field.placeholder = [ScStrings stringForKey:strAddressLine1Prompt];
    addressLine2Field.placeholder = [ScStrings stringForKey:strAddressLine2Prompt];
    postCodeAndCityField.placeholder = [ScStrings stringForKey:strPostCodeAndCityPrompt];
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
    
    [addressLine1Field becomeFirstResponder];
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
    
    if (![self isAddressValid]) {
        alertMessage = [ScStrings stringForKey:strNoAddressAlert];
    } else if (![self isDateOfBirthValid]) {
        alertMessage = [ScStrings stringForKey:strInvalidDateOfBirthAlert];
    }
    
    BOOL shouldReturn = !alertMessage;
    
    if (shouldReturn) {
        [self.view endEditing:YES];
        
        homeScola.addressLine1 = addressLine1Field.text;
        homeScola.addressLine2 = addressLine2Field.text;
        homeScola.postCodeAndCity = postCodeAndCityField.text;
        
        if (dateOfBirthField.text.length > 0) {
            member.dateOfBirth = dateOfBirthPicker.date;
        }
        
        [self performSegueWithIdentifier:kSegueToRegistrationView2 sender:self];
    } else {
        UIAlertView *validationAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK]otherButtonTitles:nil];
        
        [validationAlert show];
    }
    
    return shouldReturn;
}

@end
