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

static NSString * const kAuthInfoKeyUserId = @"userId";
static NSString * const kAuthInfoKeyPasswordHash = @"passwordHash";
static NSString * const kAuthInfoKeyActivationCode = @"activationCode";
static NSString * const kAuthInfoKeyIsUserListed = @"isListed";
static NSString * const kAuthInfoKeyIsRegistered = @"isRegistered";

static NSInteger const kAlertButtonStartOver = 0;
static NSInteger const kAlertTagWelcomeBack = 0;


@implementation OAuthViewController

#pragma mark - Auxiliary methods

- (void)initialiseFields
{
    if ([OState s].actionIsLogin) {
        _passwordField.text = @"";
        
        if ([OMeta m].userId) {
            _emailField.text = [OMeta m].userId;
            [_passwordField becomeFirstResponder];
        } else {
            [_emailField becomeFirstResponder];
        }
    } else if ([OState s].actionIsActivate) {
        _activationCodeField.text = @"";
        _repeatPasswordField.text = @"";
        
        [_activationCodeField becomeFirstResponder];
    }
}


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
    
    [self initialiseFields];
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
            password = _passwordField.text;
            
            _emailField.placeholder = [OStrings stringForKey:strPromptPleaseWait];
            _emailField.text = @"";
            _passwordField.placeholder = [OStrings stringForKey:strPromptPleaseWait];
            _passwordField.text = @"";
        } else if ([OState s].actionIsActivate) {
            activationCode = _activationCodeField.text;
            password = _repeatPasswordField.text;
            
            _activationCodeField.placeholder = [OStrings stringForKey:strPromptPleaseWait];
            _activationCodeField.text = @"";
            _repeatPasswordField.placeholder = [OStrings stringForKey:strPromptPleaseWait];
            _repeatPasswordField.text = @"";
        }
        
        [_activityIndicator startAnimating];
    } else {
        if ([OState s].actionIsLogin) {
            _emailField.text = email;
            _emailField.placeholder = [OStrings stringForKey:strPromptAuthEmail];
            _passwordField.text = password;
            _passwordField.placeholder = [OStrings stringForKey:strPromptPassword];
        } else if ([OState s].actionIsActivate) {
            _activationCodeField.text = activationCode;
            _activationCodeField.placeholder = [OStrings stringForKey:strPromptActivationCode];
            _repeatPasswordField.text = password;
            _repeatPasswordField.placeholder = [OStrings stringForKey:strPromptPassword];
        }
        
        [_activityIndicator stopAnimating];
    }
    
    _editingIsAllowed = !isPending;
}


- (void)handleInvalidInputForField:(OTextField *)textField;
{
    _numberOfActivationAttempts++;
    
    if (_numberOfActivationAttempts < 3) {
        [_authCell shakeAndVibrateDevice];
        
        if (textField == _activationCodeField) {
            _activationCodeField.text = @"";
        }
        
        _passwordField.text = @"";
        
        [textField becomeFirstResponder];
    } else {
        _numberOfActivationAttempts = 0;
        
        [[[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleActivationFailed] message:[OStrings stringForKey:strAlertTextActivationFailed] delegate:nil cancelButtonTitle:[OStrings stringForKey:strButtonOK] otherButtonTitles:nil] show];
        
        [OState s].actionIsLogin = YES;
        [self reload];
        
        OLogState;
    }
}


- (void)presentEULA
{
    UIActionSheet *EULASheet = [[UIActionSheet alloc] initWithTitle:[OStrings stringForKey:strSheetTitleEULA] delegate:self cancelButtonTitle:nil destructiveButtonTitle:[OStrings stringForKey:strButtonDecline] otherButtonTitles:[OStrings stringForKey:strButtonAccept], nil];
    EULASheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    [EULASheet showInView:self.view];
}


- (void)registerNewDevice
{
    ODevice *device = [[OMeta m].context insertEntityForClass:ODevice.class inOrigo:[[OMeta m].user rootMembership].origo entityId:[OMeta m].deviceId];
    device.type = [UIDevice currentDevice].model;
    device.displayName = [UIDevice currentDevice].name;
    device.member = [OMeta m].user;
}


#pragma mark - Input validation

- (BOOL)activationCodeIsValid
{
    NSString *activationCode = [[_authInfo objectForKey:kAuthInfoKeyActivationCode] lowercaseString];
    NSString *activationCodeAsEntered = [_activationCodeField.text lowercaseString];
    
    BOOL isValid = [activationCodeAsEntered isEqualToString:activationCode];
    
    if (!isValid) {
        [self handleInvalidInputForField:_activationCodeField];
    }
    
    return isValid;
}


