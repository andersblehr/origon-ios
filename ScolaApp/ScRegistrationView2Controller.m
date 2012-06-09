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

#import "ScMembershipViewController.h"


static NSString * const kSegueToMainView = @"registrationView2ToMainView";

static int const kGenderSegmentFemale = 0;
static int const kGenderSegmentMale = 1;

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


- (void)modallyAddHouseholdMembers
{
    ScMembershipViewController *membershipViewController = [self.storyboard instantiateViewControllerWithIdentifier:kMembershipViewController];
    
    membershipViewController.scola = homeScola;
    membershipViewController.isRegistrationWizardStep = YES;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:membershipViewController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    
    [self.navigationController presentModalViewController:navigationController animated:YES];
}


#pragma mark - Input validation

- (BOOL)isPhoneNumberGiven
{
    BOOL isGiven = NO;
    
    isGiven = isGiven || (mobilePhoneField.text.length > 0);
    isGiven = isGiven || (landlineField.text.length > 0);
    
    if (!isGiven) {
        [ScMeta showAlertWithTitle:[ScStrings stringForKey:strNoPhoneNumberTitle] message:[ScStrings stringForKey:strNoPhoneNumberAlert]];
        
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
    
    self.title = [ScStrings stringForKey:strRegistrationView2Title];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(completeRegistration)];
    
    self.navigationItem.rightBarButtonItem = doneButton;
    
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
    
    if (isUserListed && [member hasMobilPhone]) {
        mobilePhoneUserHelpLabel.text = [ScStrings stringForKey:strVerifyMobilePhoneUserHelp];
    } else {
        mobilePhoneUserHelpLabel.text = [ScStrings stringForKey:strMobilePhoneUserHelp];
    }
    
    mobilePhoneField.placeholder = [ScStrings stringForKey:strMobilePhonePrompt];
    mobilePhoneField.keyboardType = UIKeyboardTypeNumberPad;
    
    ScMemberResidency *residency = [ScMemberResidency residencyForMember:[ScMeta m].userId];
    BOOL isLandlineEditable = [[residency isAdmin] boolValue];
    
    if (isUserListed && isLandlineEditable && [homeScola hasLandline]) {
        landlineUserHelpLabel.text = [ScStrings stringForKey:strVerifyLandlineUserHelp];
    } else if (isLandlineEditable) {
        landlineUserHelpLabel.text = [ScStrings stringForKey:strProvideLandlineUserHelp];
    } else {
        landlineUserHelpLabel.text = [ScStrings stringForKey:strLandlineUserHelp];
    }
    
    if (isLandlineEditable) {
        landlineField.placeholder = [ScStrings stringForKey:strLandlinePrompt];
        landlineField.keyboardType = UIKeyboardTypeNumberPad;
    } else {
        landlineField.enabled = NO;
        landlineField.textColor = [UIColor grayColor];
    }
    
    [mobilePhoneField becomeFirstResponder];
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


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        [self syncViewState];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Selector implementations

- (void)completeRegistration
{
    BOOL didComplete = [ScMeta isGenderGiven:genderControl.selectedSegmentIndex female:femaleLabel male:maleLabel];
    didComplete = didComplete && [self isPhoneNumberGiven];
    
    if (didComplete) {
        [self syncViewState];
        [[ScMeta m].managedObjectContext synchronise];
        
        ScMemberResidency *residency = [ScMemberResidency residencyForMember:[ScMeta m].userId];
        
        if ([[residency isAdmin] boolValue]) {
            [self modallyAddHouseholdMembers];
        }
        
        [self performSegueWithIdentifier:kSegueToMainView sender:self];
    }
}

@end
