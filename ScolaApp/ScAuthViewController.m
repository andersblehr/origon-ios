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
#import "ScRegistrationView1Controller.h"
#import "ScServerConnection.h"
#import "ScStrings.h"
#import "ScUUIDGenerator.h"

#import "ScDevice.h"
#import "ScMember.h"
#import "ScMemberResidency.h"
#import "ScScola.h"

typedef enum {
    ScAuthPopUpTagServerError,
    ScAuthPopUpTagEmailAlreadyRegistered,
    ScAuthPopUpTagEmailSent,
    ScAuthPopUpTagRegistrationCodesDoNotMatch,
    ScAuthPopUpTagPasswordsDoNotMatch,
    ScAuthPopUpTagWelcomeBack,
    ScAuthPopUpTagUserExistsAndIsLoggedIn,
    ScAuthPopUpTagNotLoggedIn,
} ScAuthPopUpTag;

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
static NSString * const kAuthInfoKeyIsAuthenticated = @"isAuthenticated";
static NSString * const kAuthInfoKeyHomeScolaId = @"homeScola";

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
        ScLogWarning(@"Error initialising audio: %@", [error localizedDescription]);
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


- (void)userIntentionDidChange
{
    NSString *namePrompt = [ScStrings stringForKey:strNamePrompt];
    NSString *emailPrompt = [ScStrings stringForKey:strEmailPrompt];
    NSString *passwordPrompt = [ScStrings stringForKey:strPasswordPrompt];
    
    switch (currentUserIntention) {
        case kUserIntentionLogin:
            emailAsEntered = nameOrEmailOrRegistrationCodeField.text;
            
            break;
            
        case kUserIntentionRegistration:
            nameAsEntered = nameOrEmailOrRegistrationCodeField.text;
            emailAsEntered = emailOrPasswordField.text;
            
            break;
            
        default:
            break;
    }
    
    currentUserIntention = userIntentionControl.selectedSegmentIndex;
    
    switch (currentUserIntention) {
        case kUserIntentionLogin:
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
            
        case kUserIntentionRegistration:
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
    return [[password diff:salt] hashUsingSHA1];
}


#pragma mark - View composition

- (void)setUpForUserIntention:(int)userIntention;
{
    passwordField.hidden = NO;
    userIntentionControl.enabled = YES;
    userIntentionControl.selectedSegmentIndex = userIntention;
    
    [self userIntentionDidChange];
}


- (void)setUpForUserConfirmation
{
    userIntentionControl.selectedSegmentIndex = kUserIntentionRegistration;
    userIntentionControl.enabled = NO;
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
    emailOrPasswordField.text = [authInfo objectForKey:kAuthInfoKeyUserId];
    [self setUpForUserIntention:kUserIntentionRegistration];
    [passwordField becomeFirstResponder];
    
    [ScMeta removeUserDefaultForKey:kUserDefaultsKeyAuthInfo];
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
        userIntentionControl.enabled = NO;
        
        isEditingAllowed = NO;
        [activityIndicator startAnimating];
    } else {
        nameOrEmailOrRegistrationCodeField.text = nameEtc;
        nameOrEmailOrRegistrationCodeField.placeholder = nameEtcPlaceholder;
        emailOrPasswordField.text = emailEtc;
        emailOrPasswordField.placeholder = emailEtcPlaceholder;
        
        userIntentionControl.enabled = YES;
        
        isEditingAllowed = YES;
        [activityIndicator stopAnimating];
    }
}


#pragma mark - Input validation

