//
//  OAuthViewController.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OAuthViewController.h"

static CGFloat const kStatusBarHeight = 20.f;
static CGFloat const kScreenHeightSmall = 460.f;
static CGFloat const kLogoRadius = 60.f;
static CGFloat const kLogoRadiusSmall = 25.f;
static CGFloat const kLogoCornerRadius = 12.f;
static CGFloat const kLogoAlpha = 0.7f;

static NSInteger const kAuthActionNone = 0;
static NSInteger const kAuthActionRegister = 1;
static NSInteger const kAuthActionLogin = 2;

static NSInteger const kSectionKeyAuth = 0;

static NSInteger const kMaxAttempts = 2;

static NSInteger const kActionSheetTagAuthAction = 0;
static NSInteger const kButtonTagAuthActionRegister = 0;
static NSInteger const kButtonTagAuthActionLogin = 1;

static NSInteger const kAlertTagWelcomeBack = 0;
static NSInteger const kAlertTagActivationFailed = 1;
static NSInteger const kAlertTagForgottenPassword = 2;

static NSInteger const kAlertButtonWelcomeBackStartOver = 0;


@interface OAuthViewController () <OTableViewController, OInputCellDelegate, OConnectionDelegate, UIActionSheetDelegate, UIAlertViewDelegate> {
@private
    OTableViewCell *_inputCell;
    
    OInputField *_emailField;
    OInputField *_passwordField;
    OInputField *_activationCodeField;
    OInputField *_repeatPasswordField;
    
    OInputField *_oldPasswordField;
    OInputField *_newPasswordField;
    OInputField *_repeatNewPasswordField;
    
    NSInteger _authAction;
    NSInteger _numberOfFailedAttempts;
    NSDictionary *_authInfo;
}

@end


@implementation OAuthViewController

#pragma mark - Auxiliary methods

- (void)addLogoBanner
{
    BOOL isSmallScreen = [OMeta screenSize].height == kScreenHeightSmall;
    NSString *logoFile = isSmallScreen ? kIconFileLogoSmall : kIconFileLogo;
    CGFloat logoRadius = isSmallScreen ? kLogoRadiusSmall : kLogoRadius;
    CGFloat logoCornerRadius = isSmallScreen ? kLogoCornerRadius / 2.f : kLogoCornerRadius;
    
    UIImageView *logoBanner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:logoFile]];
    logoBanner.center = CGPointMake([OMeta screenSize].width / 2.f, logoRadius + kStatusBarHeight);
    logoBanner.layer.masksToBounds = YES;
    logoBanner.layer.cornerRadius = logoCornerRadius;
    logoBanner.alpha = kLogoAlpha;
    
    self.tableView.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, [OMeta screenSize].width, [OMeta screenSize].height)];
    self.tableView.backgroundView.backgroundColor = [UIColor tableViewBackgroundColour];
    [self.tableView.backgroundView addSubview:logoBanner];
    [self.tableView setTopContentInset:2.f * logoRadius];
}


- (void)initialiseFields
{
    if ([self actionIs:kActionLogin]) {
        _passwordField.value = @"";
        
        if ([OMeta m].userEmail) {
            _emailField.value = [OMeta m].userEmail;
            [_passwordField becomeFirstResponder];
        } else {
            _emailField.value = @"";
            [_emailField becomeFirstResponder];
        }
    } else if ([self actionIs:kActionActivate]) {
        _activationCodeField.value = @"";
        _repeatPasswordField.value = @"";
        
        [_activationCodeField becomeFirstResponder];
    } else if ([self actionIs:kActionChange]) {
        [_oldPasswordField becomeFirstResponder];
    }
}


- (void)enableOrDisableButtons
{
    if ([self actionIs:kActionLogin]) {
        [_inputCell buttonForKey:kActionKeyRegister].enabled = self.isOnline;
        [_inputCell buttonForKey:kActionKeyLogin].enabled = self.isOnline;
    } else if ([self actionIs:kActionActivate]) {
        [_inputCell buttonForKey:kActionKeyCancel].enabled = self.isOnline;
        [_inputCell buttonForKey:kActionKeyActivate].enabled = self.isOnline;
    } else if ([self actionIs:kActionChange]) {
        [_inputCell buttonForKey:kActionKeyCancel].enabled = self.isOnline;
        [_inputCell buttonForKey:kActionKeyChangePassword].enabled = self.isOnline;
    }
}


