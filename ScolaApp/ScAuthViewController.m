//
//  ScAuthViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 01.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScAuthViewController.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "NSString+ScStringExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScMeta.h"
#import "ScLogging.h"
#import "ScServerConnection.h"
#import "ScStrings.h"
#import "ScUUIDGenerator.h"

#import "ScDevice.h"
#import "ScMember.h"
#import "ScMemberResidency.h"
#import "ScMessageBoard.h"
#import "ScScola.h"

#import "ScMember+ScMemberExtensions.h"
#import "ScScola+ScScolaExtensions.h"

#import "ScMainViewController.h"
#import "ScRegistrationView1Controller.h"

typedef enum {
    ScAuthAlertTagEmailSent,
    ScAuthAlertTagConfirmationFailed,
    ScAuthAlertTagWelcomeBack,
    ScAuthAlertTagNotLoggedIn,
} ScAuthAlertTag;

static NSString * const kSegueToMainView = @"authToMainView";
static NSString * const kSegueToRegistrationView1 = @"authToRegistrationView1";

static int const kMinimumPassordLength = 6;

static int const kUserIntentionLogin = 0;
static int const kUserIntentionRegistration = 1;

static NSString * const kUserDefaultsKeyAuthInfo = @"scola.auth.info";

static NSString * const kAuthInfoKeyName = @"name";
static NSString * const kAuthInfoKeyUserId = @"userId";
static NSString * const kAuthInfoKeyPasswordHash = @"passwordHash";
static NSString * const kAuthInfoKeyRegistrationCode = @"registrationCode";
static NSString * const kAuthInfoKeyIsListed = @"isListed";
static NSString * const kAuthInfoKeyIsRegistered = @"isRegistered";
static NSString * const kAuthInfoKeyHomeScolaId = @"homeScolaId";

static int const kPopUpButtonLater = 0;
static int const kPopUpButtonContinue = 1;
static int const kPopUpButtonGoBack = 0;


@implementation ScAuthViewController

@synthesize darkLinenView;
@synthesize userIntentionControl;
@synthesize userHelpLabel;
@synthesize nameOrEmailOrRegistrationCodeField;
@synthesize emailOrPasswordField;
@synthesize passwordField;
@synthesize scolaDescriptionHeadingLabel;
@synthesize scolaDescriptionTextView;
@synthesize scolaSplashLabel;
@synthesize showInfoButton;
@synthesize activityIndicator;


#pragma mark - Auxiliary methods

- (void)runSplashSequence
{   
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"."
                                    waitUntilDone:YES];
    
    [NSThread sleepForTimeInterval:0.2];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@".."
                                    waitUntilDone:YES];
    
    [NSThread sleepForTimeInterval:0.2];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..s"
                                    waitUntilDone:YES];
    
    [NSThread sleepForTimeInterval:0.2];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..sc"
                                    waitUntilDone:YES];
    
    [NSThread sleepForTimeInterval:0.2];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..sco"
                                    waitUntilDone:YES];
    
    [NSThread sleepForTimeInterval:0.2];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..scol"
                                    waitUntilDone:YES];
    
    [NSThread sleepForTimeInterval:0.2];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..scola"
                                    waitUntilDone:YES];
    
    [NSThread sleepForTimeInterval:0.2];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..scola."
                                    waitUntilDone:YES];
    
    [NSThread sleepForTimeInterval:0.2];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..scola.."
                                    waitUntilDone:YES];
}


- (void)startSplashSequenceThread
{
    NSThread *splashSequenceThread = [[NSThread alloc] initWithTarget:self selector:@selector(runSplashSequence) object:nil];
    
    [splashSequenceThread start];
}


- (void)resignCurrentFirstResponder
{
    [self.view endEditing:YES];
}


- (NSString *)generatePasswordHash:(NSString *)password usingSalt:(NSString *)salt
{
    return [[password diff:salt] hashUsingSHA1];
}


