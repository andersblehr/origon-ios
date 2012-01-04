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
static int const kScolaNotFoundPopUpTag = 4;
static int const kInvitationNotFoundPopUpTag = 5;

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
            break;
            
        case kMembershipSegmentInvited:
            nameAsEntered = nameOrEmailOrRegistrationCodeField.text;
            scolaShortnameAsEntered = emailOrPasswordOrScolaShortnameField.text;
            break;
            
        case kMembershipSegmentMember:
            emailAsEntered = nameOrEmailOrRegistrationCodeField.text;
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
            chooseNewPasswordField.text = @"";
            
            break;
            
        case kMembershipSegmentInvited:
            userHelpLabel.text = [ScStrings stringForKey:strUserHelpInvited];
            
            nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strNameAsReceivedPrompt];
            emailOrPasswordOrScolaShortnameField.placeholder = [ScStrings stringForKey:strScolaShortnamePrompt];
            chooseNewPasswordField.hidden = NO;
            
            nameOrEmailOrRegistrationCodeField.text = nameAsEntered;
            emailOrPasswordOrScolaShortnameField.secureTextEntry = NO;
            emailOrPasswordOrScolaShortnameField.text = scolaShortnameAsEntered;
            chooseNewPasswordField.text = @"";
            
            break;
            
        case kMembershipSegmentMember:
            userHelpLabel.text = [ScStrings stringForKey:strUserHelpMember];
            
            nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strEmailPrompt];
            emailOrPasswordOrScolaShortnameField.placeholder = [ScStrings stringForKey:strPasswordPrompt];
            chooseNewPasswordField.hidden = YES;
            
            nameOrEmailOrRegistrationCodeField.text = emailAsEntered;
            emailOrPasswordOrScolaShortnameField.secureTextEntry = YES;
            emailOrPasswordOrScolaShortnameField.text = @"";
            
            break;
            
        default:
            break;
    }
    
    currentMembershipSegment = membershipStatusControl.selectedSegmentIndex;
    
    if (isEditing) {
        if ([nameOrEmailOrRegistrationCodeField.text isEqualToString:@""]) {
            [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
        } else if ([emailOrPasswordOrScolaShortnameField.text isEqualToString:@""]) {
            [emailOrPasswordOrScolaShortnameField becomeFirstResponder];
        } else if (chooseNewPasswordField.hidden == NO) {
            [chooseNewPasswordField becomeFirstResponder];
        } else {
            [nameOrEmailOrRegistrationCodeField becomeFirstResponder];
        }
    }
}


- (void)setUpForUserRegistration:(int)membershipSegment;
{
    membershipStatusControl.enabled = YES;
    chooseNewPasswordField.hidden = NO;
    
    nameOrEmailOrRegistrationCodeField.text = nameAsEntered;
    
    if (membershipSegment == kMembershipSegmentNew) {
        emailOrPasswordOrScolaShortnameField.text = emailAsEntered;
    } else if (membershipSegment == kMembershipSegmentInvited) {
        emailOrPasswordOrScolaShortnameField.text = scolaShortnameAsEntered;
    }
    
    chooseNewPasswordField.text = @"";
    
    membershipStatusControl.selectedSegmentIndex = membershipSegment;
    [self membershipStatusChanged];
}


