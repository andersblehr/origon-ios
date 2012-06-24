//
//  ScAuthViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 18.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScAuthViewController.h"

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

typedef enum {
    ScAuthAlertConfirmationFailed,
    ScAuthAlertWelcomeBack,
    ScAuthAlertNotLoggedIn,
} ScAuthAlertTag;

static NSString * const kSegueToMainView = @"authToMainView";
static NSString * const kSegueToRegistrationView = @"authToRegistrationView";

static NSString * const kUserDefaultsKeyAuthInfo = @"scola.auth.info";

static NSString * const kAuthInfoKeyUserId = @"userId";
static NSString * const kAuthInfoKeyPasswordHash = @"passwordHash";
static NSString * const kAuthInfoKeyRegistrationCode = @"registrationCode";
static NSString * const kAuthInfoKeyIsUserListed = @"isListed";
static NSString * const kAuthInfoKeyIsRegistered = @"isRegistered";
static NSString * const kAuthInfoKeyHomeScolaId = @"homeScolaId";

static NSInteger const kAlertButtonGoBack = 0;
static NSInteger const kAlertButtonContinue = 1;


@implementation ScAuthViewController


#pragma mark - Auxiliary methods

- (void)indicatePendingServerSession:(BOOL)isPending
{
    static NSString *email;
    static NSString *password;
    
    if (isPending) {
        email = emailField.text;
        password = passwordField.text;
        
        emailField.placeholder = [ScStrings stringForKey:strPleaseWait];
        emailField.text = @"";
        passwordField.placeholder = [ScStrings stringForKey:strPleaseWait];
        passwordField.text = @"";
        
        isEditingAllowed = NO;
        
        [spinner startAnimating];
    } else {
        emailField.placeholder = [ScStrings stringForKey:strEmailPrompt];
        emailField.text = email;
        passwordField.placeholder = [ScStrings stringForKey:strPasswordPrompt];
        passwordField.text = password;
        
        isEditingAllowed = YES;
        
        [spinner stopAnimating];
    }
}


- (NSString *)generatePasswordHash:(NSString *)password usingSalt:(NSString *)salt
{
    return [[password diff:salt] hashUsingSHA1];
}


- (void)showTryAgainOrGoBackAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertView *validationAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:[ScStrings stringForKey:strGoBack] otherButtonTitles:[ScStrings stringForKey:strTryAgain], nil];
    validationAlert.tag = ScAuthAlertConfirmationFailed;
    
    [validationAlert show];
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
    NSString *registrationCodeAsSent = [[authInfo objectForKey:kAuthInfoKeyRegistrationCode] lowercaseString];
    NSString *registrationCodeAsEntered = [registrationCodeField.text lowercaseString];
    
    BOOL isValid = [registrationCodeAsEntered isEqualToString:registrationCodeAsSent];
    
    if (!isValid) {
        [self showTryAgainOrGoBackAlertWithTitle:[ScStrings stringForKey:strInvalidRegistrationCodeTitle] message:[ScStrings stringForKey:strInvalidRegistrationCodeAlert]];
        
        [registrationCodeField becomeFirstResponder];
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
            [self showTryAgainOrGoBackAlertWithTitle:[ScStrings stringForKey:strPasswordsDoNotMatchTitle] message:[ScStrings stringForKey:strPasswordsDoNotMatchAlert]];
        }
    }
    
    if (!isValid) {
        passwordField.text = @"";
        [passwordField becomeFirstResponder];
    }
    
    return isValid;
}


#pragma mark - User registration and login

- (void)attemptUserLogin
{
    [ScMeta m].userId = emailField.text;
    
    ScServerConnection *serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:emailField.text withPassword:passwordField.text];
    [serverConnection authenticateForPhase:ScAuthPhaseLogin delegate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)confirmUser
{
    ScServerConnection *serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:[ScMeta m].userId withPassword:passwordField.text];
    [serverConnection authenticateForPhase:ScAuthPhaseConfirmation delegate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)userDidLogInWithData:(NSArray *)data
{
    [ScMeta m].isUserLoggedIn = YES;
    
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    
    if (data) {
        [context saveWithDictionaries:data];
    }
    
    isModelUpToDate = YES;
    
    if (authPhase == ScAuthPhaseLogin) {
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
    } else if (authPhase == ScAuthPhaseConfirmation) {
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
        
        [self performSegueWithIdentifier:kSegueToRegistrationView sender:self];
    }
}


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
    
    [self performSegueWithIdentifier:kSegueToRegistrationView sender:self];
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
        NSString *popUpMessage = [NSString stringWithFormat:[ScStrings stringForKey:strWelcomeBackPopUpMessage], [authInfo objectForKey:kAuthInfoKeyUserId]];
        
        UIAlertView *welcomeBackPopUp = [[UIAlertView alloc] initWithTitle:[ScStrings stringForKey:strWelcomeBackPopUpTitle] message:popUpMessage delegate:self cancelButtonTitle:[ScStrings stringForKey:strGoBack] otherButtonTitles:[ScStrings stringForKey:strHaveCode], nil];
        welcomeBackPopUp.tag = ScAuthAlertWelcomeBack;
        
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
    UITableViewCell *cell = nil;
    
    if (authPhase == ScAuthPhaseLogin) {
        cell = [tableView cellWithReuseIdentifier:kReuseIdentifierUserLogin delegate:self];
    } else if (authPhase == ScAuthPhaseConfirmation) {
        cell = [tableView cellWithReuseIdentifier:kReuseIdentifierUserConfirmation delegate:self];
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell.backgroundView addShadow];
    
    ScTableViewCell *authCell = (ScTableViewCell *)cell;
    
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
            shouldReturn = shouldReturn && [self isRegistrationCodeValid];
            shouldReturn = shouldReturn && [self isPasswordValid];
            
            if (shouldReturn) {
                [self confirmUser];
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
        case ScAuthAlertConfirmationFailed:
        case ScAuthAlertWelcomeBack:
            if (buttonIndex == kAlertButtonGoBack) {
                [self setUpForAuthPhase:ScAuthPhaseLogin];
            }
            
            break;
            
        case ScAuthAlertNotLoggedIn:
            [passwordField becomeFirstResponder];
            
            break;
            
        default:
            break;
    }
}


#pragma mark - ScServerConnectionDelegate methods

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    [self indicatePendingServerSession:NO];
    
    NSInteger status = response.statusCode;
    
    if ((status == kHTTPStatusCodeOK) || (status == kHTTPStatusCodeNotModified)) {
        [self userDidLogInWithData:data];
    } else if (status == kHTTPStatusCodeCreated) {
        [self userDidRegisterWithData:data];
    } else if (status >= kHTTPStatusCodeErrorRangeStart) {
        [ScMeta m].isUserLoggedIn = NO;
        
        if (response.statusCode == kHTTPStatusCodeUnauthorized) {
            NSString *alertMessage = [ScStrings stringForKey:strNotLoggedInAlert];
            
            UIAlertView *notLoggedInAlert = [[UIAlertView alloc] initWithTitle:nil message:alertMessage delegate:self cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
            notLoggedInAlert.tag = ScAuthAlertNotLoggedIn;
            
            [notLoggedInAlert show];
        } else {
            [ScServerConnection showAlertForHTTPStatus:response.statusCode];
        }
    }
}


- (void)didFailWithError:(NSError *)error
{
    
}

@end
