//
//  ScRegistrationView2Controller.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScRegistrationView2Controller.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScMeta.h"
#import "ScLogging.h"
#import "ScStrings.h"
#import "ScServerConnection.h"
#import "ScUUIDGenerator.h"

#import "ScDevice.h"
#import "ScMember.h"
#import "ScMembership.h"
#import "ScMessageBoard.h"
#import "ScScola.h"


static NSString * const kSegueToMainView = @"registrationView2ToMainView";

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
@synthesize mobilePhoneLabel;
@synthesize mobilePhoneField;
@synthesize deviceNameUserHelpLabel;
@synthesize deviceNameField;

@synthesize member;
@synthesize homeScola;
@synthesize userIsListed;


#pragma mark - Input validation

- (UIAlertView *)alertViewIfNoDeviceName
{
    UIAlertView *alertView = nil;
    
    if (deviceNameField.text.length == 0) {
        NSString *deviceType = [UIDevice currentDevice].model;
        NSString *deviceTypeDefinite;
        NSString *deviceTypePossessive;
        
        if ([deviceType isEqualToString:@"iPod"]) {
            deviceTypeDefinite = [ScStrings stringForKey:str_iPodDefinite];
            deviceTypePossessive = [ScStrings stringForKey:str_iPodPossessive];
        } else if ([deviceType isEqualToString:@"iPad"]) {
            deviceTypeDefinite = [ScStrings stringForKey:str_iPadDefinite];
            deviceTypePossessive = [ScStrings stringForKey:str_iPadPossessive];
        } else {
            deviceTypeDefinite = [ScStrings stringForKey:strPhoneDefinite];
            deviceTypePossessive = [ScStrings stringForKey:strPhonePossessive];
        }
        
        NSString *alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strNoDeviceNameAlert], deviceTypeDefinite, deviceTypePossessive, [UIDevice currentDevice].name];
        NSString *useConfiguredButtonTitle = [ScStrings stringForKey:strUseConfigured];
        NSString *useNewButtonTitle = [ScStrings stringForKey:strUseNew];
        
        alertView = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:self cancelButtonTitle:useConfiguredButtonTitle otherButtonTitles:useNewButtonTitle, nil];
    }
    
    return alertView;
}


