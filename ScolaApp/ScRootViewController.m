//
//  ScRootViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 01.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScRootViewController.h"

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

static int const kMembershipSegmentNew = 0;
static int const kMembershipSegmentInvited = 1;
static int const kMembershipSegmentMember = 2;

static int const kEmailSentPopUpTag = 0;
static int const kRegistrationCodesDoNotMatchPopUpTag = 1;
static int const kPasswordsDoNotMatchPopUpTag = 2;
static int const kWelcomeBackPopUpTag = 3;

static int const kEmailSentPopUpButtonIndexLater = 0;
static int const kEmailSentPopUpButtonIndexContinue = 1;
static int const kRegistrationCodesDoNotMatchPopUpButtonIndexTryAgain = 1;
static int const kRegistrationCodesDoNotMatchPopUpButtonIndexGoBack = 0;
static int const kPasswordsDoNotMatchPopUpButtonIndexTryAgain = 1;
static int const kPasswordsDoNotMatchPopUpButtonIndexGoBack = 0;

@implementation ScRootViewController

@synthesize darkLinenView;
@synthesize promptLabel;
@synthesize membershipStatus;
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


- (void)startSplashSequenceThread
{
    NSThread *splashSequenceThread = [[NSThread alloc] initWithTarget:self selector:@selector(runSplashSequence:) object:nil];
    
    [splashSequenceThread start];
}


- (void)setUpForUserRegistration
{
    ScLogDebug(@"Need to start factoring out this method tomorrow..");
}


- (void)setUpForUserConfirmation
{
    membershipStatus.enabled = NO;
    userHelpLabel.hidden = YES;
    chooseNewPasswordField.hidden = YES;
    
    userHelpLabel.text = [ScStrings stringForKey:strUserHelpCompleteRegistration];
    userHelpLabel.hidden = NO;
    nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strRegistrationCodePrompt];
    emailOrPasswordOrScolaShortnameField.placeholder = [ScStrings stringForKey:strRepeatPasswordPrompt];
    emailOrPasswordOrScolaShortnameField.secureTextEntry = YES;
}


- (NSString *)generatePasswordHash:(NSString *)password
{
    NSString *saltyDiff = [password diff:[ScAppEnv env].deviceUUID];
    
    return [saltyDiff hashUsingSHA1];
}


#pragma mark - Input validation

- (BOOL)isNameValid
{
    BOOL isValid = NO;
    
    switch (membershipStatus.selectedSegmentIndex) {
        case kMembershipSegmentNew:
        case kMembershipSegmentInvited:
            isValid = ([nameOrEmailOrRegistrationCodeField.text rangeOfString:@" "].location != NSNotFound);
            break;
            
        case kMembershipSegmentMember:
            ScLogBreakage(@"Attempt to validate name while in 'Member' segment");
            break;
            
        default:
            break;
    }
    
    return isValid;
}


- (BOOL)isEmailValid
{
    BOOL isValid = NO;
    NSString *email = nil;
    
    switch (membershipStatus.selectedSegmentIndex) {
        case kMembershipSegmentNew:
            email = emailOrPasswordOrScolaShortnameField.text;
            break;
            
        case kMembershipSegmentInvited:
            ScLogBreakage(@"Attempt to validate email while in 'Invited' segment");
            break;
            
        case kMembershipSegmentMember:
            email = nameOrEmailOrRegistrationCodeField.text;
            break;
            
        default:
            break;
    }
    
    isValid =
    (([email rangeOfString:@"@"].location != NSNotFound) &&
     ([email rangeOfString:@"."].location != NSNotFound) &&
     ([email rangeOfString:@" "].location == NSNotFound));
    
    return isValid;
}


- (BOOL)isPasswordValid
{
    BOOL isValid = NO;
    
    switch (membershipStatus.selectedSegmentIndex) {
        case kMembershipSegmentNew:
        case kMembershipSegmentInvited:
            isValid = (chooseNewPasswordField.text.length >= kMinimumPassordLength);
            break;
            
        case kMembershipSegmentMember:
            isValid = (emailOrPasswordOrScolaShortnameField.text.length > kMinimumPassordLength);
            break;
            
        default:
            break;
    }
    
    return isValid;
}


