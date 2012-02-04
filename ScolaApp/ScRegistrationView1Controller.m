//
//  ScRegistrationView1Controller.m
//  ScolaApp
//
//  Created by Anders Blehr on 28.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScRegistrationView1Controller.h"

#import "NSManagedObjectContext+ScPersistenceCache.h"
#import "UIView+ScShadowEffects.h"

#import "ScAppEnv.h"
#import "ScRegistrationView2Controller.h"
#import "ScHousehold.h"
#import "ScLogging.h"
#import "ScStrings.h"


static NSString * const kSegueToDateOfBirthView = @"addressToDateOfBirthView";

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


#pragma mark - auxiliary methods

- (void)setDatePickerToApril1st1976
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

- (UIAlertView *)alertViewIfUnrealisticDateOfBirth
{
    NSString *alertMessage = nil;
    UIAlertView *alertView = nil;
    
    NSDate *dateOfBirth = dateOfBirthPicker.date;
    NSDate *now = [NSDate date];
    
    BOOL isDateOfBirthInThePast = ([dateOfBirth compare:now] == NSOrderedAscending);
    
    if (isDateOfBirthInThePast) {
        NSDateComponents *ageComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:dateOfBirth toDate:now options:kNilOptions];
        NSInteger apparentAge = ageComponents.year;
        
        if ((apparentAge < kMinimumRealisticAge) || (apparentAge > kMaximumRealisticAge)) {
            alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strUnrealisticAgeAlert], apparentAge];
        }
    } else {
        alertMessage = [ScStrings stringForKey:strNotBornAlert];
    }
    
    if (alertMessage) {
        alertView = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
    }
    
    return alertView;
}


- (BOOL)isDoneEditing
{
    UIAlertView *alertView = nil;
    
    if ((addressLine1Field.text.length > 0) || (postCodeAndCityField.text.length > 0)) {
        alertView = [self alertViewIfUnrealisticDateOfBirth];
    } else {
        alertView = [[UIAlertView alloc] initWithTitle:nil message:[ScStrings stringForKey:strNoAddressAlert] delegate:self cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
    }
    
    BOOL isDone = (!alertView);
    
    if (isDone) {
        NSManagedObjectContext *context = [ScAppEnv env].managedObjectContext;
        household = [context entityForClass:ScHousehold.class];
        
        household.addressLine1 = addressLine1Field.text;
        household.addressLine2 = addressLine2Field.text;
        household.postCodeAndCity = postCodeAndCityField.text;
        
        if (dateOfBirthField.text.length > 0) {
            member.dateOfBirth = dateOfBirthPicker.date;
        }
        
        [self performSegueWithIdentifier:kSegueToDateOfBirthView sender:self];
    } else {
        [alertView show];
    }

    return isDone;
}


#pragma mark - View lifecycle

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [darkLinenView addGradientLayer];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:[ScStrings stringForKey:strNext] style:UIBarButtonItemStyleDone target:self action:@selector(isDoneEditing)];
    
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = nextButton;
    
    addressLine1Field.delegate = self;
    addressLine2Field.delegate = self;
    postCodeAndCityField.delegate = self;
    
    addressUserHelpLabel.text = [ScStrings stringForKey:strProvideAddressUserHelp];
    addressLine1Field.placeholder = [ScStrings stringForKey:strAddressLine1Prompt];
    addressLine2Field.placeholder = [ScStrings stringForKey:strAddressLine2Prompt];
    postCodeAndCityField.placeholder = [ScStrings stringForKey:strPostCodeAndCityPrompt];
    
    addressLine1Field.text = @"";
    addressLine2Field.text = @"";
    postCodeAndCityField.text = @"";
    
    dateOfBirthUserHelpLabel.text = [ScStrings stringForKey:strDateOfBirthUserHelp];
    dateOfBirthField.delegate = self;
    dateOfBirthField.placeholder = [ScStrings stringForKey:strDateOfBirthClickHerePrompt];
    dateOfBirthField.text = @"";
    
    [dateOfBirthPicker addTarget:self action:@selector(dateOfBirthDidChange) forControlEvents:UIControlEventValueChanged];
    [self setDatePickerToApril1st1976];
    
    [addressLine1Field becomeFirstResponder];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToDateOfBirthView]) {
        member.household = household;
        
        ScRegistrationView2Controller *nextViewController = segue.destinationViewController;
        nextViewController.member = member;
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
    [self setDatePickerToApril1st1976];
    
    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return [self isDoneEditing];
}


#pragma mark - UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [addressLine1Field becomeFirstResponder];
}

@end
