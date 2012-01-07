//
//  ScRootViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 01.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScAuthViewController.h"

#import "NSString+ScStringExtensions.h"

#import "ScAppDelegate.h"
#import "ScAppEnv.h"
#import "ScLogging.h"
#import "ScRegisterUserController.h"
#import "ScServerConnection.h"
#import "ScStrings.h"

static NSString * const kUserDefaultsKeyAuthToken = @"scola.authtoken";
static NSString * const kUserDefaultsKeyAuthState = @"scola.authstate";

static NSString * const kSoundbiteTypewriter = @"typewriter.caf";

static NSString * const kSegueToMainPage = @"rootViewToMainPage";

static int const kMinimumPassordLength = 6;
static int const kMinimumScolaShortnameLength = 4;

static int const kMembershipSegmentMember = 0;
static int const kMembershipSegmentNew = 1;
static int const kMembershipSegmentInvited = 2;

static NSString * const kUIStateKeyName = @"name";
static NSString * const kUIStateKeyNamePlaceholder = @"namePlaceholder";
static NSString * const kUIStateKeyEmail = @"email";
static NSString * const kUIStateKeyEmailPlaceholder = @"emailPlaceholder";

static NSString * const kAuthInfoKeyEmail = @"email";
static NSString * const kAuthInfoKeyName = @"name";
static NSString * const kAuthInfoKeyPasswordHash = @"passwordHash";
static NSString * const kAuthInfoKeyScolaShortname = @"scolaShortname";
static NSString * const kAuthInfoKeyRegistrationCode = @"registrationCode";
static NSString * const kAuthInfoKeyIsActive = @"isActive";
static NSString * const kAuthInfoKeyIsAuthenticated = @"isAuthenticated";
static NSString * const kAuthInfoKeyIsDeviceListed = @"isDeviceListed";

static NSString * const kServerReason = @"reason";
static NSString * const kServerReasonScolaNotFound = @"scola";
static NSString * const kServerReasonInvitationNotFound = @"name";

static int const kInternalErrorPopUpTag = 0;
static int const kEmailSentPopUpTag = 1;
static int const kRegistrationCodesDoNotMatchPopUpTag = 2;
static int const kPasswordsDoNotMatchPopUpTag = 3;
static int const kWelcomeBackPopUpTag = 4;
static int const kScolaNotFoundPopUpTag = 5;
static int const kInvitationNotFoundPopUpTag = 6;
static int const kUserExistsButNotLoggedInPopUpTag = 7;
static int const kUserExistsAndLoggedInPopUpTag = 8;

static int const kPopUpButtonLater = 0;
static int const kPopUpButtonGoBack = 0;
static int const kPopUpButtonContinue = 1;
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


#pragma mark - Internal methods

- (BOOL)isValidAuthToken:(NSString *)authToken
{
    return NO; // TODO
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


- (void)membershipStatusChanged
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
    if ([nameOrEmailOrRegistrationCodeField isFirstResponder]) {
        [nameOrEmailOrRegistrationCodeField resignFirstResponder];
    } else if ([emailOrPasswordOrScolaShortnameField isFirstResponder]) {
        [emailOrPasswordOrScolaShortnameField resignFirstResponder];
    } else if ([chooseNewPasswordField isFirstResponder]) {
        [chooseNewPasswordField resignFirstResponder];
    }
}


- (void)setUpForUserLogin
{
    membershipStatusControl.enabled = YES;
    chooseNewPasswordField.hidden = YES;
    
    membershipStatusControl.selectedSegmentIndex = kMembershipSegmentMember;
    [self membershipStatusChanged];
}


- (void)setUpForUserRegistration:(int)membershipSegment;
{
    membershipStatusControl.enabled = YES;
    chooseNewPasswordField.hidden = NO;
    
    membershipStatusControl.selectedSegmentIndex = membershipSegment;
    [self membershipStatusChanged];
}


- (void)setUpForUserConfirmation
{
    membershipStatusControl.enabled = NO;
    chooseNewPasswordField.hidden = YES;
    
    userHelpLabel.text = [ScStrings stringForKey:strUserHelpCompleteRegistration];
    
    nameOrEmailOrRegistrationCodeField.text = @"";
    nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strRegistrationCodePrompt];
    
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
    [userDefaults removeObjectForKey:kUserDefaultsKeyAuthState];
    authInfo = nil;
}


