//
//  OOrigoViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OOrigoViewController.h"

#import "NSManagedObjectContext+OrigoExtensions.h"
#import "NSString+OrigoExtensions.h"
#import "UIBarButtonItem+OrigoExtensions.h"
#import "UITableView+OrigoExtensions.h"

#import "OEntityObservingDelegate.h"
#import "OModalViewControllerDelegate.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextField.h"
#import "OTextView.h"

#import "OMember+OrigoExtensions.h"
#import "OMembership.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"

#import "OMemberListViewController.h"

static NSString * const kModalSegueToMemberListView = @"modalFromOrigoToMemberListView";

static NSInteger const kOrigoSection = 0;


@implementation OOrigoViewController

#pragma mark - Selector implementations

//- (void)moveToNextInputField
//{
//    if (_currentField == _addressView) {
//        [_telephoneField becomeFirstResponder];
//    }
//}


- (void)didCancelEditing
{
    if (self.state.actionIsRegister) {
        [[OMeta m].context deleteEntity:_membership];
        
        [self.delegate dismissModalViewControllerWithIdentitifier:kOrigoViewControllerId needsReloadData:NO];
    } else {
        _addressView.text = _origo.address;
        _telephoneField.text = _origo.telephone;
        
        [self toggleEditMode];
    }
}


- (void)didFinishEditing
{
    if ([[_addressView finalText] length] > 0) {
        _origo.address = [_addressView finalText];
        _origo.telephone = [_telephoneField finalText];
        
        if (self.state.actionIsRegister) {
            if ([_member isUser] && !_member.activeSince) {
                _member.activeSince = [NSDate date];
                [self.delegate dismissModalViewControllerWithIdentitifier:kOrigoViewControllerId];
            } else {
                [self performSegueWithIdentifier:kModalSegueToMemberListView sender:self];
            }
        } else if (self.state.actionIsEdit) {
            [self toggleEditMode];
            [self.observer reloadEntity];
        }
        
        [[OMeta m].context replicateIfNeeded];
    } else {
        [self.entityCell shakeCellVibrateDevice:NO];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_origo) {
        self.title = [_origo isResidence] ? [OStrings stringForKey:strTermAddress] : _origo.name;
    } else {
        if ([_origo.type isEqualToString:kOrigoTypeDefault]) {
            self.title = [OStrings stringForKey:strViewTitleNewOrigo];
        } else {
            self.title = [OStrings stringForKey:_origo.type];
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.state.actionIsInput) {
        [_addressView becomeFirstResponder];
    } else if ([_origo userIsAdmin]) {
        self.entityCell.editable = YES;
    }
    
    OLogState;
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kModalSegueToMemberListView]) {
        [self prepareForModalSegue:segue data:_origo];
        [segue.destinationViewController setDelegate:self.delegate];
    }
}


#pragma mark - Overrides

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}


#pragma mark - OTableViewControllerDelegate conformance

- (void)loadState
{
    _membership = self.data;
    _origo = _membership.origo;
    _member = _membership.member;
    
    self.state.targetIsOrigo = YES;
    self.state.actionIsDisplay = ![OState s].actionIsInput;
    [self.state setAspectForOrigo:_origo];
}


- (void)loadData
{
    [self setData:_origo forSectionWithKey:kOrigoSection];
}


- (UIBarButtonItem *)cancelRegistrationButton
{
    UIBarButtonItem *cancelButton = nil;
    
    if (!([_origo isResidence] && self.state.aspectIsSelf)) {
        cancelButton = [UIBarButtonItem cancelButtonWithTarget:self];
    }
    
    return cancelButton;
}


#pragma mark - UITableViewDataSource conformance

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [_origo cellHeight];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.entityCell = [tableView cellForEntity:_origo delegate:self];
    
    _addressView = [self.entityCell textFieldForKeyPath:kKeyPathAddress];
    _telephoneField = [self.entityCell textFieldForKeyPath:kKeyPathTelephone];
    
    return self.entityCell;
}

@end
