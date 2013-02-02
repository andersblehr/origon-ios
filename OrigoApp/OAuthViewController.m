//
//  OAuthViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OAuthViewController.h"

#import "NSManagedObjectContext+OrigoExtensions.h"
#import "NSString+OrigoExtensions.h"
#import "UIBarButtonItem+OrigoExtensions.h"
#import "UIFont+OrigoExtensions.h"
#import "UITableView+OrigoExtensions.h"

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
#import "OMember+OrigoExtensions.h"
#import "OMembership+OrigoExtensions.h"
#import "OMemberResidency.h"
#import "OMessageBoard.h"
#import "OOrigo+OrigoExtensions.h"

#import "OMemberViewController.h"
#import "OTabBarController.h"

static NSString * const kModalSegueToMemberView = @"modalFromAuthToMemberView";

static NSInteger const kAuthSection = 0;

static NSInteger const kActivationCodeLength = 6;

static NSInteger const kAlertButtonStartOver = 0;
static NSInteger const kAlertTagWelcomeBack = 0;


@implementation OAuthViewController

#pragma mark - Auxiliary methods

- (void)initialiseFields
{
    if (self.state.actionIsLogin) {
        _passwordField.text = @"";
        
        if ([OMeta m].userEmail) {
            _emailField.text = [OMeta m].userEmail;
            [_passwordField becomeFirstResponder];
        } else {
            [_emailField becomeFirstResponder];
        }
    } else if (self.state.actionIsActivate) {
        _activationCodeField.text = @"";
        _repeatPasswordField.text = @"";
        
        [_activationCodeField becomeFirstResponder];
    }
}


- (void)toggleAuthState
{
    if ([OState s].actionIsSetup) {
        [self reflectState];
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    } else if (self.state.actionIsLogin) {
        self.state.actionIsActivate = YES;
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
    } else if (self.state.actionIsActivate) {
        self.state.actionIsLogin = YES;
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
        
        if (_authInfo) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kKeyPathAuthInfo];
        }
    }
    
    [self initialiseFields];
    
    OLogState;
}


- (NSString *)computePasswordHash:(NSString *)password
{
    return [[password seasonWith:kOrigoSeasoning] hashUsingSHA1];
}


- (void)indicatePendingServerSession:(BOOL)isPending
{
    static NSString *email;
    static NSString *password;
    static NSString *activationCode;
    
    if (isPending) {
        if (self.state.actionIsLogin) {
            email = _emailField.text;
            password = _passwordField.text;
            
            _emailField.placeholder = [OStrings stringForKey:strPlaceholderPleaseWait];
            _emailField.text = @"";
            _passwordField.placeholder = [OStrings stringForKey:strPlaceholderPleaseWait];
            _passwordField.text = @"";
        } else if (self.state.actionIsActivate) {
            activationCode = _activationCodeField.text;
            password = _repeatPasswordField.text;
            
            _activationCodeField.placeholder = [OStrings stringForKey:strPlaceholderPleaseWait];
            _activationCodeField.text = @"";
            _repeatPasswordField.placeholder = [OStrings stringForKey:strPlaceholderPleaseWait];
            _repeatPasswordField.text = @"";
        }
        
        [_activityIndicator startAnimating];
    } else {
        if (self.state.actionIsLogin) {
            _emailField.text = email;
            _emailField.placeholder = [OStrings stringForKey:strPlaceholderAuthEmail];
            _passwordField.text = password;
            _passwordField.placeholder = [OStrings stringForKey:strPlaceholderPassword];
        } else if (self.state.actionIsActivate) {
            _activationCodeField.text = activationCode;
            _activationCodeField.placeholder = [OStrings stringForKey:strPlaceholderActivationCode];
            _repeatPasswordField.text = password;
            _repeatPasswordField.placeholder = [OStrings stringForKey:strPlaceholderPassword];
        }
        
        [_activityIndicator stopAnimating];
    }
    
    _editingIsAllowed = !isPending;
}