- (BOOL)registerNewDevice
{
    BOOL didRegisterNewDevice = NO;
    
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    
    ScDevice *device = [context fetchEntityWithId:[ScMeta m].deviceId];
    
    if (!device) {
        device = [context entityForClass:ScDevice.class inScola:homeScola withId:[ScMeta m].deviceId];
        device.type = [UIDevice currentDevice].model;
        device.displayName = [UIDevice currentDevice].name;
        device.member = member;
        
        didRegisterNewDevice = YES;
    }
    
    return didRegisterNewDevice;
}


#pragma mark - View composition

- (void)userIntentionDidChange
{
    if (authPhase == ScAuthPhaseLogin) {
        emailAsEntered = nameOrEmailOrRegistrationCodeField.text;
    } else if (authPhase == ScAuthPhaseRegistration) {
        nameAsEntered = nameOrEmailOrRegistrationCodeField.text;
        
        if (emailOrPasswordField.text.length > 0) {
            emailAsEntered = emailOrPasswordField.text;
        }
    }
    
    if (userIntentionControl.selectedSegmentIndex == kUserIntentionLogin) {
        [self setUpForUserLogin];
    } else if (userIntentionControl.selectedSegmentIndex == kUserIntentionRegistration) {
        [self setUpForUserRegistration];
    }
}


- (void)setUpForUserLogin
{
    authPhase = ScAuthPhaseLogin;
    
    userHelpLabel.text = [ScStrings stringForKey:strUserHelpMember];
    
    userIntentionControl.enabled = YES;
    userIntentionControl.selectedSegmentIndex = kUserIntentionLogin;
    
    nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strEmailPrompt];
    nameOrEmailOrRegistrationCodeField.text = emailAsEntered;
    nameOrEmailOrRegistrationCodeField.keyboardType = UIKeyboardTypeEmailAddress;
    nameOrEmailOrRegistrationCodeField.autocapitalizationType = NO;
    nameOrEmailOrRegistrationCodeField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    emailOrPasswordField.placeholder = [ScStrings stringForKey:strPasswordPrompt];
    emailOrPasswordField.text = @"";
    emailOrPasswordField.keyboardType = UIKeyboardTypeDefault;
    emailOrPasswordField.secureTextEntry = YES;
    
    passwordField.hidden = YES;

    if (nameOrEmailOrRegistrationCodeField.text.length > 0) {
        [emailOrPasswordField becomeFirstResponder];
    } else {
        [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
    }
    
    if (authInfo) {
        [ScMeta removeUserDefaultForKey:kUserDefaultsKeyAuthInfo];
        authInfo = nil;
    }
}


- (void)setUpForUserRegistration
{
    authPhase = ScAuthPhaseRegistration;
    
    userHelpLabel.text = [ScStrings stringForKey:strUserHelpNew];
    
    userIntentionControl.enabled = YES;
    userIntentionControl.selectedSegmentIndex = kUserIntentionRegistration;
    
    nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strNamePrompt];
    nameOrEmailOrRegistrationCodeField.text = nameAsEntered;
    nameOrEmailOrRegistrationCodeField.keyboardType = UIKeyboardTypeDefault;
    nameOrEmailOrRegistrationCodeField.autocapitalizationType = YES;
    nameOrEmailOrRegistrationCodeField.clearButtonMode = UITextFieldViewModeNever;
    
    emailOrPasswordField.placeholder = [ScStrings stringForKey:strEmailPrompt];
    emailOrPasswordField.text = @"";
    emailOrPasswordField.keyboardType = UIKeyboardTypeEmailAddress;
    emailOrPasswordField.secureTextEntry = NO;
    
    passwordField.text = @"";
    passwordField.hidden = NO;
    
    [self resignCurrentFirstResponder];
    
    if (authInfo) {
        [ScMeta removeUserDefaultForKey:kUserDefaultsKeyAuthInfo];
        authInfo = nil;
    }
}


