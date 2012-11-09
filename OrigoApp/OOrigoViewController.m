//
//  OOrigoViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OOrigoViewController.h"

#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"
#import "UIBarButtonItem+OBarButtonItemExtensions.h"
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
#import "OMembership.h"
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
    if ([_addressLine1Field holdsValidAddressWith:_addressLine2Field]) {
        _origo.addressLine1 = _addressLine1Field.text;
        _origo.addressLine2 = _addressLine2Field.text;
        _origo.telephone = _telephoneField.text;
        
        if ([OState s].actionIsRegister && [_origo isResidence] && [OState s].aspectIsSelf) {
            [OMeta m].user.activeSince = [NSDate date];
        }
        
        [self.view endEditing:YES];
        [[OMeta m].context replicateIfNeeded];
        
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

    [OState s].targetIsOrigo = YES;
    [OState s].actionIsDisplay = ![OState s].actionIsInput;
    
    if (_membership) {
        _origo = _membership.origo;
        [[OState s] setAspectForOrigo:_origo];
        
        self.title = [_origo isResidence] ? [OStrings stringForKey:strTermAddress] : _origo.name;
    } else {
        [[OState s] setAspectForOrigoType:_origoType];
        
        if ([_origoType isEqualToString:kOrigoTypeDefault]) {
            self.title = [OStrings stringForKey:strViewTitleNewOrigo];
        } else {
            self.title = [OStrings stringForKey:_origoType];
        }
    }
    
    if ([OState s].actionIsRegister) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
        
        if (!([_origo isResidence] && [OState s].aspectIsSelf)) {
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
        }
    } else if ([OState s].actionIsDisplay) {
        if ([_origo userIsAdmin]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem editButtonWithTarget:self];
        }
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    OLogState;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - UITableViewDataSource conformance

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
    CGFloat height = 0.f;
    
    if (_origo) {
        height = [OTableViewCell heightForEntity:_origo];
    } else {
        height = [OTableViewCell heightForEntityClass:OOrigo.class];
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_origo) {
        _origoCell = [tableView cellForEntity:_origo delegate:self];
    } else {
        _origoCell = [tableView cellForEntityClass:OOrigo.class delegate:self];
    }
    
    _addressLine1Field = [_origoCell textFieldForKey:kTextFieldAddressLine1];
    _addressLine2Field = [_origoCell textFieldForKey:kTextFieldAddressLine2];
    _telephoneField = [_origoCell textFieldForKey:kTextFieldTelephone];
    
    return _origoCell;
}


#pragma mark - UITableViewDelegate conformance

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell.backgroundView addDropShadowForTrailingTableViewCell];
    
    if ([OState s].actionIsInput) {
        [_addressLine1Field becomeFirstResponder];
    }
}


#pragma mark - UITextFieldDelegate conformance

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [(OTextField *)textField toggleEmphasis];
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [(OTextField *)textField toggleEmphasis];
}


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
