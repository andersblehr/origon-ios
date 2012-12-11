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

static NSInteger const kAlertButtonStartOver = 0;
static NSInteger const kAlertTagWelcomeBack = 0;


@implementation OAuthViewController

#pragma mark - Auxiliary methods

- (void)setDefaultAuthState
{
    [OState s].actionIsLogin = YES;
    [OState s].targetIsMember = YES;
    [OState s].aspectIsSelf = YES;
}


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
        [self setDefaultAuthState];
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    } else if ([OState s].actionIsLogin) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
        
        if (_authInfo) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kKeyPathAuthInfo];
            _authInfo = nil;
        }
    } else if ([OState s].actionIsActivate) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
    }
    
    [self initialiseFields];
}


- (NSString *)computePasswordHash:(NSString *)password
{
    return [[password diff:[OMeta m].userEmail] hashUsingSHA1];
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
    NSString *activationCode = [[_authInfo objectForKey:kKeyPathActivationCode] lowercaseString];
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
        NSString *passwordHash = [_authInfo objectForKey:kKeyPathPasswordHash];
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
    
    if (deviceIsNew || [[OMeta m].context needsReplication]) {
        [[OMeta m].context replicateIfNeeded];
    }
    
    if ([[OMeta m] userIsRegistered]) {
        [_delegate dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
    } else {
        [OAlert showAlertWithTitle:[OStrings stringForKey:strAlertTitleIncompleteRegistration] message:[OStrings stringForKey:strAlertTextIncompleteRegistration]];
        
        [self performSegueWithIdentifier:kModalSegueToMemberView sender:self];
    }
}


#pragma mark - User sign-up & activation

- (void)userDidSignUpWithData:(NSDictionary *)data
{
    _authInfo = data;
    _userIsListed = [[_authInfo objectForKey:kKeyPathIsListed] boolValue];
    
    NSData *authInfoArchive = [NSKeyedArchiver archivedDataWithRootObject:_authInfo];
    [[NSUserDefaults standardUserDefaults] setObject:authInfoArchive forKey:kKeyPathAuthInfo];
    
    [OState s].actionIsActivate = YES;
    [self reload];
    
    OLogState;
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
    
    [OMeta m].user.passwordHash = [_authInfo objectForKey:kKeyPathPasswordHash];
    [OMeta m].user.didRegister_ = YES;
    
    [[OMeta m].context replicateIfNeeded];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kKeyPathAuthInfo];
    _authInfo = nil;
    
    if ([[OMeta m] userIsRegistered] && [[OMeta m].user isMinor]) {
        [_delegate dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
    } else {
        [self performSegueWithIdentifier:kModalSegueToMemberView sender:self];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setBackground];
    [self.tableView addLogoBanner];
    
    _activityIndicator = [self.tableView addActivityIndicator];
    _editingIsAllowed = YES;
    
    self.title = @"Origo";
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (![OState s].actionIsSetup) {
        [self setDefaultAuthState];
    }
    
    OLogState;
    
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
        NSString *welcomeBackMessage = [NSString stringWithFormat:[OStrings stringForKey:strAlertTextWelcomeBack], [_authInfo objectForKey:kKeyPathEmail]];
        
        UIAlertView *welcomeBackAlert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleWelcomeBack] message:welcomeBackMessage delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonStartOver] otherButtonTitles:[OStrings stringForKey:strButtonHaveCode], nil];
        welcomeBackAlert.tag = kAlertTagWelcomeBack;
        [welcomeBackAlert show];
    }
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
            [_authCell shakeCellVibrateDevice:YES];
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


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.destructiveButtonIndex) {
        [self activateMembership];
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
                [self userDidSignUpWithData:data];
            } else {
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
