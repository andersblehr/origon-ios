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
#import "ScState.h"
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

static NSString * const kUserDefaultsKeyAuthInfo = @"scola.auth.info";

static NSString * const kAuthInfoKeyUserId = @"userId";
static NSString * const kAuthInfoKeyPasswordHash = @"passwordHash";
static NSString * const kAuthInfoKeyRegistrationCode = @"registrationCode";
static NSString * const kAuthInfoKeyIsUserListed = @"isListed";
static NSString * const kAuthInfoKeyIsRegistered = @"isRegistered";
static NSString * const kAuthInfoKeyHomeScolaId = @"homeScolaId";

static NSInteger const kAlertButtonStartOver = 0;
static NSInteger const kAlertTagWelcomeBack = 0;


@interface ScAuthViewController () {
    BOOL _isEditingAllowed;
    BOOL _isUserListed;
    BOOL _isModelUpToDate;
    
    ScTableViewCell *_authCell;
    ScTextField *_emailField;
    ScTextField *_passwordField;
    ScTextField *_registrationCodeField;
    
    ScMember *_member;
    ScScola *_household;
    
    NSDictionary *_authInfo;
    UIActivityIndicatorView *_activityIndicator;
    NSInteger _numberOfConfirmationAttempts;
}

@end


@implementation ScAuthViewController

#pragma mark - Private methods

- (void)reload
{
    if ([ScMeta state].actionIsLogin) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
        
        if (_authInfo) {
            [ScMeta removeUserDefaultForKey:kUserDefaultsKeyAuthInfo];
            _authInfo = nil;
        }
    } else if ([ScMeta state].actionIsConfirm) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
    }
}


- (NSString *)generatePasswordHash:(NSString *)password usingSalt:(NSString *)salt
{
    return [[password diff:salt] hashUsingSHA1];
}


- (void)indicatePendingServerSession:(BOOL)isPending
{
    static NSString *email;
    static NSString *password;
    static NSString *registrationCode;
    
    if (isPending) {
        if ([ScMeta state].actionIsLogin) {
            email = _emailField.text;
            _emailField.placeholder = [ScStrings stringForKey:strPleaseWait];
            _emailField.text = @"";
        } else if ([ScMeta state].actionIsConfirm) {
            registrationCode = _registrationCodeField.text;
            _registrationCodeField.placeholder = [ScStrings stringForKey:strPleaseWait];
            _registrationCodeField.text = @"";
        }
        
        password = _passwordField.text;
        _passwordField.placeholder = [ScStrings stringForKey:strPleaseWait];
        _passwordField.text = @"";
        
        _isEditingAllowed = NO;
        
        [_activityIndicator startAnimating];
    } else {
        if ([ScMeta state].actionIsLogin) {
            _emailField.text = email;
            _emailField.placeholder = [ScStrings stringForKey:strAuthEmailPrompt];
        } else if ([ScMeta state].actionIsConfirm) {
            _registrationCodeField.text = registrationCode;
            _registrationCodeField.placeholder = [ScStrings stringForKey:strRegistrationCodePrompt];
        }
        
        _passwordField.text = password;
        _passwordField.placeholder = [ScStrings stringForKey:strPasswordPrompt];
        
        _isEditingAllowed = YES;
        
        [_activityIndicator stopAnimating];
    }
}


- (void)handleFailedConfirmationForField:(ScTextField *)field;
{
    if (_numberOfConfirmationAttempts < 3) {
        [_authCell shakeAndVibrateDevice];
        
        if (field == _registrationCodeField) {
            _registrationCodeField.text = @"";
        }
        
        _passwordField.text = @"";
        
        [field becomeFirstResponder];
    } else {
        _numberOfConfirmationAttempts = 0;
        
        [[[UIAlertView alloc] initWithTitle:[ScStrings stringForKey:strUserConfirmationFailedTitle] message:[ScStrings stringForKey:strUserConfirmationFailedAlert] delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil] show];
        
        [ScMeta state].action = ScStateActionLogin;
        [self reload];
        
        ScLogState;
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
        device = [context entityForClass:ScDevice.class inScola:_household withId:[ScMeta m].deviceId];
        device.type = [UIDevice currentDevice].model;
        device.displayName = [UIDevice currentDevice].name;
        device.member = _member;
        
        didRegisterNewDevice = YES;
    }
    
    return didRegisterNewDevice;
}