- (void)performAuthAction:(NSInteger)authAction
{
    _authAction = authAction;
    
    [OMeta m].userEmail = _emailField.value;
    
    if (_authAction == kAuthActionRegister) {
        [[OConnection connectionWithDelegate:self] registerWithEmail:[OMeta m].userEmail password:_passwordField.value];
    } else if (_authAction == kAuthActionLogin) {
        [[OConnection connectionWithDelegate:self] loginWithEmail:[OMeta m].userEmail password:_passwordField.value];
    }
}


- (void)toggleAuthState
{
    [self.state toggleAction:@[kActionLogin, kActionActivate]];
    
    if ([self actionIs:kActionActivate]) {
        [self reloadSectionWithKey:kSectionKeyAuth rowAnimation:UITableViewRowAnimationLeft];
    } else if ([self actionIs:kActionLogin]) {
        [self reloadSectionWithKey:kSectionKeyAuth rowAnimation:UITableViewRowAnimationRight];
        
        if (_authInfo) {
            [ODefaults removeGlobalDefaultForKey:kDefaultsKeyAuthInfo];
        }
    }
    
    [self initialiseFields];
    
    _numberOfFailedAttempts = 0;
    
    OLogState;
}


- (void)handleFailedActivationAttempt
{
    _numberOfFailedAttempts++;
    
    if (_numberOfFailedAttempts == kMaxAttempts) {
        _numberOfFailedAttempts = 0;
        
        if ([self targetIs:kTargetUser]) {
            [OAlert showAlertWithTitle:NSLocalizedString(@"Activation failed", @"") message:NSLocalizedString(@"It looks like you may have lost the activation code ...", @"") delegate:self tag:kAlertTagActivationFailed];
        } else if ([self targetIs:kTargetEmail]) {
            [self.dismisser dismissModalViewController:self];
        }
    }
}


#pragma mark - Handling server responses

- (void)didReceiveAuthInfo:(NSDictionary *)authInfo
{
    _authInfo = authInfo;
    
    if ([self targetIs:kTargetUser]) {
        [ODefaults setGlobalDefault:[NSKeyedArchiver archivedDataWithRootObject:_authInfo] forKey:kDefaultsKeyAuthInfo];
        
        [self toggleAuthState];
    }
}


- (void)userDidAuthenticateWithData:(NSArray *)data
{
    [[OMeta m] userDidLogin];
    
    if (data) {
        [[OMeta m].context saveEntityDictionaries:data];
    }
    
    ODevice *device = [ODevice device];
    
    if ([device hasExpired]) {
        [device unexpire];
    }
    
    if ([self actionIs:kActionLogin]) {
        [OMeta m].user.passwordHash = [OCrypto passwordHashWithPassword:_passwordField.value];
    } else if ([self actionIs:kActionActivate]) {
        [OMeta m].user.passwordHash = _authInfo[kPropertyKeyPasswordHash];
        
        [[OMeta m] userDidRegister];
        [[OMeta m].user primaryResidence];
        
        [ODefaults removeGlobalDefaultForKey:kDefaultsKeyAuthInfo];
    }
    
    [self.dismisser dismissModalViewController:self];
}


#pragma mark - Selector implementations

- (void)performRegisterAction
{
    _authAction = kAuthActionRegister;
    
    [self.inputCell processInputShouldValidate:YES];
}


- (void)performLoginAction
{
    _authAction = kAuthActionLogin;
    
    [self.inputCell processInputShouldValidate:YES];
}


- (void)performActivateAction
{
    [self.inputCell processInputShouldValidate:YES];
}


- (void)performChangePasswordAction
{
    [self.inputCell processInputShouldValidate:YES];
}


