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
#import "ScScola.h"

#import "ScMainViewController.h"
#import "ScRegistrationView1Controller.h"

typedef enum {
    ScAuthAlertTagEmailSent,
    ScAuthAlertTagConfirmationFailed,
    ScAuthAlertTagWelcomeBack,
    ScAuthAlertTagNotLoggedIn,
} ScAuthAlertTag;

static NSString * const kSoundbiteTypewriter = @"typewriter.caf";

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

static NSTimeInterval const kTimeIntervalTwoWeeks = 1209600;

static int const kPopUpButtonLater = 0;
static int const kPopUpButtonContinue = 1;
static int const kPopUpButtonGoBack = 0;


@implementation ScAuthViewController

@synthesize darkLinenView;
@synthesize userIntentionPromptLabel;
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
    
    [NSThread sleepForTimeInterval:0.6];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..s"
                                    waitUntilDone:YES];
    
    [NSThread sleepForTimeInterval:0.3];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..sc"
                                    waitUntilDone:YES];
    
    [NSThread sleepForTimeInterval:0.4];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..sco"
                                    waitUntilDone:YES];
    
    [NSThread sleepForTimeInterval:0.3];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..scol"
                                    waitUntilDone:YES];
    
    [NSThread sleepForTimeInterval:0.6];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..scola"
                                    waitUntilDone:YES];
    
    [NSThread sleepForTimeInterval:0.4];
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


#pragma mark - View composition