- (void)handleInvalidInputForField:(OTextField *)textField;
{
    _numberOfActivationAttempts++;
    
    if (_numberOfActivationAttempts < 3) {
        [_authCell shakeCellVibrateDevice:YES];
        
        if (textField == _activationCodeField) {
            _activationCodeField.text = @"";
        }
        
        _passwordField.text = @"";
        
        [textField becomeFirstResponder];
    } else {
        if (self.state.targetIsMember) {
            _numberOfActivationAttempts = 0;
            
            [[[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleActivationFailed] message:[OStrings stringForKey:strAlertTextActivationFailed] delegate:nil cancelButtonTitle:[OStrings stringForKey:strButtonOK] otherButtonTitles:nil] show];

            [self toggleAuthState];
        } else if (self.state.targetIsEmail) {
            [self.delegate dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
        }
    }
}


- (void)registerNewDevice
{
    ODevice *device = [[OMeta m].context insertEntityForClass:ODevice.class inOrigo:[[OMeta m].user rootMembership].origo entityId:[OMeta m].deviceId];
    device.type = [UIDevice currentDevice].model;
    device.displayName = [UIDevice currentDevice].name;
    device.member = [OMeta m].user;
}


#pragma mark - Input validation

- (BOOL)activationIsValid
{
    NSString *activationCode = [[_authInfo objectForKey:kKeyPathActivationCode] lowercaseString];
    NSString *activationCodeAsEntered = [_activationCodeField.text lowercaseString];
    
    BOOL activationCodeIsValid = [activationCodeAsEntered isEqualToString:activationCode];
    BOOL passwordIsValid = NO;
    
    if (activationCodeIsValid) {
        NSString *passwordHashAsEntered = [self computePasswordHash:_repeatPasswordField.text];
        NSString *passwordHash = nil;
        
        if (self.state.targetIsMember) {
            passwordHash = [_authInfo objectForKey:kKeyPathPasswordHash];
        } else if (self.state.targetIsEmail) {
            passwordHash = [OMeta m].user.passwordHash;
        }
        
        passwordIsValid = [passwordHashAsEntered isEqualToString:passwordHash];
        
        if (passwordIsValid && self.state.targetIsEmail) {
            [OMeta m].user.email = self.data;
        } else if (!passwordIsValid) {
            [self handleInvalidInputForField:_repeatPasswordField];
        }
    } else {
        [self handleInvalidInputForField:_activationCodeField];
    }
    
    return (activationCodeIsValid && passwordIsValid);
}


#pragma mark - User login

- (void)attemptUserLogin
{
    [OMeta m].userEmail = _emailField.text;
    
    OServerConnection *serverConnection = [[OServerConnection alloc] init];
    [serverConnection setAuthHeaderForEmail:_emailField.text password:_passwordField.text];
    [serverConnection authenticate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)userDidAuthenticateWithData:(NSArray *)data
{
    if (data) {
        [[OMeta m].context saveServerReplicas:data];
    }
    
    [[OMeta m] userDidSignIn];
    
    if (self.state.actionIsActivate) {
        [self completeActivation];
    } else if (self.state.actionIsLogin) {
        [self completeLogin];
    }
}


- (void)completeLogin
{
    BOOL deviceIsNew = ([[OMeta m].context entityWithId:[OMeta m].deviceId] == nil);
    
    if (deviceIsNew) {
        [self registerNewDevice];
    }
    
    if (deviceIsNew || [[OMeta m].context needsReplication]) {
        [[OMeta m].context replicateIfNeeded];
    }
    
    [self.delegate dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
}


#pragma mark - User sign-up & activation

- (void)didReceiveActivationData:(NSDictionary *)data
{
    _authInfo = data;
    
    if (self.state.targetIsMember) {
        _userIsListed = [[_authInfo objectForKey:kKeyPathIsListed] boolValue];
        
        NSData *authInfoArchive = [NSKeyedArchiver archivedDataWithRootObject:_authInfo];
        [[NSUserDefaults standardUserDefaults] setObject:authInfoArchive forKey:kKeyPathAuthInfo];
        
        [self toggleAuthState];
    }
}


- (void)activateMembership
{
    OServerConnection *serverConnection = [[OServerConnection alloc] init];
    [serverConnection setAuthHeaderForEmail:[OMeta m].userEmail password:_repeatPasswordField.text];
    [serverConnection authenticate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)completeActivation
{
    [self registerNewDevice];
    
    if (_userIsListed) {
        OMembership *rootMembership = [[OMeta m].user rootMembership];
        rootMembership.isActive = @YES;
        rootMembership.isAdmin = @YES;
        
        for (OMemberResidency *residency in [OMeta m].user.residencies) {
            residency.isActive = @YES;
            
            if (![[OMeta m].user isMinor]) {
                residency.isAdmin = @YES;
            }
        }
    } else {
        OOrigo *residence = [[OMeta m].context insertOrigoEntityOfType:kOrigoTypeResidence];
        OMemberResidency *residency = [residence addResident:[OMeta m].user];
        residency.isActive = @YES;
        residency.isAdmin = @YES;
        
        OMessageBoard *residenceMessageBoard = [[OMeta m].context insertEntityForClass:OMessageBoard.class inOrigo:residence];
        residenceMessageBoard.title = [OStrings stringForKey:strNameMyMessageBoard];
    }
    
    [OMeta m].user.passwordHash = [_authInfo objectForKey:kKeyPathPasswordHash];
    
    [[OMeta m].context replicateIfNeeded];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kKeyPathAuthInfo];
    
    if ([[OMeta m] userIsRegistered] && [[OMeta m].user isMinor]) {
        [self.delegate dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
    } else {
        [self performSegueWithIdentifier:kModalSegueToMemberView sender:self];
    }
}


#pragma mark - User email activation

- (void)sendActivationCode
{
    NSString *activationCode = [[OUUIDGenerator generateUUID] substringToIndex:kActivationCodeLength];
    
    OServerConnection *serverConnection = [[OServerConnection alloc] init];
    [serverConnection setAuthHeaderForEmail:self.data password:activationCode];
    [serverConnection emailActivationCode:self];
    
    [self indicatePendingServerSession:YES];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView addLogoBanner];

    self.shouldDemphasiseOnEndEdit = NO;
    
    _activityIndicator = [self.tableView addActivityIndicator];
    _editingIsAllowed = YES;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([OState s].actionIsSetup) {
        [_activityIndicator startAnimating];
        [OStrings fetchStrings:self];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self initialiseFields];

    if (self.state.actionIsActivate) {
        if (self.state.targetIsMember) {
            NSString *welcomeBackMessage = [NSString stringWithFormat:[OStrings stringForKey:strAlertTextWelcomeBack], [_authInfo objectForKey:kKeyPathEmail]];
            
            UIAlertView *welcomeBackAlert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleWelcomeBack] message:welcomeBackMessage delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonStartOver] otherButtonTitles:[OStrings stringForKey:strButtonHaveCode], nil];
            welcomeBackAlert.tag = kAlertTagWelcomeBack;
            [welcomeBackAlert show];
        } else if (self.state.targetIsEmail) {
            [self sendActivationCode];
        }
    }
    
    OLogState;
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kModalSegueToMemberView]) {
        [self prepareForModalSegue:segue data:[[OMeta m].user initialResidency]];
    }
}