#pragma mark - Input validation

- (BOOL)isRegistrationCodeValid
{
    NSString *registrationCode = [[_authInfo objectForKey:kAuthInfoKeyRegistrationCode] lowercaseString];
    NSString *registrationCodeAsEntered = [_registrationCodeField.text lowercaseString];
    
    BOOL isValid = [registrationCodeAsEntered isEqualToString:registrationCode];
    
    if (!isValid) {
        [self handleFailedConfirmationForField:_registrationCodeField];
    }
    
    return isValid;
}


- (BOOL)isPasswordValid
{
    BOOL isValid = NO;
    
    if ([ScMeta state].actionIsConfirm) {
        NSString *passwordHashAsPersisted = [_authInfo objectForKey:kAuthInfoKeyPasswordHash];
        NSString *passwordHashAsEntered = [self generatePasswordHash:_passwordField.text usingSalt:[ScMeta m].userId];
        
        isValid = [passwordHashAsEntered isEqualToString:passwordHashAsPersisted];
        
        if (!isValid) {
            [self handleFailedConfirmationForField:_passwordField];
        }
    }
    
    return isValid;
}


#pragma mark - User login

- (void)attemptUserLogin
{
    [ScMeta m].userId = _emailField.text;
    
    ScServerConnection *serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:_emailField.text withPassword:_passwordField.text];
    [serverConnection authenticateUsingDelegate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)userDidAuthenticateWithData:(NSArray *)data
{
    [ScMeta m].isUserLoggedIn = YES;
    
    if (data) {
        [[ScMeta m].managedObjectContext saveWithDictionaries:data];
    }
    
    _isModelUpToDate = YES;
    
    if ([ScMeta state].actionIsLogin) {
        [self completeLogin];
    } else if ([ScMeta state].actionIsConfirm) {
        [self completeSignUp];
    }
}


- (void)completeLogin
{
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    
    _member = [context fetchEntityWithId:[ScMeta m].userId];
    _household = [context fetchEntityWithId:_member.scolaId];
    
    [ScMeta m].householdId = _member.scolaId;
    
    if ([self registerNewDevice]) {
        [context synchronise];
    }
    
    if ([self isRegistrationComplete]) {
        [self performSegueWithIdentifier:kSegueToMainView sender:self];
    } else {
        [ScMeta showAlertWithTitle:[ScStrings stringForKey:strIncompleteRegistrationTitle] message:[ScStrings stringForKey:strIncompleteRegistrationAlert]];
        
        [self completeRegistration];
    }
}


#pragma mark - User sign-up

- (void)userDidSignUpWithData:(NSDictionary *)data
{
    _authInfo = data;
    
    NSData *authInfoArchive = [NSKeyedArchiver archivedDataWithRootObject:_authInfo];
    [ScMeta setUserDefault:authInfoArchive forKey:kUserDefaultsKeyAuthInfo];
    
    _isUserListed = [[_authInfo objectForKey:kAuthInfoKeyIsUserListed] boolValue];
    
    if (_isUserListed) {
        [ScMeta m].householdId = [_authInfo objectForKey:kAuthInfoKeyHomeScolaId];
    } else {
        [ScMeta m].householdId = [ScUUIDGenerator generateUUID];
    }
    
    [ScMeta state].action = ScStateActionConfirm;
    [self reload];
    
    ScLogState;
}