- (void)setUpForUserConfirmation
{
    authPhase = ScAuthPhaseConfirmation;
    
    userHelpLabel.text = [ScStrings stringForKey:strUserHelpCompleteRegistration];
    
    userIntentionControl.enabled = NO;
    userIntentionControl.selectedSegmentIndex = kUserIntentionRegistration;
    
    nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strRegistrationCodePrompt];
    nameOrEmailOrRegistrationCodeField.text = @"";
    nameOrEmailOrRegistrationCodeField.keyboardType = UIKeyboardTypeDefault;
    nameOrEmailOrRegistrationCodeField.autocapitalizationType = NO;
    
    emailOrPasswordField.placeholder = [ScStrings stringForKey:strRepeatPasswordPrompt];
    emailOrPasswordField.text = @"";
    emailOrPasswordField.keyboardType = UIKeyboardTypeDefault;
    emailOrPasswordField.secureTextEntry = YES;
    emailOrPasswordField.clearButtonMode = UITextFieldViewModeNever;
    
    passwordField.hidden = YES;
}


- (void)indicatePendingServerSession:(BOOL)isPending
{
    static NSString *nameEtcPlaceholder;
    static NSString *nameEtc;
    static NSString *emailEtcPlaceholder;
    static NSString *emailEtc;
    
    if (isPending) {
        nameEtcPlaceholder = nameOrEmailOrRegistrationCodeField.placeholder;
        nameEtc = nameOrEmailOrRegistrationCodeField.text;
        emailEtcPlaceholder = emailOrPasswordField.placeholder;
        emailEtc = emailOrPasswordField.text;
        
        nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strPleaseWait];
        nameOrEmailOrRegistrationCodeField.text = @"";
        emailOrPasswordField.placeholder = [ScStrings stringForKey:strPleaseWait];
        emailOrPasswordField.text = @"";
        
        passwordField.hidden = YES;
        userIntentionControl.enabled = NO;
        isEditingAllowed = NO;
        
        [activityIndicator startAnimating];
    } else {
        [activityIndicator stopAnimating];
        
        if (authPhase == ScAuthPhaseRegistration) {
            [self setUpForUserRegistration];
        } else if (authPhase == ScAuthPhaseConfirmation) {
            userIntentionControl.selectedSegmentIndex = UISegmentedControlNoSegment;
        }
        
        nameOrEmailOrRegistrationCodeField.placeholder = nameEtcPlaceholder;
        nameOrEmailOrRegistrationCodeField.text = nameEtc;
        emailOrPasswordField.placeholder = emailEtcPlaceholder;
        emailOrPasswordField.text = emailEtc;
        
        userIntentionControl.enabled = YES;
        isEditingAllowed = YES;
    }
}


#pragma mark - Input validation

