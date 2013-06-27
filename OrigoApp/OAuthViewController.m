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
#import "OConnection.h"
#import "ODefaults.h"
#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTableViewCellBlueprint.h"
#import "OTextField.h"
#import "OUUIDGenerator.h"

#import "OMember+OrigoExtensions.h"
#import "OMembership.h"
#import "OOrigo+OrigoExtensions.h"

static NSInteger const kAuthSection = 0;

static NSInteger const kActivationCodeLength = 6;

static NSInteger const kAlertTagWelcomeBack = 0;
static NSInteger const kAlertTagActivationFailed = 1;

static NSInteger const kAlertButtonWelcomeBackStartOver = 0;


@implementation OAuthViewController

#pragma mark - Auxiliary methods

- (void)initialiseFields
{
    if ([self actionIs:kActionSignIn]) {
        _passwordField.text = @"";
        
        if ([OMeta m].userEmail) {
            _emailField.text = [OMeta m].userEmail;
            [_passwordField becomeFirstResponder];
        } else {
            [_emailField becomeFirstResponder];
        }
    } else if ([self actionIs:kActionActivate]) {
        _activationCodeField.text = @"";
        _repeatPasswordField.text = @"";
        
        [_activationCodeField becomeFirstResponder];
    }
}


- (void)toggleAuthState
{
    if ([self actionIs:kActionSignIn]) {
        self.action = kActionActivate;
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
    } else if ([self actionIs:kActionActivate]) {
        self.action = kActionSignIn;
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
        
        if (_authInfo) {
            [ODefaults setGlobalDefault:nil forKey:kDefaultsKeyAuthInfo];
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
        if ([self actionIs:kActionSignIn]) {
            email = _emailField.text;
            password = _passwordField.text;
            
            _emailField.placeholder = [OStrings stringForKey:strPlaceholderPleaseWait];
            _emailField.text = @"";
            _passwordField.placeholder = [OStrings stringForKey:strPlaceholderPleaseWait];
            _passwordField.text = @"";
        } else if ([self actionIs:kActionActivate]) {
            activationCode = _activationCodeField.text;
            password = _repeatPasswordField.text;
            
            _activationCodeField.placeholder = [OStrings stringForKey:strPlaceholderPleaseWait];
            _activationCodeField.text = @"";
            _repeatPasswordField.placeholder = [OStrings stringForKey:strPlaceholderPleaseWait];
            _repeatPasswordField.text = @"";
        }
        
        [self.activityIndicator startAnimating];
    } else {
        if ([self actionIs:kActionSignIn]) {
            _emailField.text = email;
            _emailField.placeholder = [OStrings stringForKey:strPlaceholderAuthEmail];
            _passwordField.text = password;
            _passwordField.placeholder = [OStrings stringForKey:strPlaceholderPassword];
        } else if ([self actionIs:kActionActivate]) {
            _activationCodeField.text = activationCode;
            _activationCodeField.placeholder = [OStrings stringForKey:strPlaceholderActivationCode];
            _repeatPasswordField.text = password;
            _repeatPasswordField.placeholder = [OStrings stringForKey:strPlaceholderPassword];
        }
        
        [self.activityIndicator stopAnimating];
    }
    
    self.canEdit = !isPending;
}


#pragma mark - Input validation

#pragma mark - Initiating server requests

- (void)sendUserLoginRequest
{
    [OMeta m].userEmail = _emailField.text;
    
    OConnection *serverConnection = [[OConnection alloc] init];
    [serverConnection setAuthHeaderForEmail:_emailField.text password:_passwordField.text];
    [serverConnection authenticate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)sendUserActivationRequest
{
    OConnection *serverConnection = [[OConnection alloc] init];
    [serverConnection setAuthHeaderForEmail:[OMeta m].userEmail password:_repeatPasswordField.text];
    [serverConnection authenticate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)sendEmailActivationRequest
{
    NSString *emailActivationCode = [[OUUIDGenerator generateUUID] substringToIndex:kActivationCodeLength];
    
    OConnection *serverConnection = [[OConnection alloc] init];
    [serverConnection setAuthHeaderForEmail:self.data password:emailActivationCode];
    [serverConnection sendEmailActivationCode:self];
    
    [self indicatePendingServerSession:YES];
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
        if (![[OMeta m] userIsRegistered]) {
            [ODefaults setUserDefault:@YES forKey:kDefaultsKeyRegistrationAborted];
        }
    } else if ([self actionIs:kActionActivate]) {
        [ODefaults setUserDefault:[_authInfo objectForKey:kJSONKeyPasswordHash] forKey:kDefaultsKeyPasswordHash];
        
        if ([[_authInfo objectForKey:kJSONKeyIsListed] boolValue]) {
            [[OMeta m].user makeActive];
        } else {
            OOrigo *residence = [[OMeta m].context insertOrigoEntityOfType:kOrigoTypeResidence];
            [residence addMember:[OMeta m].user];
        }
        
        [ODefaults setGlobalDefault:nil forKey:kDefaultsKeyAuthInfo];
    }
    
    [self.dismisser dismissModalViewControllerWithIdentifier:self.viewControllerId];
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
            NSString *welcomeBackMessage = [NSString stringWithFormat:[OStrings stringForKey:strAlertTextWelcomeBack], [_authInfo objectForKey:kPropertyKeyEmail]];
            
            UIAlertView *welcomeBackAlert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleWelcomeBack] message:welcomeBackMessage delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonStartOver] otherButtonTitles:[OStrings stringForKey:strButtonHaveCode], nil];
            welcomeBackAlert.tag = kAlertTagWelcomeBack;
            [welcomeBackAlert show];
        } else if ([self targetIs:kTargetEmail]) {
            [self sendEmailActivationRequest];
        }
    }
}