- (BOOL)isInvitationCodeValid
{
    BOOL isValid = NO;
    
    switch (membershipStatus.selectedSegmentIndex) {
        case kMembershipSegmentNew:
            ScLogBreakage(@"Attempt to validate Scola shortname while in 'New' segnemt");
            break;
            
        case kMembershipSegmentInvited:
            isValid = (emailOrPasswordOrScolaShortnameField.text.length >= kMinimumScolaShortnameLength);
            break;
            
        case kMembershipSegmentMember:
            ScLogBreakage(@"Attempt to validate Scola shortname while in 'Member' segnemt");
            break;
            
        default:
            break;
    }
    
    return isValid;
}


#pragma mark - User registration and authentication

- (void)registerNewUser
{
    NSString *userName = nameOrEmailOrRegistrationCodeField.text;
    NSString *userEmail = emailOrPasswordOrScolaShortnameField.text;
    NSString *userPassword = chooseNewPasswordField.text;
    NSString *authString = [NSString stringWithFormat:@"%@:%@", userEmail, userPassword];
    
    ScServerConnection *serverConnection = [[ScServerConnection alloc] initForUserRegistration];
    
    [serverConnection setValue:userName forURLParameter:@"name"];
    [serverConnection setValue:[NSString stringWithFormat:@"Basic %@", [authString base64EncodedString]] forHTTPHeaderField:@"Authorization"];
    [serverConnection getRemoteClass:@"ScAuthState" usingDelegate:self];
    
    nameOrEmailOrRegistrationCodeField.text = @"";
    nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strPleaseWait];
    emailOrPasswordOrScolaShortnameField.text = @"";
    emailOrPasswordOrScolaShortnameField.placeholder = [ScStrings stringForKey:strPleaseWait];
    
    [self setUpForUserConfirmation];
    
    isEditingAllowed = NO;
    [activityIndicator startAnimating];
}


- (void)registerInvitedUser
{
    
}


- (void)authenticateUser
{
    
}


#pragma mark - NSThread selector

- (void)runSplashSequence:(id)sender
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


#pragma mark - UISegmentedControl selector

- (void)membershipStatusChanged:(id)sender
{
    switch (currentMembershipSegment) {
        case kMembershipSegmentNew:
            nameAsEntered = nameOrEmailOrRegistrationCodeField.text;
            emailAsEntered = emailOrPasswordOrScolaShortnameField.text;
            passwordAsEntered = chooseNewPasswordField.text;
            break;
            
        case kMembershipSegmentInvited:
            nameAsEntered = nameOrEmailOrRegistrationCodeField.text;
            invitationCodeAsEntered = emailOrPasswordOrScolaShortnameField.text;
            passwordAsEntered = chooseNewPasswordField.text;
            break;
            
        case kMembershipSegmentMember:
            emailAsEntered = nameOrEmailOrRegistrationCodeField.text;
            passwordAsEntered = emailOrPasswordOrScolaShortnameField.text;
            break;
            
        default:
            break;
    }
    
    if ([emailOrPasswordOrScolaShortnameField isFirstResponder] || [chooseNewPasswordField isFirstResponder]) {
        [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
    }
    
    switch (membershipStatus.selectedSegmentIndex) {
        case kMembershipSegmentNew:
            userHelpLabel.text = [ScStrings stringForKey:strUserHelpNew];
            
            nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strNamePrompt];
            emailOrPasswordOrScolaShortnameField.placeholder = [ScStrings stringForKey:strEmailPrompt];
            chooseNewPasswordField.hidden = NO;
            
            nameOrEmailOrRegistrationCodeField.text = nameAsEntered;
            emailOrPasswordOrScolaShortnameField.secureTextEntry = NO;
            emailOrPasswordOrScolaShortnameField.text = emailAsEntered;
            chooseNewPasswordField.text = passwordAsEntered;
            
            break;
            
        case kMembershipSegmentInvited:
            userHelpLabel.text = [ScStrings stringForKey:strUserHelpInvited];
            
            nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strNameAsReceivedPrompt];
            emailOrPasswordOrScolaShortnameField.placeholder = [ScStrings stringForKey:strInvitationCodePrompt];
            chooseNewPasswordField.hidden = NO;
            
            nameOrEmailOrRegistrationCodeField.text = nameAsEntered;
            emailOrPasswordOrScolaShortnameField.secureTextEntry = NO;
            emailOrPasswordOrScolaShortnameField.text = invitationCodeAsEntered;
            chooseNewPasswordField.text = passwordAsEntered;
            
            break;
            
        case kMembershipSegmentMember:
            userHelpLabel.text = [ScStrings stringForKey:strUserHelpMember];

            nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strEmailPrompt];
            emailOrPasswordOrScolaShortnameField.placeholder = [ScStrings stringForKey:strPasswordPrompt];
            chooseNewPasswordField.hidden = YES;
            
            nameOrEmailOrRegistrationCodeField.text = emailAsEntered;
            emailOrPasswordOrScolaShortnameField.secureTextEntry = YES;
            emailOrPasswordOrScolaShortnameField.text = passwordAsEntered;
            
            break;
            
        default:
            break;
    }
    
    currentMembershipSegment = membershipStatus.selectedSegmentIndex;
}


