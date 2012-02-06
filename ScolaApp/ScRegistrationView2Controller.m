//
//  ScRegistrationView2Controller.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScRegistrationView2Controller.h"

#import "NSManagedObjectContext+ScPersistenceCache.h"
#import "UIView+ScShadowEffects.h"

#import "ScAppEnv.h"
#import "ScLogging.h"
#import "ScStrings.h"


static NSString * const kSegueToMainView = @"dateOfBirthToMainView";

static int const kGenderSegmentFemale = 0;
static int const kGenderSegmentMale = 1;

static NSString * const kGenderFemale = @"F";
static NSString * const kGenderMale = @"M";

static NSInteger const kAgeOfMajority = 18;

static int const kPopUpButtonUseBuiltIn = 0;
static int const kPopUpButtonUseNew = 1;


@implementation ScRegistrationView2Controller

@synthesize darkLinenView;
@synthesize genderUserHelpLabel;
@synthesize genderControl;
@synthesize mobileNumberLabel;
@synthesize mobileNumberField;
@synthesize deviceNameUserHelpLabel;
@synthesize deviceNameField;

@synthesize member;


#pragma mark - Input validation

- (UIAlertView *)alertViewIfNoDeviceName
{
    UIAlertView *alertView = nil;
    
    if (deviceNameField.text.length == 0) {
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


- (BOOL)isDoneEditing
{
    UIAlertView *alertView = nil;
    
    if (mobileNumberField.text.length == 0) {
        alertView = [[UIAlertView alloc] initWithTitle:nil message:[ScStrings stringForKey:strNoMobileNumberAlert] delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
    } else {
        alertView = [self alertViewIfNoDeviceName];
    }

    BOOL isDone = (!alertView);
    
    if (isDone) {
        NSManagedObjectContext *context = [ScAppEnv env].managedObjectContext;
        
        if (genderControl.selectedSegmentIndex == kGenderSegmentFemale) {
            member.gender = kGenderFemale;
        } else if (genderControl.selectedSegmentIndex == kGenderSegmentMale) {
            member.gender = kGenderMale;
        }

        member.mobilePhone = mobileNumberField.text;
        
        device = [context entityForClass:ScDevice.class];
        device.name = deviceNameField.text;
        device.uuid = [ScAppEnv env].deviceUUID;
        [member addDevicesObject:device];
        
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
    
    NSDate *now = [NSDate date];
    NSDateComponents *ageComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:member.dateOfBirth toDate:now options:kNilOptions];
    BOOL isMinor =  (ageComponents.year < kAgeOfMajority);
    
    NSString *femaleTerm = [ScStrings stringForKey:(isMinor ? strFemaleMinor : strFemaleAdult)];
    NSString *maleTerm = [ScStrings stringForKey:(isMinor ? strMaleMinor : strMaleAdult)];

    genderUserHelpLabel.text = [NSString stringWithFormat:[ScStrings stringForKey:strGenderUserHelp], [femaleTerm lowercaseString], [maleTerm lowercaseString]];
    [genderControl setTitle:femaleTerm forSegmentAtIndex:kGenderSegmentFemale];
    [genderControl setTitle:maleTerm forSegmentAtIndex:kGenderSegmentMale];

    mobileNumberLabel.text = [ScStrings stringForKey:strMobileNumberUserHelp];
    mobileNumberField.placeholder = [ScStrings stringForKey:strMobileNumberPrompt];
    mobileNumberField.keyboardType = UIKeyboardTypeNumberPad;
    mobileNumberField.delegate = self;
    [mobileNumberField becomeFirstResponder];
    
    deviceNameUserHelpLabel.text = [NSString stringWithFormat:[ScStrings stringForKey:strDeviceNameUserHelp], [ScStrings stringForKey:strThisPhone]];
    deviceNameField.placeholder = [NSString stringWithFormat:[ScStrings stringForKey:strDeviceNamePrompt], [ScStrings stringForKey:strPhoneDeterminate]];
    deviceNameField.delegate = self;
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
        genderControl.selectedSegmentIndex = [[viewState objectForKey:@"member.gender"] intValue];
        mobileNumberField.text = [viewState objectForKey:@"member.mobilePhone"];
        deviceNameField.text = [viewState objectForKey:@"device.name"];
        
        [userDefaults removeObjectForKey:self.class.description];
    } else {
        genderControl.selectedSegmentIndex = UISegmentedControlNoSegment;
        mobileNumberField.text = @"";
        deviceNameField.text = [ScAppEnv env].deviceName;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
    BOOL userDidTapBackButton =
        ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound);
    
    if (userDidTapBackButton) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *viewState = [[NSMutableDictionary alloc] init];
        NSNumber *genderId = [NSNumber numberWithInt:genderControl.selectedSegmentIndex];
        
        [viewState setObject:genderId forKey:@"member.gender"];
        [viewState setObject:mobileNumberField.text forKey:@"member.mobilePhone"];
        [viewState setObject:deviceNameField.text forKey:@"device.name"];
        
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