#pragma mark - Overrides

- (BOOL)modalImpliesRegistration
{
    return NO;
}


#pragma mark - OTableViewControllerDelegate conformance

- (void)loadState
{
    if (self.data) {
        self.state.actionIsActivate = YES;
        self.state.targetIsEmail = YES;
    } else {
        NSData *authInfoArchive = [[NSUserDefaults standardUserDefaults] objectForKey:kKeyPathAuthInfo];
        
        if (authInfoArchive) {
            _authInfo = [NSKeyedUnarchiver unarchiveObjectWithData:authInfoArchive];
            [OMeta m].userEmail = [_authInfo objectForKey:kKeyPathEmail];
            
            self.state.actionIsActivate = YES;
        } else {
            self.state.actionIsLogin = YES;
        }
        
        self.state.targetIsMember = YES;
    }
    
    self.state.aspectIsSelf = YES;
}


#pragma mark - UITableViewDataSource conformance

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [OState s].actionIsSetup ? 0 : 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 3 * (kDefaultPadding + [UIFont detailFieldHeight]) + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.state.actionIsLogin) {
        _authCell = [tableView cellWithReuseIdentifier:kReuseIdentifierUserSignIn delegate:self];
        
        _emailField = [_authCell textFieldForKeyPath:kKeyPathAuthEmail];
        _passwordField = [_authCell textFieldForKeyPath:kKeyPathPassword];
    } else {
        _authCell = [tableView cellWithReuseIdentifier:kReuseIdentifierUserActivation delegate:self];
        
        _activationCodeField = [_authCell textFieldForKeyPath:kKeyPathActivationCode];
        _repeatPasswordField = [_authCell textFieldForKeyPath:kKeyPathRepeatPassword];
    }
    
    return _authCell;
}


