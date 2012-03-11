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
#import "UIView+ScShadowEffects.h"

#import "ScAppEnv.h"
#import "ScLogging.h"
#import "ScServerConnection.h"
#import "ScRegistrationView1Controller.h"
#import "ScStrings.h"

#import "ScHousehold.h"
#import "ScHouseholdResidency.h"
#import "ScScolaMember.h"


static NSString * const kUserDefaultsKeyAuthId = @"scola.auth.id";
static NSString * const kUserDefaultsKeyAuthToken = @"scola.auth.token";
static NSString * const kUserDefaultsKeyAuthExpiryDate = @"scola.auth.expires";
static NSString * const kUserDefaultsKeyAuthInfo = @"scola.auth.info";

static NSString * const kSoundbiteTypewriter = @"typewriter.caf";

static NSString * const kSegueToMainView = @"authToMainView";
static NSString * const kSegueToAddressView = @"authToAddressView";

static int const kMinimumPassordLength = 6;

static int const kMembershipStatusMember = 0;
static int const kMembershipStatusNewUser = 1;

static NSString * const kAuthInfoKeyEmail = @"email";
static NSString * const kAuthInfoKeyName = @"name";
static NSString * const kAuthInfoKeyPasswordHash = @"passwordHash";
static NSString * const kAuthInfoKeyScolaShortname = @"scolaShortname";
static NSString * const kAuthInfoKeyRegistrationCode = @"registrationCode";
static NSString * const kAuthInfoKeyIsListed = @"isListed";
static NSString * const kAuthInfoKeyIsRegistered = @"isRegistered";
static NSString * const kAuthInfoKeyIsAuthenticated = @"isAuthenticated";
static NSString * const kAuthInfoKeyMemberInfo = @"member";
static NSString * const kAuthInfoKeyHouseholdInfo = @"household";

static NSString * const kListedPersonKeyDateOfBirth = @"dateOfBirth";
static NSString * const kListedPersonKeyGender = @"gender";
static NSString * const kListedPersonKeyMobilePhone = @"mobilePhone";

static NSString * const kHouseholdKeyAddressLine1 = @"addressLine1";
static NSString * const kHouseholdKeyAddressLine2 = @"addressLine2";
static NSString * const kHouseholdKeyPostCodeAndCity = @"postCodeAndCity";