- (void)performCancelAction
{
    self.didCancel = YES;
    
    if ([self actionIs:kActionActivate]) {
        if ([self targetIs:kTargetEmail]) {
            [self.dismisser dismissModalViewController:self];
        } else {
            [self toggleAuthState];
        }
    } else if ([self actionIs:kActionChange]) {
        [self.dismisser dismissModalViewController:self];
    }
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self addLogoBanner];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self initialiseFields];

    if ([self actionIs:kActionActivate]) {
        if ([self targetIs:kTargetUser]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Welcome back!", @"") message:[NSString stringWithFormat:NSLocalizedString(@"If you have the activation code sent to %@ ...", @""), _authInfo[kPropertyKeyEmail]] delegate:self cancelButtonTitle:NSLocalizedString(@"Go back", @"") otherButtonTitles:NSLocalizedString(@"Have code", @""), nil];
            alert.tag = kAlertTagWelcomeBack;
            
            [alert show];
        } else if ([self targetIs:kTargetEmail]) {
            [[OConnection connectionWithDelegate:self] sendActivationCodeToEmail:self.target];
        }
    }
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    if ([OValidator isEmailValue:self.target]) {
        self.state.target = kTargetEmail;
        self.state.action = kActionActivate;
    } else if ([self targetIs:kTargetPassword]) {
        self.state.action = kActionChange;
    } else {
        NSData *authInfoArchive = [ODefaults globalDefaultForKey:kDefaultsKeyAuthInfo];
        
        if (authInfoArchive) {
            _authInfo = [NSKeyedUnarchiver unarchiveObjectWithData:authInfoArchive];
            
            [OMeta m].userEmail = _authInfo[kPropertyKeyEmail];
            [OMeta m].deviceId = _authInfo[kInternalKeyDeviceId];

            self.state.action = kActionActivate;
        } else {
            self.state.action = kActionLogin;
        }
        
        _numberOfFailedAttempts = 0;
    }
    
    if (![self actionIs:kActionActivate] || ![self targetIs:kTargetEmail]) {
        self.requiresSynchronousServerCalls = YES;
    }
}


- (void)loadData
{
    [self setDataForInputSection];
}


- (NSString *)reuseIdentifierForInputSection
{
    NSString *reuseIdentifier = nil;
    
    if ([self actionIs:kActionLogin]) {
        reuseIdentifier = kReuseIdentifierUserLogin;
    } else if ([self actionIs:kActionActivate]) {
        reuseIdentifier = kReuseIdentifierUserActivation;
    } else if ([self actionIs:kActionChange] && [self targetIs:kTargetPassword]) {
        reuseIdentifier = kReuseIdentifierPasswordChange;
    }
    
    return reuseIdentifier;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return YES;
}


- (NSString *)footerContentForSectionWithKey:(NSInteger)sectionKey
{
    NSString *footerContent = nil;
    
    if (self.isOnline) {
        if ([self actionIs:kActionLogin]) {
            footerContent = NSLocalizedString(@"When you register, you will receive an email with an activation code to use in the next step.", @"");
        } else if ([self actionIs:kActionActivate]) {
            if ([self targetIs:kTargetUser]) {
                footerContent = [NSString stringWithFormat:NSLocalizedString(@"Your activation code has been sent to %@ ...", @""), _emailField.value];
            } else if ([self targetIs:kTargetEmail]) {
                footerContent = [NSString stringWithFormat:NSLocalizedString(@"Your activation code has been sent to %@.", @""), self.target];
            }
        }
    } else {
        footerContent = NSLocalizedString(@"You need a working internet connection to continue.", @"");
    }
    
    return footerContent;
}


- (void)willDisplayInputCell:(OTableViewCell *)inputCell
{
    _inputCell = inputCell;
    
    if ([self actionIs:kActionLogin]) {
        _emailField = [inputCell inputFieldForKey:kInputKeyAuthEmail];
        _passwordField = [inputCell inputFieldForKey:kInputKeyPassword];
        
        ((UITextField *)_emailField).clearButtonMode = UITextFieldViewModeAlways;
    } else if ([self actionIs:kActionActivate]) {
        _activationCodeField = [inputCell inputFieldForKey:kInputKeyActivationCode];
        _repeatPasswordField = [inputCell inputFieldForKey:kInputKeyRepeatPassword];
    } else if ([self actionIs:kActionChange]) {
        _oldPasswordField = [inputCell inputFieldForKey:kInputKeyOldPassword];
        _newPasswordField = [inputCell inputFieldForKey:kInputKeyNewPassword];
        _repeatNewPasswordField = [inputCell inputFieldForKey:kInputKeyRepeatNewPassword];
    }
    
    [self enableOrDisableButtons];
}


- (void)onlineStatusDidChange
{
    [self enableOrDisableButtons];
    [self reloadFooterForSectionWtihKey:kSectionKeyAuth];
}


