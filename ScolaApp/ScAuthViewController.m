//
//  ScRootViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 01.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScAuthViewController.h"

#import "NSString+ScStringExtensions.h"
#import "UIView+ScShadowEffects.h"

#import "ScAppDelegate.h"
#import "ScAppEnv.h"
#import "ScLogging.h"
#import "ScScolaMember.h"
#import "ScServerConnection.h"
#import "ScStrings.h"


static NSString * const kUserDefaultsKeyAuthId = @"scola.auth.id";
static NSString * const kUserDefaultsKeyAuthToken = @"scola.auth.token";
static NSString * const kUserDefaultsKeyAuthExpiryDate = @"scola.auth.expires";
static NSString * const kUserDefaultsKeyAuthInfo = @"scola.auth.info";

static NSString * const kSoundbiteTypewriter = @"typewriter.caf";

static NSString * const kSegueToMainView = @"authToMainView";
static NSString * const kSegueToAddressView = @"authToAddressView";

static int const kMinimumPassordLength = 6;
static int const kMinimumScolaShortnameLength = 4;

static int const kMembershipSegmentMember = 0;
static int const kMembershipSegmentNew = 1;
static int const kMembershipSegmentInvited = 2;

static NSString * const kAuthInfoKeyEmail = @"email";
static NSString * const kAuthInfoKeyName = @"name";
static NSString * const kAuthInfoKeyPasswordHash = @"passwordHash";
static NSString * const kAuthInfoKeyScolaShortname = @"scolaShortname";
static NSString * const kAuthInfoKeyRegistrationCode = @"registrationCode";
static NSString * const kAuthInfoKeyIsActive = @"isActive";
static NSString * const kAuthInfoKeyIsAuthenticated = @"isAuthenticated";
static NSString * const kAuthInfoKeyIsDeviceListed = @"isDeviceListed";
static NSString * const kAuthInfoKeyMember = @"member";

static NSTimeInterval kTimeIntervalTwoWeeks = 1209600;

static int const kPopUpButtonLogIn = 0;
static int const kPopUpButtonNewUser = 1;
static int const kPopUpButtonLater = 0;
static int const kPopUpButtonContinue = 1;
static int const kPopUpButtonGoBack = 0;
static int const kPopUpButtonTryAgain = 1;


@implementation ScAuthViewController

@synthesize darkLinenView;
@synthesize membershipPromptLabel;
@synthesize membershipStatusControl;
@synthesize userHelpLabel;
@synthesize nameOrEmailOrRegistrationCodeField;
@synthesize emailOrPasswordOrScolaShortnameField;
@synthesize chooseNewPasswordField;
@synthesize scolaDescriptionHeadingLabel;
@synthesize scolaDescriptionTextView;
@synthesize scolaSplashLabel;
@synthesize showInfoButton;
@synthesize activityIndicator;


#pragma mark - Auxiliary methods

- (NSString *)generateAuthToken:(NSDate *)expiryDate
{
    NSString *deviceUUID = [ScAppEnv env].deviceUUID;
    NSString *expiryDateAsString = expiryDate.description;
    NSString *saltyDiff = [deviceUUID diff:expiryDateAsString];
    
    return [saltyDiff hashUsingSHA1];
}


- (BOOL)isAuthTokenValid
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *authTokenAsStored = [userDefaults objectForKey:kUserDefaultsKeyAuthToken];
    NSDate *authExpiryDate = [userDefaults objectForKey:kUserDefaultsKeyAuthExpiryDate];

    BOOL isTokenValid = (authTokenAsStored && authExpiryDate);
    
    if (isTokenValid) {
        NSDate *now = [NSDate date];
        isTokenValid = ([now compare:authExpiryDate] == NSOrderedAscending);
    }        
    
    if (isTokenValid) {
        NSString *validToken = [self generateAuthToken:authExpiryDate];
        isTokenValid = [authTokenAsStored isEqualToString:validToken];
    }
    
    if (!isTokenValid) {
        [userDefaults removeObjectForKey:kUserDefaultsKeyAuthToken];
        [userDefaults removeObjectForKey:kUserDefaultsKeyAuthExpiryDate];
    }
    
    return isTokenValid;
}


- (void)setUpTypewriterAudioForSplashSequence
{
    NSURL *typewriterURL = [NSURL fileURLWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:kSoundbiteTypewriter]];
    
    NSError *error;
    typewriter1 = [[AVAudioPlayer alloc] initWithContentsOfURL:typewriterURL error:&error];
    typewriter2 = [[AVAudioPlayer alloc] initWithContentsOfURL:typewriterURL error:&error];
    
    if (typewriter1 && typewriter2) {
        [typewriter1 prepareToPlay];
        [typewriter2 prepareToPlay];
    } else {
        ScLogWarning(@"Error initialising audio: %@", error);
    }
}


