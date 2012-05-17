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
#import "ScMemberResidency.h"
#import "ScMessageBoard.h"
#import "ScScola.h"

#import "ScMember+ScMemberExtensions.h"
#import "ScMemberResidency+ScMemberResidencyExtensions.h"
#import "ScScola+ScScolaExtensions.h"


static NSString * const kSegueToMainView = @"registrationView2ToMainView";

static int const kGenderSegmentFemale = 0;
static int const kGenderSegmentMale = 1;

static NSString * const kGenderFemale = @"F";
static NSString * const kGenderMale = @"M";
static NSString * const kGenderNoneGiven = @"N";

static int const kPopUpButtonUseBuiltIn = 0;
static int const kPopUpButtonUseNew = 1;


@implementation ScRegistrationView2Controller

@synthesize darkLinenView;
@synthesize genderUserHelpLabel;
@synthesize genderControl;
@synthesize mobilePhoneUserHelpLabel;
@synthesize mobilePhoneField;
@synthesize landlineUserHelpLabel;
@synthesize landlineField;

@synthesize member;
@synthesize homeScola;

@synthesize isUserListed;


#pragma mark - Auxiiary methods

- (void)syncViewState
{
    if (genderControl.selectedSegmentIndex == kGenderSegmentFemale) {
        member.gender = kGenderFemale;
    } else if (genderControl.selectedSegmentIndex == kGenderSegmentMale) {
        member.gender = kGenderMale;
    } else {
        member.gender = kGenderNoneGiven;
    }
    
    member.mobilePhone = mobilePhoneField.text;
    homeScola.landline = landlineField.text;
}


#pragma mark - Input validation

- (BOOL)isPhoneNumberGiven
{
    BOOL isGiven = NO;
    
    isGiven = isGiven || (mobilePhoneField.text.length > 0);
    isGiven = isGiven || (landlineField.text.length > 0);
    
    if (!isGiven) {
        [mobilePhoneField becomeFirstResponder];
    }
    
    return isGiven;
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
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:[ScStrings stringForKey:strDone] style:UIBarButtonItemStyleDone target:self action:@selector(textFieldShouldReturn:)];
    
    self.navigationItem.rightBarButtonItem = doneButton;
    
    NSString *femaleLabel;
    NSString *maleLabel;
    
    if ([member isMinor]) {
        femaleLabel = [ScStrings stringForKey:strFemaleMinor];
        maleLabel = [ScStrings stringForKey:strMaleMinor];
    } else {
        femaleLabel = [ScStrings stringForKey:strFemale];
        maleLabel = [ScStrings stringForKey:strMale];
    }

    [genderControl setTitle:femaleLabel forSegmentAtIndex:kGenderSegmentFemale];
    [genderControl setTitle:maleLabel forSegmentAtIndex:kGenderSegmentMale];
    genderUserHelpLabel.text = [NSString stringWithFormat:[ScStrings stringForKey:strGenderUserHelp], [femaleLabel lowercaseString], [maleLabel lowercaseString]];
    
    if (isUserListed && (member.mobilePhone.length > 0)) {
        mobilePhoneUserHelpLabel.text = [ScStrings stringForKey:strMobilePhoneListedUserHelp];
    } else {
        mobilePhoneUserHelpLabel.text = [ScStrings stringForKey:strMobilePhoneUserHelp];
    }
    
    if (isUserListed && (homeScola.landline.length > 0)) {
        landlineUserHelpLabel.text = [ScStrings stringForKey:strLandlineListedUserHelp];
    } else {
        landlineUserHelpLabel.text = [ScStrings stringForKey:strLandlineUserHelp];
    }
    
    mobilePhoneField.delegate = self;
    mobilePhoneField.placeholder = [ScStrings stringForKey:strMobilePhonePrompt];
    mobilePhoneField.keyboardType = UIKeyboardTypeNumberPad;
    
    landlineField.delegate = self;
    landlineField.placeholder = [ScStrings stringForKey:strLandlinePrompt];
    landlineField.keyboardType = UIKeyboardTypeNumberPad;
    
    [mobilePhoneField becomeFirstResponder];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([member.gender isEqualToString:kGenderFemale]) {
        genderControl.selectedSegmentIndex = kGenderSegmentFemale;
    } else if ([member.gender isEqualToString:kGenderMale]) {
        genderControl.selectedSegmentIndex = kGenderSegmentMale;
    } else {
        genderControl.selectedSegmentIndex = UISegmentedControlNoSegment;
    }
    
    mobilePhoneField.text = member.mobilePhone;
    landlineField.text = homeScola.landline;
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        [self syncViewState];
    }
}


- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - UITextFieldDelegate implementation

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *alertMessage = nil;
    
    if (![self isPhoneNumberGiven]) {
        alertMessage = [ScStrings stringForKey:strNoPhoneNumberAlert];
    }
    
    BOOL shouldReturn = !alertMessage;
    
    if (shouldReturn) {
        [self syncViewState];
        
        NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
        
        member.activeSince = [NSDate date];
        member.didRegister = [NSNumber numberWithBool:YES];
        
        if ([member.residencies count] == 0) {
            ScMemberResidency *residency = [homeScola addResident:member];
            
            residency.isActive = [NSNumber numberWithBool:YES];
            residency.isAdmin = [NSNumber numberWithBool:![member isMinor]];
        }
        
        if ([homeScola.messageBoards count] == 0) {
            ScMessageBoard *defaultMessageBoard = [context entityForClass:ScMessageBoard.class inScola:homeScola];
            
            defaultMessageBoard.title = [ScStrings stringForKey:strMyMessageBoard];
            defaultMessageBoard.scola = homeScola;
        }
        
        ScDevice *device = [context fetchEntityWithId:[ScMeta m].deviceId];
        
        if (!device) {
            device = [context entityForClass:ScDevice.class inScola:homeScola withId:[ScMeta m].deviceId];
        }
        
        device.type = [UIDevice currentDevice].model;
        device.displayName = [UIDevice currentDevice].name;
        device.member = member;
        
        [context saveAndPersist];
        
        [self performSegueWithIdentifier:kSegueToMainView sender:self];
    } else {
        UIAlertView *validationAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
        
        [validationAlert show];
    }
    
    return shouldReturn;
}

@end
