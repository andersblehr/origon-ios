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
static int const kValuesDoNotMatchPopUpButtonIndexGoBack = 0;
static int const kValuesDoNotMatchPopUpButtonIndexTryAgain = 1;

@implementation ScRootViewController

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
    
    switch (membershipStatusControl.selectedSegmentIndex) {
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
    
    currentMembershipSegment = membershipStatusControl.selectedSegmentIndex;
}


- (void)setUpForUserRegistration
{
    membershipStatusControl.enabled = YES;
    chooseNewPasswordField.hidden = NO;
    
    nameOrEmailOrRegistrationCodeField.text = @"";
    emailOrPasswordOrScolaShortnameField.text = @"";
    chooseNewPasswordField.text = @"";
    
    membershipStatusControl.selectedSegmentIndex = kMembershipSegmentNew;
    [self membershipStatusChanged];
}


- (void)setUpForUserConfirmation
{
    membershipStatusControl.enabled = NO;
    chooseNewPasswordField.hidden = YES;
    
    userHelpLabel.text = [ScStrings stringForKey:strUserHelpCompleteRegistration];
    nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strRegistrationCodePrompt];
    emailOrPasswordOrScolaShortnameField.placeholder = [ScStrings stringForKey:strRepeatPasswordPrompt];
    emailOrPasswordOrScolaShortnameField.secureTextEntry = YES;
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


- (NSString *)generatePasswordHash:(NSString *)password usingSalt:(NSString *)salt
{
    NSString *saltyDiff = [password diff:salt];
    
    return [saltyDiff hashUsingSHA1];
}


#pragma mark - Input validation

