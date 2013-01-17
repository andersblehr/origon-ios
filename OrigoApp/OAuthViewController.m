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

static NSString * const kHTTPHeaderLocation = @"Location";

static NSInteger const kActivationCodeLength = 6;

static NSInteger const kAlertButtonStartOver = 0;
static NSInteger const kAlertTagWelcomeBack = 0;


@implementation OAuthViewController

#pragma mark - Auxiliary methods

- (void)initialiseFields
{
    if ([OState s].actionIsLogin) {
        _passwordField.text = @"";
        
        if ([OMeta m].userEmail) {
            _emailField.text = [OMeta m].userEmail;
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
    if ([OState s].actionIsSetup) {
        [self restoreState];
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    } else if ([OState s].actionIsLogin) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
        
        if (_authInfo) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kKeyPathAuthInfo];
        }
    } else if ([OState s].actionIsActivate) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
    }
    
    [self initialiseFields];
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
        if ([OState s].actionIsLogin) {
            email = _emailField.text;
            password = _passwordField.text;
            
            _emailField.placeholder = [OStrings stringForKey:strPlaceholderPleaseWait];
            _emailField.text = @"";
            _passwordField.placeholder = [OStrings stringForKey:strPlaceholderPleaseWait];
            _passwordField.text = @"";
        } else if ([OState s].actionIsActivate) {
            activationCode = _activationCodeField.text;
            password = _repeatPasswordField.text;
            
            _activationCodeField.placeholder = [OStrings stringForKey:strPlaceholderPleaseWait];
            _activationCodeField.text = @"";
            _repeatPasswordField.placeholder = [OStrings stringForKey:strPlaceholderPleaseWait];
            _repeatPasswordField.text = @"";
        }
        
        [_activityIndicator startAnimating];
    } else {
        if ([OState s].actionIsLogin) {
            _emailField.text = email;
            _emailField.placeholder = [OStrings stringForKey:strPlaceholderAuthEmail];
            _passwordField.text = password;
            _passwordField.placeholder = [OStrings stringForKey:strPlaceholderPassword];
        } else if ([OState s].actionIsActivate) {
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
        if ([OState s].targetIsMember) {
            _numberOfActivationAttempts = 0;
            
            [[[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleActivationFailed] message:[OStrings stringForKey:strAlertTextActivationFailed] delegate:nil cancelButtonTitle:[OStrings stringForKey:strButtonOK] otherButtonTitles:nil] show];
            
            [OState s].actionIsLogin = YES;
            [self reload];
            
            OLogState;
        } else if ([OState s].targetIsEmail) {
            [_delegate dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
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
        
        if ([OState s].targetIsMember) {
            passwordHash = [_authInfo objectForKey:kKeyPathPasswordHash];
        } else if ([OState s].targetIsEmail) {
            passwordHash = [OMeta m].user.passwordHash;
        }
        
        passwordIsValid = [passwordHashAsEntered isEqualToString:passwordHash];
        
        if (passwordIsValid && [OState s].targetIsEmail) {
            [OMeta m].user.email = _emailToActivate;
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
    
    if ([OState s].actionIsActivate) {
        [self completeActivation];
    } else if ([OState s].actionIsLogin) {
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
    
    [_delegate dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
}


#pragma mark - User sign-up & activation

- (void)didReceiveActivationData:(NSDictionary *)data
{
    _authInfo = data;
    
    if ([OState s].targetIsMember) {
        _userIsListed = [[_authInfo objectForKey:kKeyPathIsListed] boolValue];
        
        NSData *authInfoArchive = [NSKeyedArchiver archivedDataWithRootObject:_authInfo];
        [[NSUserDefaults standardUserDefaults] setObject:authInfoArchive forKey:kKeyPathAuthInfo];
        
        [OState s].actionIsActivate = YES;
        [self reload];
        
        OLogState;
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
        [_delegate dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
    } else {
        [self performSegueWithIdentifier:kModalSegueToMemberView sender:self];
    }
}


#pragma mark - User email activation

- (void)emailActivationCode
{
    NSString *activationCode = [[OUUIDGenerator generateUUID] substringToIndex:kActivationCodeLength];
    
    OServerConnection *serverConnection = [[OServerConnection alloc] init];
    [serverConnection setAuthHeaderForEmail:_emailToActivate password:activationCode];
    [serverConnection emailActivationCode:self];
    
    [self indicatePendingServerSession:YES];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setBackground];
    [self.tableView addLogoBanner];
    
    _activityIndicator = [self.tableView addActivityIndicator];
    _editingIsAllowed = YES;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([OState s].actionIsSetup) {
        [_activityIndicator startAnimating];
        [OStrings fetchStrings:self];
    } else {
        NSData *authInfoArchive = [[NSUserDefaults standardUserDefaults] objectForKey:kKeyPathAuthInfo];
        
        if (authInfoArchive) {
            _authInfo = [NSKeyedUnarchiver unarchiveObjectWithData:authInfoArchive];
            
            [OMeta m].userEmail = [_authInfo objectForKey:kKeyPathEmail];
            [OState s].actionIsActivate = YES;
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self initialiseFields];

    if ([OState s].actionIsActivate) {
        if ([OState s].targetIsMember) {
            NSString *welcomeBackMessage = [NSString stringWithFormat:[OStrings stringForKey:strAlertTextWelcomeBack], [_authInfo objectForKey:kKeyPathEmail]];
            
            UIAlertView *welcomeBackAlert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleWelcomeBack] message:welcomeBackMessage delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonStartOver] otherButtonTitles:[OStrings stringForKey:strButtonHaveCode], nil];
            welcomeBackAlert.tag = kAlertTagWelcomeBack;
            [welcomeBackAlert show];
        } else if ([OState s].targetIsEmail) {
            [self emailActivationCode];
        }
    }
    
    OLogState;
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kModalSegueToMemberView]) {
        [OState s].actionIsRegister = YES;
        
        UINavigationController *navigationController = segue.destinationViewController;
        OMemberViewController *memberViewController = navigationController.viewControllers[0];
        memberViewController.membership = [[OMeta m].user.residencies anyObject]; // TODO: Fix!
        memberViewController.delegate = self;
    }
}


#pragma mark - OStateDelegate conformance

- (void)setState
{
    if ([OStrings hasStrings]) {
        if (_emailToActivate) {
            [OState s].actionIsActivate = YES;
            [OState s].targetIsEmail = YES;
        } else {
            [OState s].actionIsLogin = YES;
            [OState s].targetIsMember = YES;
        }
        
        [OState s].aspectIsSelf = YES;
    } else {
        [OState s].actionIsSetup = YES;
        
        self.stateIsIntrinsic = NO;
    }
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
    if ([OState s].actionIsLogin) {
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
    [cell willAppearTrailing:YES];
    
    if ([OState s].actionIsLogin) {
        _emailField.hasEmphasis = YES;
        _passwordField.hasEmphasis = YES;
    } else if ([OState s].actionIsActivate) {
        _activationCodeField.hasEmphasis = YES;
        _repeatPasswordField.hasEmphasis = YES;
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *footerText = nil;
    
    if ([OState s].actionIsLogin) {
        footerText = [OStrings stringForKey:strFooterSignInOrRegister];
    } else if ([OState s].actionIsActivate) {
        if ([OState s].targetIsMember) {
            footerText = [OStrings stringForKey:strFooterActivate];
        } else if ([OState s].targetIsEmail) {
            footerText = [NSString stringWithFormat:[OStrings stringForKey:strFooterActivateEmail], _emailToActivate];
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
            
            if ([OState s].targetIsMember) {
                [self activateMembership];
            } else if ([OState s].targetIsEmail) {
                [_delegate dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
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
            [OState s].actionIsLogin = YES;
            OLogState;
            
            [self reload];
            [_passwordField becomeFirstResponder];
        }
    }
}


#pragma mark - OModalViewControllerDelegate conformance

- (void)dismissModalViewControllerWithIdentitifier:(NSString *)identitifier
{
    if ([identitifier isEqualToString:kMemberListViewControllerId]) {
        [_delegate dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
    } else if ([identitifier isEqualToString:kMemberViewControllerId]) {
        if ([[OMeta m] userIsSignedIn]) {
            [_delegate dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
        } else {
            [self dismissViewControllerAnimated:YES completion:NULL];
            [self reload];
        }
    }
}


#pragma mark - OServerConnectionDelegate conformance

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    if ([OState s].actionIsSetup) {
        [_activityIndicator stopAnimating];
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kKeyPathStringDate];
        
        [OStrings.class didCompleteWithResponse:response data:data];
        [(OTabBarController *)((UIViewController *)_delegate).tabBarController setTabBarTitles];
        
        [self reload];
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