#pragma mark - OInputCellDelegate conformance

- (OInputCellBlueprint *)inputCellBlueprint
{
    OInputCellBlueprint *blueprint = [[OInputCellBlueprint alloc] init];
    blueprint.fieldsAreLabeled = NO;
    blueprint.fieldsShouldDeemphasiseOnEndEdit = NO;
    
    if ([self actionIs:kActionLogin]) {
        blueprint.titleKey = kLabelKeyRegisterOrLogIn;
        blueprint.detailKeys = @[kInputKeyAuthEmail, kInputKeyPassword];
        blueprint.buttonKeys = @[kActionKeyRegister, kActionKeyLogin];
    } else if ([self actionIs:kActionActivate]) {
        blueprint.titleKey = kLabelKeyActivate;
        blueprint.detailKeys = @[kInputKeyActivationCode, kInputKeyRepeatPassword];
        blueprint.buttonKeys = @[kActionKeyCancel, kActionKeyActivate];
    } else if ([self actionIs:kActionChange]) {
        blueprint.titleKey = kActionKeyChangePassword;
        blueprint.detailKeys = @[kInputKeyOldPassword, kInputKeyNewPassword, kInputKeyRepeatNewPassword];
        blueprint.buttonKeys = @[kActionKeyCancel, kActionKeyChangePassword];
    }
    
    return blueprint;
}


- (BOOL)isReceivingInput
{
    return YES;
}


- (BOOL)inputIsValid
{
    BOOL inputIsValid = NO;
    
    if ([self actionIs:kActionLogin]) {
        inputIsValid = [_emailField hasValidValue] && [_passwordField hasValidValue];
    } else if ([self actionIs:kActionActivate]) {
        inputIsValid = [_activationCodeField hasValidValue] && [_repeatPasswordField hasValidValue];
    } else if ([self actionIs:kActionChange]) {
        inputIsValid = [_oldPasswordField hasValidValue] && [_newPasswordField hasValidValue] && [_repeatNewPasswordField hasValidValue];
    }
    
    if (!inputIsValid) {
        if ([self actionIs:kActionActivate]) {
            [self handleFailedActivationAttempt];
        } else if ([self actionIs:kActionChange]) {
            [self.inputCell clearInputFields];
            [_oldPasswordField becomeFirstResponder];
        }
        
        if (_authAction) {
            _authAction = kAuthActionNone;
        }
    }
    
    return inputIsValid;
}


- (void)processInput
{
    if ([self actionIs:kActionLogin]) {
        if (!_authAction && [_emailField.value isEqualToString:[OMeta m].userEmail]) {
            _authAction = kAuthActionLogin;
        }
        
        if (_authAction) {
            [self performAuthAction:_authAction];
        } else {
            OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagAuthAction];
            [actionSheet addButtonWithTitle:NSLocalizedString(kActionKeyRegister, kStringPrefixTitle) tag:kButtonTagAuthActionRegister];
            [actionSheet addButtonWithTitle:NSLocalizedString(kActionKeyLogin, kStringPrefixTitle) tag:kButtonTagAuthActionLogin];
            
            [actionSheet show];
        }
    } else if ([self actionIs:kActionActivate]) {
        if ([self targetIs:kTargetUser]) {
            [[OConnection connectionWithDelegate:self] activateWithEmail:[OMeta m].userEmail password:_repeatPasswordField.value];
        } else if ([self targetIs:kTargetEmail]) {
            [OMeta m].userEmail = self.target;
            [self.dismisser dismissModalViewController:self];
        }
    } else if ([self actionIs:kActionChange]) {
        [OMeta m].user.passwordHash = [OCrypto passwordHashWithPassword:_newPasswordField.value];
        [[OConnection connectionWithDelegate:self] changePasswordWithEmail:[OMeta m].userEmail password:_newPasswordField.value];
    }
}


- (BOOL)willValidateInputForKey:(NSString *)key
{
    return [@[kInputKeyActivationCode, kInputKeyRepeatPassword, kInputKeyOldPassword, kInputKeyNewPassword, kInputKeyRepeatNewPassword] containsObject:key];
}