- (void)runSplashSequence
{   
    [typewriter1 play];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"."
                                    waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.2];
    [typewriter2 play];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@".."
                                    waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.6];
    [typewriter1 play];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..s"
                                    waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.3];
    [typewriter2 play];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..sc"
                                    waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.4];
    [typewriter1 play];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..sco"
                                    waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.3];
    [typewriter2 play];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..scol"
                                    waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.6];
    [typewriter1 play];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..scola"
                                    waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.4];
    [typewriter2 play];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..scola."
                                    waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.2];
    [typewriter1 play];
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..scola.."
                                    waitUntilDone:YES];
}


- (void)startSplashSequenceThread
{
    NSThread *splashSequenceThread = [[NSThread alloc] initWithTarget:self selector:@selector(runSplashSequence) object:nil];
    
    [splashSequenceThread start];
}


- (void)membershipStatusDidChange
{
    NSString *namePrompt = [ScStrings stringForKey:strNamePrompt];
    NSString *nameAsReceivedPrompt = [ScStrings stringForKey:strNameAsReceivedPrompt];
    NSString *emailPrompt = [ScStrings stringForKey:strEmailPrompt];
    NSString *passwordPrompt = [ScStrings stringForKey:strPasswordPrompt];
    NSString *scolaShortnamePrompt = [ScStrings stringForKey:strScolaShortnamePrompt];
    
    switch (currentMembershipSegment) {
        case kMembershipSegmentMember:
            emailAsEntered = nameOrEmailOrRegistrationCodeField.text;
            break;
            
        case kMembershipSegmentNew:
            nameAsEntered = nameOrEmailOrRegistrationCodeField.text;
            emailAsEntered = emailOrPasswordOrScolaShortnameField.text;
            break;
            
        case kMembershipSegmentInvited:
            nameAsEntered = nameOrEmailOrRegistrationCodeField.text;
            scolaShortnameAsEntered = emailOrPasswordOrScolaShortnameField.text;
            break;
            
        default:
            break;
    }
    
    currentMembershipSegment = membershipStatusControl.selectedSegmentIndex;
    
    switch (currentMembershipSegment) {
        case kMembershipSegmentMember:
            userHelpLabel.text = [ScStrings stringForKey:strUserHelpMember];
            
            nameOrEmailOrRegistrationCodeField.placeholder = emailPrompt;
            nameOrEmailOrRegistrationCodeField.text = emailAsEntered;
            nameOrEmailOrRegistrationCodeField.keyboardType = UIKeyboardTypeEmailAddress;
            nameOrEmailOrRegistrationCodeField.autocapitalizationType = NO;

            emailOrPasswordOrScolaShortnameField.placeholder = passwordPrompt;
            emailOrPasswordOrScolaShortnameField.text = @"";
            emailOrPasswordOrScolaShortnameField.keyboardType = UIKeyboardTypeDefault;
            emailOrPasswordOrScolaShortnameField.secureTextEntry = YES;
            
            chooseNewPasswordField.hidden = YES;
            
            break;
            
        case kMembershipSegmentNew:
            userHelpLabel.text = [ScStrings stringForKey:strUserHelpNew];
            
            nameOrEmailOrRegistrationCodeField.placeholder = namePrompt;
            nameOrEmailOrRegistrationCodeField.text = nameAsEntered;
            nameOrEmailOrRegistrationCodeField.keyboardType = UIKeyboardTypeDefault;
            nameOrEmailOrRegistrationCodeField.autocapitalizationType = YES;
            
            emailOrPasswordOrScolaShortnameField.placeholder = emailPrompt;
            emailOrPasswordOrScolaShortnameField.text = emailAsEntered;
            emailOrPasswordOrScolaShortnameField.keyboardType = UIKeyboardTypeEmailAddress;
            emailOrPasswordOrScolaShortnameField.secureTextEntry = NO;
            
            chooseNewPasswordField.text = @"";
            chooseNewPasswordField.hidden = NO;
            
            break;
            
        case kMembershipSegmentInvited:
            userHelpLabel.text = [ScStrings stringForKey:strUserHelpInvited];
            
            nameOrEmailOrRegistrationCodeField.placeholder = nameAsReceivedPrompt;
            nameOrEmailOrRegistrationCodeField.text = nameAsEntered;
            nameOrEmailOrRegistrationCodeField.keyboardType = UIKeyboardTypeDefault;
            nameOrEmailOrRegistrationCodeField.autocapitalizationType = YES;
            
            emailOrPasswordOrScolaShortnameField.placeholder = scolaShortnamePrompt;
            emailOrPasswordOrScolaShortnameField.text = scolaShortnameAsEntered;
            emailOrPasswordOrScolaShortnameField.keyboardType = UIKeyboardTypeDefault;
            emailOrPasswordOrScolaShortnameField.secureTextEntry = NO;
            
            chooseNewPasswordField.text = @"";
            chooseNewPasswordField.hidden = NO;
            
            break;
            
        default:
            break;
    }
}


