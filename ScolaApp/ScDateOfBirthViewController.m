//
//  ScRegisterDeviceController.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScDateOfBirthViewController.h"

#import "NSManagedObjectContext+ScPersistenceCache.h"
#import "UIView+ScShadowEffects.h"

#import "ScAppEnv.h"
#import "ScLogging.h"
#import "ScStrings.h"


static NSString * const kSegueToMainView = @"dateOfBirthToMainView";

static int const kGenderSegmentFemale = 0;
static int const kGenderSegmentMale = 1;
static int const kGenderSegmentNeutral = 2;

static NSString * const kGenderFemale = @"F";
static NSString * const kGenderMale = @"M";
static NSString * const kGenderNeutral = @"N";

static int const kMinimumRealisticAge = 5;
static int const kMaximumRealisticAge = 110;

static int const kPopUpButtonUseBuiltIn = 0;
static int const kPopUpButtonUseNew = 1;


@implementation ScDateOfBirthViewController

@synthesize darkLinenView;
@synthesize deviceNameUserHelpLabel;
@synthesize deviceNameField;
@synthesize genderUserHelpLabel;
@synthesize genderControl;
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

- (UIAlertView *)alertViewIfNoDeviceName
{
    UIAlertView *alertView = nil;
    
    BOOL isDeviceNameValid = (deviceNameField.text.length > 0);
    
    if (!isDeviceNameValid) {
        NSString *deviceType = [ScAppEnv env].deviceType;
        NSString *deviceTypeDeterminate;
        NSString *deviceTypePossessive;
        
        if ([deviceType isEqualToString:@"iPod"]) {
            deviceTypeDeterminate = [ScStrings stringForKey:str_iPodDeterminate];
            deviceTypePossessive = [ScStrings stringForKey:str_iPodPossessive];
        } else if ([deviceType isEqualToString:@"iPad"]) {
            deviceTypeDeterminate = [ScStrings stringForKey:str_iPadDeterminate];
            deviceTypePossessive = [ScStrings stringForKey:str_iPadPossessive];
        } else {
            deviceTypeDeterminate = [ScStrings stringForKey:strPhoneDeterminate];
            deviceTypePossessive = [ScStrings stringForKey:strPhonePossessive];
        }
        
        NSString *alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strNoDeviceNameAlert], deviceTypeDeterminate, deviceTypePossessive, [ScAppEnv env].deviceName];
        NSString *useConfiguredButtonTitle = [ScStrings stringForKey:strUseConfigured];
        NSString *useNewButtonTitle = [ScStrings stringForKey:strUseNew];
        
        alertView = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:self cancelButtonTitle:useConfiguredButtonTitle otherButtonTitles:useNewButtonTitle, nil];
    }
    
    return alertView;
}


- (UIAlertView *)alertViewIfUnrealisticDateOfBirth
{
    UIAlertView *alertView = nil;
    
    NSDate *dateOfBirth = dateOfBirthPicker.date;
    NSDate *now = [NSDate date];
    NSInteger apparentAge;

    BOOL isDateOfBirthInThePast = ([dateOfBirth compare:now] == NSOrderedAscending);
    BOOL isDateOfBirthRealistic = YES;
    
    NSString *alertMessage;
    
    if (!isDateOfBirthInThePast) {
        alertMessage = [ScStrings stringForKey:strNotBornAlert];
    }
    
    if (isDateOfBirthInThePast) {
        NSDateComponents *ageComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:dateOfBirthPicker.date toDate:now options:kNilOptions];
        apparentAge = ageComponents.year;
        
        BOOL isTooYoung = (apparentAge < kMinimumRealisticAge);
        BOOL isTooOld = (apparentAge > kMaximumRealisticAge);
        
        isDateOfBirthRealistic = (!isTooYoung && !isTooOld);
    }
    
    if (!isDateOfBirthRealistic) {
        alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strUnrealisticAgeAlert], apparentAge];
    } 
    
    if (!isDateOfBirthInThePast || !isDateOfBirthRealistic) {
        alertView = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
    }

    return alertView;
}