- (void)userIntentionDidChange
{
    if (authPhase == ScAuthPhaseLogin) {
        emailAsEntered = nameOrEmailOrRegistrationCodeField.text;
    } else if (authPhase == ScAuthPhaseRegistration) {
        nameAsEntered = nameOrEmailOrRegistrationCodeField.text;
        emailAsEntered = emailOrPasswordField.text;
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
    emailOrPasswordField.text = emailAsEntered;
    emailOrPasswordField.keyboardType = UIKeyboardTypeEmailAddress;
    emailOrPasswordField.secureTextEntry = NO;
    
    passwordField.text = @"";
    passwordField.hidden = NO;
    
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
    nameOrEmailOrRegistrationCodeField.clearButtonMode = UITextFieldViewModeNever;
    
    emailOrPasswordField.placeholder = [ScStrings stringForKey:strRepeatPasswordPrompt];
    emailOrPasswordField.text = @"";
    emailOrPasswordField.keyboardType = UIKeyboardTypeDefault;
    emailOrPasswordField.secureTextEntry = YES;
    
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
        
        nameOrEmailOrRegistrationCodeField.placeholder = nameEtcPlaceholder;
        nameOrEmailOrRegistrationCodeField.text = nameEtc;
        emailOrPasswordField.placeholder = emailEtcPlaceholder;
        emailOrPasswordField.text = emailEtc;
        
        userIntentionControl.enabled = YES;
        isEditingAllowed = YES;
        
        if (authPhase == ScAuthPhaseRegistration) {
            [self setUpForUserRegistration];
        } else if (authPhase == ScAuthPhaseConfirmation) {
            userIntentionControl.selectedSegmentIndex = UISegmentedControlNoSegment;
        }
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
    [ScMeta m].isUserLoggedIn = YES;
    
    NSString *password = emailOrPasswordField.text;
    
    serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:emailAsEntered withPassword:password];
    [serverConnection setValue:[ScMeta m].homeScolaId forURLParameter:kURLParameterScolaId];
    [serverConnection authenticateForPhase:ScAuthPhaseConfirmation usingDelegate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)userDidLogIn
{
    [ScMeta m].isUserLoggedIn = YES;
    
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    
    if (authPhase == ScAuthPhaseLogin) {
        member = [context fetchEntityWithId:[ScMeta m].userId];
        homeScola = [context fetchEntityWithId:member.scolaId];
        
        [ScMeta m].homeScolaId = homeScola.entityId;
        
        ScDevice *device = [context fetchEntityWithId:[ScMeta m].deviceId];
        
        if (!device) {
            device = [context entityForClass:ScDevice.class inScola:homeScola withId:[ScMeta m].deviceId];
            device.type = [UIDevice currentDevice].model;
            device.displayName = [UIDevice currentDevice].name;
            device.member = member;
            
            [context saveAndPersist];
        }
        
        [self performSegueWithIdentifier:kSegueToMainView sender:self];
    } else if (authPhase == ScAuthPhaseConfirmation) {
        if (isUserListed) {
            homeScola = [context fetchEntityWithId:[ScMeta m].homeScolaId];
            member = [context fetchEntityWithId:[ScMeta m].userId];
        } else {
            homeScola = [context entityForScolaWithName:[ScStrings stringForKey:strMyPlace] scolaId:[ScMeta m].homeScolaId];
            member = [context entityForClass:ScMember.class inScola:homeScola withId:emailAsEntered];
        }
        
        member.name = nameAsEntered;
        member.passwordHash = [authInfo objectForKey:kAuthInfoKeyPasswordHash];
        
        [ScMeta removeUserDefaultForKey:kUserDefaultsKeyAuthInfo];
        authInfo = nil;
        
        [self performSegueWithIdentifier:kSegueToRegistrationView1 sender:self];
    }
}


#pragma mark - Process data from server

- (void)finishedReceivingLoginData:(NSArray *)data
{
    [[ScMeta m].managedObjectContext saveWithDictionaries:data];
    
    isUpToDate = YES;
    
    [self userDidLogIn];
}


- (void)finishedReceivingRegistrationData:(NSDictionary *)data
{
    authInfo = data;
    
    isUserListed = [[authInfo objectForKey:kAuthInfoKeyIsListed] boolValue];
    BOOL userDidRegister = [[authInfo objectForKey:kAuthInfoKeyIsRegistered] boolValue];

    if (!userDidRegister) {
        NSData *authInfoArchive = [NSKeyedArchiver archivedDataWithRootObject:authInfo];
        [ScMeta setUserDefault:authInfoArchive forKey:kUserDefaultsKeyAuthInfo];
        
        NSString *alertTitle = nil;
        NSString *alertMessage = nil;
        
        if (isUserListed) {
            [ScMeta m].homeScolaId = [authInfo objectForKey:kAuthInfoKeyHomeScolaId];
            
            alertTitle = [ScStrings stringForKey:strEmailSentToInviteeAlertTitle];
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


#pragma mark - View lifecycle

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([[ScMeta m] isUserLoggedIn]) {
        [self performSegueWithIdentifier:kSegueToMainView sender:self];
    } else {
        [darkLinenView addGradientLayer];
        [darkLinenView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignCurrentFirstResponder)]];
        
        isEditingAllowed = YES;
        nameOrEmailOrRegistrationCodeField.delegate = self;
        emailOrPasswordField.delegate = self;
        passwordField.delegate = self;
        passwordField.secureTextEntry = YES;
        activityIndicator.hidesWhenStopped = YES;

        userIntentionPromptLabel.text = [ScStrings stringForKey:strUserIntentionPrompt];
        [userIntentionControl setTitle:[ScStrings stringForKey:strUserIntentionRegistration] forSegmentAtIndex:kUserIntentionRegistration];
        [userIntentionControl setTitle:[ScStrings stringForKey:strUserIntentionLogin] forSegmentAtIndex:kUserIntentionLogin];
        [userIntentionControl addTarget:self action:@selector(userIntentionDidChange) forControlEvents:UIControlEventValueChanged];
        
        passwordField.placeholder = [ScStrings stringForKey:strNewPasswordPrompt];
        scolaDescriptionTextView.text = [ScStrings stringForKey:strScolaDescription];
    }
}


- (void)viewDidUnload
{
    [super viewDidUnload];
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
        [self setUpForUserLogin];
        
        if ([ScMeta m].userId) {
            nameOrEmailOrRegistrationCodeField.text = [ScMeta m].userId;
            [emailOrPasswordField becomeFirstResponder];
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
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToMainView]) {
        if (!isUpToDate) {
            [[[ScServerConnection alloc] init] fetchEntities];
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
    NSString *cancelButtonTitle = [ScStrings stringForKey:strOK];
    
    [self textFieldShouldEndEditing:textField];
    
    switch (authPhase) {
        case ScAuthPhaseLogin:
            if (![self isEmailValid]) {
                alertMessage = [ScStrings stringForKey:strInvalidEmailAlert];
            } else if (![self isPasswordValid]) {
                alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strInvalidPasswordAlert], kMinimumPassordLength];
            }
            
            break;
            
        case ScAuthPhaseRegistration:
            if (![self isNameValid]) {
                alertMessage = [ScStrings stringForKey:strInvalidNameAlert];
            } else if (![self isEmailValid]) {
                alertMessage = [ScStrings stringForKey:strInvalidEmailAlert];
            } else if (![self isPasswordValid]) {
                alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strInvalidPasswordAlert], kMinimumPassordLength];
            }
            
            break;
            
        case ScAuthPhaseConfirmation:
            if (![self isRegistrationCodeValid]) {
                alertMessage = [ScStrings stringForKey:strRegistrationCodesDoNotMatchAlert];
            } else if (![self isPasswordValid]) {
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
        UIAlertView *validationAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
        
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
            if (buttonIndex == kPopUpButtonGoBack) {
                [self setUpForUserRegistration];
                [passwordField becomeFirstResponder];
            }
            
            break;

        case ScAuthAlertTagWelcomeBack:
            if (buttonIndex == kPopUpButtonContinue) {
                [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
            } else if (buttonIndex == kPopUpButtonGoBack) {
                [self setUpForUserRegistration];
                [passwordField becomeFirstResponder];
            }
            
            break;
        
        case ScAuthAlertTagNotLoggedIn:
            [self setUpForUserLogin];
            [emailOrPasswordField becomeFirstResponder];
            
            break;
            
        default:
            break;
    }
}