- (BOOL)isNameValid
{
    BOOL isValid = NO;
    
    if (currentUserIntention == kUserIntentionRegistration) {
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
    
    if (currentUserIntention == kUserIntentionLogin) {
        emailField = nameOrEmailOrRegistrationCodeField;
    } else if (currentUserIntention == kUserIntentionRegistration) {
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
    
    if (currentUserIntention == kUserIntentionLogin) {
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
    
    [ScMeta m].userId = emailAsEntered;
    
    serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:[ScMeta m].userId withPassword:password];
    [serverConnection authenticateForPhase:ScAuthPhaseLogin usingDelegate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)registerNewUser
{
    authPhase = ScAuthPhaseRegistration;
    
    nameAsEntered = nameOrEmailOrRegistrationCodeField.text;
    emailAsEntered = emailOrPasswordField.text;
    NSString *password = passwordField.text;
    
    serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:[ScMeta m].userId withPassword:password];
    [serverConnection setValue:nameAsEntered forURLParameter:kURLParameterName];
    [serverConnection authenticateForPhase:ScAuthPhaseRegistration usingDelegate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)confirmNewUser
{
    authPhase = ScAuthPhaseConfirmation;
    
    nameAsEntered = [authInfo objectForKey:kAuthInfoKeyName];
    emailAsEntered = [authInfo objectForKey:kAuthInfoKeyUserId];
    NSString *password = emailOrPasswordField.text;
    
    serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:[ScMeta m].userId withPassword:password];
    [serverConnection setValue:[ScMeta m].homeScolaId forURLParameter:kURLParameterScolaId];
    [serverConnection authenticateForPhase:ScAuthPhaseConfirmation usingDelegate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)userDidLogIn:(NSString *)userId isNewUser:(BOOL)isNewUser
{
    [ScMeta m].isUserLoggedIn = YES;
    
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    
    if (isNewUser) {
        if (isUserListed) {
            homeScola = [context fetchEntityWithId:[ScMeta m].homeScolaId];
            member = [context fetchEntityWithId:[ScMeta m].userId];
        } else {
            homeScola = [context entityForScolaWithName:[ScStrings stringForKey:strMyPlace] andId:[ScMeta m].homeScolaId];
            member = [context entityForClass:ScMember.class inScola:homeScola withId:emailAsEntered];
        }
        
        member.name = nameAsEntered;
        member.passwordHash = [authInfo objectForKey:kAuthInfoKeyPasswordHash];
        
        [self performSegueWithIdentifier:kSegueToRegistrationView1 sender:self];
    } else {
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
    }
}


#pragma mark - Process data from server

- (void)finishedReceivingLoginData:(NSArray *)data
{
    [[ScMeta m].managedObjectContext saveWithDictionaries:data];
    
    if (authPhase == ScAuthPhaseConfirmation) {
        [self userDidLogIn:emailAsEntered isNewUser:YES];
    } else if (authPhase == ScAuthPhaseLogin) {
        [self userDidLogIn:emailAsEntered isNewUser:NO];
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
        [ScMeta setUserDefault:authInfoArchive forKey:kUserDefaultsKeyAuthInfo];
        
        NSString *popUpTitle = nil;
        NSString *popUpMessage = nil;
        
        if (isUserListed) {
            [ScMeta m].homeScolaId = [authInfo objectForKey:kAuthInfoKeyHomeScolaId];
            
            popUpTitle = [ScStrings stringForKey:strEmailSentToInviteePopUpTitle];
            popUpMessage = [NSString stringWithFormat:[ScStrings stringForKey:strEmailSentToInviteePopUpMessage], [authInfo objectForKey:kAuthInfoKeyUserId]];
        } else {
            [ScMeta m].homeScolaId = [ScUUIDGenerator generateUUID];
            
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

    if ([[ScMeta m] isUserLoggedIn]) {
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
        [userIntentionControl setTitle:[ScStrings stringForKey:strIsNew] forSegmentAtIndex:kUserIntentionRegistration];
        [userIntentionControl setTitle:[ScStrings stringForKey:strIsMember] forSegmentAtIndex:kUserIntentionLogin];
        [userIntentionControl addTarget:self action:@selector(membershipStatusDidChange) forControlEvents:UIControlEventValueChanged];
        
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
    
    NSData *authInfoArchive = [ScMeta userDefaultForKey:kUserDefaultsKeyAuthInfo];
    
    if (authInfoArchive) {
        authInfo = [NSKeyedUnarchiver unarchiveObjectWithData:authInfoArchive];
        
        [self setUpForUserConfirmation];
    } else {
        [self setUpForUserIntention:kUserIntentionLogin];
        
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
    
    if (authInfo) {
        NSString *email = [authInfo objectForKey:kAuthInfoKeyUserId];
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
    if ([segue.identifier isEqualToString:kSegueToRegistrationView1]) {
        ScRegistrationView1Controller *nextViewController = segue.destinationViewController;

        nextViewController.member = member;
        nextViewController.homeScola = homeScola;
        nextViewController.userIsListed = isUserListed;
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
    
    if (currentUserIntention == kUserIntentionLogin) {
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
    
    switch (currentUserIntention) {
        case kUserIntentionLogin:
            if (![self isEmailValid]) {
                alertMessage = [ScStrings stringForKey:strInvalidEmailAlert];
            } else if (![self isPasswordValid]) {
                alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strInvalidPasswordAlert], kMinimumPassordLength];
            }
            
            break;
            
        case kUserIntentionRegistration:
            if (![self isNameValid]) {
                alertMessage = [ScStrings stringForKey:strInvalidNameAlert];
            } else if (![self isEmailValid]) {
                alertMessage = [ScStrings stringForKey:strInvalidEmailAlert];
            } else if (![self isPasswordValid]) {
                alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strInvalidPasswordAlert], kMinimumPassordLength];
            }
            
            if (!alertMessage) {
                emailIsRegistered = [emailOrPasswordField.text isEqualToString:[ScMeta m].userId];
                
                if (!emailIsRegistered) {
                    [ScMeta m].userId = emailOrPasswordField.text;
                }
            }
            
            break;
            
        default:
            break;
    }
    
    shouldReturn = (!alertMessage && !emailIsRegistered);
    
    if (shouldReturn) {
        [textField resignFirstResponder];
        
        if (currentUserIntention == kUserIntentionLogin) {
            [self loginUser];
        } else if (currentUserIntention == kUserIntentionRegistration) {
            [self registerNewUser];
        }
    } else {
        if (emailIsRegistered) {
            alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strEmailAlreadyRegisteredAlert], emailOrPasswordField.text];
            
            UIAlertView *emailRegisteredAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:self cancelButtonTitle:[ScStrings stringForKey:strLogIn] otherButtonTitles:[ScStrings stringForKey:strNewUser], nil];
            emailRegisteredAlert.tag = ScAuthPopUpTagEmailAlreadyRegistered;
            
            [emailRegisteredAlert show];
        } else {
            UIAlertView *popUpAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
            [popUpAlert show];
        }
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
        NSString *email = [authInfo objectForKey:kAuthInfoKeyUserId];
        NSString *password = emailOrPasswordField.text;
        
        NSString *passwordHashAsPersisted = [authInfo objectForKey:kAuthInfoKeyPasswordHash];
        NSString *passwordHashAsEntered = [self generatePasswordHash:password usingSalt:email];
        
        passwordsDoMatch = [passwordHashAsEntered isEqualToString:passwordHashAsPersisted];
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
        [ScMeta removeUserDefaultForKey:kUserDefaultsKeyAuthInfo];
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
                [self setUpForUserIntention:kUserIntentionLogin];
                
                emailOrPasswordField.text = passwordField.text;
                [self loginUser];
            } else if (buttonIndex == kPopUpButtonNewUser) {
                [self setUpForUserIntention:kUserIntentionRegistration];
                
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
            [self setUpForUserIntention:kUserIntentionLogin];
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
    
    if (response.statusCode != kHTTPStatusCodeOK) {
        [self indicatePendingServerSession:NO];
    }
    
    if (authPhase == ScAuthPhaseConfirmation) {
        if (response.statusCode == kHTTPStatusCodeNoContent) {
            [self userDidLogIn:emailAsEntered isNewUser:YES];
        }
    } else if (authPhase == ScAuthPhaseLogin) {
        if (response.statusCode == kHTTPStatusCodeNotModified) {
            [self userDidLogIn:emailAsEntered isNewUser:NO];
        }
    } else if (response.statusCode >= kHTTPStatusCodeBadRequest) {
        [ScMeta m].isUserLoggedIn = NO;
        
        if (response.statusCode == kHTTPStatusCodeUnauthorized) {
            NSString *alertMessage = [ScStrings stringForKey:strNotLoggedInAlert];
            
            UIAlertView *notLoggedInAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:self cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
            notLoggedInAlert.tag = ScAuthPopUpTagNotLoggedIn;
            
            [notLoggedInAlert show];
        } else {
            [ScServerConnection showAlertForHTTPStatus:response.statusCode tagWith:ScAuthPopUpTagServerError usingDelegate:self];
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
    [ScServerConnection showAlertForError:error tagWith:ScAuthPopUpTagServerError usingDelegate:self];
}

@end
