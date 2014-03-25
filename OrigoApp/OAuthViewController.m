//
//  OAuthViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OAuthViewController.h"

static NSInteger const kSectionKeyAuth = 0;

static NSInteger const kMaxActivationAttempts = 3;

static NSInteger const kAlertTagWelcomeBack = 0;
static NSInteger const kAlertTagActivationFailed = 1;

static NSInteger const kAlertButtonWelcomeBackStartOver = 0;


@implementation OAuthViewController

#pragma mark - Auxiliary methods

- (void)initialiseFields
{
    if ([self actionIs:kActionSignIn]) {
        _passwordField.value = [NSString string];
        
        if ([OMeta m].userEmail) {
            _emailField.value = [OMeta m].userEmail;
            [_passwordField becomeFirstResponder];
        } else {
            [_emailField becomeFirstResponder];
        }
    } else if ([self actionIs:kActionActivate]) {
        _activationCodeField.value = [NSString string];
        _repeatPasswordField.value = [NSString string];
        
        [_activationCodeField becomeFirstResponder];
    }
}


- (void)toggleAuthState
{
    [self.state toggleAction:@[kActionSignIn, kActionActivate]];
    
    if ([self actionIs:kActionActivate]) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
    } else if ([self actionIs:kActionSignIn]) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
        
        if (_authInfo) {
            [ODefaults setGlobalDefault:nil forKey:kDefaultsKeyAuthInfo];
        }
    }
    
    [self initialiseFields];
    
    OLogState;
}


- (void)handleFailedActivationAttempt
{
    static NSInteger numberOfFailedAttempts = 0;
    
    numberOfFailedAttempts++;
    
    if (numberOfFailedAttempts == kMaxActivationAttempts) {
        numberOfFailedAttempts = 0;
        
        if ([self targetIs:kTargetUser]) {
            [OAlert showAlertWithTitle:NSLocalizedString(@"Activation failed", @"") text:NSLocalizedString(@"It looks like you may have lost the activation code ...", @"") tag:kAlertTagActivationFailed];
        } else if ([self targetIs:kTargetEmail]) {
            [self.dismisser dismissModalViewController:self reload:YES];
        }
    }
}


#pragma mark - Handling server responses

- (void)userDidSignUpWithData:(NSDictionary *)data
{
    _authInfo = data;
    
    if ([self targetIs:kTargetUser]) {
        [ODefaults setGlobalDefault:[NSKeyedArchiver archivedDataWithRootObject:_authInfo] forKey:kDefaultsKeyAuthInfo];
        
        [self toggleAuthState];
    }
}


- (void)userDidAuthenticateWithData:(NSArray *)data
{
    if (data) {
        [[OMeta m].context saveServerReplicas:data];
    }
    
    [[OMeta m] userDidSignIn];
    
    if ([self actionIs:kActionSignIn]) {
        [OMeta m].user.passwordHash = [OCrypto passwordHashWithPassword:_passwordField.value];
    } else if ([self actionIs:kActionActivate]) {
        [OMeta m].user.passwordHash = _authInfo[kJSONKeyPasswordHash];
        
        [[OMeta m] userDidSignUp];
        [[OMeta m].user ensureResidency];
        
        [ODefaults setGlobalDefault:nil forKey:kDefaultsKeyAuthInfo];
    }
    
    [self.dismisser dismissModalViewController:self reload:YES];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView addLogoBanner];

    self.canEdit = YES;
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self initialiseFields];

    if ([self actionIs:kActionActivate]) {
        if ([self targetIs:kTargetUser]) {
            UIAlertView *welcomeBackAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Welcome back!", @"") message:[NSString stringWithFormat:NSLocalizedString(@"If you have handy the activation code sent to %@ ...", @""), _authInfo[kPropertyKeyEmail]] delegate:self cancelButtonTitle:NSLocalizedString(@"Start over", @"") otherButtonTitles:NSLocalizedString(@"Have code", @""), nil];
            welcomeBackAlert.tag = kAlertTagWelcomeBack;
            [welcomeBackAlert show];
        } else if ([self targetIs:kTargetEmail]) {
            [OConnection sendActivationCodeToEmail:self.data];
        }
    }
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialiseState
{
    if (self.data) {
        self.state.action = kActionActivate;
        self.state.target = kTargetEmail;
    } else {
        NSData *authInfoArchive = [ODefaults globalDefaultForKey:kDefaultsKeyAuthInfo];
        
        if (authInfoArchive) {
            _authInfo = [NSKeyedUnarchiver unarchiveObjectWithData:authInfoArchive];
            
            [OMeta m].userEmail = _authInfo[kJSONKeyEmail];
            [OMeta m].deviceId = _authInfo[kJSONKeyDeviceId];

            self.state.action = kActionActivate;
        } else {
            self.state.action = kActionSignIn;
        }
        
        self.state.target = kTargetUser;
    }
}


- (void)initialiseData
{
    [self setData:kCustomData forSectionWithKey:kSectionKeyAuth];
}