- (BOOL)isNameValid
{
    BOOL isValid = NO;
    
    if (authPhase == ScAuthPhaseRegistration) {
        nameAsEntered = nameOrEmailOrRegistrationCodeField.text;
        
        isValid = (nameAsEntered.length > 0);
        isValid = isValid && ([nameAsEntered rangeOfString:@" "].location != NSNotFound);
    }
    
    if (!isValid) {
        [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)isEmailValid
{
    BOOL isValid = NO;
    UITextField *emailField;
    
    if (authPhase == ScAuthPhaseLogin) {
        emailField = nameOrEmailOrRegistrationCodeField;
    } else if (authPhase == ScAuthPhaseRegistration) {
        emailField = emailOrPasswordField;
    }
    
    emailAsEntered = emailField.text;
    
    NSUInteger atLocation = [emailAsEntered rangeOfString:@"@"].location;
    NSUInteger dotLocation = [emailAsEntered rangeOfString:@"." options:NSBackwardsSearch].location;
    NSUInteger spaceLocation = [emailAsEntered rangeOfString:@" "].location;
    
    isValid = (atLocation != NSNotFound);
    isValid = isValid && (dotLocation != NSNotFound);
    isValid = isValid && (dotLocation > atLocation);
    isValid = isValid && (spaceLocation == NSNotFound);

    if (!isValid) {
        [emailField becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)isPasswordValid
{
    BOOL isValid = NO;
    UITextField *currentPasswordField;
    
    if ((authPhase == ScAuthPhaseLogin) || (authPhase == ScAuthPhaseConfirmation)) {
        currentPasswordField = emailOrPasswordField;
    } else if (authPhase == ScAuthPhaseRegistration) {
        currentPasswordField = passwordField;
    }
    
    if (authPhase == ScAuthPhaseConfirmation) {
        NSString *passwordHashAsPersisted = [authInfo objectForKey:kAuthInfoKeyPasswordHash];
        NSString *passwordHashAsEntered = [self generatePasswordHash:currentPasswordField.text usingSalt:emailAsEntered];
        
        isValid = [passwordHashAsEntered isEqualToString:passwordHashAsPersisted];
    } else {
        isValid = (currentPasswordField.text.length >= kMinimumPassordLength);
    }
    
    if (!isValid) {
        currentPasswordField.text = @"";
        [currentPasswordField becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)isRegistrationCodeValid
{
    NSString *registrationCodeAsSent = [[authInfo objectForKey:kAuthInfoKeyRegistrationCode] lowercaseString];
    NSString *registrationCodeAsEntered = [nameOrEmailOrRegistrationCodeField.text lowercaseString];
    
    BOOL isValid = [registrationCodeAsEntered isEqualToString:registrationCodeAsSent];

    if (!isValid) {
        [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
    }
    
    return isValid;
}


#pragma mark - User registration and authentication

- (void)loginUser
{
    [ScMeta m].userId = emailAsEntered;
    
    NSString *password = emailOrPasswordField.text;
    
    serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:emailAsEntered withPassword:password];
    [serverConnection authenticateForPhase:ScAuthPhaseLogin usingDelegate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)registerUser
{
    [ScMeta m].userId = emailAsEntered;
    
    NSString *password = passwordField.text;
    
    serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:emailAsEntered withPassword:password];
    [serverConnection setValue:nameAsEntered forURLParameter:kURLParameterName];
    [serverConnection authenticateForPhase:ScAuthPhaseRegistration usingDelegate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)confirmUser
{
    [ScMeta m].userId = emailAsEntered;
    
    NSString *password = emailOrPasswordField.text;
    
    serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:emailAsEntered withPassword:password];
    [serverConnection setValue:[ScMeta m].homeScolaId forURLParameter:kURLParameterScolaId];
    [serverConnection authenticateForPhase:ScAuthPhaseConfirmation usingDelegate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)userDidLogInWithData:(NSArray *)data
{
    [ScMeta m].isUserLoggedIn = YES;
    
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    
    if (data) {
        [context saveWithDictionaries:data];
    }
    
    isUpToDate = YES;
    
    if (authPhase == ScAuthPhaseLogin) {
        member = [context fetchEntityWithId:[ScMeta m].userId];
        homeScola = [context fetchEntityWithId:member.scolaId];
        
        [ScMeta m].homeScolaId = member.scolaId;
        
        if ([self registerNewDevice]) {
            [context synchronise];
        }
        
        if ([self isRegistrationComplete]) {
            [self performSegueWithIdentifier:kSegueToMainView sender:self];
        } else {
            [self completeRegistration];
        }
    } else if (authPhase == ScAuthPhaseConfirmation) {
        if (isUserListed) {
            homeScola = [context fetchEntityWithId:[ScMeta m].homeScolaId];
            member = [context fetchEntityWithId:[ScMeta m].userId];
        } else {
            homeScola = [context entityForScolaWithName:[ScStrings stringForKey:strMyPlace] scolaId:[ScMeta m].homeScolaId];
            member = [context entityForClass:ScMember.class inScola:homeScola withId:emailAsEntered];
            
            ScMemberResidency *residency = [homeScola addResident:member];
            residency.isActive = [NSNumber numberWithBool:YES];
            residency.isAdmin = [NSNumber numberWithBool:YES];
            
            ScMessageBoard *defaultMessageBoard = [context entityForClass:ScMessageBoard.class inScola:homeScola];
            
            defaultMessageBoard.title = [ScStrings stringForKey:strMyMessageBoard];
            defaultMessageBoard.scola = homeScola;
        }
        
        member.name = nameAsEntered;
        member.gender = kGenderNoneGiven;
        member.passwordHash = [authInfo objectForKey:kAuthInfoKeyPasswordHash];
        member.didRegister = [NSNumber numberWithBool:YES];
        member.activeSince = [NSDate date];
        
        [self registerNewDevice];
        
        [context synchronise];
        
        [ScMeta removeUserDefaultForKey:kUserDefaultsKeyAuthInfo];
        authInfo = nil;
        
        [self performSegueWithIdentifier:kSegueToRegistrationView1 sender:self];
    }
}


- (void)userDidRegisterWithData:(NSDictionary *)data
{
    authInfo = data;
    
    isUserListed = [[authInfo objectForKey:kAuthInfoKeyIsListed] boolValue];
    BOOL isUserRegistered = [[authInfo objectForKey:kAuthInfoKeyIsRegistered] boolValue];

    if (!isUserRegistered) {
        NSData *authInfoArchive = [NSKeyedArchiver archivedDataWithRootObject:authInfo];
        [ScMeta setUserDefault:authInfoArchive forKey:kUserDefaultsKeyAuthInfo];
        
        NSString *alertTitle = nil;
        NSString *alertMessage = nil;
        
        if (isUserListed) {
            [ScMeta m].homeScolaId = [authInfo objectForKey:kAuthInfoKeyHomeScolaId];
            
            alertTitle = [ScStrings stringForKey:strEmailSentToInviteeTitle];
            alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strEmailSentToInviteeAlert], emailAsEntered];
        } else {
            [ScMeta m].homeScolaId = [ScUUIDGenerator generateUUID];
            
            alertTitle = [ScStrings stringForKey:strEmailSentAlertTitle];
            alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strEmailSentAlert], emailAsEntered];
        }
        
        UIAlertView *emailSentAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:[ScStrings stringForKey:strLater] otherButtonTitles:[ScStrings stringForKey:strHaveAccess], nil];
        emailSentAlert.tag = ScAuthAlertTagEmailSent;
        
        [emailSentAlert show];
    } else {
        UIAlertView *userExistsAlert = [[UIAlertView alloc] initWithTitle:nil message:[ScStrings stringForKey:strUserExistsMustLogInAlert] delegate:self cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
        userExistsAlert.tag = ScAuthAlertTagNotLoggedIn;
        
        [userExistsAlert show];
    }
}


- (BOOL)isRegistrationComplete
{
    if (!member) {
        NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
        
        member = [context fetchEntityWithId:[ScMeta m].userId];
        homeScola = [context fetchEntityWithId:[ScMeta m].homeScolaId];
    }
    
    BOOL isAddressValid = (homeScola.addressLine1.length > 0);
    
    isAddressValid = isAddressValid || (homeScola.addressLine2.length > 0);
    isAddressValid = isAddressValid || (homeScola.postCodeAndCity.length > 0);
    
    BOOL isPhoneNumberGiven = (member.mobilePhone.length > 0);
    
    isPhoneNumberGiven = isPhoneNumberGiven || (homeScola.landline.length > 0);
    
    return (isAddressValid && isPhoneNumberGiven);
}


- (void)completeRegistration
{
    UIAlertView *incompleteRegistrationAlert = [[UIAlertView alloc] initWithTitle:[ScStrings stringForKey:strIncompleteRegistrationTitle] message:[ScStrings stringForKey:strIncompleteRegistrationAlert] delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
    
    [incompleteRegistrationAlert show];
    
    [self performSegueWithIdentifier:kSegueToRegistrationView1 sender:self];
}


#pragma mark - View lifecycle

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([[ScMeta m] isUserLoggedIn]) {
        if ([self isRegistrationComplete]) {
            [self performSegueWithIdentifier:kSegueToMainView sender:self];
        } else {
            [self completeRegistration];
        }
    } else {
        [darkLinenView addGradientLayer];
        [darkLinenView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignCurrentFirstResponder)]];
        
        isEditingAllowed = YES;
        nameOrEmailOrRegistrationCodeField.delegate = self;
        emailOrPasswordField.delegate = self;
        passwordField.delegate = self;
        passwordField.secureTextEntry = YES;
        activityIndicator.hidesWhenStopped = YES;

        [userIntentionControl setTitle:[ScStrings stringForKey:strUserIntentionRegistration] forSegmentAtIndex:kUserIntentionRegistration];
        [userIntentionControl setTitle:[ScStrings stringForKey:strUserIntentionLogin] forSegmentAtIndex:kUserIntentionLogin];
        [userIntentionControl addTarget:self action:@selector(userIntentionDidChange) forControlEvents:UIControlEventValueChanged];
        
        passwordField.placeholder = [ScStrings stringForKey:strNewPasswordPrompt];
        scolaDescriptionTextView.text = [ScStrings stringForKey:strScolaDescription];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    [self navigationController].navigationBarHidden = YES;
    
    scolaSplashLabel.text = @"";
    
    NSData *authInfoArchive = [ScMeta userDefaultForKey:kUserDefaultsKeyAuthInfo];
    
    if (authInfoArchive) {
        authInfo = [NSKeyedUnarchiver unarchiveObjectWithData:authInfoArchive];
        
        nameAsEntered = [authInfo objectForKey:kAuthInfoKeyName];
        emailAsEntered = [authInfo objectForKey:kAuthInfoKeyUserId];
        
        [self setUpForUserConfirmation];
    } else {
        if ([ScMeta m].userId) {
            emailAsEntered = [ScMeta m].userId;
            
            [self setUpForUserLogin];
        } else {
            [self setUpForUserRegistration];
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self startSplashSequenceThread];
    
    if ([ScMeta m].isInternetConnectionAvailable) {
        [ScStrings refreshStrings];
    }
    
    if (authPhase == ScAuthPhaseConfirmation) {
        NSString *popUpMessage = [NSString stringWithFormat:[ScStrings stringForKey:strWelcomeBackPopUpMessage], [authInfo objectForKey:kAuthInfoKeyUserId]];
        
        UIAlertView *welcomeBackPopUp = [[UIAlertView alloc] initWithTitle:[ScStrings stringForKey:strWelcomeBackPopUpTitle] message:popUpMessage delegate:self cancelButtonTitle:[ScStrings stringForKey:strGoBack] otherButtonTitles:[ScStrings stringForKey:strHaveCode], nil];
        welcomeBackPopUp.tag = ScAuthAlertTagWelcomeBack;
        
        [welcomeBackPopUp show];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToMainView]) {
        if (!isUpToDate) {
            [[ScMeta m].managedObjectContext synchronise];
        }
    } else if ([segue.identifier isEqualToString:kSegueToRegistrationView1]) {
        ScRegistrationView1Controller *nextViewController = segue.destinationViewController;

        nextViewController.member = member;
        nextViewController.homeScola = homeScola;
        nextViewController.isUserListed = isUserListed;
    }
}


#pragma mark - IBAction implementation

- (IBAction)showInfo:(id)sender
{
    // TODO: Using this for various test purposes now, keep in mind to fix later
    
    [self performSegueWithIdentifier:kSegueToRegistrationView1 sender:self];
}


#pragma mark - UITextFieldDelegate implementation

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return isEditingAllowed;
}


- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    BOOL shouldRemove = YES;
    
    if (authPhase == ScAuthPhaseLogin) {
        shouldRemove = (textField != emailOrPasswordField);
    } else {
        shouldRemove = (textField != passwordField);
    }

    if (shouldRemove) {
        NSString *text = textField.text;
        textField.text = [text removeLeadingAndTrailingSpaces];
    }
    
    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *alertMessage = nil;
    NSString *alertTitle = nil;
    NSString *cancelButtonTitle = [ScStrings stringForKey:strOK];
    
    [self textFieldShouldEndEditing:textField];
    
    switch (authPhase) {
        case ScAuthPhaseLogin:
            if (![self isEmailValid]) {
                alertTitle = [ScStrings stringForKey:strInvalidEmailTitle];
                alertMessage = [ScStrings stringForKey:strInvalidEmailAlert];
            } else if (![self isPasswordValid]) {
                alertTitle = [ScStrings stringForKey:strInvalidPasswordTitle];
                alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strInvalidPasswordAlert], kMinimumPassordLength];
            }
            
            break;
            
        case ScAuthPhaseRegistration:
            if (![self isNameValid]) {
                alertTitle = [ScStrings stringForKey:strInvalidNameTitle];
                alertMessage = [ScStrings stringForKey:strInvalidNameAlert];
            } else if (![self isEmailValid]) {
                alertTitle = [ScStrings stringForKey:strInvalidEmailTitle];
                alertMessage = [ScStrings stringForKey:strInvalidEmailAlert];
            } else if (![self isPasswordValid]) {
                alertTitle = [ScStrings stringForKey:strInvalidPasswordTitle];
                alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strInvalidPasswordAlert], kMinimumPassordLength];
            }
            
            break;
            
        case ScAuthPhaseConfirmation:
            if (![self isRegistrationCodeValid]) {
                alertTitle = [ScStrings stringForKey:strInvalidRegistrationCodeTitle];
                alertMessage = [ScStrings stringForKey:strInvalidRegistrationCodeAlert];
            } else if (![self isPasswordValid]) {
                alertTitle = [ScStrings stringForKey:strPasswordsDoNotMatchTitle];
                alertMessage = [ScStrings stringForKey:strPasswordsDoNotMatchAlert];
            }
            
            cancelButtonTitle = [ScStrings stringForKey:strGoBack];
            
            break;
            
        default:
            break;
    }
    
    BOOL shouldReturn = !alertMessage;
    
    if (shouldReturn) {
        [textField resignFirstResponder];
        
        if (authPhase == ScAuthPhaseLogin) {
            [self loginUser];
        } else if (authPhase == ScAuthPhaseRegistration) {
            [self registerUser];
        } else if (authPhase == ScAuthPhaseConfirmation) {
            [self confirmUser];
        }
    } else {
        UIAlertView *validationAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
        
        if (authPhase == ScAuthPhaseConfirmation) {
            [validationAlert addButtonWithTitle:[ScStrings stringForKey:strTryAgain]];
            validationAlert.tag = ScAuthAlertTagConfirmationFailed;
            validationAlert.delegate = self;
        }
        
        [validationAlert show];
    }

    return shouldReturn;
}


