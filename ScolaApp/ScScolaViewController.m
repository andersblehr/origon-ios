//
//  ScScolaViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 01.07.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScScolaViewController.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "UITableView+UITableViewExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScMemberListViewController.h"

#import "ScLogging.h"
#import "ScMeta.h"
#import "ScState.h"
#import "ScStrings.h"
#import "ScTableViewCell.h"
#import "ScTextField.h"

#import "ScMember.h"
#import "ScScola.h"

#import "ScScola+ScScolaExtensions.h"


@implementation ScScolaViewController

#pragma mark - Selector implementations

- (void)startEditing
{
    
}


- (void)cancelEditing
{
    [_delegate dismissViewControllerWithIdentitifier:kScolaViewControllerId];
}


- (void)didFinishEditing
{
    if ([ScMeta isAddressValidWithLine1:_addressLine1Field line2:_addressLine2Field]) {
        _scola.addressLine1 = _addressLine1Field.text;
        _scola.addressLine2 = _addressLine2Field.text;
        _scola.telephone = _telephoneField.text;
        
        if ([ScState s].actionIsRegister && [_scola isResidence] && [ScState s].aspectIsSelf) {
            [ScMeta m].user.activeSince = [NSDate date];
        }
        
        [self.view endEditing:YES];
        [[ScMeta m].context synchroniseCacheWithServer];
        
        [_delegate dismissViewControllerWithIdentitifier:kScolaViewControllerId];
    } else {
        [_scolaCell shake];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ScLogState;
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    [self.tableView setBackground];
    
    _editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(startEditing)];
    _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditing)];
    _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didFinishEditing)];
    
    if ([ScState s].actionIsRegister) {
        self.title = [ScStrings stringForKey:strAddressLabel];
        self.navigationItem.rightBarButtonItem = _doneButton;
        
        if ([_scola isResidence]) {
            self.navigationItem.hidesBackButton = YES;
        } else {
            self.navigationItem.leftBarButtonItem = _cancelButton;
        }
    } else if ([ScState s].actionIsDisplay) {
        self.title = [ScStrings stringForKey:strAddressLabel];
        self.navigationItem.rightBarButtonItem = _editButton;
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - ScModalViewControllerDelegate methods

- (void)shouldDismissViewControllerWithIdentitifier:(NSString *)identitifier
{
    if ([identitifier isEqualToString:kMemberListViewControllerId]) {
        [self dismissViewControllerAnimated:YES completion:^{
            [_delegate dismissViewControllerWithIdentitifier:kScolaViewControllerId];
        }];
    }
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
    return [ScTableViewCell heightForEntity:_scola];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([ScState s].actionIsRegister) {
        _scolaCell = [tableView cellForEntity:_scola delegate:self];
        
        _addressLine1Field = [_scolaCell textFieldWithKey:kTextFieldKeyAddressLine1];
        _addressLine2Field = [_scolaCell textFieldWithKey:kTextFieldKeyAddressLine2];
        _telephoneField = [_scolaCell textFieldWithKey:kTextFieldKeyTelephone];
        
        [_addressLine1Field becomeFirstResponder];
    } else if ([ScState s].actionIsDisplay) {
        _scolaCell = [tableView cellForEntity:_scola];
    }
    
    return _scolaCell;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell.backgroundView addShadowForBottomTableViewCell];
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _addressLine1Field) {
        [_addressLine2Field becomeFirstResponder];
    } else if (textField == _addressLine2Field) {
        [_telephoneField becomeFirstResponder];
    }
    
    return YES;
}

@end