#pragma mark - UITapGestureRecognizer selector

- (void)resignFirstResponder:(id)sender
{
    if ([nameOrEmailOrRegistrationCodeField isFirstResponder]) {
        [nameOrEmailOrRegistrationCodeField resignFirstResponder];
    } else if ([emailOrPasswordOrScolaShortnameField isFirstResponder]) {
        [emailOrPasswordOrScolaShortnameField resignFirstResponder];
    } else if ([chooseNewPasswordField isFirstResponder]) {
        [chooseNewPasswordField resignFirstResponder];
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

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *authToken = [userDefaults objectForKey:kUserDefaultsKeyAuthToken];
    
    if ([self isValidAuthToken:authToken]) {
        [self performSegueWithIdentifier:kSegueToMainPage sender:self];
    } else {
        [darkLinenView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignFirstResponder:)]];
        
        // [self setUpTypewriterAudioForSplashSequence]; // TODO: Comment back in!
        scolaSplashLabel.text = @"";
        activityIndicator.hidesWhenStopped = YES;
        
        nameOrEmailOrRegistrationCodeField.delegate = self;
        emailOrPasswordOrScolaShortnameField.delegate = self;
        chooseNewPasswordField.delegate = self;
        
        BOOL areStringsAvailable = [ScStrings areStringsAvailable];
        
        promptLabel.hidden = !areStringsAvailable;
        membershipStatus.hidden = !areStringsAvailable;
        userHelpLabel.hidden = !areStringsAvailable;
        nameOrEmailOrRegistrationCodeField.hidden = !areStringsAvailable;
        emailOrPasswordOrScolaShortnameField.hidden = !areStringsAvailable;
        chooseNewPasswordField.hidden = !areStringsAvailable;
        scolaDescriptionHeadingLabel.hidden = !areStringsAvailable;
        
        chooseNewPasswordField.secureTextEntry = YES;
        
        if (areStringsAvailable) {
            isEditingAllowed = YES;
            
            promptLabel.text = [ScStrings stringForKey:strMembershipPrompt];
            chooseNewPasswordField.placeholder = [ScStrings stringForKey:strNewPasswordPrompt];
            scolaDescriptionTextView.text = [ScStrings stringForKey:strScolaDescription];
            
            [membershipStatus setTitle:[ScStrings stringForKey:strIsNew] forSegmentAtIndex:kMembershipSegmentNew];
            [membershipStatus setTitle:[ScStrings stringForKey:strIsInvited] forSegmentAtIndex:kMembershipSegmentInvited];
            [membershipStatus setTitle:[ScStrings stringForKey:strIsMember] forSegmentAtIndex:kMembershipSegmentMember];
            
            [membershipStatus addTarget:self action:@selector(membershipStatusChanged:)forControlEvents:UIControlEventValueChanged];
        } else {
            scolaDescriptionTextView.font = [UIFont systemFontOfSize:14];
            
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
    
    if ([ScStrings areStringsAvailable]) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *authState = [userDefaults objectForKey:kUserDefaultsKeyAuthState];
        
        if (!authState) {
            membershipStatus.selectedSegmentIndex = kMembershipSegmentNew;
            [self membershipStatusChanged:self];
        } else {
            NSString *scolaShortname = [authState objectForKey:@"scolaShortname"];
            
            if (scolaShortname) {
                membershipStatus.selectedSegmentIndex = kMembershipSegmentInvited;
            } else {
                membershipStatus.selectedSegmentIndex = kMembershipSegmentNew;
            }
            
            [self setUpForUserConfirmation];
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self startSplashSequenceThread];
    
    if ([ScStrings areStringsAvailable]) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *authState = [userDefaults objectForKey:kUserDefaultsKeyAuthState];
        
        if (authState) {
            NSString *userEmail = [authState objectForKey:@"userEmail"];
            NSString *popUpTitle = [ScStrings stringForKey:strWelcomeBackPopUpTitle];
            NSString *popUpMessage = [NSString stringWithFormat:[ScStrings stringForKey:strWelcomeBackPopUpMessage], userEmail];
            NSString *OKButtonTitle = [ScStrings stringForKey:strOK];
            
            UIAlertView *welcomeBackPopUp = [[UIAlertView alloc] initWithTitle:popUpTitle message:popUpMessage delegate:self cancelButtonTitle:OKButtonTitle otherButtonTitles:nil];
            welcomeBackPopUp.tag = kWelcomeBackPopUpTag;
            
            [welcomeBackPopUp show];
        }
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


- (BOOL)userRegistrationTextFieldShouldReturn:(UITextField *)textField
{
    BOOL shouldReturn = NO;
    
    BOOL isNameValid = NO;
    BOOL isEmailValid = NO;
    BOOL isPasswordValid = NO;
    BOOL isInvitationCodeValid = NO;
    
    NSString *alertMessage = nil;
    
    switch (membershipStatus.selectedSegmentIndex) {
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
            isInvitationCodeValid = isNameValid && [self isInvitationCodeValid];
            isPasswordValid = isInvitationCodeValid && [self isPasswordValid];
            
            if (!isNameValid) {
                alertMessage = [ScStrings stringForKey:strInvalidNameAlert];
            } else if (!isInvitationCodeValid) {
                alertMessage = [ScStrings stringForKey:strInvalidInvitationCodeAlert];
            } else if (!isPasswordValid) {
                alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strInvalidPasswordAlert], kMinimumPassordLength];
            }
            
            shouldReturn = (isNameValid && isInvitationCodeValid && isPasswordValid);
            
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
        
        switch (membershipStatus.selectedSegmentIndex) {
            case kMembershipSegmentNew:
                [self registerNewUser];
                break;
                
            case kMembershipSegmentInvited:
                [self registerInvitedUser];
                break;
                
            case kMembershipSegmentMember:
                [self authenticateUser];
                break;
                
            default:
                break;
        }
    } else {
        NSString *OKButtonTitle  = [ScStrings stringForKey:strOK];
        
        UIAlertView *popUpAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:nil cancelButtonTitle:OKButtonTitle otherButtonTitles:nil];
        [popUpAlert show];
    }
    
    return shouldReturn;
}