- (void)confirmSignUp
{
    ScServerConnection *serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:[ScMeta m].userId withPassword:_passwordField.text];
    [serverConnection setValue:[ScMeta m].householdId forURLParameter:kURLParameterScolaId];
    [serverConnection authenticateUsingDelegate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)completeSignUp
{
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    
    if (_isUserListed) {
        _household = [context fetchEntityWithId:[ScMeta m].householdId];
        _member = [context fetchEntityWithId:[ScMeta m].userId];
        
        for (ScMemberResidency *residency in _member.residencies) {
            residency.isActive = [NSNumber numberWithBool:YES];
            residency.isAdmin = [NSNumber numberWithBool:![_member isMinor]];
        }
    } else {
        _household = [context entityForScolaWithName:[ScStrings stringForKey:strMyPlace] scolaId:[ScMeta m].householdId];
        _member = [context entityForClass:ScMember.class inScola:_household withId:[ScMeta m].userId];
        
        ScMemberResidency *residency = [_household addResident:_member];
        residency.isActive = [NSNumber numberWithBool:YES];
        residency.isAdmin = [NSNumber numberWithBool:YES];
        
        ScMessageBoard *defaultMessageBoard = [context entityForClass:ScMessageBoard.class inScola:_household];
        defaultMessageBoard.title = [ScStrings stringForKey:strMyMessageBoard];
        defaultMessageBoard.scola = _household;
    }
    
    _member.passwordHash = [_authInfo objectForKey:kAuthInfoKeyPasswordHash];
    _member.didRegister = [NSNumber numberWithBool:YES];
    
    [self registerNewDevice];
    [context synchronise];
    
    [ScMeta removeUserDefaultForKey:kUserDefaultsKeyAuthInfo];
    _authInfo = nil;
    
    [self completeRegistration];
}


#pragma mark - User registration

- (BOOL)isRegistrationComplete
{
    if (!_member) {
        NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
        
        _member = [context fetchEntityWithId:[ScMeta m].userId];
        _household = [context fetchEntityWithId:[ScMeta m].householdId];
    }
    
    BOOL isPhoneNumberGiven = ([_member hasMobilPhone] || [_household hasLandline]);
    
    return (isPhoneNumberGiven && [_household hasAddress]);
}


