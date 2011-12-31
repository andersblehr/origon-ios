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

static NSString * const kSoundbiteTypewriter = @"typewriter.caf";

static NSString * const kSegueToMainPage = @"rootViewToMainPage";

static int const kMembershipSegmentNew     = 0;
static int const kMembershipSegmentInvited = 1;
static int const kMembershipSegmentMember  = 2;

static int const kMinimumPassordLength        = 6;
static int const kMinimumScolaShortnameLength = 4;

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


#pragma mark - Utility methods

- (BOOL)shouldGoStraightToMainPage
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
    
    isEditingAllowed = NO;
    
    membershipStatus.enabled = NO;
    userHelpLabel.hidden = YES;
    nameOrEmailOrRegistrationCodeField.text = @"";
    nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strPleaseWait];
    emailOrPasswordOrScolaShortnameField.text = @"";
    emailOrPasswordOrScolaShortnameField.placeholder = [ScStrings stringForKey:strPleaseWait];
    chooseNewPasswordField.hidden = YES;
    
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
{   /*
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
    [typewriter1 play]; */
    [scolaSplashLabel performSelectorOnMainThread:@selector(setText:)
                                       withObject:@"..scola.."
                                    waitUntilDone:YES];

    didRunSplashSequence = YES;
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

    if ([self shouldGoStraightToMainPage]) {
        [self performSegueWithIdentifier:kSegueToMainPage sender:self];
    } else {
        [darkLinenView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignFirstResponder:)]];
        
        didRunSplashSequence = NO;
        
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
            
            membershipStatus.selectedSegmentIndex = kMembershipSegmentNew;
            [self membershipStatusChanged:self];
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
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!didRunSplashSequence) {
        NSThread *splashSequenceThread = [[NSThread alloc] initWithTarget:self selector:@selector(runSplashSequence:) object:nil];
        
        [splashSequenceThread start];
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


- (BOOL)textFieldShouldReturn:(UITextField *)textField
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
            isEmailValid = [self isEmailValid];
            isPasswordValid = [self isPasswordValid];
            
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
            isInvitationCodeValid = [self isInvitationCodeValid];
            isPasswordValid = [self isPasswordValid];
            
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
            isPasswordValid = [self isPasswordValid];
            
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
        
        //[self performSegueWithIdentifier:<#(NSString *)#> sender:<#(id)#>
    } else {
        UIAlertView *popUpAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [popUpAlert show];
    }
    
    return shouldReturn;
}


#pragma mark - UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    ScLogDebug(@"Clicked button at index %d", buttonIndex);
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


- (void)finishedReceivingData:(NSDictionary *)dataAsDictionary
{
    ScLogInfo(@"Received data: %@", dataAsDictionary);
    
    if (membershipStatus.selectedSegmentIndex == kMembershipSegmentNew) {
        [activityIndicator stopAnimating];
        
        NSString *userEmail = [dataAsDictionary objectForKey:@"userEmail"];

        UIAlertView *emailSentPopUp = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:[ScStrings stringForKey:strEmailSentPopUp], userEmail] delegate:self cancelButtonTitle:[ScStrings stringForKey:strLater] otherButtonTitles:[ScStrings stringForKey:strContinue], nil];
        [emailSentPopUp show];
        
        userHelpLabel.text = [ScStrings stringForKey:strPleaseProvide];
        userHelpLabel.hidden = NO;
        nameOrEmailOrRegistrationCodeField.placeholder = [ScStrings stringForKey:strRegistrationCodePrompt];
        emailOrPasswordOrScolaShortnameField.placeholder = [ScStrings stringForKey:strRepeatPasswordPrompt];
        
        isEditingAllowed = YES;
    }
}


@end
