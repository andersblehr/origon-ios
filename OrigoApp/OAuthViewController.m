//
//  OAuthViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OAuthViewController.h"

#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"
#import "NSString+OStringExtensions.h"
#import "UIColor+OColorExtensions.h"
#import "UITableView+OTableViewExtensions.h"
#import "UIView+OViewExtensions.h"

#import "OAlert.h"
#import "OLogging.h"
#import "OMeta.h"
#import "OServerConnection.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextField.h"
#import "OUUIDGenerator.h"

#import "ODevice.h"
#import "OMember.h"
#import "OMemberResidency.h"
#import "OMembership.h"
#import "OMessageBoard.h"
#import "OOrigo.h"

#import "OMember+OMemberExtensions.h"
#import "OMembership+OMembershipExtensions.h"
#import "OOrigo+OOrigoExtensions.h"

#import "OMemberViewController.h"

static NSInteger const kNumberOfAuthSections = 1;
static NSInteger const kNumberOfRowsInAuthSection = 1;

static NSString * const kSegueToOrigoListView = @"authToOrigoListView";

static NSString * const kUserDefaultsKeyAuthInfo = @"origo.auth.info";
static NSString * const kAuthInfoKeyUserId = @"userId";
static NSString * const kAuthInfoKeyPasswordHash = @"passwordHash";
static NSString * const kAuthInfoKeyActivationCode = @"activationCode";
static NSString * const kAuthInfoKeyIsUserListed = @"isListed";
static NSString * const kAuthInfoKeyIsRegistered = @"isRegistered";

static NSInteger const kAlertButtonStartOver = 0;
static NSInteger const kAlertTagWelcomeBack = 0;


@implementation OAuthViewController

#pragma mark - Auxiliary methods

- (void)reload
{
    if ([OState s].actionIsLogin) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
        
        if (_authInfo) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserDefaultsKeyAuthInfo];
            _authInfo = nil;
        }
    } else if ([OState s].actionIsActivate) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
    }
}


- (NSString *)computePasswordHash:(NSString *)password
{
    return [[password diff:[OMeta m].userId] hashUsingSHA1];
}


- (void)indicatePendingServerSession:(BOOL)isPending
{
    static NSString *email;
    static NSString *password;
    static NSString *activationCode;
    
    if (isPending) {
        if ([OState s].actionIsLogin) {
            email = _emailField.text;
            _emailField.placeholder = [OStrings stringForKey:strPleaseWait];
            _emailField.text = @"";
        } else if ([OState s].actionIsActivate) {
            activationCode = _activationCodeField.text;
            _activationCodeField.placeholder = [OStrings stringForKey:strPleaseWait];
            _activationCodeField.text = @"";
        }
        
        password = _passwordField.text;
        _passwordField.placeholder = [OStrings stringForKey:strPleaseWait];
        _passwordField.text = @"";
        
        [_activityIndicator startAnimating];
    } else {
        if ([OState s].actionIsLogin) {
            _emailField.text = email;
            _emailField.placeholder = [OStrings stringForKey:strAuthEmailPrompt];
        } else if ([OState s].actionIsActivate) {
            _activationCodeField.text = activationCode;
            _activationCodeField.placeholder = [OStrings stringForKey:strActivationCodePrompt];
        }
        
        _passwordField.text = password;
        _passwordField.placeholder = [OStrings stringForKey:strPasswordPrompt];
        
        [_activityIndicator stopAnimating];
    }
    
    _isEditingAllowed = !isPending;
}


- (void)handleInvalidInputForField:(OTextField *)field;
{
    if (_numberOfActivationAttempts < 3) {
        [_authCell shakeAndVibrateDevice];
        
        if (field == _activationCodeField) {
            _activationCodeField.text = @"";
        }
        
        _passwordField.text = @"";
        
        [field becomeFirstResponder];
    } else {
        _numberOfActivationAttempts = 0;
        
        [[[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strActivationFailedTitle] message:[OStrings stringForKey:strActivationFailedAlert] delegate:nil cancelButtonTitle:[OStrings stringForKey:strOK] otherButtonTitles:nil] show];
        
        [OState s].actionIsLogin = YES;
        [self reload];
        
        OLogState;
    }
}