#pragma mark - UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case ScAuthAlertTagEmailSent:
            [self setUpForUserConfirmation];
            
            if (buttonIndex == kPopUpButtonContinue) {
                [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
            } else if (buttonIndex == kPopUpButtonLater) {
                UIAlertView *seeYouLaterPopUp = [[UIAlertView alloc] initWithTitle:[ScStrings stringForKey:strSeeYouLaterPopUpTitle] message:[ScStrings stringForKey:strSeeYouLaterPopUpMessage] delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
                
                [seeYouLaterPopUp show];
            }
            
            break;
            
        case ScAuthAlertTagConfirmationFailed:
        case ScAuthAlertTagWelcomeBack:
            if (buttonIndex == kPopUpButtonGoBack) {
                [self setUpForUserRegistration];
                
                emailOrPasswordField.text = emailAsEntered;
                [passwordField becomeFirstResponder];
            }
            
            break;
        
        case ScAuthAlertTagNotLoggedIn:
            [self setUpForUserLogin];
            
            break;
            
        default:
            break;
    }
}


#pragma mark - ScServerConnectionDelegate implementation

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    [self indicatePendingServerSession:NO];
    
    if (response.statusCode < kHTTPStatusCodeErrorRangeStart) {
        if (authPhase == ScAuthPhaseRegistration) {
            [self userDidRegisterWithData:data];
        } else {
            [self userDidLogInWithData:data];
        }
    } else {
        [ScMeta m].isUserLoggedIn = NO;
        
        if (response.statusCode == kHTTPStatusCodeUnauthorized) {
            NSString *alertMessage = [ScStrings stringForKey:strNotLoggedInAlert];
            
            UIAlertView *notLoggedInAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:self cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
            notLoggedInAlert.tag = ScAuthAlertTagNotLoggedIn;
            
            [notLoggedInAlert show];
        } else {
            [ScServerConnection showAlertForHTTPStatus:response.statusCode];
        }
    }
}


- (void)didFailWithError:(NSError *)error
{
    [self indicatePendingServerSession:NO];
    
    [ScMeta m].isUserLoggedIn = NO;
    
    [ScServerConnection showAlertForError:error];
}

@end