- (void)resignCurrentFirstResponder
{
    [self.view endEditing:YES];
}


- (NSString *)generatePasswordHash:(NSString *)password usingSalt:(NSString *)salt
{
    NSString *saltyDiff = [password diff:salt];
    
    return [saltyDiff hashUsingSHA1];
}


#pragma mark - View composition

- (void)setUpForUserLogin
{
    membershipStatusControl.enabled = YES;
    chooseNewPasswordField.hidden = YES;
    
    membershipStatusControl.selectedSegmentIndex = kMembershipSegmentMember;
    [self membershipStatusDidChange];
}


- (void)setUpForUserRegistration:(int)membershipSegment;
{
    membershipStatusControl.enabled = YES;
    chooseNewPasswordField.hidden = NO;
    
    membershipStatusControl.selectedSegmentIndex = membershipSegment;
    [self membershipStatusDidChange];
}


- (void)setUpForUserConfirmation
{
    membershipStatusControl.enabled = NO;
    chooseNewPasswordField.hidden = YES;
    
    userHelpLabel.text = [ScStrings stringForKey:strUserHelpCompleteRegistration];
    
    nameOrEmailOrRegistrationCodeField.text = @"";
    nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strRegistrationCodePrompt];
    nameOrEmailOrRegistrationCodeField.autocapitalizationType = NO;
    
    emailOrPasswordOrScolaShortnameField.text = @"";
    emailOrPasswordOrScolaShortnameField.placeholder = [ScStrings stringForKey:strRepeatPasswordPrompt];
    emailOrPasswordOrScolaShortnameField.secureTextEntry = YES;
}


- (void)goBackToUserRegistration
{
    currentMembershipSegment = membershipStatusControl.selectedSegmentIndex;
    
    [self resignCurrentFirstResponder];
    
    nameOrEmailOrRegistrationCodeField.text = [authInfo objectForKey:kAuthInfoKeyName];
    NSString *scolaShortname = [authInfo objectForKey:kAuthInfoKeyScolaShortname];
    
    if (scolaShortname) {
        emailOrPasswordOrScolaShortnameField.text = scolaShortname;
        [self setUpForUserRegistration:kMembershipSegmentInvited];
    } else {
        emailOrPasswordOrScolaShortnameField.text = [authInfo objectForKey:kAuthInfoKeyEmail];
        [self setUpForUserRegistration:kMembershipSegmentNew];
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:kUserDefaultsKeyAuthInfo];
    authInfo = nil;
}


- (void)indicatePendingServerSession:(BOOL)isPending
{
    static NSString *nameEtc;
    static NSString *nameEtcPlaceholder;
    static NSString *emailEtc;
    static NSString *emailEtcPlaceholder;
    
    if (isPending) {
        nameEtc = nameOrEmailOrRegistrationCodeField.text;
        nameEtcPlaceholder = nameOrEmailOrRegistrationCodeField.placeholder;
        emailEtc = emailOrPasswordOrScolaShortnameField.text;
        emailEtcPlaceholder = emailOrPasswordOrScolaShortnameField.placeholder;
        
        nameOrEmailOrRegistrationCodeField.text = @"";
        nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strPleaseWait];
        emailOrPasswordOrScolaShortnameField.text = @"";
        emailOrPasswordOrScolaShortnameField.placeholder = [ScStrings stringForKey:strPleaseWait];
        
        chooseNewPasswordField.hidden = YES;
        membershipStatusControl.enabled = NO;
        
        isEditingAllowed = NO;
        [activityIndicator startAnimating];
    } else {
        nameOrEmailOrRegistrationCodeField.text = nameEtc;
        nameOrEmailOrRegistrationCodeField.placeholder = nameEtcPlaceholder;
        emailOrPasswordOrScolaShortnameField.text = emailEtc;
        emailOrPasswordOrScolaShortnameField.placeholder = emailEtcPlaceholder;
        
        isEditingAllowed = YES;
        [activityIndicator stopAnimating];
    }
}


#pragma mark - Input validation

