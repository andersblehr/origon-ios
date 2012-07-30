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

#import "ScMembershipViewController.h"

#import "ScLogging.h"
#import "ScMeta.h"
#import "ScState.h"
#import "ScStrings.h"
#import "ScTableViewCell.h"
#import "ScTextField.h"

#import "ScMember.h"
#import "ScScola.h"


@interface ScScolaViewController () {
    ScTableViewCell *_scolaCell;
    
    UIBarButtonItem *_editButton;
    UIBarButtonItem *_cancelButton;
    UIBarButtonItem *_doneButton;
    
    ScTextField *_addressLine1Field;
    ScTextField *_addressLine2Field;
    ScTextField *_landlineField;
}

@end


@implementation ScScolaViewController


#pragma mark - Selector implementations

- (void)startEditing
{
    
}


- (void)cancelEditing
{
    [_delegate shouldDismissViewControllerWithIdentitifier:kScolaViewControllerId];
}


- (void)didFinishEditing
{
    if ([ScMeta isAddressValidWithLine1:_addressLine1Field line2:_addressLine2Field]) {
        NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
        
        _scola.addressLine1 = _addressLine1Field.text;
        _scola.addressLine2 = _addressLine2Field.text;
        _scola.landline = _landlineField.text;
        
        ScState *state = [ScMeta state];
        
        if (state.actionIsRegister && state.targetIsHousehold && state.aspectIsHome) {
            ScMember *member = [context fetchEntityWithId:[ScMeta m].userId];
            member.activeSince = [NSDate date];
        }
        
        [self.view endEditing:YES];
        [context synchronise];
        
        [_delegate shouldDismissViewControllerWithIdentitifier:kScolaViewControllerId];
    } else {
        [_scolaCell shake];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ScLogState;
    
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:kDarkLinenImageFile]];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    _editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(startEditing)];
    _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditing)];
    _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didFinishEditing)];
    
    if ([ScMeta state].actionIsRegister) {
        self.title = [ScStrings stringForKey:strAddressLabel];
        self.navigationItem.rightBarButtonItem = _doneButton;
        
        if ([ScMeta state].targetIsHousehold) {
            self.navigationItem.hidesBackButton = YES;
        } else {
            self.navigationItem.leftBarButtonItem = _cancelButton;
        }
    } else if ([ScMeta state].actionIsDisplay) {
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
    if ([identitifier isEqualToString:kMembershipViewControllerId]) {
        [self dismissViewControllerAnimated:YES completion:^{
            [_delegate shouldDismissViewControllerWithIdentitifier:kScolaViewControllerId];
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
    return [ScTableViewCell heightForEntity:_scola editing:[ScMeta state].actionIsRegister];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([ScMeta state].actionIsRegister) {
        _scolaCell = [tableView cellForEntity:_scola editing:YES delegate:self];
        
        _addressLine1Field = [_scolaCell textFieldWithKey:kTextFieldKeyAddressLine1];
        _addressLine2Field = [_scolaCell textFieldWithKey:kTextFieldKeyAddressLine2];
        _landlineField = [_scolaCell textFieldWithKey:kTextFieldKeyLandline];
        
        [_addressLine1Field becomeFirstResponder];
    } else if ([ScMeta state].actionIsDisplay) {
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
        [_landlineField becomeFirstResponder];
    }
    
    return YES;
}

@end