#pragma mark - ScServerConnectionDelegate implementation

- (BOOL)doUseAutomaticAlerts
{
    return NO;
}


- (void)didReceiveResponse:(NSHTTPURLResponse *)response
{
    ScLogDebug(@"Received response. HTTP status code: %d", response.statusCode);
    
    NSInteger status = response.statusCode;
    
    if (status != kHTTPStatusCodeOK) {
        [self indicatePendingServerSession:NO];
    }
    
    if (((authPhase == ScAuthPhaseLogin) && (status == kHTTPStatusCodeNotModified)) ||
        ((authPhase == ScAuthPhaseConfirmation) && (status == kHTTPStatusCodeNoContent))) {
        [self userDidLogIn];
    } else if (status >= kHTTPStatusCodeErrorRangeStart) {
        [ScMeta m].isUserLoggedIn = NO;
        
        if (status == kHTTPStatusCodeUnauthorized) {
            NSString *alertMessage = [ScStrings stringForKey:strNotLoggedInAlert];
            
            UIAlertView *notLoggedInAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:self cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
            notLoggedInAlert.tag = ScAuthAlertTagNotLoggedIn;
            
            [notLoggedInAlert show];
        } else {
            [ScServerConnection showAlertForHTTPStatus:status];
        }
    }
}


- (void)finishedReceivingData:(id)data
{
    [self indicatePendingServerSession:NO];
    
    if (authPhase == ScAuthPhaseRegistration) {
        [self finishedReceivingRegistrationData:data];
    } else {
        [self finishedReceivingLoginData:data];
    }
}


- (void)didFailWithError:(NSError *)error
{
    [self indicatePendingServerSession:NO];
    [ScMeta m].isUserLoggedIn = NO;
    
    [ScServerConnection showAlertForError:error];
}

@end
