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

#import "ScMeta.h"
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
    
    BOOL _isRegistering;
    BOOL _isDisplaying;
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
        
        if ([ScMeta appState_] == ScAppStateRegisterUserHousehold) {
            ScMember *member = [context fetchEntityWithId:[ScMeta m].userId];
            member.activeSince = [NSDate date];
        }
        
        [context synchronise];
        
        [self.view endEditing:YES];
        [_delegate shouldDismissViewControllerWithIdentitifier:kScolaViewControllerId];
    } else {
        [_scolaCell shake];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:kDarkLinenImageFile]];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    _isRegistering = ([ScMeta appState_] == ScAppStateRegisterUserHousehold);
    _isRegistering = _isRegistering || ([ScMeta appState_] == ScAppStateRegisterScola);
    _isRegistering = _isRegistering || ([ScMeta appState_] == ScAppStateRegisterScolaMemberHousehold);
    
    _isDisplaying = ([ScMeta appState_] == ScAppStateDisplayUserHousehold);
    _isDisplaying = _isDisplaying || ([ScMeta appState_] == ScAppStateDisplayScola);
    
    _editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(startEditing)];
    _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditing)];
    _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didFinishEditing)];
    
    if (_isRegistering) {
        self.title = [ScStrings stringForKey:strAddressLabel];
        self.navigationItem.rightBarButtonItem = _doneButton;
        
        if ([ScMeta appState_] == ScAppStateRegisterUserHousehold) {
            self.navigationItem.hidesBackButton = YES;
        } else {
            self.navigationItem.leftBarButtonItem = _cancelButton;
        }
    } else if (_isDisplaying) {
        self.title = [ScStrings stringForKey:strAddressLabel];
        self.navigationItem.rightBarButtonItem = _editButton;
    }
}


- (void) viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        [ScMeta popAppState];
    }
    
    [super viewWillDisappear:animated];
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
    return [ScTableViewCell heightForEntity:_scola editing:_isRegistering];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_isRegistering) {
        _scolaCell = [tableView cellForEntity:_scola editing:YES delegate:self];
        
        _addressLine1Field = [_scolaCell textFieldWithKey:kTextFieldKeyAddressLine1];
        _addressLine2Field = [_scolaCell textFieldWithKey:kTextFieldKeyAddressLine2];
        _landlineField = [_scolaCell textFieldWithKey:kTextFieldKeyLandline];
        
        [_addressLine1Field becomeFirstResponder];
    } else if (_isDisplaying) {
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