- (BOOL)isDoneEditing
{
    UIAlertView *alertView = nil;
    
    if (mobilePhoneField.text.length == 0) {
        alertView = [[UIAlertView alloc] initWithTitle:nil message:[ScStrings stringForKey:strNoMobilePhoneAlert] delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
    } else {
        alertView = [self alertViewIfNoDeviceName];
    }

    BOOL isDone = (!alertView);
    
    if (isDone) {
        NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
        
        ScMessageBoard *defaultMessageBoard = [context entityForClass:ScMessageBoard.class inScola:homeScola];
        defaultMessageBoard.title = [ScStrings stringForKey:strMyMessageBoard];
        defaultMessageBoard.scola = homeScola;
        
        ScMembership *scolaMembership = [context entityForClass:ScMembership.class inScola:homeScola];
        scolaMembership.scola = homeScola;
        scolaMembership.member = member;
        scolaMembership.isResidency = [NSNumber numberWithBool:YES];
        scolaMembership.isActive = [NSNumber numberWithBool:YES];
        scolaMembership.isAdmin = [NSNumber numberWithBool:YES];
        
        ScDevice *device = [context entityForClass:ScDevice.class inScola:homeScola withId:[ScMeta m].deviceId];
        device.type = [UIDevice currentDevice].model;
        device.displayName = deviceNameField.text;
        device.member = member;
        
        if (genderControl.selectedSegmentIndex == kGenderSegmentFemale) {
            member.gender = kGenderFemale;
        } else if (genderControl.selectedSegmentIndex == kGenderSegmentMale) {
            member.gender = kGenderMale;
        }
        
        member.mobilePhone = mobilePhoneField.text;
        member.activeSince = [NSDate date];
        member.didRegister = [NSNumber numberWithBool:YES];
        
        [context saveUsingDelegate:self];
        
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
    
    BOOL isMinor = NO;
    
    if (member.dateOfBirth) {
        NSDate *now = [NSDate date];
        NSDateComponents *ageComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:member.dateOfBirth toDate:now options:kNilOptions];
        
        isMinor =  (ageComponents.year < kAgeOfMajority);
    }
    
    NSString *femaleTerm = [ScStrings stringForKey:(isMinor ? strFemaleMinor : strFemaleAdult)];
    NSString *maleTerm = [ScStrings stringForKey:(isMinor ? strMaleMinor : strMaleAdult)];

    genderUserHelpLabel.text = [NSString stringWithFormat:[ScStrings stringForKey:strGenderUserHelp], [femaleTerm lowercaseString], [maleTerm lowercaseString]];
    mobilePhoneLabel.text = [ScStrings stringForKey:strMobilePhoneUserHelp];
    deviceNameUserHelpLabel.text = [NSString stringWithFormat:[ScStrings stringForKey:strDeviceNameUserHelp], [ScStrings stringForKey:strThisPhone]];
    
    mobilePhoneField.delegate = self;
    deviceNameField.delegate = self;
    
    [genderControl setTitle:femaleTerm forSegmentAtIndex:kGenderSegmentFemale];
    [genderControl setTitle:maleTerm forSegmentAtIndex:kGenderSegmentMale];

    mobilePhoneField.placeholder = [ScStrings stringForKey:strMobilePhonePrompt];
    mobilePhoneField.keyboardType = UIKeyboardTypeNumberPad;
    [mobilePhoneField becomeFirstResponder];
    
    deviceNameField.placeholder = [NSString stringWithFormat:[ScStrings stringForKey:strDeviceNamePrompt], [ScStrings stringForKey:strPhoneDefinite]];
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
    
    NSDictionary *viewState = [ScMeta userDefaultForKey:self.class.description];
    
    if (userIsListed) {
        if ([member.gender isEqualToString:kGenderFemale]) {
            genderControl.selectedSegmentIndex = kGenderSegmentFemale;
        } else if ([member.gender isEqualToString:kGenderMale]) {
            genderControl.selectedSegmentIndex = kGenderSegmentMale;
        }
        
        mobilePhoneField.text = member.mobilePhone;
        deviceNameField.text = [UIDevice currentDevice].name;
    } else if (viewState) {
        genderControl.selectedSegmentIndex = [[viewState objectForKey:@"member.gender"] intValue];
        mobilePhoneField.text = [viewState objectForKey:@"member.mobilePhone"];
        deviceNameField.text = [viewState objectForKey:@"device.name"];
        
        [ScMeta removeUserDefaultForKey:self.class.description];
    } else {
        genderControl.selectedSegmentIndex = kGenderSegmentFemale;
        mobilePhoneField.text = @"";
        deviceNameField.text = [UIDevice currentDevice].name;
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
        NSMutableDictionary *viewState = [[NSMutableDictionary alloc] init];
        NSNumber *genderId = [NSNumber numberWithInt:genderControl.selectedSegmentIndex];
        
        [viewState setObject:genderId forKey:@"member.gender"];
        [viewState setObject:mobilePhoneField.text forKey:@"member.mobilePhone"];
        [viewState setObject:deviceNameField.text forKey:@"device.name"];
        
        [ScMeta setUserDefault:viewState forKey:self.class.description];
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
        deviceNameField.text = [UIDevice currentDevice].name;
    } else if (buttonIndex == kPopUpButtonUseNew) {
        [deviceNameField becomeFirstResponder];
    }
}


#pragma mark - ScServerConnectionDelegate implementation

- (void)didReceiveResponse:(NSHTTPURLResponse *)response
{
    ScLogDebug(@"Received response. HTTP status code: %d", response.statusCode);
    
    if (response.statusCode == kHTTPStatusCodeCreated) {
        [[ScMeta m] didPersistEntitiesToServer];
    } else {
        [ScServerConnection showAlertForHTTPStatus:response.statusCode];
    }
}


- (void)didFailWithError:(NSError *)error
{
    [ScServerConnection showAlertForError:error];
}

@end