- (BOOL)passwordIsValid
{
    BOOL isValid = NO;
    
    if ([OState s].actionIsActivate) {
        NSString *passwordHash = [_authInfo objectForKey:kAuthInfoKeyPasswordHash];
        NSString *passwordHashAsEntered = [self computePasswordHash:_repeatPasswordField.text];
        
        isValid = [passwordHashAsEntered isEqualToString:passwordHash];
        
        if (!isValid) {
            [self handleInvalidInputForField:_repeatPasswordField];
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
        [[OMeta m].context saveServerReplicas:data];
    }
    
    if ([OState s].actionIsActivate) {
        [self completeActivation];
    } else if ([OState s].actionIsLogin) {
        [self completeLogin];
    }
}


- (void)completeLogin
{
    [[OMeta m] userDidSignIn];
    
    BOOL deviceIsNew = ([[OMeta m].context entityWithId:[OMeta m].deviceId] == nil);
    
    if (deviceIsNew) {
        [self registerNewDevice];
    }
    
    if (deviceIsNew || [[OMeta m].context savedReplicationStateIsDirty]) {
        [[OMeta m].context replicate];
    }
    
    if ([[OMeta m] registrationIsComplete]) {
        [self performSegueWithIdentifier:kSegueToOrigoListView sender:self];
    } else {
        [OAlert showAlertWithTitle:[OStrings stringForKey:strAlertTitleIncompleteRegistration] message:[OStrings stringForKey:strAlertTextIncompleteRegistration]];
        
        [self completeRegistration];
    }
}


#pragma mark - User sign-up & activation

- (void)userDidSignUpWithData:(NSDictionary *)data
{
    _authInfo = data;
    _userIsListed = [[_authInfo objectForKey:kAuthInfoKeyIsUserListed] boolValue];
    
    NSData *authInfoArchive = [NSKeyedArchiver archivedDataWithRootObject:_authInfo];
    [[NSUserDefaults standardUserDefaults] setObject:authInfoArchive forKey:kUserDefaultsKeyAuthInfo];
    
    [OState s].actionIsActivate = YES;
    [self reload];
    
    OLogState;
}


- (void)activateMembership
{
    OServerConnection *serverConnection = [[OServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:[OMeta m].userId password:_repeatPasswordField.text];
    [serverConnection authenticate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)completeActivation
{
    [[OMeta m] userDidSignIn];
    
    [self registerNewDevice];
    
    if (_userIsListed) {
        for (OMemberResidency *residency in [OMeta m].user.residencies) {
            residency.isActive_ = YES;
            
            if ([[OMeta m].user isMinor]) {
                residency.isAdmin_ = NO;
            } else {
                residency.isAdmin_ = YES;
            }
        }
    } else {
        OOrigo *residence = [[OMeta m].context insertOrigoEntityOfType:kOrigoTypeResidence];
        OMemberResidency *residency = [residence addResident:[OMeta m].user];
        residency.isActive_ = YES;
        residency.isAdmin_ = YES;
        
        OMessageBoard *residenceMessageBoard = [[OMeta m].context insertEntityForClass:OMessageBoard.class inOrigo:residence];
        residenceMessageBoard.title = [OStrings stringForKey:strNameMyMessageBoard];
    }
    
    [OMeta m].user.passwordHash = [_authInfo objectForKey:kAuthInfoKeyPasswordHash];
    [OMeta m].user.didRegister_ = YES;
    
    [[OMeta m].context replicate];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserDefaultsKeyAuthInfo];
    _authInfo = nil;
    
    if ([[OMeta m] registrationIsComplete] && [[OMeta m].user isMinor]) {
        [self performSegueWithIdentifier:kSegueToOrigoListView sender:self];
    } else {
        [self completeRegistration];
    }
}


#pragma mark - User registration

- (void)completeRegistration
{
    [OState s].actionIsRegister = YES;
    
    OMemberViewController *memberViewController = [self.storyboard instantiateViewControllerWithIdentifier:kMemberViewControllerId];
    memberViewController.membership = [[OMeta m].user.residencies anyObject]; // TODO: Fix!
    memberViewController.delegate = self;
    
    UINavigationController *modalController = [[UINavigationController alloc] initWithRootViewController:memberViewController];
    modalController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self.navigationController presentViewController:modalController animated:YES completion:NULL];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setBackground];
    [self.tableView addLogoBanner];
    self.navigationController.navigationBarHidden = YES;
    
    self.title = [OStrings stringForKey:strTabBarTitleOrigo];
    
    if ([[OMeta m] userIsSignedIn]) {
        [OAlert showAlertWithTitle:[OStrings stringForKey:strAlertTitleIncompleteRegistration] message:[OStrings stringForKey:strAlertTextIncompleteRegistration]];
        
        [self completeRegistration];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [OState s].actionIsLogin = YES;
    [OState s].targetIsMember = YES;
    [OState s].aspectIsSelf = YES;
    
    OLogState;
    
    _editingIsAllowed = YES;
    _activityIndicator = [self.tableView addActivityIndicator];
    
    NSData *authInfoArchive = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsKeyAuthInfo];
    
    if (authInfoArchive) {
        _authInfo = [NSKeyedUnarchiver unarchiveObjectWithData:authInfoArchive];
        
        [OMeta m].userId = [_authInfo objectForKey:kAuthInfoKeyUserId];
        [OState s].actionIsActivate = YES;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self initialiseFields];

    if ([OState s].actionIsActivate) {
        NSString *welcomeBackMessage = [NSString stringWithFormat:[OStrings stringForKey:strAlertTextWelcomeBack], [_authInfo objectForKey:kAuthInfoKeyUserId]];
        
        UIAlertView *welcomeBackAlert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleWelcomeBack] message:welcomeBackMessage delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonStartOver] otherButtonTitles:[OStrings stringForKey:strButtonHaveCode], nil];
        welcomeBackAlert.tag = kAlertTagWelcomeBack;
        [welcomeBackAlert show];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - UITableViewDataSource conformance

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
        
        _emailField = [_authCell textFieldForKey:kTextFieldAuthEmail];
        _passwordField = [_authCell textFieldForKey:kTextFieldPassword];
    } else {
        _authCell = [tableView cellWithReuseIdentifier:kReuseIdentifierUserActivation delegate:self];
        
        _activationCodeField = [_authCell textFieldForKey:kTextFieldActivationCode];
        _repeatPasswordField = [_authCell textFieldForKey:kTextFieldRepeatPassword];
    }
    
    return _authCell;
}