- (NSString *)reuseIdentifierForIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = nil;
    
    if ([self actionIs:kActionSignIn]) {
        reuseIdentifier = kReuseIdentifierUserSignIn;
    } else if ([self actionIs:kActionActivate]) {
        reuseIdentifier = kReuseIdentifierUserActivation;
    }
    
    return reuseIdentifier;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return YES;
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if ([self actionIs:kActionSignIn]) {
        text = NSLocalizedString(@"New users will receive an email with an activation code that must be entered in the next step.", @"");
    } else if ([self actionIs:kActionActivate]) {
        if ([self targetIs:kTargetUser]) {
            text = [NSString stringWithFormat:NSLocalizedString(@"The activation code has been sent to %@ ...", @""), _emailField.value];
        } else if ([self targetIs:kTargetEmail]) {
            text = [NSString stringWithFormat:NSLocalizedString(@"The activation code has been sent to %@.", @""), self.data];
        }
    }
    
    return text;
}


- (void)willDisplayCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self actionIs:kActionSignIn]) {
        _emailField = [cell inputFieldForKey:kInterfaceKeyAuthEmail];
        _passwordField = [cell inputFieldForKey:kInterfaceKeyPassword];
    } else if ([self actionIs:kActionActivate]) {
        _activationCodeField = [cell inputFieldForKey:kInterfaceKeyActivationCode];
        _repeatPasswordField = [cell inputFieldForKey:kInterfaceKeyRepeatPassword];
    }
}


- (BOOL)serverRequestsAreSynchronous
{
    return ![self actionIs:kActionActivate] || ![self targetIs:kTargetEmail];
}


#pragma mark - OTableViewInputDelegate conformance

- (BOOL)inputIsValid
{
    BOOL inputIsValid = NO;
    
    if ([self actionIs:kActionSignIn]) {
        inputIsValid = [_emailField hasValidValue] && [_passwordField hasValidValue];
    } else if ([self actionIs:kActionActivate]) {
        inputIsValid = [_activationCodeField hasValidValue] && [_repeatPasswordField hasValidValue];
    }
    
    return inputIsValid;
}


- (void)processInput
{
    if ([self actionIs:kActionSignIn]) {
        [OMeta m].userEmail = _emailField.value;
        [OConnection signInWithEmail:[OMeta m].userEmail password:_passwordField.value];
    } else if ([self actionIs:kActionActivate]) {
        if ([self targetIs:kTargetUser]) {
            [OConnection activateWithEmail:[OMeta m].userEmail password:_repeatPasswordField.value];
        } else if ([self targetIs:kTargetEmail]) {
            [OMeta m].userEmail = self.data;
            [self.dismisser dismissModalViewController:self reload:YES];
        }
    }
}


- (BOOL)willValidateInputForKey:(NSString *)key
{
    return [@[kInterfaceKeyActivationCode, kInterfaceKeyRepeatPassword] containsObject:key];
}


- (BOOL)inputValue:(id)inputValue isValidForKey:(NSString *)key
{
    BOOL isValid = NO;
    
    if ([key isEqualToString:kInterfaceKeyActivationCode]) {
        NSString *activationCode = _authInfo[kJSONKeyActivationCode];
        NSString *activationCodeAsEntered = [inputValue lowercaseString];
        
        isValid = [activationCodeAsEntered isEqualToString:activationCode];
    } else if ([key isEqualToString:kInterfaceKeyRepeatPassword]) {
        NSString *passwordHashAsEntered = [OCrypto passwordHashWithPassword:inputValue];
        NSString *passwordHash = nil;
        
        if ([self targetIs:kTargetUser]) {
            passwordHash = _authInfo[kJSONKeyPasswordHash];
        } else if ([self targetIs:kTargetEmail]) {
            passwordHash = [OMeta m].user.passwordHash;
        }
        
        isValid = [passwordHashAsEntered isEqualToString:passwordHash];
    }
    
    if (!isValid) {
        [self handleFailedActivationAttempt];
    }
    
    return isValid;
}


#pragma mark - UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertTagWelcomeBack:
            if (buttonIndex == kAlertButtonWelcomeBackStartOver) {
                [self toggleAuthState];
            }
            
            break;
            
        case kAlertTagActivationFailed:
            [self toggleAuthState];
            
            break;
            
        default:
            break;
    }
}


#pragma mark - OconnectionDelegate conformance

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    [super didCompleteWithResponse:response data:data];
    
    if (response.statusCode < kHTTPStatusErrorRangeStart) {
        if (response.statusCode == kHTTPStatusCreated) {
            [self userDidSignUpWithData:data];
        } else {
            if (![OMeta m].userId) {
                if (response.statusCode == kHTTPStatusOK) {
                    [OMeta m].userId = [response allHeaderFields][kHTTPHeaderLocation];
                } else {
                    [OMeta m].userId = [OCrypto generateUUID];
                }
            }
            
            [self userDidAuthenticateWithData:data];
        }
    } else if (response.statusCode == kHTTPStatusUnauthorized) {
        [self.detailCell shakeCellVibrate:YES];
        [_passwordField becomeFirstResponder];
    }
}

@end