static NSTimeInterval const kTimeIntervalTwoWeeks = 1209600;

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
@synthesize emailOrPasswordField;
@synthesize passwordField;
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
    NSString *emailPrompt = [ScStrings stringForKey:strEmailPrompt];
    NSString *passwordPrompt = [ScStrings stringForKey:strPasswordPrompt];
    
    switch (currentMembershipSegment) {
        case kMembershipStatusMember:
            emailAsEntered = nameOrEmailOrRegistrationCodeField.text;
            break;
            
        case kMembershipStatusNewUser:
            nameAsEntered = nameOrEmailOrRegistrationCodeField.text;
            emailAsEntered = emailOrPasswordField.text;
            break;
            
        default:
            break;
    }
    
    currentMembershipSegment = membershipStatusControl.selectedSegmentIndex;
    
    switch (currentMembershipSegment) {
        case kMembershipStatusMember:
            userHelpLabel.text = [ScStrings stringForKey:strUserHelpMember];
            
            nameOrEmailOrRegistrationCodeField.placeholder = emailPrompt;
            nameOrEmailOrRegistrationCodeField.text = emailAsEntered;
            nameOrEmailOrRegistrationCodeField.keyboardType = UIKeyboardTypeEmailAddress;
            nameOrEmailOrRegistrationCodeField.autocapitalizationType = NO;

            emailOrPasswordField.placeholder = passwordPrompt;
            emailOrPasswordField.text = @"";
            emailOrPasswordField.keyboardType = UIKeyboardTypeDefault;
            emailOrPasswordField.secureTextEntry = YES;
            
            passwordField.hidden = YES;
            
            break;
            
        case kMembershipStatusNewUser:
            userHelpLabel.text = [ScStrings stringForKey:strUserHelpNew];
            
            nameOrEmailOrRegistrationCodeField.placeholder = namePrompt;
            nameOrEmailOrRegistrationCodeField.text = nameAsEntered;
            nameOrEmailOrRegistrationCodeField.keyboardType = UIKeyboardTypeDefault;
            nameOrEmailOrRegistrationCodeField.autocapitalizationType = YES;
            
            emailOrPasswordField.placeholder = emailPrompt;
            emailOrPasswordField.text = emailAsEntered;
            emailOrPasswordField.keyboardType = UIKeyboardTypeEmailAddress;
            emailOrPasswordField.secureTextEntry = NO;
            
            passwordField.text = @"";
            passwordField.hidden = NO;
            
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

- (void)setUpForMembershipStatus:(int)membershipStatus;
{
    membershipStatusControl.enabled = YES;
    passwordField.hidden = NO;
    
    membershipStatusControl.selectedSegmentIndex = membershipStatus;
    [self membershipStatusDidChange];
}


- (void)setUpForUserConfirmation
{
    membershipStatusControl.enabled = NO;
    passwordField.hidden = YES;
    
    userHelpLabel.text = [ScStrings stringForKey:strUserHelpCompleteRegistration];
    
    nameOrEmailOrRegistrationCodeField.text = @"";
    nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strRegistrationCodePrompt];
    nameOrEmailOrRegistrationCodeField.autocapitalizationType = NO;
    
    emailOrPasswordField.text = @"";
    emailOrPasswordField.placeholder = [ScStrings stringForKey:strRepeatPasswordPrompt];
    emailOrPasswordField.secureTextEntry = YES;
}


- (void)goBackToUserRegistration
{
    nameOrEmailOrRegistrationCodeField.text = [authInfo objectForKey:kAuthInfoKeyName];
    emailOrPasswordField.text = [authInfo objectForKey:kAuthInfoKeyEmail];
    [self setUpForMembershipStatus:kMembershipStatusNewUser];
    [passwordField becomeFirstResponder];
    
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
        emailEtc = emailOrPasswordField.text;
        emailEtcPlaceholder = emailOrPasswordField.placeholder;
        
        nameOrEmailOrRegistrationCodeField.text = @"";
        nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strPleaseWait];
        emailOrPasswordField.text = @"";
        emailOrPasswordField.placeholder = [ScStrings stringForKey:strPleaseWait];
        
        passwordField.hidden = YES;
        membershipStatusControl.enabled = NO;
        
        isEditingAllowed = NO;
        [activityIndicator startAnimating];
    } else {
        nameOrEmailOrRegistrationCodeField.text = nameEtc;
        nameOrEmailOrRegistrationCodeField.placeholder = nameEtcPlaceholder;
        emailOrPasswordField.text = emailEtc;
        emailOrPasswordField.placeholder = emailEtcPlaceholder;
        
        membershipStatusControl.enabled = YES;
        
        isEditingAllowed = YES;
        [activityIndicator stopAnimating];
    }
}


#pragma mark - Input validation

- (BOOL)isNameValid
{
    BOOL isValid = NO;
    
    if (currentMembershipSegment == kMembershipStatusMember) {
        ScLogBreakage(@"Attempt to validate name while in 'Member' segment");
    } else {
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
    
    if (currentMembershipSegment == kMembershipStatusMember) {
        emailField = nameOrEmailOrRegistrationCodeField;
    } else {
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
    
    if (currentMembershipSegment == kMembershipStatusMember) {
        currentPasswordField = emailOrPasswordField;
    } else {
        currentPasswordField = passwordField;
    }
    
    isValid = (currentPasswordField.text.length >= kMinimumPassordLength);
    
    if (!isValid) {
        currentPasswordField.text = @"";
        [currentPasswordField becomeFirstResponder];
    }
    
    return isValid;
}


#pragma mark - User registration and authentication

- (void)loginUser
{
    authPhase = ScAuthPhaseLogin;

    emailAsEntered = nameOrEmailOrRegistrationCodeField.text;
    NSString *password = emailOrPasswordField.text;
    
    [self indicatePendingServerSession:YES];
    
    serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:emailAsEntered withPassword:password];
    [serverConnection authenticateForPhase:ScAuthPhaseLogin usingDelegate:self];
}


- (void)registerNewUser
{
    authPhase = ScAuthPhaseRegistration;
    
    nameAsEntered = nameOrEmailOrRegistrationCodeField.text;
    emailAsEntered = emailOrPasswordField.text;
    NSString *password = passwordField.text;
    
    [self indicatePendingServerSession:YES];
    
    serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:emailAsEntered withPassword:password];
    [serverConnection setValue:nameAsEntered forURLParameter:kURLParameterName];
    [serverConnection authenticateForPhase:ScAuthPhaseRegistration usingDelegate:self];
}


