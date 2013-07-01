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
#import "OCrypto.h"

#import "OMember+OrigoExtensions.h"
#import "OMembership.h"
#import "OOrigo+OrigoExtensions.h"

static NSInteger const kSectionKeyAuth = 0;

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


- (void)indicatePendingRequest:(BOOL)isPending
{
    if ([self actionIs:kActionSignIn]) {
        [_emailField indicatePendingEvent:isPending];
        [_passwordField indicatePendingEvent:isPending];
    } else if ([self actionIs:kActionActivate]) {
        [_activationCodeField indicatePendingEvent:isPending];
        [_repeatPasswordField indicatePendingEvent:isPending];
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
    
    if (numberOfFailedAttempts == 3) {
        numberOfFailedAttempts = 0;
        
        if ([self targetIs:kTargetUser]) {
            [OAlert showAlertWithTitle:[OStrings stringForKey:strAlertTitleActivationFailed] text:[OStrings stringForKey:strAlertTextActivationFailed] tag:kAlertTagActivationFailed];
        } else if ([self targetIs:kTargetEmail]) {
            [self.dismisser dismissModalViewControllerWithIdentifier:self.viewControllerId];
        }
    }
}


#pragma mark - Initiating server requests

- (void)sendUserSignInRequest
{
    [OMeta m].userEmail = [_emailField textValue];
    
    OConnection *connection = [[OConnection alloc] init];
    [connection authenticateWithEmail:[OMeta m].userEmail password:_passwordField.text];
}


- (void)sendUserActivationRequest
{
    OConnection *connection = [[OConnection alloc] init];
    [connection authenticateWithEmail:[OMeta m].userEmail password:_repeatPasswordField.text];
}


- (void)sendEmailActivationRequest
{
    NSString *activationCode = [[OCrypto generateUUID] substringToIndex:kActivationCodeLength];
    
    OConnection *connection = [[OConnection alloc] init];
    [connection sendActivationCode:activationCode toEmailAddress:self.data];
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
        [ODefaults setUserDefault:_authInfo[kJSONKeyPasswordHash] forKey:kDefaultsKeyPasswordHash];
        
        if ([_authInfo[kJSONKeyIsListed] boolValue]) {
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
            NSString *welcomeBackMessage = [NSString stringWithFormat:[OStrings stringForKey:strAlertTextWelcomeBack], _authInfo[kPropertyKeyEmail]];
            
            UIAlertView *welcomeBackAlert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleWelcomeBack] message:welcomeBackMessage delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonStartOver] otherButtonTitles:[OStrings stringForKey:strButtonHaveCode], nil];
            welcomeBackAlert.tag = kAlertTagWelcomeBack;
            [welcomeBackAlert show];
        } else if ([self targetIs:kTargetEmail]) {
            [self sendEmailActivationRequest];
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


- (void)initialiseDataSource
{
    [self setData:kCustomCell forSectionWithKey:kSectionKeyAuth];
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
        reuseIdentifier = kReuseIdentifierUserSignIn;
    } else if ([self actionIs:kActionActivate]) {
        reuseIdentifier = kReuseIdentifierUserActivation;
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
        [self sendUserSignInRequest];
    } else if ([self actionIs:kActionActivate]) {
        if ([self targetIs:kTargetUser]) {
            [self sendUserActivationRequest];
        } else if ([self targetIs:kTargetEmail]) {
            [OMeta m].userEmail = self.data;
            [self.dismisser dismissModalViewControllerWithIdentifier:self.viewControllerId];
        }
    }
}


- (BOOL)willValidateInputForKey:(NSString *)key
{
    BOOL willValidate = NO;
    
    willValidate = willValidate || [key isEqualToString:kInputKeyActivationCode];
    willValidate = willValidate || [key isEqualToString:kInputKeyRepeatPassword];
    
    return willValidate;
}


- (BOOL)inputValue:(id)inputValue isValidForKey:(NSString *)key
{
    BOOL valueIsValid = NO;
    
    if ([key isEqualToString:kInputKeyActivationCode]) {
        NSString *activationCode = _authInfo[kJSONKeyActivationCode];
        NSString *activationCodeAsEntered = [inputValue lowercaseString];
        
        valueIsValid = [activationCodeAsEntered isEqualToString:activationCode];
    } else if ([key isEqualToString:kInputKeyRepeatPassword]) {
        NSString *passwordHashAsEntered = [OCrypto passwordHashWithPassword:inputValue];
        NSString *passwordHash = nil;
        
        if ([self targetIs:kTargetUser]) {
            passwordHash = _authInfo[kJSONKeyPasswordHash];
        } else if ([self targetIs:kTargetEmail]) {
            passwordHash = [ODefaults userDefaultForKey:kDefaultsKeyPasswordHash];
        }
        
        valueIsValid = [passwordHashAsEntered isEqualToString:passwordHash];
    }
    
    if (!valueIsValid) {
        [self handleFailedActivationAttempt];
    }
    
    return valueIsValid;
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

- (void)willSendRequest:(NSURLRequest *)request
{
    if (![self actionIs:kActionActivate] || ![self targetIs:kTargetEmail]) {
        [self indicatePendingRequest:YES];
    }
}


- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    [self indicatePendingRequest:NO];
    
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
    } else {
        if (response.statusCode == kHTTPStatusUnauthorized) {
            [self.detailCell shakeCellVibrate:YES];
            [_passwordField becomeFirstResponder];
        }
    }
}


- (void)didFailWithError:(NSError *)error
{
    [self indicatePendingRequest:NO];
}

@end