- (BOOL)isNameValid
{
    BOOL isValid = NO;
    
    if (currentMembershipSegment == kMembershipSegmentMember) {
        ScLogBreakage(@"Attempt to validate name while in 'Member' segment");
    } else {
        nameAsEntered = nameOrEmailOrRegistrationCodeField.text;
        isValid = ([nameAsEntered rangeOfString:@" "].location != NSNotFound);
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
    
    if (currentMembershipSegment == kMembershipSegmentMember) {
        emailField = nameOrEmailOrRegistrationCodeField;
    } else {
        emailField = emailOrPasswordOrScolaShortnameField;
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
    UITextField *passwordField;
    
    if (currentMembershipSegment == kMembershipSegmentMember) {
        passwordField = emailOrPasswordOrScolaShortnameField;
    } else {
        passwordField = chooseNewPasswordField;
    }
    
    isValid = (passwordField.text.length >= kMinimumPassordLength);
    
    if (!isValid) {
        passwordField.text = @"";
        [passwordField becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)isScolaShortnameValid
{
    BOOL isValid = NO;
    
    if (currentMembershipSegment == kMembershipSegmentInvited) {
        scolaShortnameAsEntered = emailOrPasswordOrScolaShortnameField.text;
        isValid = (scolaShortnameAsEntered.length >= kMinimumScolaShortnameLength);
    } else {
        ScLogBreakage(@"Attempt to validate Scola shortname while not in 'Invited' segment");
    }
    
    if (!isValid) {
        [emailOrPasswordOrScolaShortnameField becomeFirstResponder];
    }
    
    return isValid;
}


#pragma mark - User registration and authentication

- (void)loginUser
{
    authPhase = ScAuthPhaseLogin;

    emailAsEntered = nameOrEmailOrRegistrationCodeField.text;
    NSString *password = emailOrPasswordOrScolaShortnameField.text;
    
    [self indicatePendingServerSession:YES];
    
    serverConnection = [[ScServerConnection alloc] initForAuthPhase:ScAuthPhaseLogin];
    [serverConnection setAuthHeaderUsingId:emailAsEntered andPassword:password];
    [serverConnection setValue:[ScAppEnv env].deviceName forURLParameter:kURLParameterName];
    [serverConnection getRemoteClass:@"ScScolaMember" usingDelegate:self];
}


- (void)registerNewUser
{
    authPhase = ScAuthPhaseRegistration;
    
    nameAsEntered = nameOrEmailOrRegistrationCodeField.text;
    emailAsEntered = emailOrPasswordOrScolaShortnameField.text;
    NSString *password = chooseNewPasswordField.text;
    
    [self indicatePendingServerSession:YES];
    
    serverConnection = [[ScServerConnection alloc] initForAuthPhase:ScAuthPhaseRegistration];
    [serverConnection setAuthHeaderUsingId:emailAsEntered andPassword:password];
    [serverConnection setValue:nameAsEntered forURLParameter:kURLParameterName];
    [serverConnection getRemoteClass:@"ScAuthInfo" usingDelegate:self];
}


- (void)registerInvitedUser
{
    // TODO
}


- (void)confirmNewUser
{
    authPhase = ScAuthPhaseConfirmation;
    
    nameAsEntered = [authInfo objectForKey:kAuthInfoKeyName];
    emailAsEntered = [authInfo objectForKey:kAuthInfoKeyEmail];
    NSString *password = emailOrPasswordOrScolaShortnameField.text;
    
    [self indicatePendingServerSession:YES];
    
    serverConnection = [[ScServerConnection alloc] initForAuthPhase:ScAuthPhaseConfirmation];
    [serverConnection setAuthHeaderUsingId:emailAsEntered andPassword:password];
    [serverConnection getRemoteClass:@"ScScolaMember" usingDelegate:self];
}


- (void)userDidLogIn:(NSString *)authId isNewUser:(BOOL)isNew
{
    NSDate *authExpiryDate  = [NSDate dateWithTimeIntervalSinceNow:1];
    //NSDate *authExpiryDate  = [NSDate dateWithTimeIntervalSinceNow:kTimeIntervalTwoWeeks];
    NSString *authToken = [self generateAuthToken:authExpiryDate];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:authId forKey:kUserDefaultsKeyAuthId];
    [userDefaults setObject:authToken forKey:kUserDefaultsKeyAuthToken];
    [userDefaults setObject:authExpiryDate forKey:kUserDefaultsKeyAuthExpiryDate];
    
    if (isNew) {
        ScManagedObjectContext *context = [ScAppEnv env].managedObjectContext;
        ScScolaMember *member = [context entityForClass:ScScolaMember.class];
        
        member.name = nameAsEntered;
        member.email = emailAsEntered;
        
        [context save];
        
        [self performSegueWithIdentifier:kSegueToAddressView sender:self];
    } else {
        [self performSegueWithIdentifier:kSegueToMainView sender:self];
    }
}


#pragma mark - Process server response

- (void)didReceiveServerAvailabilityStatus:(NSNotification *)notification
{
    if ([ScAppEnv env].isServerAvailable) {
        [ScStrings refreshStrings];
    } else {
        NSString *alertMessage = [ScStrings stringForKey:strServerUnavailableAlert];
        
        UIAlertView *serverUnavailableAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
        [serverUnavailableAlert show];
        
        isEditingAllowed = NO;
    }
}


- (void)didReceiveLoginResponse:(NSHTTPURLResponse *)response
{
    if (response.statusCode == kHTTPStatusCodeNoContent) {
        [self userDidLogIn:emailAsEntered isNewUser:NO];
    } else if (response.statusCode == kHTTPStatusCodeUnauthorized) {
        NSString *alertMessage = [ScStrings stringForKey:strNotLoggedInAlert];
        
        UIAlertView *notLoggedInAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:self cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
        notLoggedInAlert.tag = ScAuthPopUpTagNotLoggedIn;
        
        [notLoggedInAlert show];
    }
}


- (void)didReceiveRegistrationResponse:(NSHTTPURLResponse *)response
{
    if (response.statusCode == kHTTPStatusCodeNotFound) {
        NSString *alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strScolaInvitationNotFoundAlert], scolaShortnameAsEntered];
        
        UIAlertView *notFoundAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:self cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
        notFoundAlert.tag = ScAuthPopUpTagScolaInvitationNotFound;
        
        [notFoundAlert show];
        
        isEditingAllowed = YES;
    }
}


- (void)didReceiveConfirmationResponse:(NSHTTPURLResponse *)response
{
    if (response.statusCode == kHTTPStatusCodeNoContent) {
        [self userDidLogIn:emailAsEntered isNewUser:YES];
    } else {
        ScLogBreakage(@"Unexpected server response for user confirmation: %@", response);
    }
}


- (void)finishedReceivingRegistrationData:(NSDictionary *)data
{
    authInfo = data;
    
    BOOL isActive = [[data objectForKey:kAuthInfoKeyIsActive] boolValue];
    BOOL isAuthenticated = [[data objectForKey:kAuthInfoKeyIsAuthenticated] boolValue];

    if (!isActive) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:authInfo forKey:kUserDefaultsKeyAuthInfo];
        
        NSString *email = [authInfo objectForKey:kAuthInfoKeyEmail];
        NSString *popUpTitle = [ScStrings stringForKey:strEmailSentPopUpTitle];
        NSString *popUpMessage = [NSString stringWithFormat:[ScStrings stringForKey:strEmailSentPopUpMessage], email];
        NSString *laterButtonTitle = [ScStrings stringForKey:strLater];
        NSString *continueButtonTitle = [ScStrings stringForKey:strHaveAccess];
        
        UIAlertView *emailSentPopUp = [[UIAlertView alloc] initWithTitle:popUpTitle message:popUpMessage delegate:self cancelButtonTitle:laterButtonTitle otherButtonTitles:continueButtonTitle, nil];
        emailSentPopUp.tag = ScAuthPopUpTagEmailSent;
        
        [emailSentPopUp show];
    } else {
        NSString *alertMessage;
        ScAuthPopUpTag alertTag;
        
        NSString *alertTitle = [ScStrings stringForKey:strUserExistsAlertTitle];
        
        if (isAuthenticated) {
            alertMessage = [ScStrings stringForKey:strUserExistsAndLoggedInAlert];
            alertTag = ScAuthPopUpTagUserExistsAndIsLoggedIn;
        } else {
            alertMessage = [ScStrings stringForKey:strUserExistsButNotLoggedInAlert];
            alertTag = ScAuthPopUpTagNotLoggedIn;
        }
        
        UIAlertView *userExistsAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
        userExistsAlert.tag = alertTag;
        
        [userExistsAlert show];
    }
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

    if ([self isAuthTokenValid]) {
        [self performSegueWithIdentifier:kSegueToMainView sender:self];
    } else {
        if ([ScAppEnv env].isInternetConnectionAvailable) {
            NSNotificationCenter *notificationCentre = [NSNotificationCenter defaultCenter];
            serverConnection = [[ScServerConnection alloc] init];
            
            [notificationCentre addObserver:self selector:@selector(didReceiveServerAvailabilityStatus:) name:kServerAvailabilityNotification object:nil];
            [serverConnection checkServerAvailability];
        }
        
        [darkLinenView addGradientLayer];
        [darkLinenView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignCurrentFirstResponder)]];
        
        //[self setUpTypewriterAudioForSplashSequence]; // TODO: Comment back in!
        scolaSplashLabel.text = @"";
        
        isEditingAllowed = YES;
        nameOrEmailOrRegistrationCodeField.delegate = self;
        emailOrPasswordOrScolaShortnameField.delegate = self;
        chooseNewPasswordField.delegate = self;
        chooseNewPasswordField.secureTextEntry = YES;
        activityIndicator.hidesWhenStopped = YES;

        membershipPromptLabel.text = [ScStrings stringForKey:strMembershipPrompt];
        [membershipStatusControl setTitle:[ScStrings stringForKey:strIsNew] forSegmentAtIndex:kMembershipSegmentNew];
        [membershipStatusControl setTitle:[ScStrings stringForKey:strIsInvited] forSegmentAtIndex:kMembershipSegmentInvited];
        [membershipStatusControl setTitle:[ScStrings stringForKey:strIsMember] forSegmentAtIndex:kMembershipSegmentMember];
        [membershipStatusControl addTarget:self action:@selector(membershipStatusDidChange) forControlEvents:UIControlEventValueChanged];
        
        chooseNewPasswordField.placeholder = [ScStrings stringForKey:strNewPasswordPrompt];
        scolaDescriptionTextView.text = [ScStrings stringForKey:strScolaDescription];
    }
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
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    [self navigationController].navigationBarHidden = YES;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    authInfo = [userDefaults objectForKey:kUserDefaultsKeyAuthInfo];
    
    if (authInfo) {
        if ([authInfo objectForKey:kAuthInfoKeyScolaShortname]) {
            membershipStatusControl.selectedSegmentIndex = kMembershipSegmentInvited;
        } else {
            membershipStatusControl.selectedSegmentIndex = kMembershipSegmentNew;
        }
        
        [self setUpForUserConfirmation];
    } else {
        [self setUpForUserLogin];
        
        NSString *email = [userDefaults objectForKey:kUserDefaultsKeyAuthId];
        
        if (email) {
            nameOrEmailOrRegistrationCodeField.text = email;
            [emailOrPasswordOrScolaShortnameField becomeFirstResponder];
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self startSplashSequenceThread];
    
    if (authInfo) {
        NSString *email = [authInfo objectForKey:kAuthInfoKeyEmail];
        NSString *popUpTitle = [ScStrings stringForKey:strWelcomeBackPopUpTitle];
        NSString *popUpMessage = [NSString stringWithFormat:[ScStrings stringForKey:strWelcomeBackPopUpMessage], email];
        NSString *continueButtonTitle = [ScStrings stringForKey:strHaveCode];
        NSString *goBackButtonTitle = [ScStrings stringForKey:strGoBack];
        
        UIAlertView *welcomeBackPopUp = [[UIAlertView alloc] initWithTitle:popUpTitle message:popUpMessage delegate:self cancelButtonTitle:goBackButtonTitle otherButtonTitles:continueButtonTitle, nil];
        welcomeBackPopUp.tag = ScAuthPopUpTagWelcomeBack;
        
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


#pragma mark - IBAction implementation

- (IBAction)showInfo:(id)sender
{
    // TODO: Using this for various test purposes now, keep in mind to fix later
    
    [self performSegueWithIdentifier:kSegueToAddressView sender:self];
}


#pragma mark - UITextFieldDelegate implementation

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return isEditingAllowed;
}


- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    BOOL shouldRemove = YES;
    
    if (currentMembershipSegment == kMembershipSegmentMember) {
        shouldRemove = (textField != emailOrPasswordOrScolaShortnameField);
    } else {
        shouldRemove = (textField != chooseNewPasswordField);
    }

    if (shouldRemove) {
        NSString *text = textField.text;
        textField.text = [text removeLeadingAndTrailingSpaces];
    }
    
    return YES;
}