- (void)confirmNewUser
{
    authPhase = ScAuthPhaseConfirmation;
    
    nameAsEntered = [authInfo objectForKey:kAuthInfoKeyName];
    emailAsEntered = [authInfo objectForKey:kAuthInfoKeyEmail];
    NSString *password = emailOrPasswordField.text;
    
    [self indicatePendingServerSession:YES];
    
    serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:emailAsEntered withPassword:password];
    [serverConnection authenticateForPhase:ScAuthPhaseConfirmation usingDelegate:self];
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
        NSManagedObjectContext *context = [ScAppEnv env].managedObjectContext;
        member = [context entityForClass:ScScolaMember.class];
        
        member.name = nameAsEntered;
        member.email = emailAsEntered;
        member.entityId = member.email;
        member.passwordHash = [authInfo objectForKey:kAuthInfoKeyPasswordHash];
        
        if (isUserListed) {
            NSDictionary *memberInfo = [authInfo objectForKey:kAuthInfoKeyMemberInfo];
            NSDictionary *householdInfo = [authInfo objectForKey:kAuthInfoKeyHouseholdInfo];
            
            member.dateOfBirth = [NSDate dateWithTimeIntervalSince1970:[[memberInfo objectForKey:kListedPersonKeyDateOfBirth] doubleValue] / 1000];
            member.gender = [memberInfo objectForKey:kListedPersonKeyGender];
            member.mobilePhone = [memberInfo objectForKey:kListedPersonKeyMobilePhone];
            
            ScHousehold *household = [context entityForClass:ScHousehold.class];
            household.addressLine1 = [householdInfo objectForKey:kHouseholdKeyAddressLine1];
            //household.addressLine2 = [householdInfo objectForKey:kHouseholdKeyAddressLine2];
            household.postCodeAndCity = [householdInfo objectForKey:kHouseholdKeyPostCodeAndCity];
            
            member.primaryResidence = household;
        }
        
        [self performSegueWithIdentifier:kSegueToAddressView sender:self];
    } else {
        [self performSegueWithIdentifier:kSegueToMainView sender:self];
    }
}


