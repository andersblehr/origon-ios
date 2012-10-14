//
//  ScAuthViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 18.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScAuthViewController.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "NSString+ScStringExtensions.h"
#import "UIColor+ScColorExtensions.h"
#import "UITableView+UITableViewExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScAlert.h"
#import "ScMeta.h"
#import "ScServerConnection.h"
#import "ScState.h"
#import "ScStrings.h"
#import "ScTableViewCell.h"
#import "ScTextField.h"
#import "ScUUIDGenerator.h"

#import "ScDevice.h"
#import "ScLogging.h"
#import "ScMember.h"
#import "ScMemberResidency.h"
#import "ScMembership.h"
#import "ScMessageBoard.h"
#import "ScScola.h"

#import "ScMember+ScMemberExtensions.h"
#import "ScScola+ScScolaExtensions.h"

#import "ScMemberViewController.h"

static NSInteger const kNumberOfAuthSections = 1;
static NSInteger const kNumberOfRowsInAuthSection = 1;

static NSString * const kSegueToMainView = @"authToMainView";

static NSString * const kUserDefaultsKeyAuthInfo = @"scola.auth.info";
static NSString * const kAuthInfoKeyUserId = @"userId";
static NSString * const kAuthInfoKeyPasswordHash = @"passwordHash";
static NSString * const kAuthInfoKeyActivationCode = @"activationCode";
static NSString * const kAuthInfoKeyIsUserListed = @"isListed";
static NSString * const kAuthInfoKeyIsRegistered = @"isRegistered";
static NSString * const kAuthInfoKeyHomeScolaId = @"homeScolaId";

static NSInteger const kAlertButtonStartOver = 0;
static NSInteger const kAlertTagWelcomeBack = 0;


@implementation ScAuthViewController

#pragma mark - Auxiliary methods

- (void)reload
{
    if ([ScState s].actionIsLogin) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
        
        if (_authInfo) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserDefaultsKeyAuthInfo];
            _authInfo = nil;
        }
    } else if ([ScState s].actionIsActivate) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
    }
}


- (NSString *)computePasswordHash:(NSString *)password
{
    return [[password diff:[ScMeta m].userId] hashUsingSHA1];
}


- (void)indicatePendingServerSession:(BOOL)isPending
{
    static NSString *email;
    static NSString *password;
    static NSString *activationCode;
    
    if (isPending) {
        if ([ScState s].actionIsLogin) {
            email = _emailField.text;
            _emailField.placeholder = [ScStrings stringForKey:strPleaseWait];
            _emailField.text = @"";
        } else if ([ScState s].actionIsActivate) {
            activationCode = _activationCodeField.text;
            _activationCodeField.placeholder = [ScStrings stringForKey:strPleaseWait];
            _activationCodeField.text = @"";
        }
        
        password = _passwordField.text;
        _passwordField.placeholder = [ScStrings stringForKey:strPleaseWait];
        _passwordField.text = @"";
        
        [_activityIndicator startAnimating];
    } else {
        if ([ScState s].actionIsLogin) {
            _emailField.text = email;
            _emailField.placeholder = [ScStrings stringForKey:strAuthEmailPrompt];
        } else if ([ScState s].actionIsActivate) {
            _activationCodeField.text = activationCode;
            _activationCodeField.placeholder = [ScStrings stringForKey:strActivationCodePrompt];
        }
        
        _passwordField.text = password;
        _passwordField.placeholder = [ScStrings stringForKey:strPasswordPrompt];
        
        [_activityIndicator stopAnimating];
    }
    
    _isEditingAllowed = !isPending;
}


- (void)handleInvalidInputForField:(ScTextField *)field;
{
    if (_numberOfActivationAttempts < 3) {
        [_authCell shakeAndVibrateDevice];
        
        if (field == _activationCodeField) {
            _activationCodeField.text = @"";
        }
        
        _passwordField.text = @"";
        
        [field becomeFirstResponder];
    } else {
        _numberOfActivationAttempts = 0;
        
        [[[UIAlertView alloc] initWithTitle:[ScStrings stringForKey:strActivationFailedTitle] message:[ScStrings stringForKey:strActivationFailedAlert] delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil] show];
        
        [ScState s].action = ScStateActionLogin;
        [self reload];
        
        ScLogState;
    }
}