- (BOOL)textFieldShouldReturnForUserRegistration:(UITextField *)textField
{
    BOOL emailIsRegistered = NO;
    BOOL shouldReturn = NO;
    
    NSString *alertMessage = nil;
    
    switch (currentMembershipSegment) {
        case kMembershipSegmentMember:
            if (![self isEmailValid]) {
                alertMessage = [ScStrings stringForKey:strInvalidEmailAlert];
            } else if (![self isPasswordValid]) {
                alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strInvalidPasswordAlert], kMinimumPassordLength];
            }
            
            break;
            
        case kMembershipSegmentNew:
            if (![self isNameValid]) {
                alertMessage = [ScStrings stringForKey:strInvalidNameAlert];
            } else if (![self isEmailValid]) {
                alertMessage = [ScStrings stringForKey:strInvalidEmailAlert];
            } else if (![self isPasswordValid]) {
                alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strInvalidPasswordAlert], kMinimumPassordLength];
            }
            
            if (!alertMessage) {
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                NSString *userId = [userDefaults objectForKey:kUserDefaultsKeyAuthId];
                
                emailIsRegistered =
                    [userId isEqualToString:emailOrPasswordOrScolaShortnameField.text];
            }
            
            break;
            
        case kMembershipSegmentInvited:
            if (![self isNameValid]) {
                alertMessage = [ScStrings stringForKey:strInvalidNameAlert];
            } else if (![self isScolaShortnameValid]) {
                alertMessage = [ScStrings stringForKey:strInvalidScolaShortnameAlert];
            } else if (![self isPasswordValid]) {
                alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strInvalidPasswordAlert], kMinimumPassordLength];
            }
            
            break;
            
        default:
            break;
    }
    
    shouldReturn = (!alertMessage && !emailIsRegistered);
    
    if (shouldReturn) {
        [textField resignFirstResponder];
        
        if (currentMembershipSegment == kMembershipSegmentMember) {
            [self loginUser];
        } else if (currentMembershipSegment == kMembershipSegmentNew) {
            [self registerNewUser];
        } else {
            [self registerInvitedUser];
        }
    } else if (emailIsRegistered) {
        NSString *email = emailOrPasswordOrScolaShortnameField.text;
        alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strEmailAlreadyRegisteredAlert], email];
        NSString *logInButtonTitle = [ScStrings stringForKey:strLogIn];
        NSString *newUserButtonTitle = [ScStrings stringForKey:strNewUser];
        
        UIAlertView *emailRegisteredAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:self cancelButtonTitle:logInButtonTitle otherButtonTitles:newUserButtonTitle, nil];
        emailRegisteredAlert.tag = ScAuthPopUpTagEmailAlreadyRegistered;
        
        [emailRegisteredAlert show];
    } else {
        UIAlertView *popUpAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
        [popUpAlert show];
    }
    
    return shouldReturn;
}


