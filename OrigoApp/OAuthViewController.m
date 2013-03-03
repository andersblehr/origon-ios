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
#import "OTableViewCellBlueprint.h"

#import "ODevice.h"
#import "OMember+OrigoExtensions.h"
#import "OMembership.h"
#import "OMemberResidency.h"
#import "OMessageBoard.h"
#import "OOrigo+OrigoExtensions.h"

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
    if (self.state.actionIsLogin) {
        self.state.actionIsActivate = YES;
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
    } else if (self.state.actionIsActivate) {
        self.state.actionIsLogin = YES;
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
        
        if (_authInfo) {
            [[OMeta m] setGlobalDefault:nil forKey:kDefaultsKeyAuthInfo];
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
        
        [self.activityIndicator startAnimating];
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
        
        [self.activityIndicator stopAnimating];
    }
    
    self.canEdit = !isPending;
}


- (void)handleInvalidInputForField:(OTextField *)textField;
{
    _numberOfActivationAttempts++;
    
    if (_numberOfActivationAttempts < 3) {
        [self.detailCell shakeCellShouldVibrate:YES];
        
        if (textField == _activationCodeField) {
            _activationCodeField.text = @"";
        }
        
        _passwordField.text = @"";
        
        [textField becomeFirstResponder];
    } else {
        if (self.state.aspectIsSelf) {
            _numberOfActivationAttempts = 0;
            
            [[[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleActivationFailed] message:[OStrings stringForKey:strAlertTextActivationFailed] delegate:nil cancelButtonTitle:[OStrings stringForKey:strButtonOK] otherButtonTitles:nil] show];

            [self toggleAuthState];
        } else if (self.state.aspectIsEmail) {
            [self.dismisser dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
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
    NSString *activationCode = [[_authInfo objectForKey:kInputKeyActivationCode] lowercaseString];
    NSString *activationCodeAsEntered = [_activationCodeField.text lowercaseString];
    
    BOOL activationCodeIsValid = [activationCodeAsEntered isEqualToString:activationCode];
    BOOL passwordIsValid = NO;
    
    if (activationCodeIsValid) {
        NSString *passwordHashAsEntered = [self computePasswordHash:_repeatPasswordField.text];
        NSString *passwordHash = nil;
        
        if (self.state.aspectIsSelf) {
            passwordHash = [_authInfo objectForKey:kJSONKeyPasswordHash];
        } else if (self.state.aspectIsEmail) {
            passwordHash = [OMeta m].user.passwordHash;
        }
        
        passwordIsValid = [passwordHashAsEntered isEqualToString:passwordHash];
        
        if (passwordIsValid && self.state.aspectIsEmail) {
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
    if (![[OMeta m].context entityWithId:[OMeta m].deviceId]) {
        [self registerNewDevice];
    }
    
    if (![[OMeta m] userIsRegistered]) {
        [[OMeta m] setUserDefault:@YES forKey:kDefaultsKeyRegistrationAborted];
    }
    
    [self.dismisser dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
}


#pragma mark - User sign-up & activation

- (void)didReceiveActivationData:(NSDictionary *)data
{
    _authInfo = data;
    
    if (self.state.aspectIsSelf) {
        _userIsListed = [[_authInfo objectForKey:kJSONKeyIsListed] boolValue];
        
        [[OMeta m] setGlobalDefault:[NSKeyedArchiver archivedDataWithRootObject:_authInfo] forKey:kDefaultsKeyAuthInfo];
        
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
    
    [OMeta m].user.passwordHash = [_authInfo objectForKey:kJSONKeyPasswordHash];
    [[OMeta m] setGlobalDefault:nil forKey:kDefaultsKeyAuthInfo];
    
    [self.dismisser dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
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

    self.canEdit = YES;
    self.shouldDemphasiseOnEndEdit = NO;
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self initialiseFields];

    if (self.state.actionIsActivate) {
        if (self.state.aspectIsSelf) {
            NSString *welcomeBackMessage = [NSString stringWithFormat:[OStrings stringForKey:strAlertTextWelcomeBack], [_authInfo objectForKey:kPropertyKeyEmail]];
            
            UIAlertView *welcomeBackAlert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleWelcomeBack] message:welcomeBackMessage delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonStartOver] otherButtonTitles:[OStrings stringForKey:strButtonHaveCode], nil];
            welcomeBackAlert.tag = kAlertTagWelcomeBack;
            [welcomeBackAlert show];
        } else if (self.state.aspectIsEmail) {
            [self sendActivationCode];
        }
    }
    
    OLogState;
}


#pragma mark - OTableViewController overrides

- (BOOL)modalImpliesRegistration
{
    return NO;
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialise
{
    if (self.data) {
        self.state.actionIsActivate = YES;
        self.state.aspectIsEmail = YES;
    } else {
        NSData *authInfoArchive = [[OMeta m] globalDefaultForKey:kDefaultsKeyAuthInfo];
        
        if (authInfoArchive) {
            _authInfo = [NSKeyedUnarchiver unarchiveObjectWithData:authInfoArchive];
            [OMeta m].userEmail = [_authInfo objectForKey:kPropertyKeyEmail];
            
            self.state.actionIsActivate = YES;
        }
        
        self.state.aspectIsSelf = YES;
    }
}


- (void)populateDataSource
{
    [self setData:kEmptyDetailCellPlaceholder forSectionWithKey:kAuthSection];
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (self.state.actionIsLogin) {
        text = [OStrings stringForKey:strFooterSignInOrRegister];
    } else if (self.state.actionIsActivate) {
        if (self.state.aspectIsSelf) {
            text = [NSString stringWithFormat:[OStrings stringForKey:strFooterActivate], [_emailField finalText]];
        } else if (self.state.aspectIsEmail) {
            text = [NSString stringWithFormat:[OStrings stringForKey:strFooterActivateEmail], self.data];
        }
    }
    
    return text;
}


#pragma mark - UITableViewDataSource conformance

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 3 * (kDefaultCellPadding + [UIFont detailFieldHeight]) + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.state.actionIsLogin) {
        self.detailCell = [tableView cellWithReuseIdentifier:kReuseIdentifierUserSignIn delegate:self];
        
        _emailField = [self.detailCell textFieldForKey:kInputKeyAuthEmail];
        _passwordField = [self.detailCell textFieldForKey:kInputKeyPassword];
    } else {
        self.detailCell = [tableView cellWithReuseIdentifier:kReuseIdentifierUserActivation delegate:self];
        
        _activationCodeField = [self.detailCell textFieldForKey:kInputKeyActivationCode];
        _repeatPasswordField = [self.detailCell textFieldForKey:kInputKeyRepeatPassword];
    }
    
    return self.detailCell;
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


#pragma mark - UITextFieldDelegate conformance

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return self.canEdit;
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
            [self.detailCell shakeCellShouldVibrate:YES];
        }
    } else if (textField == _activationCodeField) {
        [_repeatPasswordField becomeFirstResponder];
    } else if (textField == _repeatPasswordField) {
        shouldReturn = [self activationIsValid];
        
        if (shouldReturn) {
            [self.view endEditing:YES];
            
            if (self.state.aspectIsSelf) {
                [self activateMembership];
            } else if (self.state.aspectIsEmail) {
                [self.dismisser dismissModalViewControllerWithIdentitifier:kAuthViewControllerId];
            }
        } else {
            _repeatPasswordField.text = @"";
            [self.detailCell shakeCellShouldVibrate:YES];
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


#pragma mark - OServerConnectionDelegate conformance

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
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
            [self.detailCell shakeCellShouldVibrate:YES];
            [_passwordField becomeFirstResponder];
        } else {
            [OAlert showAlertForHTTPStatus:response.statusCode];
        }
    }
}

@end