#pragma mark - UITableViewDelegate conformance

- (void)tableView:(UITableView *)tableView willDisplayCell:(OTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    
    if (self.state.actionIsLogin) {
        _emailField.hasEmphasis = YES;
        _passwordField.hasEmphasis = YES;
    } else if (self.state.actionIsActivate) {
        _activationCodeField.hasEmphasis = YES;
        _repeatPasswordField.hasEmphasis = YES;
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *footerText = nil;
    
    if (self.state.actionIsLogin) {
        footerText = [OStrings stringForKey:strFooterSignInOrRegister];
    } else if (self.state.actionIsActivate) {
        if (self.state.targetIsMember) {
            footerText = [OStrings stringForKey:strFooterActivate];
        } else if (self.state.targetIsEmail) {
            footerText = [NSString stringWithFormat:[OStrings stringForKey:strFooterActivateEmail], self.data];
        }
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
            [_authCell shakeCellVibrateDevice:YES];
        }
    } else if (textField == _activationCodeField) {
        [_repeatPasswordField becomeFirstResponder];
    } else if (textField == _repeatPasswordField) {
        shouldReturn = [self activationIsValid];
        
        if (shouldReturn) {
            [self.view endEditing:YES];
            
            if (self.state.targetIsMember) {
                [self activateMembership];
            } else if (self.state.targetIsEmail) {
                [self.delegate dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
            }
        } else {
            _repeatPasswordField.text = @"";
            [_authCell shakeCellVibrateDevice:YES];
        }
    }
    
    return shouldReturn;
}


#pragma mark - UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kAlertTagWelcomeBack) {
        if (buttonIndex == kAlertButtonStartOver) {
            [self toggleAuthState];
            [_passwordField becomeFirstResponder];
        }
    }
}


#pragma mark - OModalViewControllerDelegate conformance

- (void)dismissModalViewControllerWithIdentitifier:(NSString *)identitifier
{
    if ([identitifier isEqualToString:kMemberListViewControllerId]) {
        [self.delegate dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
    } else if ([identitifier isEqualToString:kMemberViewControllerId]) {
        if ([[OMeta m] userIsSignedIn]) {
            [self.delegate dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
        } else {
            [self dismissViewControllerAnimated:YES completion:NULL];
            [self toggleAuthState];
        }
    }
}


#pragma mark - OServerConnectionDelegate conformance

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    if ([OState s].actionIsSetup) {
        [_activityIndicator stopAnimating];
        
        [OStrings.class didCompleteWithResponse:response data:data];
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kKeyPathStringDate];
        [(OTabBarController *)((UIViewController *)self.delegate).tabBarController setTabBarTitles];
        
        [self toggleAuthState];
    } else {
        [self indicatePendingServerSession:NO];
        
        if (response.statusCode < kHTTPStatusErrorRangeStart) {
            if (response.statusCode == kHTTPStatusCreated) {
                [self didReceiveActivationData:data];
            } else {
                if (![OMeta m].userId) {
                    if (response.statusCode == kHTTPStatusOK) {
                        [OMeta m].userId = [[response allHeaderFields] objectForKey:kHTTPHeaderLocation];
                    } else {
                        [OMeta m].userId = [OUUIDGenerator generateUUID];
                    }
                }
                
                [self userDidAuthenticateWithData:data];
            }
        } else {
            if (response.statusCode == kHTTPStatusUnauthorized) {
                [_authCell shakeCellVibrateDevice:YES];
                [_passwordField becomeFirstResponder];
            } else {
                [OAlert showAlertForHTTPStatus:response.statusCode];
            }
        }
    }
}


- (void)didFailWithError:(NSError *)error
{
    [self indicatePendingServerSession:NO];
    
    // TODO: Handle errors (-1001: Timeout, and others)
}

@end
