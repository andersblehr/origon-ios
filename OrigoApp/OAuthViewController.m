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

#import "OMember+OrigoExtensions.h"
#import "OMembership.h"
#import "OOrigo+OrigoExtensions.h"

static NSInteger const kAuthSection = 0;

static NSInteger const kActivationCodeLength = 6;

static NSInteger const kAlertButtonStartOver = 0;
static NSInteger const kAlertTagWelcomeBack = 0;


@implementation OAuthViewController

#pragma mark - Auxiliary methods

- (void)initialiseFields
{
    if ([self actionIs:kActionLogin]) {
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
    if ([self actionIs:kActionLogin]) {
        self.action = kActionActivate;
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
    } else if ([self actionIs:kActionActivate]) {
        self.action = kActionLogin;
        
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
        if ([self actionIs:kActionLogin]) {
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
        if ([self actionIs:kActionLogin]) {
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
        if ([self targetIs:kTargetUser]) {
            _numberOfActivationAttempts = 0;
            
            [OAlert showAlertWithTitle:[OStrings stringForKey:strAlertTitleActivationFailed] message:[OStrings stringForKey:strAlertTextActivationFailed]];
            [self toggleAuthState];
        } else if ([self targetIs:kTargetEmail]) {
            [self.dismisser dismissModalViewWithIdentitifier:kViewIdAuth];
        }
    }
}


- (BOOL)activationIsValid
{
    NSString *activationCode = [[_authInfo objectForKey:kInputKeyActivationCode] lowercaseString];
    NSString *activationCodeAsEntered = [_activationCodeField.text lowercaseString];
    
    BOOL activationCodeIsValid = [activationCodeAsEntered isEqualToString:activationCode];
    BOOL passwordIsValid = NO;
    
    if (activationCodeIsValid) {
        NSString *passwordHashAsEntered = [self computePasswordHash:_repeatPasswordField.text];
        NSString *passwordHash = nil;
        
        if ([self targetIs:kTargetUser]) {
            passwordHash = [_authInfo objectForKey:kJSONKeyPasswordHash];
        } else if ([self targetIs:kTargetEmail]) {
            passwordHash = [[OMeta m] userDefaultForKey:kDefaultsKeyPasswordHash];
        }
        
        passwordIsValid = [passwordHashAsEntered isEqualToString:passwordHash];
        
        if (passwordIsValid && [self targetIs:kTargetEmail]) {
            [OMeta m].user.email = self.data;
        } else if (!passwordIsValid) {
            [self handleInvalidInputForField:_repeatPasswordField];
        }
    } else {
        [self handleInvalidInputForField:_activationCodeField];
    }
    
    return (activationCodeIsValid && passwordIsValid);
}


#pragma mark - Initiating server requests

- (void)initiateUserLogin
{
    [OMeta m].userEmail = _emailField.text;
    
    OServerConnection *serverConnection = [[OServerConnection alloc] init];
    [serverConnection setAuthHeaderForEmail:_emailField.text password:_passwordField.text];
    [serverConnection authenticate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)initiateUserActivation
{
    OServerConnection *serverConnection = [[OServerConnection alloc] init];
    [serverConnection setAuthHeaderForEmail:[OMeta m].userEmail password:_repeatPasswordField.text];
    [serverConnection authenticate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)initiateEmailActivation
{
    NSString *emailActivationCode = [[OUUIDGenerator generateUUID] substringToIndex:kActivationCodeLength];
    
    OServerConnection *serverConnection = [[OServerConnection alloc] init];
    [serverConnection setAuthHeaderForEmail:self.data password:emailActivationCode];
    [serverConnection sendEmailActivationCode:self];
    
    [self indicatePendingServerSession:YES];
}


#pragma mark - Handling server responses

- (void)userDidSignUpWithData:(NSDictionary *)data
{
    _authInfo = data;
    
    if ([self targetIs:kTargetUser]) {
        [[OMeta m] setGlobalDefault:[NSKeyedArchiver archivedDataWithRootObject:_authInfo] forKey:kDefaultsKeyAuthInfo];
        
        [self toggleAuthState];
    }
}


- (void)userDidAuthenticateWithData:(NSArray *)data
{
    if (data) {
        [[OMeta m].context saveServerReplicas:data];
    }
    
    [[OMeta m] userDidSignIn];
    
    if ([self actionIs:kActionLogin]) {
        if (![OMeta m].userIsRegistered) {
            [[OMeta m] setUserDefault:@YES forKey:kDefaultsKeyRegistrationAborted];
        }
    } else if ([self actionIs:kActionActivate]) {
        [[OMeta m] setUserDefault:[_authInfo objectForKey:kJSONKeyPasswordHash] forKey:kDefaultsKeyPasswordHash];
        
        if ([[_authInfo objectForKey:kJSONKeyIsListed] boolValue]) {
            [[OMeta m].user makeActive];
        } else {
            OOrigo *residence = [[OMeta m].context insertOrigoEntityOfType:kOrigoTypeResidence];
            [residence addMember:[OMeta m].user];
        }
        
        [[OMeta m] setGlobalDefault:nil forKey:kDefaultsKeyAuthInfo];
    }
    
    [self.dismisser dismissModalViewWithIdentitifier:kViewIdAuth];
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

    if ([self actionIs:kActionActivate]) {
        if ([self targetIs:kTargetUser]) {
            NSString *welcomeBackMessage = [NSString stringWithFormat:[OStrings stringForKey:strAlertTextWelcomeBack], [_authInfo objectForKey:kPropertyKeyEmail]];
            
            UIAlertView *welcomeBackAlert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleWelcomeBack] message:welcomeBackMessage delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonStartOver] otherButtonTitles:[OStrings stringForKey:strButtonHaveCode], nil];
            welcomeBackAlert.tag = kAlertTagWelcomeBack;
            [welcomeBackAlert show];
        } else if ([self targetIs:kTargetEmail]) {
            [self initiateEmailActivation];
        }
    }
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
        self.action = kActionActivate;
        self.target = kTargetEmail;
    } else {
        NSData *authInfoArchive = [[OMeta m] globalDefaultForKey:kDefaultsKeyAuthInfo];
        
        if (authInfoArchive) {
            _authInfo = [NSKeyedUnarchiver unarchiveObjectWithData:authInfoArchive];
            [OMeta m].userEmail = [_authInfo objectForKey:kPropertyKeyEmail];

            self.action = kActionActivate;
        } else {
            self.action = kActionLogin;
        }
        
        self.target = kTargetUser;
    }
}


- (void)populateDataSource
{
    [self setData:kEmptyDetailCellPlaceholder forSectionWithKey:kAuthSection];
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if ([self actionIs:kActionLogin]) {
        text = [OStrings stringForKey:strFooterSignInOrRegister];
    } else if ([self actionIs:kActionActivate]) {
        if ([self targetIs:kTargetUser]) {
            text = [NSString stringWithFormat:[OStrings stringForKey:strFooterActivate], [_emailField finalText]];
        } else if ([self targetIs:kTargetEmail]) {
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
    if ([self actionIs:kActionLogin]) {
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
    
    if ([self actionIs:kActionLogin]) {
        _emailField.hasEmphasis = YES;
        _passwordField.hasEmphasis = YES;
    } else if ([self actionIs:kActionActivate]) {
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
            [self initiateUserLogin];
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
            
            if ([self targetIs:kTargetUser]) {
                [self initiateUserActivation];
            } else if ([self targetIs:kTargetEmail]) {
                [self.dismisser dismissModalViewWithIdentitifier:kViewIdAuth];
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
            [self.detailCell shakeCellShouldVibrate:YES];
            [_passwordField becomeFirstResponder];
        }
    }
}

@end
