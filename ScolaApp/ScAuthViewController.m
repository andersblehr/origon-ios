//
//  ScAuthViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 18.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScAuthViewController.h"

#import <AudioToolbox/AudioToolbox.h>

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "NSString+ScStringExtensions.h"
#import "UIColor+ScColorExtensions.h"
#import "UITableView+UITableViewExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScMeta.h"
#import "ScServerConnection.h"
#import "ScStrings.h"
#import "ScTableViewCell.h"
#import "ScTextField.h"
#import "ScUUIDGenerator.h"

#import "ScDevice.h"
#import "ScLogging.h"
#import "ScMember.h"
#import "ScMemberResidency.h"
#import "ScMessageBoard.h"
#import "ScScola.h"

#import "ScMember+ScMemberExtensions.h"
#import "ScScola+ScScolaExtensions.h"

#import "ScMemberViewController.h"

static NSString * const kSegueToMainView = @"authToMainView";
static NSString * const kSegueToMemberView = @"authToMemberView";

static NSString * const kUserDefaultsKeyAuthInfo = @"scola.auth.info";

static NSString * const kAuthInfoKeyUserId = @"userId";
static NSString * const kAuthInfoKeyPasswordHash = @"passwordHash";
static NSString * const kAuthInfoKeyRegistrationCode = @"registrationCode";
static NSString * const kAuthInfoKeyIsUserListed = @"isListed";
static NSString * const kAuthInfoKeyIsRegistered = @"isRegistered";
static NSString * const kAuthInfoKeyHomeScolaId = @"homeScolaId";

static NSInteger const kAlertButtonStartOver = 0;
static NSInteger const kAlertTagWelcomeBack = 0;


@implementation ScAuthViewController


#pragma mark - Auxiliary methods

- (void)indicatePendingServerSession:(BOOL)isPending
{
    static NSString *email;
    static NSString *password;
    static NSString *registrationCode;
    
    if (isPending) {
        if (authPhase == ScAuthPhaseLogin) {
            email = emailField.text;
            emailField.placeholder = [ScStrings stringForKey:strPleaseWait];
            emailField.text = @"";
        } else if (authPhase == ScAuthPhaseConfirmation) {
            registrationCode = registrationCodeField.text;
            registrationCodeField.placeholder = [ScStrings stringForKey:strPleaseWait];
            registrationCodeField.text = @"";
        }
        
        password = passwordField.text;
        passwordField.placeholder = [ScStrings stringForKey:strPleaseWait];
        passwordField.text = @"";
        
        isEditingAllowed = NO;
        
        [spinner startAnimating];
    } else {
        if (authPhase == ScAuthPhaseLogin) {
            emailField.text = email;
            emailField.placeholder = [ScStrings stringForKey:strAuthEmailPrompt];
        } else if (authPhase == ScAuthPhaseConfirmation) {
            registrationCodeField.text = registrationCode;
            registrationCodeField.placeholder = [ScStrings stringForKey:strRegistrationCodePrompt];
        }
        
        passwordField.text = password;
        passwordField.placeholder = [ScStrings stringForKey:strPasswordPrompt];
        
        isEditingAllowed = YES;
        
        [spinner stopAnimating];
    }
}


- (NSString *)generatePasswordHash:(NSString *)password usingSalt:(NSString *)salt
{
    return [[password diff:salt] hashUsingSHA1];
}


- (void)handleFailedConfirmationForField:(ScTextField *)field;
{
    if (numberOfConfirmationAttempts < 3) {
        [authCell shake];
        
        if (field == registrationCodeField) {
            registrationCodeField.text = @"";
        }
        
        passwordField.text = @"";
        
        [field becomeFirstResponder];
    } else {
        [[[UIAlertView alloc] initWithTitle:[ScStrings stringForKey:strUserConfirmationFailedTitle] message:[ScStrings stringForKey:strUserConfirmationFailedAlert] delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil] show];
        
        [self setUpForAuthPhase:ScAuthPhaseLogin];
        numberOfConfirmationAttempts = 0;
    }
}


