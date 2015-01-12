//
//  OAuthViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OAuthViewController.h"

static CGFloat const kLogoHeight = 40.f;
static CGFloat const kLogoFontSize = 26.f;

static NSString * const kLogoFontName = @"CourierNewPS-BoldMT";
static NSString * const kLogoText = @"..origo..";

static NSInteger const kSignInActionNone = 0;
static NSInteger const kSignInActionSignUp = 1;
static NSInteger const kSignInActionSignIn = 2;

static NSInteger const kSectionKeyAuth = 0;

static NSInteger const kMaxActivationAttempts = 3;

static NSInteger const kActionSheetTagSignInAction = 0;
static NSInteger const kButtonTagSignInActionSignUp = 0;
static NSInteger const kButtonTagSignInActionSignIn = 1;

static NSInteger const kAlertTagWelcomeBack = 0;
static NSInteger const kAlertTagActivationFailed = 1;

static NSInteger const kAlertButtonWelcomeBackStartOver = 0;


@interface OAuthViewController () <OTableViewController, OInputCellDelegate, OConnectionDelegate, UIActionSheetDelegate, UIAlertViewDelegate> {
@private
    OInputField *_emailField;
    OInputField *_passwordField;
    
    OInputField *_activationCodeField;
    OInputField *_repeatPasswordField;
    
    OInputField *_oldPasswordField;
    OInputField *_newPasswordField;
    OInputField *_repeatNewPasswordField;
    
    NSInteger _signInAction;
    NSDictionary *_authInfo;
}

@end


@implementation OAuthViewController

#pragma mark - Auxiliary methods

- (void)addLogoBanner
{
    CGFloat screenWidth = [OMeta screenWidth];
    CGRect logoFrame = CGRectMake(0.f, kLogoHeight, screenWidth, kLogoHeight);
    UILabel *logoBanner = [[UILabel alloc] initWithFrame:logoFrame];
    logoBanner.backgroundColor = [UIColor toolbarColour];
    logoBanner.font = [UIFont fontWithName:kLogoFontName size:kLogoFontSize];
    logoBanner.text = kLogoText;
    logoBanner.textAlignment = NSTextAlignmentCenter;
    logoBanner.textColor = [UIColor globalTintColour];
    
    UIView *topHairline = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, screenWidth, 0.5f)];
    topHairline.backgroundColor = [UIColor toolbarHairlineColour];
    [logoBanner addSubview:topHairline];
    
    UIView *bottomHairline = [[UIView alloc] initWithFrame:CGRectMake(0.f, kLogoHeight, screenWidth, 0.5f)];
    bottomHairline.backgroundColor = [UIColor toolbarHairlineColour];
    [logoBanner addSubview:bottomHairline];
    
    [self.view addSubview:logoBanner];
    [self.tableView setTopContentInset:2.f * kLogoHeight];
}


- (void)initialiseFields
{
    if ([self actionIs:kActionSignIn]) {
        _passwordField.value = [NSString string];
        
        if ([OMeta m].userEmail) {
            _emailField.value = [OMeta m].userEmail;
            [_passwordField becomeFirstResponder];
        } else {
            _emailField.value = [NSString string];
            [_emailField becomeFirstResponder];
        }
    } else if ([self actionIs:kActionActivate]) {
        _activationCodeField.value = [NSString string];
        _repeatPasswordField.value = [NSString string];
        
        [_activationCodeField becomeFirstResponder];
    } else if ([self actionIs:kActionChange]) {
        [_oldPasswordField becomeFirstResponder];
    }
}