- (void)indicatePendingServerSession:(BOOL)isPending
{
    if (isPending) {
        if (!UIState) {
            UIState = [[NSMutableDictionary alloc] init];
        }
        
        [UIState setObject:nameOrEmailOrRegistrationCodeField.text forKey:kUIStateKeyName];
        [UIState setObject:nameOrEmailOrRegistrationCodeField.placeholder forKey:kUIStateKeyNamePlaceholder];
        [UIState setObject:emailOrPasswordOrScolaShortnameField.text forKey:kUIStateKeyEmail];
        [UIState setObject:emailOrPasswordOrScolaShortnameField.placeholder forKey:kUIStateKeyEmailPlaceholder];
        
        nameOrEmailOrRegistrationCodeField.text = @"";
        nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strPleaseWait];
        emailOrPasswordOrScolaShortnameField.text = @"";
        emailOrPasswordOrScolaShortnameField.placeholder = [ScStrings stringForKey:strPleaseWait];
        
        chooseNewPasswordField.hidden = YES;
        membershipStatusControl.enabled = NO;
        
        isEditingAllowed = NO;
        [activityIndicator startAnimating];
    } else {
        nameOrEmailOrRegistrationCodeField.text = [UIState objectForKey:kUIStateKeyName];
        nameOrEmailOrRegistrationCodeField.placeholder = [UIState objectForKey:kUIStateKeyNamePlaceholder];
        emailOrPasswordOrScolaShortnameField.text = [UIState objectForKey:kUIStateKeyEmail];
        emailOrPasswordOrScolaShortnameField.placeholder = [UIState objectForKey:kUIStateKeyEmailPlaceholder];
        
        isEditingAllowed = YES;
        [activityIndicator stopAnimating];
    }
}


- (NSString *)generatePasswordHash:(NSString *)password usingSalt:(NSString *)salt
{
    NSString *saltyDiff = [password diff:salt];
    
    return [saltyDiff hashUsingSHA1];
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
    authPhase = kAuthPhaseLogin;

    NSString *email = nameOrEmailOrRegistrationCodeField.text;
    NSString *password = emailOrPasswordOrScolaShortnameField.text;
    
    [self indicatePendingServerSession:YES];
    
    serverConnection = [[ScServerConnection alloc] initForAuthPhase:kAuthPhaseLogin];
    [serverConnection setAuthHeaderUsingIdent:email andPassword:password];
    [serverConnection setValue:[ScAppEnv env].deviceName forURLParameter:kURLParameterName];
    [serverConnection getRemoteClass:@"ScAuthInfo" usingDelegate:self];
}


- (void)registerNewUser
{
    authPhase = kAuthPhaseRegistration;
    
    NSString *name = nameOrEmailOrRegistrationCodeField.text;
    NSString *emailOrScolaShortname = emailOrPasswordOrScolaShortnameField.text;
    NSString *password = chooseNewPasswordField.text;
    
    [self indicatePendingServerSession:YES];
    
    serverConnection = [[ScServerConnection alloc] initForAuthPhase:kAuthPhaseRegistration];
    [serverConnection setAuthHeaderUsingIdent:emailOrScolaShortname andPassword:password];
    [serverConnection setValue:name forURLParameter:kURLParameterName];
    [serverConnection getRemoteClass:@"ScAuthInfo" usingDelegate:self];
}


- (void)confirmNewUser
{
    authPhase = kAuthPhaseConfirmation;
    
    NSString *email = [authInfo objectForKey:kAuthInfoKeyEmail];
    NSString *password = emailOrPasswordOrScolaShortnameField.text;
    
    [self indicatePendingServerSession:YES];
    
    serverConnection = [[ScServerConnection alloc] initForAuthPhase:kAuthPhaseConfirmation];
    [serverConnection setAuthHeaderUsingIdent:email andPassword:password];
    [serverConnection getRemoteClass:@"ScAuthInfo" usingDelegate:self];
}


#pragma mark - Process server response

- (void)receivedLoginResponse:(NSDictionary *)responseInfo
{
    BOOL isAuthenticated = [[responseInfo objectForKey:kAuthInfoKeyIsAuthenticated] boolValue];
}