- (void)presentEULA
{
    UIActionSheet *EULASheet = [[UIActionSheet alloc] initWithTitle:[ScStrings stringForKey:strEULA] delegate:self cancelButtonTitle:nil destructiveButtonTitle:[ScStrings stringForKey:strDecline] otherButtonTitles:[ScStrings stringForKey:strAccept], nil];
    EULASheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    [EULASheet showInView:self.view];
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

- (void)setUpForAuthPhase:(ScAuthPhase)authenticationPhase
{
    authPhase = authenticationPhase;
    
    if (authPhase == ScAuthPhaseLogin) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
        
        if (authInfo) {
            [ScMeta removeUserDefaultForKey:kUserDefaultsKeyAuthInfo];
            authInfo = nil;
        }
    } else if (authPhase == ScAuthPhaseConfirmation) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
    }
}


#pragma mark - Input validation

- (BOOL)isRegistrationCodeValid
{
    NSString *registrationCode = [[authInfo objectForKey:kAuthInfoKeyRegistrationCode] lowercaseString];
    NSString *registrationCodeAsEntered = [registrationCodeField.text lowercaseString];
    
    BOOL isValid = [registrationCodeAsEntered isEqualToString:registrationCode];
    
    if (!isValid) {
        [self handleFailedConfirmationForField:registrationCodeField];
    }
    
    return isValid;
}


- (BOOL)isPasswordValid
{
    BOOL isValid = NO;
    
    if (authPhase == ScAuthPhaseConfirmation) {
        NSString *passwordHashAsPersisted = [authInfo objectForKey:kAuthInfoKeyPasswordHash];
        NSString *passwordHashAsEntered = [self generatePasswordHash:passwordField.text usingSalt:[ScMeta m].userId];
        
        isValid = [passwordHashAsEntered isEqualToString:passwordHashAsPersisted];
        
        if (!isValid) {
            [self handleFailedConfirmationForField:passwordField];
        }
    }
    
    return isValid;
}


#pragma mark - User login

- (void)attemptUserLogin
{
    [ScMeta m].userId = emailField.text;
    
    ScServerConnection *serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:emailField.text withPassword:passwordField.text];
    [serverConnection authenticateForPhase:ScAuthPhaseLogin delegate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)userDidLogInWithData:(NSArray *)data
{
    [ScMeta m].isUserLoggedIn = YES;
    
    if (data) {
        [[ScMeta m].managedObjectContext saveWithDictionaries:data];
    }
    
    isModelUpToDate = YES;
    
    if (authPhase == ScAuthPhaseLogin) {
        [self processLoginData:data];
    } else if (authPhase == ScAuthPhaseConfirmation) {
        [self processConfirmationData:data];
    }
}


- (void)processLoginData:(NSArray *)data
{
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    
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
}


#pragma mark - User registration

- (void)userDidRegisterWithData:(NSDictionary *)data
{
    authInfo = data;
    
    NSData *authInfoArchive = [NSKeyedArchiver archivedDataWithRootObject:authInfo];
    [ScMeta setUserDefault:authInfoArchive forKey:kUserDefaultsKeyAuthInfo];
    
    isUserListed = [[authInfo objectForKey:kAuthInfoKeyIsUserListed] boolValue];
    
    if (isUserListed) {
        [ScMeta m].homeScolaId = [authInfo objectForKey:kAuthInfoKeyHomeScolaId];
    } else {
        [ScMeta m].homeScolaId = [ScUUIDGenerator generateUUID];
    }
    
    [self setUpForAuthPhase:ScAuthPhaseConfirmation];
}