- (BOOL)userConfirmationTextFieldShouldReturn:(UITextField *)textField
{
    BOOL doRegistrationCodesMatch = NO;
    BOOL doPasswordsMatch = NO;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *authState = [userDefaults objectForKey:kUserDefaultsKeyAuthState];
    
    NSString *registrationCodeAsSent = [[authState objectForKey:@"registrationCode"] lowercaseString];
    NSString *registrationCodeAsEntered = [nameOrEmailOrRegistrationCodeField.text lowercaseString];
    
    NSString *alertMessage = nil;
    int alertTag;
    
    doRegistrationCodesMatch = [registrationCodeAsEntered isEqualToString:registrationCodeAsSent];
    
    if (doRegistrationCodesMatch) {
        NSString *passwordHashFromServer = [authState objectForKey:@"passwordHash"];
        NSString *passwordHashAsEntered = [self generatePasswordHash:emailOrPasswordOrScolaShortnameField.text];
        
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
        [userDefaults removeObjectForKey:kUserDefaultsKeyAuthState];
        [textField resignFirstResponder];
    } else {        
        NSString *tryAgainTitle = [ScStrings stringForKey:strTryAgain];
        NSString *goBackTitle = [ScStrings stringForKey:strGoBack];
        
        UIAlertView *popUpAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:self cancelButtonTitle:goBackTitle otherButtonTitles:tryAgainTitle, nil];
        popUpAlert.tag = alertTag;
        
        [popUpAlert show];
    }
    
    return shouldReturn;  // LVJUQPAC
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    BOOL shouldReturn = NO;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *authState = [userDefaults objectForKey:kUserDefaultsKeyAuthState];
    
    if (authState) {
        shouldReturn = [self userConfirmationTextFieldShouldReturn:textField];
    } else {
        shouldReturn = [self userRegistrationTextFieldShouldReturn:textField];
    }
    
    return shouldReturn;
}