- (void)receivedRegistrationResponse:(NSDictionary *)responseInfo
{
    BOOL isActive = [[responseInfo objectForKey:kAuthInfoKeyIsActive] boolValue];
    BOOL isAuthenticated = [[responseInfo objectForKey:kAuthInfoKeyIsAuthenticated] boolValue];
    NSString *email = [responseInfo objectForKey:kAuthInfoKeyEmail];

    if (!isActive) {
        authInfo = responseInfo;
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:authInfo forKey:kUserDefaultsKeyAuthState];
        
        NSString *popUpTitle = [ScStrings stringForKey:strEmailSentPopUpTitle];
        NSString *popUpMessage = [NSString stringWithFormat:[ScStrings stringForKey:strEmailSentPopUpMessage], email];
        NSString *laterButtonTitle = [ScStrings stringForKey:strLater];
        NSString *continueButtonTitle = [ScStrings stringForKey:strHaveAccess];
        
        UIAlertView *emailSentPopUp = [[UIAlertView alloc] initWithTitle:popUpTitle message:popUpMessage delegate:self cancelButtonTitle:laterButtonTitle otherButtonTitles:continueButtonTitle, nil];
        emailSentPopUp.tag = kEmailSentPopUpTag;
        
        [emailSentPopUp show];
    } else {
        NSString *alertMessage;
        int alertTag;
        
        if (isAuthenticated) {
            alertMessage = [ScStrings stringForKey:strUserExistsAndLoggedInAlert];
            alertTag = kUserExistsAndLoggedInPopUpTag;
        } else {
            alertMessage = [ScStrings stringForKey:strUserExistsButNotLoggedInAlert];
            alertTag = kUserExistsButNotLoggedInPopUpTag;
        }
        
        NSString *alertTitle = [ScStrings stringForKey:strUserExistsAlertTitle];
        NSString *OKButtonTitle = [ScStrings stringForKey:strOK];
        
        UIAlertView *userExistsAlert = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:OKButtonTitle otherButtonTitles:nil];
        userExistsAlert.tag = alertTag;
        
        [userExistsAlert show];
    }
}


- (void)receivedConfirmationResponse:(NSDictionary *)responseInfo
{
    
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

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *authToken = [userDefaults objectForKey:kUserDefaultsKeyAuthToken];
    
    if ([self isValidAuthToken:authToken]) {
        [self performSegueWithIdentifier:kSegueToMainPage sender:self];
    } else {
        [darkLinenView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignCurrentFirstResponder)]];
        
        //[self setUpTypewriterAudioForSplashSequence]; // TODO: Comment back in!
        scolaSplashLabel.text = @"";
        
        isEditingAllowed = YES;
        nameOrEmailOrRegistrationCodeField.delegate = self;
        emailOrPasswordOrScolaShortnameField.delegate = self;
        chooseNewPasswordField.delegate = self;
        chooseNewPasswordField.secureTextEntry = YES;
        activityIndicator.hidesWhenStopped = YES;
        
        if ([ScServerConnection isServerAvailable]) {
            membershipPromptLabel.text = [ScStrings stringForKey:strMembershipPrompt];
            
            [membershipStatusControl setTitle:[ScStrings stringForKey:strIsNew] forSegmentAtIndex:kMembershipSegmentNew];
            [membershipStatusControl setTitle:[ScStrings stringForKey:strIsInvited] forSegmentAtIndex:kMembershipSegmentInvited];
            [membershipStatusControl setTitle:[ScStrings stringForKey:strIsMember] forSegmentAtIndex:kMembershipSegmentMember];
            [membershipStatusControl addTarget:self action:@selector(membershipStatusChanged) forControlEvents:UIControlEventValueChanged];
            
            chooseNewPasswordField.placeholder = [ScStrings stringForKey:strNewPasswordPrompt];
            scolaDescriptionTextView.text = [ScStrings stringForKey:strScolaDescription];
        } else {
            membershipPromptLabel.hidden = YES;
            membershipStatusControl.hidden = YES;
            userHelpLabel.hidden = YES;
            nameOrEmailOrRegistrationCodeField.hidden = YES;
            emailOrPasswordOrScolaShortnameField.hidden = YES;
            chooseNewPasswordField.hidden = YES;
            
            if ([ScAppEnv env].isInternetConnectionAvailable) {
                scolaDescriptionTextView.text = NSLocalizedString(istrServerDown, @"");
            } else {
                scolaDescriptionTextView.text = NSLocalizedString(istrNoInternet, @"");
            }
        }
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
    
    if (membershipPromptLabel.hidden == NO) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        authInfo = [userDefaults objectForKey:kUserDefaultsKeyAuthState];
        
        if (authInfo) {
            if ([authInfo objectForKey:kAuthInfoKeyScolaShortname]) {
                membershipStatusControl.selectedSegmentIndex = kMembershipSegmentInvited;
            } else {
                membershipStatusControl.selectedSegmentIndex = kMembershipSegmentNew;
            }
            
            [self setUpForUserConfirmation];
        } else {
            [self setUpForUserLogin];
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self startSplashSequenceThread];
    
    if (authInfo && (membershipPromptLabel.hidden == NO)) {
        NSString *email = [authInfo objectForKey:kAuthInfoKeyEmail];
        NSString *popUpTitle = [ScStrings stringForKey:strWelcomeBackPopUpTitle];
        NSString *popUpMessage = [NSString stringWithFormat:[ScStrings stringForKey:strWelcomeBackPopUpMessage], email];
        NSString *continueButtonTitle = [ScStrings stringForKey:strHaveCode];
        NSString *goBackButtonTitle = [ScStrings stringForKey:strGoBack];
        
        UIAlertView *welcomeBackPopUp = [[UIAlertView alloc] initWithTitle:popUpTitle message:popUpMessage delegate:self cancelButtonTitle:goBackButtonTitle otherButtonTitles:continueButtonTitle, nil];
        welcomeBackPopUp.tag = kWelcomeBackPopUpTag;
        
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
    
}