- (void)toggleAuthState
{
    [self.state toggleAction:@[kActionSignIn, kActionActivate]];
    
    if ([self actionIs:kActionActivate]) {
        [self reloadSectionWithKey:kSectionKeyAuth rowAnimation:UITableViewRowAnimationLeft];
    } else if ([self actionIs:kActionSignIn]) {
        [self reloadSectionWithKey:kSectionKeyAuth rowAnimation:UITableViewRowAnimationRight];
        
        if (_authInfo) {
            [ODefaults removeGlobalDefaultForKey:kDefaultsKeyAuthInfo];
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
            [OAlert showAlertWithTitle:NSLocalizedString(@"Activation failed", @"") text:NSLocalizedString(@"It looks like you may have lost the activation code ...", @"") delegate:self tag:kAlertTagActivationFailed];
        } else if ([self targetIs:kTargetEmail]) {
            [self.dismisser dismissModalViewController:self];
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
    [[OMeta m] userDidSignIn];
    
    if (data) {
        [[OMeta m].context saveEntityDictionaries:data];
    }
    
    if ([self actionIs:kActionSignIn]) {
        [OMeta m].user.passwordHash = [OCrypto passwordHashWithPassword:_passwordField.value];
    } else if ([self actionIs:kActionActivate]) {
        [OMeta m].user.passwordHash = _authInfo[kPropertyKeyPasswordHash];
        
        [[OMeta m] userDidSignUp];
        [[OMeta m].user primaryResidence];
        
        [ODefaults removeGlobalDefaultForKey:kDefaultsKeyAuthInfo];
    }
    
    [self.dismisser dismissModalViewController:self];
}


#pragma mark - Selector implementations

- (void)performSignUpAction
{
    _signInAction = kSignInActionSignUp;
    
    [self.inputCell processInputShouldValidate:YES];
}


- (void)performSignInAction
{
    _signInAction = kSignInActionSignIn;
    
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
            UIAlertView *welcomeBackAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Welcome back!", @"") message:[NSString stringWithFormat:NSLocalizedString(@"If you have handy the activation code sent to %@ ...", @""), _authInfo[kPropertyKeyEmail]] delegate:self cancelButtonTitle:NSLocalizedString(@"Start over", @"") otherButtonTitles:NSLocalizedString(@"Have code", @""), nil];
            welcomeBackAlert.tag = kAlertTagWelcomeBack;
            [welcomeBackAlert show];
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
            [OMeta m].deviceId = _authInfo[kExternalKeyDeviceId];

            self.state.action = kActionActivate;
        } else {
            self.state.action = kActionSignIn;
        }
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
    
    if ([self actionIs:kActionSignIn]) {
        reuseIdentifier = kReuseIdentifierUserSignIn;
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
    NSString *text = nil;
    
    if ([self actionIs:kActionSignIn]) {
        text = NSLocalizedString(@"If you are signing up, you will receive an email ...", @"");
    } else if ([self actionIs:kActionActivate]) {
        if ([self targetIs:kTargetUser]) {
            text = [NSString stringWithFormat:NSLocalizedString(@"The activation code has been sent to %@ ...", @""), _emailField.value];
        } else if ([self targetIs:kTargetEmail]) {
            text = [NSString stringWithFormat:NSLocalizedString(@"The activation code has been sent to %@.", @""), self.target];
        }
    }
    
    return text;
}


- (void)willDisplayInputCell:(OTableViewCell *)inputCell
{
    if ([self actionIs:kActionSignIn]) {
        _emailField = [inputCell inputFieldForKey:kExternalKeyAuthEmail];
        _passwordField = [inputCell inputFieldForKey:kExternalKeyPassword];
    } else if ([self actionIs:kActionActivate]) {
        _activationCodeField = [inputCell inputFieldForKey:kExternalKeyActivationCode];
        _repeatPasswordField = [inputCell inputFieldForKey:kExternalKeyRepeatPassword];
    } else if ([self actionIs:kActionChange]) {
        _oldPasswordField = [inputCell inputFieldForKey:kExternalKeyOldPassword];
        _newPasswordField = [inputCell inputFieldForKey:kExternalKeyNewPassword];
        _repeatNewPasswordField = [inputCell inputFieldForKey:kExternalKeyRepeatNewPassword];
    }
}


#pragma mark - OInputCellDelegate conformance

- (OInputCellBlueprint *)inputCellBlueprint
{
    OInputCellBlueprint *blueprint = [[OInputCellBlueprint alloc] init];
    blueprint.fieldsAreLabeled = NO;
    blueprint.fieldsShouldDeemphasiseOnEndEdit = NO;
    
    if ([self actionIs:kActionSignIn]) {
        blueprint.titleKey = kExternalKeySignIn;
        blueprint.detailKeys = @[kExternalKeyAuthEmail, kExternalKeyPassword];
        blueprint.buttonKeys = @[kButtonKeySignUp, kButtonKeySignIn];
    } else if ([self actionIs:kActionActivate]) {
        blueprint.titleKey = kExternalKeyActivate;
        blueprint.detailKeys = @[kExternalKeyActivationCode, kExternalKeyRepeatPassword];
        blueprint.buttonKeys = @[kButtonKeyCancel, kButtonKeyActivate];
    } else if ([self actionIs:kActionChange]) {
        blueprint.titleKey = kExternalKeyChangePassword;
        blueprint.detailKeys = @[kExternalKeyOldPassword, kExternalKeyNewPassword, kExternalKeyRepeatNewPassword];
        blueprint.buttonKeys = @[kButtonKeyCancel, kButtonKeyChangePassword];
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
    
    if ([self actionIs:kActionSignIn]) {
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
        
        if (_signInAction) {
            _signInAction = kSignInActionNone;
        }
    }
    
    return inputIsValid;
}


- (void)processInput
{
    if ([self actionIs:kActionSignIn]) {
        if (!_signInAction && [_emailField.value isEqualToString:[OMeta m].userEmail]) {
            _signInAction = kSignInActionSignIn;
        }
        
        if (!_signInAction) {
            OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagSignInAction];
            [actionSheet addButtonWithTitle:NSLocalizedString(kButtonKeySignUp, kStringPrefixTitle) tag:kButtonTagSignInActionSignUp];
            [actionSheet addButtonWithTitle:NSLocalizedString(kButtonKeySignIn, kStringPrefixTitle) tag:kButtonTagSignInActionSignIn];
            
            [actionSheet show];
        } else {
            [OMeta m].userEmail = _emailField.value;
            
            if (_signInAction == kSignInActionSignUp) {
                [[OConnection connectionWithDelegate:self] signUpWithEmail:[OMeta m].userEmail password:_passwordField.value];
            } else if (_signInAction == kSignInActionSignIn) {
                [[OConnection connectionWithDelegate:self] signInWithEmail:[OMeta m].userEmail password:_passwordField.value];
            }
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
    return [@[kExternalKeyActivationCode, kExternalKeyRepeatPassword, kExternalKeyOldPassword, kExternalKeyNewPassword, kExternalKeyRepeatNewPassword] containsObject:key];
}


- (BOOL)inputValue:(id)inputValue isValidForKey:(NSString *)key
{
    BOOL isValid = NO;
    
    if ([key isEqualToString:kExternalKeyActivationCode]) {
        NSString *activationCode = _authInfo[kExternalKeyActivationCode];
        NSString *activationCodeAsEntered = [inputValue lowercaseString];
        
        isValid = [activationCodeAsEntered isEqualToString:activationCode];
    } else if ([key isEqualToString:kExternalKeyRepeatPassword]) {
        NSString *passwordHashAsEntered = [OCrypto passwordHashWithPassword:inputValue];
        NSString *passwordHash = nil;
        
        if ([self targetIs:kTargetUser]) {
            passwordHash = _authInfo[kPropertyKeyPasswordHash];
        } else if ([self targetIs:kTargetEmail]) {
            passwordHash = [OMeta m].user.passwordHash;
        }
        
        isValid = [passwordHashAsEntered isEqualToString:passwordHash];
    } else if ([key isEqualToString:kExternalKeyOldPassword]) {
        NSString *oldPasswordHashAsEntered = [OCrypto passwordHashWithPassword:inputValue];
        NSString *oldPasswordHash = [OMeta m].user.passwordHash;
        
        isValid = [oldPasswordHashAsEntered isEqualToString:oldPasswordHash];
    } else if ([key isEqualToString:kExternalKeyNewPassword]) {
        if ([OValidator value:inputValue isValidForKey:key]) {
            NSString *newPasswordHash = [OCrypto passwordHashWithPassword:inputValue];
            NSString *oldPasswordHash = [OMeta m].user.passwordHash;
            
            isValid = ![newPasswordHash isEqualToString:oldPasswordHash];
        }
    } else if ([key isEqualToString:kExternalKeyRepeatNewPassword]) {
        isValid = [inputValue isEqualToString:_newPasswordField.value];
    }
    
    return isValid;
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case kActionSheetTagSignInAction:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
                
                if (buttonTag == kButtonTagSignInActionSignUp) {
                    [self performSignUpAction];
                } else if (buttonTag == kButtonTagSignInActionSignIn) {
                    [self performSignInAction];
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
            if ([self actionIs:kActionChange]) {
                [self.dismisser dismissModalViewController:self];
            } else {
                [self userDidSignUpWithData:data];
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
        [_passwordField becomeFirstResponder];
    }
}

@end