- (BOOL)isDoneEditing
{
    UIAlertView *alertView = [self alertViewIfNoDeviceName];

    if (!alertView && (dateOfBirthField.text.length > 0)) {
        alertView = [self alertViewIfUnrealisticDateOfBirth];
    }

    BOOL isDone = (!alertView);
    
    if (isDone) {
        NSManagedObjectContext *context = [ScAppEnv env].managedObjectContext;
        device = [context entityForClass:ScDevice.class];
        
        device.name = deviceNameField.text;
        device.uuid = [ScAppEnv env].deviceUUID;
        [member addDevicesObject:device];
        
        if (genderControl.selectedSegmentIndex == kGenderSegmentFemale) {
            member.gender = kGenderFemale;
        } else if (genderControl.selectedSegmentIndex == kGenderSegmentMale) {
            member.gender = kGenderMale;
        } else {
            member.gender = kGenderNeutral;
        }
        
        if (dateOfBirthField.text.length > 0) {
            member.dateOfBirth = dateOfBirthPicker.date;
        }
        
        [context save];
        
        [self performSegueWithIdentifier:kSegueToMainView sender:self];
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
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:[ScStrings stringForKey:strDone] style:UIBarButtonItemStyleDone target:self action:@selector(isDoneEditing)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    deviceNameUserHelpLabel.text = [NSString stringWithFormat:[ScStrings stringForKey:strDeviceNameUserHelp], [ScStrings stringForKey:strThisPhone]];
    deviceNameField.placeholder = [NSString stringWithFormat:[ScStrings stringForKey:strDeviceNamePrompt], [ScStrings stringForKey:strPhoneDeterminate]];
    deviceNameField.delegate = self;
    
    genderUserHelpLabel.text = [ScStrings stringForKey:strGenderUserHelp];
    [genderControl setTitle:[ScStrings stringForKey:strFemale] forSegmentAtIndex:kGenderSegmentFemale];
    [genderControl setTitle:[ScStrings stringForKey:strMale] forSegmentAtIndex:kGenderSegmentMale];
    [genderControl setTitle:[ScStrings stringForKey:strNeutral] forSegmentAtIndex:kGenderSegmentNeutral];
    
    dateOfBirthUserHelpLabel.text = [ScStrings stringForKey:strDateOfBirthUserHelp];
    dateOfBirthField.delegate = self;
    dateOfBirthField.placeholder = [ScStrings stringForKey:strDateOfBirthPrompt];
    dateOfBirthField.text = @"";
    
    [dateOfBirthPicker addTarget:self action:@selector(dateOfBirthDidChange) forControlEvents:UIControlEventValueChanged];
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
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *viewState = [userDefaults objectForKey:self.class.description];
    
    if (viewState) {
        NSString *deviceName = [viewState objectForKey:@"device.name"];
        int genderIndex = [[viewState objectForKey:@"member.gender"] intValue];
        NSDate *dateOfBirth = [viewState objectForKey:@"member.dateOfBirth"];
        
        deviceNameField.text = deviceName;
        genderControl.selectedSegmentIndex = genderIndex;
        [dateOfBirthPicker setDate:dateOfBirth animated:YES];
        [self dateOfBirthDidChange];
        
        [userDefaults removeObjectForKey:self.class.description];
    } else {
        deviceNameField.text = [ScAppEnv env].deviceName;
        genderControl.selectedSegmentIndex = kGenderSegmentFemale;
        [self setDatePickerToApril1st1976];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
    BOOL backButtonPressed =
        ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound);
    
    if (backButtonPressed) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *viewState = [[NSMutableDictionary alloc] init];
        NSNumber *genderIndex = [NSNumber numberWithInt:genderControl.selectedSegmentIndex];
        
        [viewState setObject:deviceNameField.text forKey:@"device.name"];
        [viewState setObject:genderIndex forKey:@"member.gender"];
        [viewState setObject:dateOfBirthPicker.date forKey:@"member.dateOfBirth"];
        
        [userDefaults setObject:viewState forKey:self.class.description];
    }
    
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
    if (buttonIndex == kPopUpButtonUseBuiltIn) {
        deviceNameField.text = [ScAppEnv env].deviceName;
        device.name = deviceNameField.text;
    } else if (buttonIndex == kPopUpButtonUseNew) {
        [deviceNameField becomeFirstResponder];
    }
}

@end