#pragma mark - UITableViewDelegate conformance

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_authCell.backgroundView addDropShadowForTrailingTableViewCell];
    
    if ([OState s].actionIsLogin) {
        [_emailField emphasise];
        [_passwordField emphasise];
    } else if ([OState s].actionIsActivate) {
        [_activationCodeField emphasise];
        [_repeatPasswordField emphasise];
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *footerText = nil;
    
    if ([OState s].actionIsLogin) {
        footerText = [OStrings stringForKey:strFooterSignInOrRegister];
    } else if ([OState s].actionIsActivate) {
        footerText = [OStrings stringForKey:strFooterActivate];
    }
    
    return [tableView footerViewWithText:footerText];
}


#pragma mark - UITextFieldDelegate conformance

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return _editingIsAllowed;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    BOOL shouldReturn = YES;
    
    if (textField == _emailField) {
        [_passwordField becomeFirstResponder];
    } else if (textField == _passwordField) {
        shouldReturn = [_emailField holdsValidEmail] && [_passwordField holdsValidPassword];
        
        if (shouldReturn) {
            [self.view endEditing:YES];
            [self attemptUserLogin];
        } else {
            _passwordField.text = @"";
            [_authCell shakeAndVibrateDevice];
        }
    } else if (textField == _activationCodeField) {
        [_repeatPasswordField becomeFirstResponder];
    } else if (textField == _repeatPasswordField) {
        shouldReturn = [self activationCodeIsValid] && [self passwordIsValid];
        
        if (shouldReturn) {
            [self.view endEditing:YES];
            [self presentEULA];
        } else {
            _repeatPasswordField.text = @"";
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
            OLogState;
            
            [self reload];
            [_passwordField becomeFirstResponder];
        }
    }
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.destructiveButtonIndex) {
        [self activateMembership];
    }
}


#pragma mark - OModalViewControllerDelegate conformance

- (void)dismissViewControllerWithIdentitifier:(NSString *)identitifier
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    if ([identitifier isEqualToString:kMemberListViewControllerId]) {
        [self performSegueWithIdentifier:kSegueToOrigoListView sender:self];
    } else if ([identitifier isEqualToString:kMemberViewControllerId]) {
        if ([OMeta m].userIsSignedIn) {
            [self performSegueWithIdentifier:kSegueToOrigoListView sender:self];
        } else {
            [self reload];
        }
    }
}


#pragma mark - OServerConnectionDelegate conformance

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    [self indicatePendingServerSession:NO];
    
    if (response.statusCode < kHTTPStatusCodeErrorRangeStart) {
        if (response.statusCode == kHTTPStatusCodeCreated) {
            [self userDidSignUpWithData:data];
        } else {
            [self userDidAuthenticateWithData:data];
        }
    } else {
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
    [self indicatePendingServerSession:NO];
}

@end