#pragma mark - Process server response

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
    
    isUserListed = [[authInfo objectForKey:kAuthInfoKeyIsListed] boolValue];
    BOOL isActive = [[authInfo objectForKey:kAuthInfoKeyIsRegistered] boolValue];
    BOOL isAuthenticated = [[authInfo objectForKey:kAuthInfoKeyIsAuthenticated] boolValue];

    if (!isActive) {
        NSData *authInfoArchive = [NSKeyedArchiver archivedDataWithRootObject:authInfo];
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:authInfoArchive forKey:kUserDefaultsKeyAuthInfo];
        
        NSString *popUpTitle = nil;
        NSString *popUpMessage = nil;
        
        if (isUserListed) {
            popUpTitle = [ScStrings stringForKey:strEmailSentToInviteePopUpTitle];
            popUpMessage = [NSString stringWithFormat:[ScStrings stringForKey:strEmailSentToInviteePopUpMessage], [authInfo objectForKey:kAuthInfoKeyEmail]];
        } else {
            popUpTitle = [ScStrings stringForKey:strEmailSentPopUpTitle];
            popUpMessage = [NSString stringWithFormat:[ScStrings stringForKey:strEmailSentPopUpMessage], emailAsEntered];
        }
        
        NSString *laterButtonTitle = [ScStrings stringForKey:strLater];
        NSString *continueButtonTitle = [ScStrings stringForKey:strHaveAccess];
        
        UIAlertView *emailSentAlert = [[UIAlertView alloc] initWithTitle:popUpTitle message:popUpMessage delegate:self cancelButtonTitle:laterButtonTitle otherButtonTitles:continueButtonTitle, nil];
        emailSentAlert.tag = ScAuthPopUpTagEmailSent;
        
        [emailSentAlert show];
    } else {
        NSString *alertTitle = [ScStrings stringForKey:strUserExistsAlertTitle];
        NSString *alertMessage = nil;
        ScAuthPopUpTag alertTag;
        
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
        [darkLinenView addGradientLayer];
        [darkLinenView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignCurrentFirstResponder)]];
        
        //[self setUpTypewriterAudioForSplashSequence]; // TODO: Comment back in!
        scolaSplashLabel.text = @"";
        
        isEditingAllowed = YES;
        nameOrEmailOrRegistrationCodeField.delegate = self;
        emailOrPasswordField.delegate = self;
        passwordField.delegate = self;
        passwordField.secureTextEntry = YES;
        activityIndicator.hidesWhenStopped = YES;

        membershipPromptLabel.text = [ScStrings stringForKey:strMembershipPrompt];
        [membershipStatusControl setTitle:[ScStrings stringForKey:strIsNew] forSegmentAtIndex:kMembershipStatusNewUser];
        [membershipStatusControl setTitle:[ScStrings stringForKey:strIsMember] forSegmentAtIndex:kMembershipStatusMember];
        [membershipStatusControl addTarget:self action:@selector(membershipStatusDidChange) forControlEvents:UIControlEventValueChanged];
        
        passwordField.placeholder = [ScStrings stringForKey:strNewPasswordPrompt];
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
    NSData *authInfoArchive = [userDefaults objectForKey:kUserDefaultsKeyAuthInfo];
    
    if (authInfoArchive) {
        authInfo = [NSKeyedUnarchiver unarchiveObjectWithData:authInfoArchive];
        
        [self setUpForUserConfirmation];
        membershipStatusControl.selectedSegmentIndex = kMembershipStatusNewUser;
    } else {
        [self setUpForMembershipStatus:kMembershipStatusMember];
        
        NSString *email = [userDefaults objectForKey:kUserDefaultsKeyAuthId];
        
        if (email) {
            nameOrEmailOrRegistrationCodeField.text = email;
            [emailOrPasswordField becomeFirstResponder];
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self startSplashSequenceThread];
    
    if ([ScAppEnv env].isInternetConnectionAvailable) {
        [ScStrings refreshStrings];
    }
    
    if (authInfo) {
        [self setUpForMembershipStatus:kMembershipStatusNewUser];
        
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


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToAddressView]) {
        ScRegistrationView1Controller *nextViewController = segue.destinationViewController;
        
        nextViewController.userIsListed = isUserListed;
        nextViewController.member = member;
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
    
    if (currentMembershipSegment == kMembershipStatusMember) {
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


- (BOOL)textFieldShouldReturnForUserRegistration:(UITextField *)textField
{
    BOOL emailIsRegistered = NO;
    BOOL shouldReturn = NO;
    
    NSString *alertMessage = nil;
    
    switch (currentMembershipSegment) {
        case kMembershipStatusMember:
            if (![self isEmailValid]) {
                alertMessage = [ScStrings stringForKey:strInvalidEmailAlert];
            } else if (![self isPasswordValid]) {
                alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strInvalidPasswordAlert], kMinimumPassordLength];
            }
            
            break;
            
        case kMembershipStatusNewUser:
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
                    [userId isEqualToString:emailOrPasswordField.text];
            }
            
            break;
            
        default:
            break;
    }
    
    shouldReturn = (!alertMessage && !emailIsRegistered);
    
    if (shouldReturn) {
        [textField resignFirstResponder];
        
        if (currentMembershipSegment == kMembershipStatusMember) {
            [self loginUser];
        } else if (currentMembershipSegment == kMembershipStatusNewUser) {
            [self registerNewUser];
        }
    } else if (emailIsRegistered) {
        NSString *email = emailOrPasswordField.text;
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
    BOOL registrationCodesDoMatch = NO;
    BOOL passwordsDoMatch = NO;
    
    NSString *registrationCodeAsSent = [[authInfo objectForKey:kAuthInfoKeyRegistrationCode] lowercaseString];
    NSString *registrationCodeAsEntered = [nameOrEmailOrRegistrationCodeField.text lowercaseString];
    
    NSString *alertMessage = nil;
    ScAuthPopUpTag alertTag;
    
    registrationCodesDoMatch = [registrationCodeAsEntered isEqualToString:registrationCodeAsSent];
    
    if (registrationCodesDoMatch) {
        NSString *email = [authInfo objectForKey:kAuthInfoKeyEmail];
        NSString *password = emailOrPasswordField.text;
        
        NSString *passwordHashFromServer = [authInfo objectForKey:kAuthInfoKeyPasswordHash];
        NSString *passwordHashAsEntered = [self generatePasswordHash:password usingSalt:email];
        
        passwordsDoMatch = [passwordHashAsEntered isEqualToString:passwordHashFromServer];
    }
    
    if (!registrationCodesDoMatch) {
        alertMessage = [ScStrings stringForKey:strRegistrationCodesDoNotMatchAlert];
        alertTag = ScAuthPopUpTagRegistrationCodesDoNotMatch;
    } else if (!passwordsDoMatch) {
        alertMessage = [ScStrings stringForKey:strPasswordsDoNotMatchAlert];
        alertTag = ScAuthPopUpTagPasswordsDoNotMatch;
    }
    
    BOOL shouldReturn = registrationCodesDoMatch && passwordsDoMatch;
    
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
        case ScAuthPopUpTagServerError:
            [self indicatePendingServerSession:NO];
            
            break;
        
        case ScAuthPopUpTagEmailAlreadyRegistered:
            if (buttonIndex == kPopUpButtonLogIn) {
                NSString *password = passwordField.text;
                
                [self setUpForMembershipStatus:kMembershipStatusMember];
                emailOrPasswordField.text = password;
                [self loginUser];
            } else if (buttonIndex == kPopUpButtonNewUser) {
                [self setUpForMembershipStatus:kMembershipStatusNewUser];
                
                emailOrPasswordField.text = @"";
                [emailOrPasswordField becomeFirstResponder];
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
                    emailOrPasswordField.text = @"";
                    [emailOrPasswordField becomeFirstResponder];
                }
            } else if (buttonIndex == kPopUpButtonGoBack) {
                [self goBackToUserRegistration];
            }
            
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
            [self setUpForMembershipStatus:kMembershipStatusMember];
            [emailOrPasswordField becomeFirstResponder];
            
            break;
            
        default:
            break;
    }
}


#pragma mark - ScServerConnectionDelegate implementation

- (void)didReceiveResponse:(NSHTTPURLResponse *)response
{
    ScLogDebug(@"Received response. HTTP status code: %d", response.statusCode);

    if (response.statusCode == kHTTPStatusCodeInternalServerError) {
        [ScServerConnection showAlertForHTTPStatus:response.statusCode tagWith:ScAuthPopUpTagServerError usingDelegate:self];
    } else if (authPhase == ScAuthPhaseLogin) {
        [self didReceiveLoginResponse:response];
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


- (void)didFailWithError:(NSError *)error
{
    [ScServerConnection showAlertForError:error tagWith:ScAuthPopUpTagServerError usingDelegate:self];
}

@end