- (BOOL)textFieldShouldReturnForUserConfirmation:(UITextField *)textField
{
    BOOL doRegistrationCodesMatch = NO;
    BOOL doPasswordsMatch = NO;
    
    NSString *registrationCodeAsSent = [[authInfo objectForKey:kAuthInfoKeyRegistrationCode] lowercaseString];
    NSString *registrationCodeAsEntered = [nameOrEmailOrRegistrationCodeField.text lowercaseString];
    
    NSString *alertMessage = nil;
    ScAuthPopUpTag alertTag;
    
    doRegistrationCodesMatch = [registrationCodeAsEntered isEqualToString:registrationCodeAsSent];
    
    if (doRegistrationCodesMatch) {
        NSString *email = [authInfo objectForKey:kAuthInfoKeyEmail];
        NSString *password = emailOrPasswordOrScolaShortnameField.text;
        
        NSString *passwordHashFromServer = [authInfo objectForKey:kAuthInfoKeyPasswordHash];
        NSString *passwordHashAsEntered = [self generatePasswordHash:password usingSalt:email];
        
        doPasswordsMatch = [passwordHashAsEntered isEqualToString:passwordHashFromServer];
    }
    
    if (!doRegistrationCodesMatch) {
        alertMessage = [ScStrings stringForKey:strRegistrationCodesDoNotMatchAlert];
        alertTag = ScAuthPopUpTagRegistrationCodesDoNotMatch;
    } else if (!doPasswordsMatch) {
        alertMessage = [ScStrings stringForKey:strPasswordsDoNotMatchAlert];
        alertTag = ScAuthPopUpTagPasswordsDoNotMatch;
    }
    
    BOOL shouldReturn = doRegistrationCodesMatch && doPasswordsMatch;
    
    if (shouldReturn) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults removeObjectForKey:kUserDefaultsKeyAuthInfo];
        
        [self confirmNewUser];
    } else {        
        NSString *tryAgainTitle = [ScStrings stringForKey:strTryAgain];
        NSString *goBackTitle = [ScStrings stringForKey:strGoBack];
        
        UIAlertView *popUpAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:self cancelButtonTitle:goBackTitle otherButtonTitles:tryAgainTitle, nil];
        popUpAlert.tag = alertTag;
        
        [popUpAlert show];
    }
    
    return shouldReturn;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    BOOL shouldReturn = NO;
    
    [self textFieldShouldEndEditing:textField];
    
    if (authInfo) {
        shouldReturn = [self textFieldShouldReturnForUserConfirmation:textField];
    } else {
        shouldReturn = [self textFieldShouldReturnForUserRegistration:textField];
    }
    
    return shouldReturn;
}