#pragma mark - IBAction implementation

- (IBAction)showInfo:(id)sender
{
    // TODO
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
    BOOL shouldReturn = NO;
    
    BOOL isNameValid = NO;
    BOOL isEmailValid = NO;
    BOOL isPasswordValid = NO;
    BOOL isScolaShortnameValid = NO;
    
    NSString *alertMessage = nil;
    
    switch (currentMembershipSegment) {
        case kMembershipSegmentNew:
            isNameValid = [self isNameValid];
            isEmailValid = isNameValid && [self isEmailValid];
            isPasswordValid = isEmailValid && [self isPasswordValid];
            
            if (!isNameValid) {
                alertMessage = [ScStrings stringForKey:strInvalidNameAlert];
            } else if (!isEmailValid) {
                alertMessage = [ScStrings stringForKey:strInvalidEmailAlert];
            } else if (!isPasswordValid) {
                alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strInvalidPasswordAlert], kMinimumPassordLength];
            }
            
            shouldReturn = (isNameValid && isEmailValid && isPasswordValid);
            
            break;
            
        case kMembershipSegmentInvited:
            isNameValid = [self isNameValid];
            isScolaShortnameValid = isNameValid && [self isScolaShortnameValid];
            isPasswordValid = isScolaShortnameValid && [self isPasswordValid];
            
            if (!isNameValid) {
                alertMessage = [ScStrings stringForKey:strInvalidNameAlert];
            } else if (!isScolaShortnameValid) {
                alertMessage = [ScStrings stringForKey:strInvalidScolaShortnameAlert];
            } else if (!isPasswordValid) {
                alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strInvalidPasswordAlert], kMinimumPassordLength];
            }
            
            shouldReturn = (isNameValid && isScolaShortnameValid && isPasswordValid);
            
            break;
            
        case kMembershipSegmentMember:
            isEmailValid = [self isEmailValid];
            isPasswordValid = isEmailValid && [self isPasswordValid];
            
            if (!isEmailValid) {
                alertMessage = [ScStrings stringForKey:strInvalidEmailAlert];
            } else if (!isPasswordValid) {
                alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strInvalidPasswordAlert], kMinimumPassordLength];
            }
            
            shouldReturn = (isEmailValid && isPasswordValid);
            
            break;
            
        default:
            break;
    }
    
    if (shouldReturn) {
        [textField resignFirstResponder];
        
        if (currentMembershipSegment == kMembershipSegmentMember) {
            [self loginUser];
        } else {
            [self registerNewUser];
        }
    } else {
        NSString *OKButtonTitle  = [ScStrings stringForKey:strOK];
        
        UIAlertView *popUpAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:nil cancelButtonTitle:OKButtonTitle otherButtonTitles:nil];
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
    int alertTag;
    
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
        alertTag = kRegistrationCodesDoNotMatchPopUpTag;
    } else if (!doPasswordsMatch) {
        alertMessage = [ScStrings stringForKey:strPasswordsDoNotMatchAlert];
        alertTag = kPasswordsDoNotMatchPopUpTag;
    }
    
    BOOL shouldReturn = doRegistrationCodesMatch && doPasswordsMatch;
    
    if (shouldReturn) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults removeObjectForKey:kUserDefaultsKeyAuthState];
        
        [textField resignFirstResponder];
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
        case kInternalErrorPopUpTag:
            break;
            
        case kEmailSentPopUpTag:
            [self setUpForUserConfirmation];
            
            if (buttonIndex == kPopUpButtonContinue) {
                [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
            } else if (buttonIndex == kPopUpButtonLater) {
                NSString *popUpTitle = [ScStrings stringForKey:strSeeYouLaterPopUpTitle];
                NSString *popUpMessage = [ScStrings stringForKey:strSeeYouLaterPopUpMessage];
                NSString *OKButtonTitle = [ScStrings stringForKey:strOK];
                
                UIAlertView *seeYouLaterPopUp = [[UIAlertView alloc] initWithTitle:popUpTitle message:popUpMessage delegate:nil cancelButtonTitle:OKButtonTitle otherButtonTitles:nil];
                [seeYouLaterPopUp show];
            }
            
            break;
            
        case kRegistrationCodesDoNotMatchPopUpTag:
        case kPasswordsDoNotMatchPopUpTag:
            if (buttonIndex == kPopUpButtonTryAgain) {
                if (alertView.tag == kRegistrationCodesDoNotMatchPopUpTag) {
                    [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
                } else if (alertView.tag == kPasswordsDoNotMatchPopUpTag) {
                    emailOrPasswordOrScolaShortnameField.text = @"";
                    [emailOrPasswordOrScolaShortnameField becomeFirstResponder];
                }
            } else if (buttonIndex == kPopUpButtonGoBack) {
                [self goBackToUserRegistration];
            }
            
            break;

        case kScolaNotFoundPopUpTag:
            [self setUpForUserRegistration:kMembershipSegmentInvited];
            [emailOrPasswordOrScolaShortnameField becomeFirstResponder];
            
            break;
            
        case kInvitationNotFoundPopUpTag:
            [self setUpForUserRegistration:kMembershipSegmentInvited];
            [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
            
            break;
            
        case kWelcomeBackPopUpTag:
            if (buttonIndex == kPopUpButtonContinue) {
                [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
            } else if (buttonIndex == kPopUpButtonGoBack) {
                [self goBackToUserRegistration];
            }
            
            break;
            
        case kUserExistsButNotLoggedInPopUpTag:
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

    if (serverConnection.HTTPStatusCode == kHTTPStatusCodeNotFound) {
        [self indicatePendingServerSession:NO];
        
        NSDictionary *responseHeaders = [response allHeaderFields];
        NSString *reason = [responseHeaders objectForKey:kServerReason];
        NSString *alertMessage;
        int alertTag;
        
        if ([reason isEqualToString:kServerReasonScolaNotFound]) {
            alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strScolaNotFoundAlert], scolaShortnameAsEntered];
            alertTag = kScolaNotFoundPopUpTag;
        } else if ([reason isEqualToString:kServerReasonInvitationNotFound]) {
            alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strInvitationNotFoundAlert], nameAsEntered, scolaShortnameAsEntered];
            alertTag = kInvitationNotFoundPopUpTag;
        }
        
        UIAlertView *notFoundAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:self cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
        notFoundAlert.tag = alertTag;
        
        [notFoundAlert show];
        
        isEditingAllowed = YES;
    } else if (serverConnection.HTTPStatusCode == kHTTPStatusCodeInternalServerError) {
        [self indicatePendingServerSession:NO];
        
        UIAlertView *internalErrorAlert = [[UIAlertView alloc] initWithTitle:nil message:[ScStrings stringForKey:strInternalServerError] delegate:self cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
        internalErrorAlert.tag = kInternalErrorPopUpTag;
        
        [internalErrorAlert show];
    }
}


- (void)finishedReceivingData:(NSDictionary *)dataAsDictionary
{
    [self indicatePendingServerSession:NO];
    
    if (serverConnection.HTTPStatusCode == kHTTPStatusCodeOK) {
        ScLogDebug(@"Received data: %@", dataAsDictionary);
        
        if (authPhase == kAuthPhaseLogin) {
            [self receivedLoginResponse:dataAsDictionary];
        } else if (authPhase == kAuthPhaseRegistration) {
            [self receivedRegistrationResponse:dataAsDictionary];
        } else if (authPhase == kAuthPhaseConfirmation) {
            [self receivedConfirmationResponse:dataAsDictionary];
        }
    }
}


@end