#pragma mark - UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kEmailSentPopUpTag) {
        if (buttonIndex == kEmailSentPopUpButtonIndexContinue) {
            [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
        } else if (buttonIndex == kEmailSentPopUpButtonIndexLater) {
            NSString *popUpTitle = [ScStrings stringForKey:strSeeYouLaterPopUpTitle];
            NSString *popUpMessage = [ScStrings stringForKey:strSeeYouLaterPopUpMessage];
            NSString *OKButtonTitle = [ScStrings stringForKey:strOK];
            
            UIAlertView *seeYouLaterPopUp = [[UIAlertView alloc] initWithTitle:popUpTitle message:popUpMessage delegate:nil cancelButtonTitle:OKButtonTitle otherButtonTitles:nil];
            [seeYouLaterPopUp show];
        }
    } else if (alertView.tag == kRegistrationCodesDoNotMatchPopUpTag) {
        if (buttonIndex == kRegistrationCodesDoNotMatchPopUpButtonIndexTryAgain) {
            [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
        } else if (buttonIndex == kRegistrationCodesDoNotMatchPopUpButtonIndexGoBack) {
            [self setUpForUserRegistration];
        }
    } else if (alertView.tag == kPasswordsDoNotMatchPopUpTag) {
        if (buttonIndex == kPasswordsDoNotMatchPopUpButtonIndexTryAgain) {
            emailOrPasswordOrScolaShortnameField.text = @"";
            [emailOrPasswordOrScolaShortnameField becomeFirstResponder];
        } else if (buttonIndex == kPasswordsDoNotMatchPopUpButtonIndexGoBack) {
            [self setUpForUserRegistration];
        }
    } else if (alertView.tag == kWelcomeBackPopUpTag) {
        [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
    }
}


#pragma mark - ScServerConnectionDelegate implementation

- (void)willSendRequest:(NSURLRequest *)request
{
    ScLogInfo(@"Sending asynchronous HTTP request with URL: %@", request.URL);
}


- (void)didReceiveResponse:(NSHTTPURLResponse *)response
{
    ScLogInfo(@"Received HTTP response. Status code: %d", response.statusCode);
}


- (void)finishedReceivingData:(NSDictionary *)authState
{
    ScLogInfo(@"Received data: %@", authState);
    
    if (membershipStatus.selectedSegmentIndex == kMembershipSegmentNew) {
        [activityIndicator stopAnimating];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:authState forKey:kUserDefaultsKeyAuthState];
        
        NSString *userEmail = [authState objectForKey:@"userEmail"];
        NSString *popUpTitle = [ScStrings stringForKey:strEmailSentPopUpTitle];
        NSString *popUpMessage = [NSString stringWithFormat:[ScStrings stringForKey:strEmailSentPopUpMessage], userEmail];
        NSString *laterButtonTitle = [ScStrings stringForKey:strLater];
        NSString *continueButtonTitle = [ScStrings stringForKey:strContinue];
        
        UIAlertView *emailSentPopUp = [[UIAlertView alloc] initWithTitle:popUpTitle message:popUpMessage delegate:self cancelButtonTitle:laterButtonTitle otherButtonTitles:continueButtonTitle, nil];
        emailSentPopUp.tag = kEmailSentPopUpTag;
        
        [emailSentPopUp show];
        
        isEditingAllowed = YES;
    }
}


@end
