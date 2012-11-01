//
//  OOrigoViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OOrigoViewController.h"

#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"
#import "UITableView+OTableViewExtensions.h"
#import "UIView+OViewExtensions.h"

#import "OMemberListViewController.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextField.h"

#import "OMember.h"
#import "OOrigo.h"

#import "OOrigo+OOrigoExtensions.h"


@implementation OOrigoViewController

#pragma mark - Selector implementations

- (void)startEditing
{
    
}


- (void)cancelEditing
{
    [_delegate dismissViewControllerWithIdentitifier:kOrigoViewControllerId];
}


- (void)didFinishEditing
{
    if ([OMeta isValidAddressWithLine1:_addressLine1Field line2:_addressLine2Field]) {
        _origo.addressLine1 = _addressLine1Field.text;
        _origo.addressLine2 = _addressLine2Field.text;
        _origo.telephone = _telephoneField.text;
        
        if ([OState s].actionIsRegister && [_origo isResidence] && [OState s].aspectIsSelf) {
            [OMeta m].user.activeSince = [NSDate date];
        }
        
        [self.view endEditing:YES];
        [[OMeta m].context replicate];
        
        [_delegate dismissViewControllerWithIdentitifier:kOrigoViewControllerId];
    } else {
        [_origoCell shake];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setBackground];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    _editButton = [[UIBarButtonItem alloc] initWithTitle:[OStrings stringForKey:strButtonEdit] style:UIBarButtonItemStylePlain target:self action:@selector(startEditing)];
    _doneButton = [[UIBarButtonItem alloc] initWithTitle:[OStrings stringForKey:strButtonDone] style:UIBarButtonItemStyleDone target:self action:@selector(didFinishEditing)];
    _cancelButton = [[UIBarButtonItem alloc] initWithTitle:[OStrings stringForKey:strButtonCancel] style:UIBarButtonItemStylePlain target:self action:@selector(cancelEditing)];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [OState s].targetIsOrigo = YES;
    [OState s].actionIsDisplay = ![OState s].actionIsInput;
    
    OLogState;
    
    self.title = [_origo isResidence] ? [OStrings stringForKey:strHeaderAddress] : _origo.name;
    
    if ([OState s].actionIsRegister) {
        self.navigationItem.rightBarButtonItem = _doneButton;
        
        if (_delegate) {
            self.navigationItem.leftBarButtonItem = _cancelButton;
        }
    } else if ([OState s].actionIsDisplay) {
        if ([_origo userIsAdmin]) {
            self.navigationItem.rightBarButtonItem = _editButton;
        }
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - OModalViewControllerDelegate methods

- (void)shouldDismissViewControllerWithIdentitifier:(NSString *)identitifier
{
    if ([identitifier isEqualToString:kMemberListViewControllerId]) {
        [self dismissViewControllerAnimated:YES completion:^{
            [_delegate dismissViewControllerWithIdentitifier:kOrigoViewControllerId];
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
    return [OTableViewCell heightForEntity:_origo];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([OState s].actionIsRegister) {
        _origoCell = [tableView cellForEntity:_origo delegate:self];
        
        _addressLine1Field = [_origoCell textFieldWithKey:kTextFieldKeyAddressLine1];
        _addressLine2Field = [_origoCell textFieldWithKey:kTextFieldKeyAddressLine2];
        _telephoneField = [_origoCell textFieldWithKey:kTextFieldKeyTelephone];
        
        [_addressLine1Field becomeFirstResponder];
    } else if ([OState s].actionIsDisplay) {
        _origoCell = [tableView cellForEntity:_origo];
    }
    
    return _origoCell;
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