- (void)presentEULA
{
    UIActionSheet *EULASheet = [[UIActionSheet alloc] initWithTitle:[OStrings stringForKey:strEULA] delegate:self cancelButtonTitle:nil destructiveButtonTitle:[OStrings stringForKey:strDecline] otherButtonTitles:[OStrings stringForKey:strAccept], nil];
    EULASheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    [EULASheet showInView:self.view];
}


- (BOOL)registerNewDevice
{
    BOOL didRegisterNewDevice = NO;
    
    ODevice *device = [[OMeta m].context fetchEntityFromCache:[OMeta m].deviceId];
    
    if (!device) {
        device = [[OMeta m].context entityForClass:ODevice.class inOrigo:[[OMeta m].user memberRoot] entityId:[OMeta m].deviceId];
        device.type = [UIDevice currentDevice].model;
        device.displayName = [UIDevice currentDevice].name;
        device.member = [OMeta m].user;
        
        didRegisterNewDevice = YES;
    }
    
    return didRegisterNewDevice;
}


#pragma mark - Input validation

- (BOOL)isActivationCodeValid
{
    NSString *activationCode = [[_authInfo objectForKey:kAuthInfoKeyActivationCode] lowercaseString];
    NSString *registrationCodeAsEntered = [_activationCodeField.text lowercaseString];
    
    BOOL isValid = [registrationCodeAsEntered isEqualToString:activationCode];
    
    if (!isValid) {
        [self handleInvalidInputForField:_activationCodeField];
    }
    
    return isValid;
}


- (BOOL)isPasswordValid
{
    BOOL isValid = NO;
    
    if ([OState s].actionIsActivate) {
        NSString *passwordHashAsPersisted = [_authInfo objectForKey:kAuthInfoKeyPasswordHash];
        NSString *passwordHashAsEntered = [self computePasswordHash:_passwordField.text];
        
        isValid = [passwordHashAsEntered isEqualToString:passwordHashAsPersisted];
        
        if (!isValid) {
            [self handleInvalidInputForField:_passwordField];
        }
    }
    
    return isValid;
}


#pragma mark - User login