#pragma mark - UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case ScAuthPopUpTagInternalServerError:
            break;
        
        case ScAuthPopUpTagEmailAlreadyRegistered:
            if (buttonIndex == kPopUpButtonLogIn) {
                NSString *password = chooseNewPasswordField.text;
                
                [self setUpForUserLogin];
                emailOrPasswordOrScolaShortnameField.text = password;
                [self loginUser];
            } else if (buttonIndex == kPopUpButtonNewUser) {
                [self setUpForUserRegistration:kMembershipSegmentNew];
                
                emailOrPasswordOrScolaShortnameField.text = @"";
                [emailOrPasswordOrScolaShortnameField becomeFirstResponder];
            }
            
            break;
            
        case ScAuthPopUpTagEmailSent:
            [self setUpForUserConfirmation];
            
            if (buttonIndex == kPopUpButtonContinue) {
                [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
            } else if (buttonIndex == kPopUpButtonLater) {
                NSString *popUpTitle = [ScStrings stringForKey:strSeeYouLaterPopUpTitle];
                NSString *popUpMessage = [ScStrings stringForKey:strSeeYouLaterPopUpMessage];
                
                UIAlertView *seeYouLaterPopUp = [[UIAlertView alloc] initWithTitle:popUpTitle message:popUpMessage delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
                [seeYouLaterPopUp show];
            }
            
            break;
            
        case ScAuthPopUpTagRegistrationCodesDoNotMatch:
        case ScAuthPopUpTagPasswordsDoNotMatch:
            if (buttonIndex == kPopUpButtonTryAgain) {
                if (alertView.tag == ScAuthPopUpTagRegistrationCodesDoNotMatch) {
                    [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
                } else if (alertView.tag == ScAuthPopUpTagPasswordsDoNotMatch) {
                    emailOrPasswordOrScolaShortnameField.text = @"";
                    [emailOrPasswordOrScolaShortnameField becomeFirstResponder];
                }
            } else if (buttonIndex == kPopUpButtonGoBack) {
                [self goBackToUserRegistration];
            }
            
            break;

        case ScAuthPopUpTagScolaInvitationNotFound:
            [self setUpForUserRegistration:kMembershipSegmentInvited];
            [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
            
            break;
            
        case ScAuthPopUpTagWelcomeBack:
            if (buttonIndex == kPopUpButtonContinue) {
                [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
            } else if (buttonIndex == kPopUpButtonGoBack) {
                [self goBackToUserRegistration];
            }
            
            break;
        
        case ScAuthPopUpTagUserExistsAndIsLoggedIn:
            [self userDidLogIn:emailAsEntered isNewUser:NO];

            break;
            
        case ScAuthPopUpTagNotLoggedIn:
            [self setUpForUserLogin];
            [emailOrPasswordOrScolaShortnameField becomeFirstResponder];
            
            break;
            
        default:
            break;
    }
}


#pragma mark - ScServerConnectionDelegate implementation

- (void)willSendRequest:(NSURLRequest *)request
{
    ScLogInfo(@"Sending asynchronous HTTP request with URL: %@", request.URL);
}


- (void)didReceiveResponse:(NSHTTPURLResponse *)response
{
    ScLogDebug(@"Received response. HTTP status code: %d", response.statusCode);

    if (response.statusCode != kHTTPStatusCodeOK) {
        [self indicatePendingServerSession:NO];
    }

    if (response.statusCode == kHTTPStatusCodeInternalServerError) {
        UIAlertView *internalErrorAlert = [[UIAlertView alloc] initWithTitle:nil message:[ScStrings stringForKey:strInternalServerError] delegate:self cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
        internalErrorAlert.tag = ScAuthPopUpTagInternalServerError;
        
        [internalErrorAlert show];
    } else if (authPhase == ScAuthPhaseLogin) {
        [self didReceiveLoginResponse:response];
    } else if (authPhase == ScAuthPhaseRegistration) {
        [self didReceiveRegistrationResponse:response]; // TODO: Deal with invitation here
    } else if (authPhase == ScAuthPhaseConfirmation) {
        [self didReceiveConfirmationResponse:response];
    }
}


- (void)finishedReceivingData:(NSDictionary *)data
{
    [self indicatePendingServerSession:NO];
    
    if (serverConnection.HTTPStatusCode == kHTTPStatusCodeOK) {
        ScLogDebug(@"Received data: %@", data);
        
        if (authPhase == ScAuthPhaseRegistration) {
            [self finishedReceivingRegistrationData:data];
        } else {
            ScLogBreakage(@"Received data for non-registration auth phase ($d)", authPhase);
        }
    }
}


@end