- (void)confirmUserRegistration
{
    ScServerConnection *serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:[ScMeta m].userId withPassword:passwordField.text];
    [serverConnection setValue:[ScMeta m].homeScolaId forURLParameter:kURLParameterScolaId];
    [serverConnection authenticateForPhase:ScAuthPhaseConfirmation delegate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)processConfirmationData:(NSArray *)data
{
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    
    if (isUserListed) {
        homeScola = [context fetchEntityWithId:[ScMeta m].homeScolaId];
        member = [context fetchEntityWithId:[ScMeta m].userId];
        
        ScMemberResidency *residency = [context fetchEntityWithId:[homeScola residencyIdForMember:member]];
        residency.isAdmin = [NSNumber numberWithBool:![member isMinor]];
    } else {
        homeScola = [context entityForScolaWithName:[ScStrings stringForKey:strMyPlace] scolaId:[ScMeta m].homeScolaId];
        member = [context entityForClass:ScMember.class inScola:homeScola withId:[ScMeta m].userId];
        
        member.gender = kGenderNoneGiven;
        
        ScMemberResidency *residency = [homeScola addResident:member];
        residency.isActive = [NSNumber numberWithBool:YES];
        residency.isAdmin = [NSNumber numberWithBool:YES];
        
        ScMessageBoard *defaultMessageBoard = [context entityForClass:ScMessageBoard.class inScola:homeScola];
        defaultMessageBoard.title = [ScStrings stringForKey:strMyMessageBoard];
        defaultMessageBoard.scola = homeScola;
    }
    
    member.name = [ScMeta m].userId;
    member.passwordHash = [authInfo objectForKey:kAuthInfoKeyPasswordHash];
    member.didRegister = [NSNumber numberWithBool:YES];
    member.activeSince = [NSDate date];
    
    [self registerNewDevice];
    
    [context synchronise];
    
    [ScMeta removeUserDefaultForKey:kUserDefaultsKeyAuthInfo];
    authInfo = nil;
    
    [self performSegueWithIdentifier:kSegueToMemberView sender:self];
}


- (BOOL)isRegistrationComplete
{
    if (!member) {
        NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
        
        member = [context fetchEntityWithId:[ScMeta m].userId];
        homeScola = [context fetchEntityWithId:[ScMeta m].homeScolaId];
    }
    
    BOOL isPhoneNumberGiven = ([member hasMobilPhone] || [homeScola hasLandline]);
    
    return (isPhoneNumberGiven && [homeScola hasAddress]);
}


