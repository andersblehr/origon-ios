//
//  OOrigoViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OOrigoViewController.h"

#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"
#import "NSString+OStringExtensions.h"
#import "UIBarButtonItem+OBarButtonItemExtensions.h"
#import "UITableView+OTableViewExtensions.h"
#import "UIView+OViewExtensions.h"

#import "OEntityObservingDelegate.h"
#import "OModalViewControllerDelegate.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextField.h"
#import "OTextView.h"

#import "OMember.h"
#import "OMembership.h"
#import "OOrigo.h"

#import "OOrigo+OOrigoExtensions.h"
#import "OReplicatedEntity+OReplicatedEntityExtensions.h"

#import "OMemberListViewController.h"


@implementation OOrigoViewController

#pragma mark - Auxiliary methods

- (void)toggleEdit
{
    static UIBarButtonItem *editButton = nil;
    static UIBarButtonItem *backButton = nil;
    
    [_origoCell toggleEditMode];
    
    if ([OState s].actionIsEdit) {
        editButton = self.navigationItem.rightBarButtonItem;
        backButton = self.navigationItem.leftBarButtonItem;
        
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];

        [_addressView becomeFirstResponder];
    } else if ([OState s].actionIsDisplay) {
        [self.view endEditing:YES];
        
        self.navigationItem.rightBarButtonItem = editButton;
        self.navigationItem.leftBarButtonItem = backButton;
    }
    
    OLogState;
}


#pragma mark - Selector implementations

- (void)startEditing
{
    [self toggleEdit];
}


- (void)cancelEditing
{
    if ([OState s].actionIsRegister) {
        [_delegate dismissViewControllerWithIdentitifier:kOrigoViewControllerId];
    } else {
        _addressView.text = _origo.address;
        _telephoneField.text = _origo.telephone;
        
        [self toggleEdit];
    }
}


- (void)didFinishEditing
{
    if ([_addressView.text length] > 0) {
        _origo.address = [_addressView.text removeLeadingAndTrailingWhitespace];
        _origo.telephone = [_telephoneField.text removeLeadingAndTrailingWhitespace];
        
        if ([OState s].actionIsRegister) {
            if ([_origo isResidence] && [OState s].aspectIsSelf) {
                [OMeta m].user.activeSince = [NSDate date];
            }
            
            [_delegate dismissViewControllerWithIdentitifier:kOrigoViewControllerId];
        } else if ([OState s].actionIsEdit) {
            [self toggleEdit];
            [_entityObservingDelegate refreshFromEntity];
        }
        
        [[OMeta m].context replicateIfNeeded];
    } else {
        [_origoCell shakeCellShouldVibrate:NO];
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
        
        if (!([OState s].actionIsRegister && [OState s].aspectIsSelf)) {
            [[OState s] setAspectForOrigo:_origo];
        }
        
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


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([OState s].actionIsInput) {
        [_addressView becomeFirstResponder];
    }
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
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
        height = [_origo displayCellHeight];
    } else {
        height = [OOrigo defaultDisplayCellHeight];
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
    
    _addressView = [_origoCell textFieldForKeyPath:kKeyPathAddress];
    _telephoneField = [_origoCell textFieldForKeyPath:kKeyPathTelephone];
    
    return _origoCell;
}


#pragma mark - UITableViewDelegate conformance

- (void)tableView:(UITableView *)tableView willDisplayCell:(OTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell willAppearTrailing:YES];
}


#pragma mark - UITextFieldDelegate conformance

- (void)textFieldDidBeginEditing:(OTextField *)textField
{
    [textField emphasise];
}


- (void)textFieldDidEndEditing:(OTextField *)textField
{
    [textField deemphasise];
}


#pragma mark - UITextViewDelegate conformance

- (void)textViewDidBeginEditing:(OTextView *)textView
{
    [textView emphasise];
}


- (void)textViewDidChange:(OTextView *)textView
{
    [_origoCell respondToTextViewSizeChange:textView];
}


- (void)textViewDidEndEditing:(OTextView *)textView
{
    [textView deemphasise];
}

@end