- (BOOL)isNameValid
{
    BOOL isValid = NO;
    
    switch (membershipStatusControl.selectedSegmentIndex) {
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

    if (!isValid) {
        [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)isEmailValid
{
    BOOL isValid = NO;
    NSString *email = nil;
    
    if (membershipStatusControl.selectedSegmentIndex == kMembershipSegmentNew) {
        email = emailOrPasswordOrScolaShortnameField.text;
        
        NSUInteger atLocation = [email rangeOfString:@"@"].location;
        NSUInteger dotLocation = [email rangeOfString:@"." options:NSBackwardsSearch].location;
        NSUInteger spaceLocation = [email rangeOfString:@" "].location;
        
        isValid = (atLocation != NSNotFound);
        isValid = isValid && (dotLocation != NSNotFound);
        isValid = isValid && (dotLocation > atLocation);
        isValid = isValid && (spaceLocation == NSNotFound);
    } else {
        ScLogBreakage(@"Attempt to validate email while not in 'New' segment");
    }
    
    if (!isValid) {
        [emailOrPasswordOrScolaShortnameField becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)isPasswordValid
{
    BOOL isValid = NO;
    
    if (membershipStatusControl.selectedSegmentIndex == kMembershipSegmentMember) {
        ScLogBreakage(@"Attempt to validate password while in 'Member' segment");
    } else {
        isValid = (chooseNewPasswordField.text.length >= kMinimumPassordLength);
    }
    
    if (!isValid) {
        chooseNewPasswordField.text = @"";
        [chooseNewPasswordField becomeFirstResponder];
    }
    
    return isValid;
}


- (BOOL)isInvitationCodeValid
{
    BOOL isValid = NO;
    
    switch (membershipStatusControl.selectedSegmentIndex) {
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
    
    if (!isValid) {
        [emailOrPasswordOrScolaShortnameField becomeFirstResponder];
    }
    
    return isValid;
}


#pragma mark - User registration and authentication

- (void)registerNewUser
{
    NSString *userName = nameOrEmailOrRegistrationCodeField.text;
    NSString *emailOrScolaShortname = emailOrPasswordOrScolaShortnameField.text;
    NSString *userPassword = chooseNewPasswordField.text;
    NSString *authString = [NSString stringWithFormat:@"%@:%@", emailOrScolaShortname, userPassword];
    
    nameOrEmailOrRegistrationCodeField.text = @"";
    nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strPleaseWait];
    emailOrPasswordOrScolaShortnameField.text = @"";
    emailOrPasswordOrScolaShortnameField.placeholder = [ScStrings stringForKey:strPleaseWait];
    chooseNewPasswordField.hidden = YES;
    
    ScServerConnection *serverConnection = [[ScServerConnection alloc] initForUserRegistration];
    
    [serverConnection setValue:userName forURLParameter:@"name"];
    [serverConnection setValue:[NSString stringWithFormat:@"Basic %@", [authString base64EncodedString]] forHTTPHeaderField:@"Authorization"];
    [serverConnection getRemoteClass:@"ScAuthState" usingDelegate:self];
    
    isEditingAllowed = NO;
    membershipStatusControl.enabled = NO;
    
    [activityIndicator startAnimating];
}


- (void)authenticateUser
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
        
        // [self setUpTypewriterAudioForSplashSequence]; // TODO: Comment back in!
        scolaSplashLabel.text = @"";
        
        isEditingAllowed = YES;
        nameOrEmailOrRegistrationCodeField.delegate = self;
        emailOrPasswordOrScolaShortnameField.delegate = self;
        chooseNewPasswordField.delegate = self;
        chooseNewPasswordField.secureTextEntry = YES;
        activityIndicator.hidesWhenStopped = YES;
        
        if ([ScStrings areStringsAvailable]) {
            membershipPromptLabel.text = [ScStrings stringForKey:strMembershipPrompt];
            
            [membershipStatusControl setTitle:[ScStrings stringForKey:strIsNew] forSegmentAtIndex:kMembershipSegmentNew];
            [membershipStatusControl setTitle:[ScStrings stringForKey:strIsInvited] forSegmentAtIndex:kMembershipSegmentInvited];
            [membershipStatusControl setTitle:[ScStrings stringForKey:strIsMember] forSegmentAtIndex:kMembershipSegmentMember];
            [membershipStatusControl addTarget:self action:@selector(membershipStatusChanged) forControlEvents:UIControlEventValueChanged];
            
            chooseNewPasswordField.placeholder = [ScStrings stringForKey:strNewPasswordPrompt];
            scolaDescriptionTextView.text = [ScStrings stringForKey:strScolaDescription];
            
            [self setUpForUserRegistration];
        } else {
            membershipPromptLabel.hidden = YES;
            membershipStatusControl.hidden = YES;
            userHelpLabel.hidden = YES;
            nameOrEmailOrRegistrationCodeField.hidden = YES;
            emailOrPasswordOrScolaShortnameField.hidden = YES;
            chooseNewPasswordField.hidden = YES;
            scolaDescriptionHeadingLabel.hidden = YES;
            
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
        
        if (authState) {
            if ([authState objectForKey:@"scolaShortname"]) {
                membershipStatusControl.selectedSegmentIndex = kMembershipSegmentInvited;
            } else {
                membershipStatusControl.selectedSegmentIndex = kMembershipSegmentNew;
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
    
    switch (membershipStatusControl.selectedSegmentIndex) {
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
        
        switch (membershipStatusControl.selectedSegmentIndex) {
            case kMembershipSegmentNew:
            case kMembershipSegmentInvited:
                [self registerNewUser];
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
        emailAsEntered = [authState objectForKey:@"userEmail"];
        passwordAsEntered = emailOrPasswordOrScolaShortnameField.text;
        
        NSString *passwordHashFromServer = [authState objectForKey:@"passwordHash"];
        NSString *passwordHashAsEntered = [self generatePasswordHash:passwordAsEntered usingSalt:emailAsEntered];
        
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
    switch (alertView.tag) {
        case kEmailSentPopUpTag:
            if (buttonIndex == kEmailSentPopUpButtonIndexContinue) {
                [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
            } else if (buttonIndex == kEmailSentPopUpButtonIndexLater) {
                NSString *popUpTitle = [ScStrings stringForKey:strSeeYouLaterPopUpTitle];
                NSString *popUpMessage = [ScStrings stringForKey:strSeeYouLaterPopUpMessage];
                NSString *OKButtonTitle = [ScStrings stringForKey:strOK];
                
                UIAlertView *seeYouLaterPopUp = [[UIAlertView alloc] initWithTitle:popUpTitle message:popUpMessage delegate:nil cancelButtonTitle:OKButtonTitle otherButtonTitles:nil];
                [seeYouLaterPopUp show];
            }
            
            break;
            
        case kRegistrationCodesDoNotMatchPopUpTag:
        case kPasswordsDoNotMatchPopUpTag:
            if (buttonIndex == kValuesDoNotMatchPopUpButtonIndexTryAgain) {
                if (alertView.tag == kRegistrationCodesDoNotMatchPopUpTag) {
                    [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
                } else if (alertView.tag == kPasswordsDoNotMatchPopUpTag) {
                    emailOrPasswordOrScolaShortnameField.text = @"";
                    [emailOrPasswordOrScolaShortnameField becomeFirstResponder];
                }
            } else if (buttonIndex == kValuesDoNotMatchPopUpButtonIndexGoBack) {
                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults removeObjectForKey:kUserDefaultsKeyAuthState];
                
                [self resignCurrentFirstResponder];
                [self setUpForUserRegistration];
            }
            
            break;

        case kWelcomeBackPopUpTag:
            [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
            
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
    ScLogInfo(@"Received HTTP response. Status code: %d", response.statusCode);
}


- (void)finishedReceivingData:(NSDictionary *)authState
{
    ScLogInfo(@"Received data: %@", authState);
    
    if (membershipStatusControl.selectedSegmentIndex == kMembershipSegmentNew) {
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
        [self setUpForUserConfirmation];
    }
}


@end