- (void)presentEULA
{
    UIActionSheet *EULASheet = [[UIActionSheet alloc] initWithTitle:[ScStrings stringForKey:strEULA] delegate:self cancelButtonTitle:nil destructiveButtonTitle:[ScStrings stringForKey:strDecline] otherButtonTitles:[ScStrings stringForKey:strAccept], nil];
    EULASheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    
    [EULASheet showInView:self.view];
}


- (BOOL)registerNewDevice
{
    BOOL didRegisterNewDevice = NO;
    
    ScDevice *device = [[ScMeta m].context fetchEntityFromCache:[ScMeta m].deviceId];
    
    if (!device) {
        device = [[ScMeta m].context entityForClass:ScDevice.class inScola:[[ScMeta m].user memberRoot] entityId:[ScMeta m].deviceId];
        device.type = [UIDevice currentDevice].model;
        device.displayName = [UIDevice currentDevice].name;
        device.member = [ScMeta m].user;
        
        didRegisterNewDevice = YES;
    }
    
    return didRegisterNewDevice;
}


#pragma mark - Input validation

- (BOOL)isActivationCodeValid
{
    NSString *activationCode = [[_authInfo objectForKey:kAuthInfoKeyActivationCode] lowercaseString];
    NSString *registrationCodeAsEntered = [_activationCodeField.text lowercaseString];
    
    BOOL isValid = [registrationCodeAsEntered isEqualToString:activationCode];
    
    if (!isValid) {
        [self handleInvalidInputForField:_activationCodeField];
    }
    
    return isValid;
}


- (BOOL)isPasswordValid
{
    BOOL isValid = NO;
    
    if ([ScState s].actionIsActivate) {
        NSString *passwordHashAsPersisted = [_authInfo objectForKey:kAuthInfoKeyPasswordHash];
        NSString *passwordHashAsEntered = [self computePasswordHash:_passwordField.text];
        
        isValid = [passwordHashAsEntered isEqualToString:passwordHashAsPersisted];
        
        if (!isValid) {
            [self handleInvalidInputForField:_passwordField];
        }
    }
    
    return isValid;
}


#pragma mark - User login

- (void)attemptUserLogin
{
    [ScMeta m].userId = _emailField.text;
    
    ScServerConnection *serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:_emailField.text withPassword:_passwordField.text];
    [serverConnection authenticate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)userDidAuthenticateWithData:(NSArray *)data
{
    if (data) {
        [[ScMeta m].context saveServerEntitiesToCache:data];
    }
    
    if ([ScState s].actionIsActivate) {
        [self completeActivation];
    } else if ([ScState s].actionIsLogin) {
        [self completeLogin];
    }
}


- (void)completeLogin
{
    [[ScMeta m] userDidLogIn];
    
    if ([self registerNewDevice]) {
        [[ScMeta m].context synchroniseCacheWithServer];
    }
    
    _isModelUpToDate = YES;
    
    if ([self isRegistrationComplete]) {
        [self performSegueWithIdentifier:kSegueToMainView sender:self];
    } else {
        [ScAlert showAlertWithTitle:[ScStrings stringForKey:strIncompleteRegistrationTitle] message:[ScStrings stringForKey:strIncompleteRegistrationAlert]];
        
        [self completeRegistration];
    }
}


#pragma mark - User sign-up & activation

- (void)userDidSignUpWithData:(NSDictionary *)data
{
    _authInfo = data;
    _isUserListed = [[_authInfo objectForKey:kAuthInfoKeyIsUserListed] boolValue];
    
    NSData *authInfoArchive = [NSKeyedArchiver archivedDataWithRootObject:_authInfo];
    [[NSUserDefaults standardUserDefaults] setObject:authInfoArchive forKey:kUserDefaultsKeyAuthInfo];
    
    [ScState s].action = ScStateActionActivate;
    [self reload];
    
    ScLogState;
}


- (void)activateMembership
{
    ScServerConnection *serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:[ScMeta m].userId withPassword:_passwordField.text];
    [serverConnection authenticate:self];
    
    [self indicatePendingServerSession:YES];
}