- (BOOL)inputValue:(id)inputValue isValidForKey:(NSString *)key
{
    BOOL isValid = NO;
    
    if ([key isEqualToString:kInputKeyActivationCode]) {
        NSString *activationCode = _authInfo[kInputKeyActivationCode];
        NSString *activationCodeAsEntered = [inputValue lowercaseString];
        
        isValid = [activationCodeAsEntered isEqualToString:activationCode];
    } else if ([key isEqualToString:kInputKeyRepeatPassword]) {
        NSString *passwordHashAsEntered = [OCrypto passwordHashWithPassword:inputValue];
        NSString *passwordHash = nil;
        
        if ([self targetIs:kTargetUser]) {
            passwordHash = _authInfo[kPropertyKeyPasswordHash];
        } else if ([self targetIs:kTargetEmail]) {
            passwordHash = [OMeta m].user.passwordHash;
        }
        
        isValid = [passwordHashAsEntered isEqualToString:passwordHash];
    } else if ([key isEqualToString:kInputKeyOldPassword]) {
        NSString *oldPasswordHashAsEntered = [OCrypto passwordHashWithPassword:inputValue];
        NSString *oldPasswordHash = [OMeta m].user.passwordHash;
        
        isValid = [oldPasswordHashAsEntered isEqualToString:oldPasswordHash];
    } else if ([key isEqualToString:kInputKeyNewPassword]) {
        if ([OValidator value:inputValue isValidForKey:key]) {
            NSString *newPasswordHash = [OCrypto passwordHashWithPassword:inputValue];
            NSString *oldPasswordHash = [OMeta m].user.passwordHash;
            
            isValid = ![newPasswordHash isEqualToString:oldPasswordHash];
        }
    } else if ([key isEqualToString:kInputKeyRepeatNewPassword]) {
        isValid = [inputValue isEqualToString:_newPasswordField.value];
    }
    
    return isValid;
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case kActionSheetTagAuthAction:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
                
                if (buttonTag == kButtonTagAuthActionRegister) {
                    [self performAuthAction:kAuthActionRegister];
                } else if (buttonTag == kButtonTagAuthActionLogin) {
                    [self performAuthAction:kAuthActionLogin];
                }
            }
            
            break;
            
        default:
            break;
    }
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
            
        case kAlertTagForgottenPassword:
            if (buttonIndex == alertView.cancelButtonIndex) {
                [_passwordField becomeFirstResponder];
            } else {
                [[OConnection connectionWithDelegate:self] resetPasswordWithEmail:[OMeta m].userEmail password:[OCrypto generateActivationCode]];
            }

            break;
            
        default:
            break;
    }
}


#pragma mark - OconnectionDelegate conformance

- (void)connection:(OConnection *)connection didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    [super connection:connection didCompleteWithResponse:response data:data];
    
    if (response.statusCode < kHTTPStatusErrorRangeStart) {
        if (response.statusCode == kHTTPStatusCreated) {
            if ([self actionIs:kActionLogin]) {
                if (_authAction == kAuthActionRegister) {
                    [self didReceiveAuthInfo:data];
                } else if (_authAction == kAuthActionLogin) {
                    [OAlert showAlertWithTitle:NSLocalizedString(@"New password", @"") message:[NSString stringWithFormat:NSLocalizedString(@"Your password has been reset and a new password has been generated and sent to %@.", @""), _emailField.value]];
                    
                    [_passwordField becomeFirstResponder];
                }
            } else if ([self actionIs:kActionChange]) {
                [OAlert showAlertWithTitle:@"" message:NSLocalizedString(@"Your password has been changed.", @"")];
                
                [self.dismisser dismissModalViewController:self];
            } else if ([self actionIs:kActionActivate] && [self targetIs:kTargetEmail]) {
                [self didReceiveAuthInfo:data];
            }
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
        [self.inputCell shakeCellVibrate:YES];
        
        if ([self actionIs:kActionLogin]) {
            _numberOfFailedAttempts++;
            
            if (_numberOfFailedAttempts == kMaxAttempts) {
                _numberOfFailedAttempts = 0;
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:NSLocalizedString(@"Did you forget the password?", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"No", @"") otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
                alert.tag = kAlertTagForgottenPassword;
                
                [alert show];
            } else {
                [_passwordField becomeFirstResponder];
            }
        } else {
            [_passwordField becomeFirstResponder];
        }
    }
}

@end