- (void)completeRegistration
{
    [[[UIAlertView alloc] initWithTitle:[ScStrings stringForKey:strIncompleteRegistrationTitle] message:[ScStrings stringForKey:strIncompleteRegistrationAlert] delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil] show];
    
    [self performSegueWithIdentifier:kSegueToMemberView sender:self];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationController.navigationBarHidden = YES;
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:kDarkLinenImageFile]];
    
    [self.tableView addLogoBanner];
    spinner = [self.tableView addActivityIndicator];
    
    if ([ScMeta m].isUserLoggedIn) {
        if ([self isRegistrationComplete]) {
            [self performSegueWithIdentifier:kSegueToMainView sender:self];
        } else {
            [self completeRegistration];
        }
    } else {
        isEditingAllowed = YES;
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSData *authInfoArchive = [ScMeta userDefaultForKey:kUserDefaultsKeyAuthInfo];
    
    if (authInfoArchive) {
        authInfo = [NSKeyedUnarchiver unarchiveObjectWithData:authInfoArchive];
        [ScMeta m].userId = [authInfo objectForKey:kAuthInfoKeyUserId];
        
        authPhase = ScAuthPhaseConfirmation;
    } else {
        authPhase = ScAuthPhaseLogin;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([ScMeta m].isInternetConnectionAvailable) {
        [ScStrings refreshStrings];
    }
    
    if (authPhase == ScAuthPhaseConfirmation) {
        NSString *popUpMessage = [NSString stringWithFormat:[ScStrings stringForKey:strWelcomeBackAlert], [authInfo objectForKey:kAuthInfoKeyUserId]];
        
        UIAlertView *welcomeBackPopUp = [[UIAlertView alloc] initWithTitle:[ScStrings stringForKey:strWelcomeBackTitle] message:popUpMessage delegate:self cancelButtonTitle:[ScStrings stringForKey:strStartOver] otherButtonTitles:[ScStrings stringForKey:strHaveCode], nil];
        welcomeBackPopUp.tag = kAlertTagWelcomeBack;
        
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
        if (!isModelUpToDate) {
            [[ScMeta m].managedObjectContext synchronise];
        }
    } else if ([segue.identifier isEqualToString:kSegueToMemberView]) {
        ScMemberViewController *nextViewController = segue.destinationViewController;
        
        nextViewController.scenario = ScMemberScenarioRegisterUser;
        nextViewController.membership = [homeScola residencyForMember:member];
    }
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.f;
    
    if (authPhase == ScAuthPhaseLogin) {
        height = [tableView heightForCellWithReuseIdentifier:kReuseIdentifierUserLogin];
    } else if (authPhase == ScAuthPhaseConfirmation) {
        height = [tableView heightForCellWithReuseIdentifier:kReuseIdentifierUserConfirmation];
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (authPhase == ScAuthPhaseLogin) {
        authCell = [tableView cellWithReuseIdentifier:kReuseIdentifierUserLogin delegate:self];
    } else if (authPhase == ScAuthPhaseConfirmation) {
        authCell = [tableView cellWithReuseIdentifier:kReuseIdentifierUserConfirmation delegate:self];
    }
    
    return authCell;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [authCell.backgroundView addOnlyOrBottomCellShadow];
    
    if (authPhase == ScAuthPhaseLogin) {
        emailField = [authCell textFieldWithKey:kTextFieldKeyEmail];
        passwordField = [authCell textFieldWithKey:kTextFieldKeyPassword];
        
        if ([ScMeta m].userId) {
            emailField.text = [ScMeta m].userId;
            [passwordField becomeFirstResponder];
        } else {
            [emailField becomeFirstResponder];
        }
    } else if (authPhase == ScAuthPhaseConfirmation) {
        registrationCodeField = [authCell textFieldWithKey:kTextFieldKeyRegistrationCode];
        passwordField = [authCell textFieldWithKey:kTextFieldKeyRepeatPassword];
        
        registrationCodeField.text = @"";
        [registrationCodeField becomeFirstResponder];
    }
    
    passwordField.text = @"";
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *footerText = nil;
    
    if (authPhase == ScAuthPhaseLogin) {
        footerText = [ScStrings stringForKey:strSignInOrRegisterFooter];
    } else if (authPhase == ScAuthPhaseConfirmation) {
        footerText = [ScStrings stringForKey:strConfirmRegistrationFooter];
    }
    
    return [tableView footerViewWithText:footerText];
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return isEditingAllowed;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    BOOL shouldReturn = YES;
    
    if ((textField == emailField) || (textField == registrationCodeField)) {
        [passwordField becomeFirstResponder];
    } else if (textField == passwordField) {
        if (authPhase == ScAuthPhaseLogin) {
            shouldReturn = shouldReturn && [ScMeta isEmailValid:emailField];
            shouldReturn = shouldReturn && [ScMeta isPasswordValid:passwordField];
            
            if (shouldReturn) {
                [self attemptUserLogin];
            }
        } else if (authPhase == ScAuthPhaseConfirmation) {
            numberOfConfirmationAttempts++;
            
            shouldReturn = shouldReturn && [self isRegistrationCodeValid];
            shouldReturn = shouldReturn && [self isPasswordValid];
            
            if (shouldReturn) {
                [self presentEULA];
            }
        }
        
        if (shouldReturn) {
            [self.view endEditing:YES];
        }
    }
    
    return shouldReturn;
}


#pragma mark - UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertTagWelcomeBack:
            if (buttonIndex == kAlertButtonStartOver) {
                [self setUpForAuthPhase:ScAuthPhaseLogin];
            }
            
            break;
            
        default:
            break;
    }
}


#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.destructiveButtonIndex) {
        [self confirmUserRegistration];
    }
}


#pragma mark - ScServerConnectionDelegate methods

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    [self indicatePendingServerSession:NO];
    
    if (response.statusCode < kHTTPStatusCodeErrorRangeStart) {
        if (response.statusCode == kHTTPStatusCodeCreated) {
            [self userDidRegisterWithData:data];
        } else {
            [self userDidLogInWithData:data];
        }
    } else if (response.statusCode >= kHTTPStatusCodeErrorRangeStart) {
        [ScMeta m].isUserLoggedIn = NO;
        
        if (response.statusCode == kHTTPStatusCodeUnauthorized) {
            [authCell shake];
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            
            [passwordField becomeFirstResponder];
        } else {
            [ScServerConnection showAlertForHTTPStatus:response.statusCode];
        }
    }
}


- (void)didFailWithError:(NSError *)error
{
    
}

@end