- (void)completeActivation
{
    [[ScMeta m] userDidLogIn];
    
    if (_isUserListed) {
        for (ScMemberResidency *residency in [ScMeta m].user.residencies) {
            residency.isActive = @YES;
            
            if ([[ScMeta m].user isMinor]) {
                residency.isAdmin = @NO;
            } else {
                residency.isAdmin = @YES;
                residency.contactRole = kContactRoleResidenceElder;
            }
        }
    } else {
        ScScola *residence = [[ScMeta m].context entityForScolaOfType:kScolaTypeResidence];
        ScMemberResidency *residency = [residence addResident:[ScMeta m].user];
        residency.isActive = @YES;
        residency.isAdmin = @YES;
        
        ScMessageBoard *residenceMessageBoard = [[ScMeta m].context entityForClass:ScMessageBoard.class inScola:residence];
        residenceMessageBoard.title = [ScStrings stringForKey:strMyMessageBoard];
    }
    
    [ScMeta m].user.passwordHash = [_authInfo objectForKey:kAuthInfoKeyPasswordHash];
    [ScMeta m].user.didRegister = @YES;
    
    [self registerNewDevice];
    [[ScMeta m].context synchroniseCacheWithServer];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserDefaultsKeyAuthInfo];
    _authInfo = nil;
    
    if (![self isRegistrationComplete]) {
        [self completeRegistration];
    }
}


#pragma mark - User registration

- (BOOL)isRegistrationComplete
{
    return ([[ScMeta m].user hasPhone] && [[ScMeta m].user hasAddress]);
}