#pragma mark - OTableViewController custom accessors

- (BOOL)modalImpliesRegistration
{
    return NO;
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialiseState
{
    if (self.data) {
        self.action = kActionActivate;
        self.target = kTargetEmail;
    } else {
        NSData *authInfoArchive = [ODefaults globalDefaultForKey:kDefaultsKeyAuthInfo];
        
        if (authInfoArchive) {
            _authInfo = [NSKeyedUnarchiver unarchiveObjectWithData:authInfoArchive];
            [OMeta m].userEmail = [_authInfo objectForKey:kPropertyKeyEmail];

            self.action = kActionActivate;
        } else {
            self.action = kActionSignIn;
        }
        
        self.target = kTargetUser;
    }
}


- (void)initialiseDataSource
{
    [self setData:kCustomCell forSectionWithKey:kAuthSection];
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if ([self actionIs:kActionSignIn]) {
        text = [OStrings stringForKey:strFooterSignInOrRegister];
    } else if ([self actionIs:kActionActivate]) {
        if ([self targetIs:kTargetUser]) {
            text = [NSString stringWithFormat:[OStrings stringForKey:strFooterActivate], [_emailField textValue]];
        } else if ([self targetIs:kTargetEmail]) {
            text = [NSString stringWithFormat:[OStrings stringForKey:strFooterActivateEmail], self.data];
        }
    }
    
    return text;
}


- (NSString *)reuseIdentifierForIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = nil;
    
    if ([self actionIs:kActionSignIn]) {
        reuseIdentifier = idCellReuseUserSignIn;
    } else if ([self actionIs:kActionActivate]) {
        reuseIdentifier = idCellReuseUserActivation;
    }
    
    return reuseIdentifier;
}


- (void)willDisplayCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self actionIs:kActionSignIn]) {
        _emailField = [cell textFieldForKey:kInputKeyAuthEmail];
        _passwordField = [cell textFieldForKey:kInputKeyPassword];
    } else if ([self actionIs:kActionActivate]) {
        _activationCodeField = [cell textFieldForKey:kInputKeyActivationCode];
        _repeatPasswordField = [cell textFieldForKey:kInputKeyRepeatPassword];
    }
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
        [self sendUserLoginRequest];
    } else if ([self actionIs:kActionActivate]) {
        if ([self targetIs:kTargetUser]) {
            [self sendUserActivationRequest];
        } else if ([self targetIs:kTargetEmail]) {
            [self.dismisser dismissModalViewControllerWithIdentifier:self.viewControllerId];
        }
    }
}


- (BOOL)willValidateInputForKey:(NSString *)key
{
    BOOL shouldValidate = NO;
    
    shouldValidate = shouldValidate || [key isEqualToString:kInputKeyActivationCode];
    shouldValidate = shouldValidate || [key isEqualToString:kInputKeyRepeatPassword];
    
    return shouldValidate;
}


- (BOOL)inputValue:(id)inputValue isValidForKey:(NSString *)key
{
    BOOL valueIsValid = NO;
    
    if ([key isEqualToString:kInputKeyActivationCode]) {
        NSString *activationCode = [_authInfo objectForKey:kInputKeyActivationCode];
        NSString *activationCodeAsEntered = [inputValue lowercaseString];
        
        valueIsValid = [activationCodeAsEntered isEqualToString:activationCode];
    } else if ([key isEqualToString:kInputKeyRepeatPassword]) {
        NSString *passwordHashAsEntered = [self computePasswordHash:inputValue];
        NSString *passwordHash = nil;
        
        if ([self targetIs:kTargetUser]) {
            passwordHash = [_authInfo objectForKey:kJSONKeyPasswordHash];
        } else if ([self targetIs:kTargetEmail]) {
            passwordHash = [ODefaults userDefaultForKey:kDefaultsKeyPasswordHash];
        }
        
        valueIsValid = [passwordHashAsEntered isEqualToString:passwordHash];
    }
    
    if (!valueIsValid) {
        _numberOfActivationAttempts++;
        
        if (_numberOfActivationAttempts == 3) {
            if ([self targetIs:kTargetUser]) {
                _numberOfActivationAttempts = 0;
                
                [OAlert showAlertWithTitle:[OStrings stringForKey:strAlertTitleActivationFailed] text:[OStrings stringForKey:strAlertTextActivationFailed] tag:kAlertTagActivationFailed];
                [self toggleAuthState];
            } else if ([self targetIs:kTargetEmail]) {
                [self.dismisser dismissModalViewControllerWithIdentifier:self.viewControllerId];
            }
        }
    }
    
    return valueIsValid;
}


#pragma mark - UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertTagWelcomeBack:
            if (buttonIndex == kAlertButtonWelcomeBackStartOver) {
                [self toggleAuthState];
                [_passwordField becomeFirstResponder];
            }
            
            break;
            
        case kAlertTagActivationFailed:
            [_passwordField becomeFirstResponder];
            
            break;
            
        default:
            break;
    }
}


#pragma mark - OServerConnectionDelegate conformance

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    [self indicatePendingServerSession:NO];
    
    if (response.statusCode < kHTTPStatusErrorRangeStart) {
        if (response.statusCode == kHTTPStatusCreated) {
            [self userDidSignUpWithData:data];
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
            [self.detailCell shakeCellVibrate:YES];
            [_passwordField becomeFirstResponder];
        }
    }
}

@end
