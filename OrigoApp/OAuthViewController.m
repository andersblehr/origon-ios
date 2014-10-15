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

static NSInteger const kMaxActivationAttempts = 3;

static NSInteger const kAlertTagWelcomeBack = 0;
static NSInteger const kAlertTagActivationFailed = 1;

static NSInteger const kAlertButtonWelcomeBackStartOver = 0;


@interface OAuthViewController () <OTableViewController, OInputCellDelegate, OConnectionDelegate, UIAlertViewDelegate> {
@private
    OInputField *_emailField;
    OInputField *_passwordField;
    OInputField *_activationCodeField;
    OInputField *_repeatPasswordField;
    
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
    logoBanner.textColor = [UIColor windowTintColour];
    
    UIView *topHairline = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, screenWidth, 0.5f)];
    topHairline.backgroundColor = [UIColor toolbarHairlineColour];
    [logoBanner addSubview:topHairline];
    
    UIView *bottomHairline = [[UIView alloc] initWithFrame:CGRectMake(0.f, kLogoHeight, screenWidth, 0.5f)];
    bottomHairline.backgroundColor = [UIColor toolbarHairlineColour];
    [logoBanner addSubview:bottomHairline];
    
    [self.view addSubview:logoBanner];
    self.tableView.contentInset = UIEdgeInsetsMake(2.f * kLogoHeight, 0.f, 0.f, 0.f);
}


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
            [OAlert showAlertWithTitle:NSLocalizedString(@"Activation failed", @"") text:NSLocalizedString(@"It looks like you may have lost the activation code ...", @"") tag:kAlertTagActivationFailed];
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
    if (data) {
        [[OMeta m].context saveEntityDictionaries:data];
    }
    
    [[OMeta m] userDidSignIn];
    
    if ([self actionIs:kActionSignIn]) {
        [OMeta m].user.passwordHash = [OCrypto passwordHashWithPassword:_passwordField.value];
    } else if ([self actionIs:kActionActivate]) {
        [OMeta m].user.passwordHash = _authInfo[kPropertyKeyPasswordHash];
        
        [[OMeta m] userDidSignUp];
        [[OMeta m].user residence];
        
        [ODefaults removeGlobalDefaultForKey:kDefaultsKeyAuthInfo];
    }
    
    [self.dismisser dismissModalViewController:self];
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
    } else if ([self actionIs:kActionActivate]) {
        blueprint.titleKey = kExternalKeyActivate;
        blueprint.detailKeys = @[kExternalKeyActivationCode, kExternalKeyRepeatPassword];
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
    }
    
    return inputIsValid;
}


- (void)processInput
{
    if ([self actionIs:kActionSignIn]) {
        [OMeta m].userEmail = _emailField.value;
        [[OConnection connectionWithDelegate:self] signInWithEmail:[OMeta m].userEmail password:_passwordField.value];
    } else if ([self actionIs:kActionActivate]) {
        if ([self targetIs:kTargetUser]) {
            [[OConnection connectionWithDelegate:self] activateWithEmail:[OMeta m].userEmail password:_repeatPasswordField.value];
        } else if ([self targetIs:kTargetEmail]) {
            [OMeta m].userEmail = self.target;
            [self.dismisser dismissModalViewController:self];
        }
    }
}


- (BOOL)willValidateInputForKey:(NSString *)key
{
    return [@[kExternalKeyActivationCode, kExternalKeyRepeatPassword] containsObject:key];
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
        [self.inputCell shakeCellVibrate:YES];
        [_passwordField becomeFirstResponder];
    }
}

@end
