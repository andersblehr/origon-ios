//
//  ScAuthViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 18.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScAuthViewController.h"

#import "UIColor+ScColorExtensions.h"
#import "UITableView+UITableViewExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScMeta.h"
#import "ScServerConnection.h"
#import "ScStrings.h"
#import "ScTableViewCell.h"
#import "ScTextField.h"


@implementation ScAuthViewController


#pragma mark - Auxiliary methods

- (void)indicatePendingServerSession:(BOOL)isPending
{
    static NSString *email;
    static NSString *password;
    
    if (isPending) {
        email = emailField.text;
        password = passwordField.text;
        
        emailField.placeholder = [ScStrings stringForKey:strPleaseWait];
        emailField.text = @"";
        passwordField.placeholder = [ScStrings stringForKey:strPleaseWait];
        passwordField.text = @"";
        
        isEditingAllowed = NO;
    } else {
        emailField.placeholder = [ScStrings stringForKey:strEmailPrompt];
        emailField.text = email;
        passwordField.placeholder = [ScStrings stringForKey:strPasswordPrompt];
        passwordField.text = password;
        
        isEditingAllowed = YES;
    }
}


- (void)attemptLogin
{
    [ScMeta m].userId = emailField.text;
    
    ScServerConnection *serverConnection = [[ScServerConnection alloc] init];
    [serverConnection setAuthHeaderForUser:emailField.text withPassword:passwordField.text];
    [serverConnection authenticateForPhase:ScAuthPhaseLogin delegate:self];
    
    [self indicatePendingServerSession:YES];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationController.navigationBarHidden = YES;
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:kDarkLinenImageFile]];
    
    [self.tableView addLogoBanner];
    
    if ([ScMeta m].isUserLoggedIn) {
        
    } else {
        isEditingAllowed = YES;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([ScMeta m].isInternetConnectionAvailable) {
        [ScStrings refreshStrings];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView heightForCellWithReuseIdentifier:kReuseIdentifierNewLogin];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ScTableViewCell *cell = [tableView cellWithReuseIdentifier:kReuseIdentifierNewLogin delegate:self];
    
    emailField = [cell textFieldWithKey:kTextFieldKeyEmail];
    passwordField = [cell textFieldWithKey:kTextFieldKeyPassword];
    
    [emailField becomeFirstResponder];
    
    return cell;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell.backgroundView addShadow];
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{ 
    NSString *footerText = [ScStrings stringForKey:strSignInOrRegisterFooter];
    
    return [tableView footerViewWithText:footerText];
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return isEditingAllowed;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    BOOL shouldReturn = YES;
    
    if (textField == emailField) {
        [passwordField becomeFirstResponder];
    } else {
        shouldReturn = shouldReturn && [ScMeta isEmailValid:emailField];
        shouldReturn = shouldReturn && [ScMeta isPasswordValid:passwordField];
        
        if (shouldReturn) {
            [self attemptLogin];
        }
    }
    
    return shouldReturn;
}


#pragma mark - ScServerConnectionDelegate methods

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    [self indicatePendingServerSession:NO];
}


- (void)didFailWithError:(NSError *)error
{
    
}

@end