- (void)setUpForUserConfirmation
{
    membershipStatusControl.enabled = NO;
    chooseNewPasswordField.hidden = YES;
    
    nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strRegistrationCodePrompt];
    emailOrPasswordOrScolaShortnameField.placeholder = [ScStrings stringForKey:strRepeatPasswordPrompt];
    emailOrPasswordOrScolaShortnameField.secureTextEntry = YES;
    
    userHelpLabel.text = [ScStrings stringForKey:strUserHelpCompleteRegistration];
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
    
    if (membershipStatusControl.selectedSegmentIndex == kMembershipSegmentMember) {
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
    
    if (membershipStatusControl.selectedSegmentIndex == kMembershipSegmentMember) {
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
    
    if (membershipStatusControl.selectedSegmentIndex == kMembershipSegmentMember) {
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
    
    if (membershipStatusControl.selectedSegmentIndex == kMembershipSegmentInvited) {
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
    
    serverConnection = [[ScServerConnection alloc] initForUserRegistration];
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
        
        if ([ScServerConnection isServerAvailable]) {
            membershipPromptLabel.text = [ScStrings stringForKey:strMembershipPrompt];
            
            [membershipStatusControl setTitle:[ScStrings stringForKey:strIsNew] forSegmentAtIndex:kMembershipSegmentNew];
            [membershipStatusControl setTitle:[ScStrings stringForKey:strIsInvited] forSegmentAtIndex:kMembershipSegmentInvited];
            [membershipStatusControl setTitle:[ScStrings stringForKey:strIsMember] forSegmentAtIndex:kMembershipSegmentMember];
            [membershipStatusControl addTarget:self action:@selector(membershipStatusChanged) forControlEvents:UIControlEventValueChanged];
            
            chooseNewPasswordField.placeholder = [ScStrings stringForKey:strNewPasswordPrompt];
            scolaDescriptionTextView.text = [ScStrings stringForKey:strScolaDescription];
            
            [self setUpForUserRegistration:kMembershipSegmentNew];
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
    
    if (membershipPromptLabel.hidden == NO) {
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
    if (isEditingAllowed) {
        isEditing = YES;
    }
    
    return isEditingAllowed;
}


- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    BOOL shouldRemove = YES;
    
    if (membershipStatusControl.selectedSegmentIndex == kMembershipSegmentMember) {
        shouldRemove = (textField != emailOrPasswordOrScolaShortnameField);
    } else {
        shouldRemove = (textField != chooseNewPasswordField);
    }

    if (shouldRemove) {
        NSString *text = textField.text;
        textField.text = [text removeLeadingAndTrailingSpaces];
    }
    
    isEditing = NO;
    
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
        isEditing = NO;
        
        if (membershipStatusControl.selectedSegmentIndex == kMembershipSegmentMember) {
            [self authenticateUser];
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
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *authState = [userDefaults objectForKey:kUserDefaultsKeyAuthState];
    
    NSString *registrationCodeAsSent = [[authState objectForKey:@"registrationCode"] lowercaseString];
    NSString *registrationCodeAsEntered = [nameOrEmailOrRegistrationCodeField.text lowercaseString];
    
    NSString *alertMessage = nil;
    int alertTag;
    
    doRegistrationCodesMatch = [registrationCodeAsEntered isEqualToString:registrationCodeAsSent];
    
    if (doRegistrationCodesMatch) {
        NSString *email = [authState objectForKey:@"userEmail"];
        NSString *password = emailOrPasswordOrScolaShortnameField.text;
        
        NSString *passwordHashFromServer = [authState objectForKey:@"passwordHash"];
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
        [userDefaults removeObjectForKey:kUserDefaultsKeyAuthState];
        [textField resignFirstResponder];
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
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *authState = [userDefaults objectForKey:kUserDefaultsKeyAuthState];
    
    if (authState) {
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
                NSDictionary *authState = [userDefaults objectForKey:kUserDefaultsKeyAuthState];
                NSString *scolaShortname = [authState objectForKey:@"scolaShortname"];
                
                [userDefaults removeObjectForKey:kUserDefaultsKeyAuthState];
                [self resignCurrentFirstResponder];
                
                if (scolaShortname) {
                    [self setUpForUserRegistration:kMembershipSegmentInvited];
                } else {
                    [self setUpForUserRegistration:kMembershipSegmentNew];
                }
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
    ScLogDebug(@"Received response. HTTP status code: %d", response.statusCode);
    
    if (serverConnection.HTTPStatusCode == kHTTPStatusCodeNotFound) {
        [activityIndicator stopAnimating];
        
        NSDictionary *responseHeaders = [response allHeaderFields];
        NSString *reason = [responseHeaders objectForKey:@"reason"];
        NSString *alertMessage;
        int alertTag;
        
        if ([reason isEqualToString:@"scolaShortname"]) {
            alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strNoScolaWithShortnameAlert], scolaShortnameAsEntered];
            alertTag = kScolaNotFoundPopUpTag;
        } else if ([reason isEqualToString:@"name"]) {
            alertMessage = [NSString stringWithFormat:[ScStrings stringForKey:strScolaHasNoListingForNameAlert], nameAsEntered, scolaShortnameAsEntered];
            alertTag = kInvitationNotFoundPopUpTag;
        }
        
        UIAlertView *notFoundAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:self cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
        notFoundAlert.tag = alertTag;
        
        [notFoundAlert show];
        
        isEditingAllowed = YES;
    }
}


- (void)finishedReceivingData:(NSDictionary *)authState
{
    [activityIndicator stopAnimating];
    
    if (serverConnection.HTTPStatusCode == kHTTPStatusCodeOK) {
        ScLogInfo(@"Received data: %@", authState);
        
        if (membershipStatusControl.selectedSegmentIndex == kMembershipSegmentNew) {
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
}


@end