- (void)completeRegistration
{
    [ScState s].action = ScStateActionRegister;
    [ScState s].target = ScStateTargetMember;
    [ScState s].aspect = ScStateAspectSelf;
    
    ScMemberViewController *memberViewController = [self.storyboard instantiateViewControllerWithIdentifier:kMemberViewControllerId];
    memberViewController.membership = [[ScMeta m].user.residencies anyObject];
    memberViewController.delegate = self;
    
    UINavigationController *modalController = [[UINavigationController alloc] initWithRootViewController:memberViewController];
    modalController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self.navigationController presentViewController:modalController animated:YES completion:NULL];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [ScState s].action = ScStateActionLogin;
    [ScState s].target = ScStateTargetMember;
    [ScState s].aspect = ScStateAspectSelf;
    
    ScLogState;
    
    self.navigationController.navigationBarHidden = YES;
    
    [self.tableView addBackground];
    [self.tableView addLogoBanner];
    _activityIndicator = [self.tableView addActivityIndicator];
    
    if ([ScMeta m].isUserLoggedIn) {
        if ([self isRegistrationComplete]) {
            [self performSegueWithIdentifier:kSegueToMainView sender:self];
        } else {
            [ScAlert showAlertWithTitle:[ScStrings stringForKey:strIncompleteRegistrationTitle] message:[ScStrings stringForKey:strIncompleteRegistrationAlert]];
            
            [self completeRegistration];
        }
    } else {
        _isEditingAllowed = YES;
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSData *authInfoArchive = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsKeyAuthInfo];
    
    if (authInfoArchive) {
        _authInfo = [NSKeyedUnarchiver unarchiveObjectWithData:authInfoArchive];
        [ScMeta m].userId = [_authInfo objectForKey:kAuthInfoKeyUserId];
        
        [ScState s].action = ScStateActionActivate;
        
        ScLogState;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [ScStrings refreshIfPossible];
    
    if ([ScState s].actionIsActivate) {
        NSString *popUpMessage = [NSString stringWithFormat:[ScStrings stringForKey:strWelcomeBackAlert], [_authInfo objectForKey:kAuthInfoKeyUserId]];
        
        UIAlertView *welcomeBackPopUp = [[UIAlertView alloc] initWithTitle:[ScStrings stringForKey:strWelcomeBackTitle] message:popUpMessage delegate:self cancelButtonTitle:[ScStrings stringForKey:strStartOver] otherButtonTitles:[ScStrings stringForKey:strHaveCode], nil];
        welcomeBackPopUp.tag = kAlertTagWelcomeBack;
        
        [welcomeBackPopUp show];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToMainView]) {
        if (!_isModelUpToDate) {
            [[ScMeta m].context synchroniseCacheWithServer];
        }
    }
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfAuthSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return kNumberOfRowsInAuthSection;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.f;
    
    if ([ScState s].actionIsLogin) {
        height = [ScTableViewCell heightForReuseIdentifier:kReuseIdentifierUserLogin];
    } else if ([ScState s].actionIsActivate) {
        height = [ScTableViewCell heightForReuseIdentifier:kReuseIdentifierUserActivation];
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([ScState s].actionIsLogin) {
        _authCell = [tableView cellWithReuseIdentifier:kReuseIdentifierUserLogin delegate:self];
    } else {
        _authCell = [tableView cellWithReuseIdentifier:kReuseIdentifierUserActivation delegate:self];
    }
    
    return _authCell;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_authCell.backgroundView addShadowForBottomTableViewCell];
    
    if ([ScState s].actionIsLogin) {
        _emailField = [_authCell textFieldWithKey:kTextFieldKeyAuthEmail];
        _passwordField = [_authCell textFieldWithKey:kTextFieldKeyPassword];
        
        if ([ScMeta m].userId) {
            _emailField.text = [ScMeta m].userId;
            [_passwordField becomeFirstResponder];
        } else {
            [_emailField becomeFirstResponder];
        }
    } else if ([ScState s].actionIsActivate) {
        _activationCodeField = [_authCell textFieldWithKey:kTextFieldKeyActivationCode];
        _passwordField = [_authCell textFieldWithKey:kTextFieldKeyRepeatPassword];
        
        _activationCodeField.text = @"";
        [_activationCodeField becomeFirstResponder];
    }
    
    _passwordField.text = @"";
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *footerText = nil;
    
    if ([ScState s].actionIsLogin) {
        footerText = [ScStrings stringForKey:strSignInOrRegisterFooter];
    } else if ([ScState s].actionIsActivate) {
        footerText = [ScStrings stringForKey:strActivateFooter];
    }
    
    return [tableView footerViewWithText:footerText];
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return _isEditingAllowed;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    BOOL shouldReturn = YES;
    
    if ((textField == _emailField) || (textField == _activationCodeField)) {
        [_passwordField becomeFirstResponder];
    } else if (textField == _passwordField) {
        if ([ScState s].actionIsLogin) {
            shouldReturn = shouldReturn && [ScMeta isEmailValid:_emailField];
            shouldReturn = shouldReturn && [ScMeta isPasswordValid:_passwordField];
            
            if (shouldReturn) {
                [self attemptUserLogin];
            }
        } else if ([ScState s].actionIsActivate) {
            _numberOfActivationAttempts++;
            
            shouldReturn = shouldReturn && [self isActivationCodeValid];
            shouldReturn = shouldReturn && [self isPasswordValid];
            
            if (shouldReturn) {
                [self presentEULA];
            }
        }
        
        if (shouldReturn) {
            [self.view endEditing:YES];
        } else {
            _passwordField.text = @"";
            [_authCell shakeAndVibrateDevice];
        }
    }
    
    return shouldReturn;
}


#pragma mark - UIAlertViewDelegate implementation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kAlertTagWelcomeBack) {
        if (buttonIndex == kAlertButtonStartOver) {
            [ScState s].action = ScStateActionLogin;
            [self reload];
            
            ScLogState;
        }
    }
}


#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.destructiveButtonIndex) {
        [self activateMembership];
    }
}


#pragma mark - ScMemberViewControllerDelegate methods

- (void)shouldDismissViewControllerWithIdentitifier:(NSString *)identitifier
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self performSegueWithIdentifier:kSegueToMainView sender:self];
}


#pragma mark - ScServerConnectionDelegate methods

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    [self indicatePendingServerSession:NO];
    
    if (response.statusCode < kHTTPStatusCodeErrorRangeStart) {
        if (response.statusCode == kHTTPStatusCodeCreated) {
            [self userDidSignUpWithData:data];
        } else {
            [self userDidAuthenticateWithData:data];
        }
    } else if (response.statusCode >= kHTTPStatusCodeErrorRangeStart) {
        if (response.statusCode == kHTTPStatusCodeUnauthorized) {
            [_authCell shake];
            [_passwordField becomeFirstResponder];
        } else {
            [ScAlert showAlertForHTTPStatus:response.statusCode];
        }
    }
}


- (void)didFailWithError:(NSError *)error
{
    
}

@end