- (void)attemptUserLogin
{
    [OMeta m].userId = _emailField.text;
    
    OServerConnection *serverConnection = [[OServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:_emailField.text password:_passwordField.text];
    [serverConnection authenticate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)userDidAuthenticateWithData:(NSArray *)data
{
    if (data) {
        [[OMeta m].context saveServerEntitiesToCache:data];
    }
    
    if ([OState s].actionIsActivate) {
        [self completeActivation];
    } else if ([OState s].actionIsLogin) {
        [self completeLogin];
    }
}


- (void)completeLogin
{
    [[OMeta m] userDidLogIn];
    
    if ([self registerNewDevice]) {
        [[OMeta m].context synchroniseCacheWithServer];
    }
    
    _isModelUpToDate = YES;
    
    if ([self isRegistrationComplete]) {
        [self performSegueWithIdentifier:kSegueToOrigoListView sender:self];
    } else {
        [OAlert showAlertWithTitle:[OStrings stringForKey:strIncompleteRegistrationTitle] message:[OStrings stringForKey:strIncompleteRegistrationAlert]];
        
        [self completeRegistration];
    }
}


#pragma mark - User sign-up & activation

- (void)userDidSignUpWithData:(NSDictionary *)data
{
    _authInfo = data;
    _isUserListed = [[_authInfo objectForKey:kAuthInfoKeyIsUserListed] boolValue];
    
    NSData *authInfoArchive = [NSKeyedArchiver archivedDataWithRootObject:_authInfo];
    [[NSUserDefaults standardUserDefaults] setObject:authInfoArchive forKey:kUserDefaultsKeyAuthInfo];
    
    [OState s].actionIsActivate = YES;
    [self reload];
    
    OLogState;
}


- (void)activateMembership
{
    OServerConnection *serverConnection = [[OServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:[OMeta m].userId password:_passwordField.text];
    [serverConnection authenticate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)completeActivation
{
    [[OMeta m] userDidLogIn];
    
    if (_isUserListed) {
        for (OMemberResidency *residency in [OMeta m].user.residencies) {
            residency.isActive_ = YES;
            
            if ([[OMeta m].user isMinor]) {
                residency.isAdmin_ = NO;
            } else {
                residency.isAdmin_ = YES;
                residency.contactRole = kContactRoleResidenceElder;
            }
        }
    } else {
        OOrigo *residence = [[OMeta m].context entityForOrigoOfType:kOrigoTypeResidence];
        OMemberResidency *residency = [residence addResident:[OMeta m].user];
        residency.isActive_ = YES;
        residency.isAdmin_ = YES;
        
        OMessageBoard *residenceMessageBoard = [[OMeta m].context entityForClass:OMessageBoard.class inOrigo:residence];
        residenceMessageBoard.title = [OStrings stringForKey:strMyMessageBoard];
    }
    
    [OMeta m].user.passwordHash = [_authInfo objectForKey:kAuthInfoKeyPasswordHash];
    [OMeta m].user.didRegister_ = YES;
    
    [self registerNewDevice];
    [[OMeta m].context synchroniseCacheWithServer];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserDefaultsKeyAuthInfo];
    _authInfo = nil;
    
    if (![self isRegistrationComplete]) {
        [self completeRegistration];
    }
}


#pragma mark - User registration

- (BOOL)isRegistrationComplete
{
    return ([[OMeta m].user hasPhone] && [[OMeta m].user hasAddress]);
}


- (void)completeRegistration
{
    [OState s].actionIsRegister = YES;
    
    OMemberViewController *memberViewController = [self.storyboard instantiateViewControllerWithIdentifier:kMemberViewControllerId];
    memberViewController.membership = [[OMeta m].user.residencies anyObject];
    memberViewController.delegate = self;
    
    UINavigationController *modalController = [[UINavigationController alloc] initWithRootViewController:memberViewController];
    modalController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self.navigationController presentViewController:modalController animated:YES completion:NULL];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationController.navigationBarHidden = YES;
    
    [self.tableView setBackground];
    [self.tableView addLogoBanner];
    _activityIndicator = [self.tableView addActivityIndicator];
    
    if ([OMeta m].isUserLoggedIn) {
        if ([self isRegistrationComplete]) {
            [self performSegueWithIdentifier:kSegueToOrigoListView sender:self];
        } else {
            [OAlert showAlertWithTitle:[OStrings stringForKey:strIncompleteRegistrationTitle] message:[OStrings stringForKey:strIncompleteRegistrationAlert]];
            
            [self completeRegistration];
        }
    } else {
        _isEditingAllowed = YES;
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [OState s].targetIsMember = YES;
    [OState s].actionIsLogin = YES;
    [OState s].aspectIsSelf = YES;
    
    OLogState;
    
    NSData *authInfoArchive = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsKeyAuthInfo];
    
    if (authInfoArchive) {
        _authInfo = [NSKeyedUnarchiver unarchiveObjectWithData:authInfoArchive];
        [OMeta m].userId = [_authInfo objectForKey:kAuthInfoKeyUserId];
        
        [OState s].actionIsActivate = YES;
        
        OLogState;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [OStrings refreshIfPossible];
    
    if ([OState s].actionIsActivate) {
        NSString *popUpMessage = [NSString stringWithFormat:[OStrings stringForKey:strWelcomeBackAlert], [_authInfo objectForKey:kAuthInfoKeyUserId]];
        
        UIAlertView *welcomeBackPopUp = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strWelcomeBackTitle] message:popUpMessage delegate:self cancelButtonTitle:[OStrings stringForKey:strStartOver] otherButtonTitles:[OStrings stringForKey:strHaveCode], nil];
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
    if ([segue.identifier isEqualToString:kSegueToOrigoListView]) {
        if (!_isModelUpToDate) {
            [[OMeta m].context synchroniseCacheWithServer];
        }
    }
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfAuthSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return kNumberOfRowsInAuthSection;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.f;
    
    if ([OState s].actionIsLogin) {
        height = [OTableViewCell heightForReuseIdentifier:kReuseIdentifierUserLogin];
    } else if ([OState s].actionIsActivate) {
        height = [OTableViewCell heightForReuseIdentifier:kReuseIdentifierUserActivation];
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([OState s].actionIsLogin) {
        _authCell = [tableView cellWithReuseIdentifier:kReuseIdentifierUserLogin delegate:self];
    } else {
        _authCell = [tableView cellWithReuseIdentifier:kReuseIdentifierUserActivation delegate:self];
    }
    
    return _authCell;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_authCell.backgroundView addShadowForBottomTableViewCell];
    
    if ([OState s].actionIsLogin) {
        _emailField = [_authCell textFieldWithKey:kTextFieldKeyAuthEmail];
        _passwordField = [_authCell textFieldWithKey:kTextFieldKeyPassword];
        
        if ([OMeta m].userId) {
            _emailField.text = [OMeta m].userId;
            [_passwordField becomeFirstResponder];
        } else {
            [_emailField becomeFirstResponder];
        }
    } else if ([OState s].actionIsActivate) {
        _activationCodeField = [_authCell textFieldWithKey:kTextFieldKeyActivationCode];
        _passwordField = [_authCell textFieldWithKey:kTextFieldKeyRepeatPassword];
        
        _activationCodeField.text = @"";
        [_activationCodeField becomeFirstResponder];
    }
    
    _passwordField.text = @"";
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *footerText = nil;
    
    if ([OState s].actionIsLogin) {
        footerText = [OStrings stringForKey:strSignInOrRegisterFooter];
    } else if ([OState s].actionIsActivate) {
        footerText = [OStrings stringForKey:strActivateFooter];
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
    
    if ((textField == _emailField) || (textField == _activationCodeField)) {
        [_passwordField becomeFirstResponder];
    } else if (textField == _passwordField) {
        if ([OState s].actionIsLogin) {
            shouldReturn = shouldReturn && [OMeta isEmailValid:_emailField];
            shouldReturn = shouldReturn && [OMeta isPasswordValid:_passwordField];
            
            if (shouldReturn) {
                [self attemptUserLogin];
            }
        } else if ([OState s].actionIsActivate) {
            _numberOfActivationAttempts++;
            
            shouldReturn = shouldReturn && [self isActivationCodeValid];
            shouldReturn = shouldReturn && [self isPasswordValid];
            
            if (shouldReturn) {
                [self presentEULA];
            }
        }
        
        if (shouldReturn) {
            [self.view endEditing:YES];
        } else {
            _passwordField.text = @"";
            [_authCell shakeAndVibrateDevice];
        }
    }
    
    return shouldReturn;
}


#pragma mark - UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kAlertTagWelcomeBack) {
        if (buttonIndex == kAlertButtonStartOver) {
            [OState s].actionIsLogin = YES;
            [self reload];
            
            OLogState;
        }
    }
}


#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.destructiveButtonIndex) {
        [self activateMembership];
    }
}


#pragma mark - OMemberViewControllerDelegate methods

- (void)dismissViewControllerWithIdentitifier:(NSString *)identitifier
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self performSegueWithIdentifier:kSegueToOrigoListView sender:self];
}


#pragma mark - OServerConnectionDelegate methods

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
        if (response.statusCode == kHTTPStatusCodeUnauthorized) {
            [_authCell shake];
            [_passwordField becomeFirstResponder];
        } else {
            [OAlert showAlertForHTTPStatus:response.statusCode];
        }
    }
}


- (void)didFailWithError:(NSError *)error
{
    
}

@end