- (void)completeRegistration
{
    [ScMeta state].action = ScStateActionRegister;
    [ScMeta state].target = ScStateTargetUser;
    [ScMeta state].aspect = ScStateAspectHome;
    
    ScMemberViewController *memberViewController = [self.storyboard instantiateViewControllerWithIdentifier:kMemberViewControllerId];
    memberViewController.membership = [_household residencyForMember:_member];
    memberViewController.delegate = self;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:memberViewController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self.navigationController presentViewController:navigationController animated:YES completion:NULL];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [ScMeta state].action = ScStateActionLogin;
    [ScMeta state].target = ScStateTargetUser;
    [ScMeta state].aspect = ScStateAspectDefault;
    
    ScLogState;
    
    self.navigationController.navigationBarHidden = YES;
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:kDarkLinenImageFile]];
    
    [self.tableView addLogoBanner];
    _activityIndicator = [self.tableView addActivityIndicator];
    
    if ([ScMeta m].isUserLoggedIn) {
        if ([self isRegistrationComplete]) {
            [self performSegueWithIdentifier:kSegueToMainView sender:self];
        } else {
            [ScMeta showAlertWithTitle:[ScStrings stringForKey:strIncompleteRegistrationTitle] message:[ScStrings stringForKey:strIncompleteRegistrationAlert]];
            
            [self completeRegistration];
        }
    } else {
        _isEditingAllowed = YES;
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSData *authInfoArchive = [ScMeta userDefaultForKey:kUserDefaultsKeyAuthInfo];
    
    if (authInfoArchive) {
        _authInfo = [NSKeyedUnarchiver unarchiveObjectWithData:authInfoArchive];
        [ScMeta m].userId = [_authInfo objectForKey:kAuthInfoKeyUserId];
        
        [ScMeta state].action = ScStateActionConfirm;
        
        ScLogState;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([ScMeta m].isInternetConnectionAvailable) {
        [ScStrings refreshStrings];
    }
    
    if ([ScMeta state].actionIsConfirm) {
        NSString *popUpMessage = [NSString stringWithFormat:[ScStrings stringForKey:strWelcomeBackAlert], [_authInfo objectForKey:kAuthInfoKeyUserId]];
        
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
        if (!_isModelUpToDate) {
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
    
    if ([ScMeta state].actionIsLogin) {
        height = [ScTableViewCell heightForReuseIdentifier:kReuseIdentifierUserLogin];
    } else if ([ScMeta state].actionIsConfirm) {
        height = [ScTableViewCell heightForReuseIdentifier:kReuseIdentifierUserConfirmation];
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([ScMeta state].actionIsLogin) {
        _authCell = [tableView cellWithReuseIdentifier:kReuseIdentifierUserLogin delegate:self];
    } else {
        _authCell = [tableView cellWithReuseIdentifier:kReuseIdentifierUserConfirmation delegate:self];
    }
    
    return _authCell;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_authCell.backgroundView addShadowForBottomTableViewCell];
    
    if ([ScMeta state].actionIsLogin) {
        _emailField = [_authCell textFieldWithKey:kTextFieldKeyAuthEmail];
        _passwordField = [_authCell textFieldWithKey:kTextFieldKeyPassword];
        
        if ([ScMeta m].userId) {
            _emailField.text = [ScMeta m].userId;
            [_passwordField becomeFirstResponder];
        } else {
            [_emailField becomeFirstResponder];
        }
    } else if ([ScMeta state].actionIsConfirm) {
        _registrationCodeField = [_authCell textFieldWithKey:kTextFieldKeyRegistrationCode];
        _passwordField = [_authCell textFieldWithKey:kTextFieldKeyRepeatPassword];
        
        _registrationCodeField.text = @"";
        [_registrationCodeField becomeFirstResponder];
    }
    
    _passwordField.text = @"";
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *footerText = nil;
    
    if ([ScMeta state].actionIsLogin) {
        footerText = [ScStrings stringForKey:strSignInOrRegisterFooter];
    } else if ([ScMeta state].actionIsConfirm) {
        footerText = [ScStrings stringForKey:strConfirmRegistrationFooter];
    }
    
    return [tableView footerViewWithText:footerText];
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return _isEditingAllowed;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    BOOL shouldReturn = YES;
    
    if ((textField == _emailField) || (textField == _registrationCodeField)) {
        [_passwordField becomeFirstResponder];
    } else if (textField == _passwordField) {
        if ([ScMeta state].actionIsLogin) {
            shouldReturn = shouldReturn && [ScMeta isEmailValid:_emailField];
            shouldReturn = shouldReturn && [ScMeta isPasswordValid:_passwordField];
            
            if (shouldReturn) {
                [self attemptUserLogin];
            }
        } else if ([ScMeta state].actionIsConfirm) {
            _numberOfConfirmationAttempts++;
            
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
    if (alertView.tag == kAlertTagWelcomeBack) {
        if (buttonIndex == kAlertButtonStartOver) {
            [ScMeta state].action = ScStateActionLogin;
            [self reload];
            
            ScLogState;
        }
    }
}


#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.destructiveButtonIndex) {
        [self confirmSignUp];
    }
}


#pragma mark - ScMemberViewControllerDelegate methods

- (void)shouldDismissViewControllerWithIdentitifier:(NSString *)identitifier
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self performSegueWithIdentifier:kSegueToMainView sender:self];
}


#pragma mark - ScServerConnectionDelegate methods

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    [self indicatePendingServerSession:NO];
    
    if (response.statusCode < kHTTPStatusCodeErrorRangeStart) {
        if (response.statusCode == kHTTPStatusCodeCreated) {
            [self userDidSignUpWithData:data];
        } else {
            [self userDidAuthenticateWithData:data];
        }
    } else if (response.statusCode >= kHTTPStatusCodeErrorRangeStart) {
        [ScMeta m].isUserLoggedIn = NO;
        
        if (response.statusCode == kHTTPStatusCodeUnauthorized) {
            [_authCell shake];
            [_passwordField becomeFirstResponder];
        } else {
            [ScServerConnection showAlertForHTTPStatus:response.statusCode];
        }
    }
}


- (void)didFailWithError:(NSError *)error
{
    
}

@end
