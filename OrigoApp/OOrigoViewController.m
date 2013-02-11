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

- (void)didCancelEditing
{
    if (self.state.actionIsRegister) {
        [self.dismisser dismissModalViewControllerWithIdentitifier:kOrigoViewControllerId needsReloadData:NO];
    } else {
        _addressView.text = _origo.address;
        _telephoneField.text = _origo.telephone;
        
        [self toggleEditMode];
    }
}


- (void)didFinishEditing
{
    if ([[_addressView finalText] length] > 0) {
        if (!_origo) {
            _origo = [[OMeta m].context insertOrigoEntityOfType:self.meta];
        }
        
        _origo.address = [_addressView finalText];
        _origo.telephone = [_telephoneField finalText];
        
        if (self.state.actionIsRegister) {
            [self.view endEditing:YES];
            
            if (_membership) {
                _member.activeSince = [NSDate date];
                [self.dismisser dismissModalViewControllerWithIdentitifier:kOrigoViewControllerId];
            } else {
                if ([_origo isResidence]) {
                    _membership = [_origo addResident:_member];
                } else {
                    _membership = [_origo addMember:_member];
                }
                
                [self performSegueWithIdentifier:kModalSegueToMemberListView sender:self];
            }
        } else if (self.state.actionIsEdit) {
            [self toggleEditMode];
        }
    } else {
        [self.detailCell shakeCellVibrateDevice:NO];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_origo) {
        self.title = [_origo isResidence] ? [OStrings stringForKey:strTermAddress] : _origo.name;
    } else {
        if ([self.meta isEqualToString:kOrigoTypeDefault]) {
            self.title = [OStrings stringForKey:strViewTitleNewOrigo];
        } else {
            self.title = [OStrings stringForKey:self.meta];
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _addressView = [self.detailCell textFieldForKeyPath:kKeyPathAddress];
    _telephoneField = [self.detailCell textFieldForKeyPath:kKeyPathTelephone];
    
    OLogState;
}


#pragma mark - OTableViewController overrides

- (BOOL)canEdit
{
    return [_origo userIsAdmin];
}


- (UIBarButtonItem *)cancelRegistrationButton
{
    UIBarButtonItem *cancelButton = nil;
    
    if (![_origo isResidence] || _member.activeSince) {
        cancelButton = [UIBarButtonItem cancelButtonWithTarget:self];
    }
    
    return cancelButton;
}


#pragma mark - UIViewController overrides

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kModalSegueToMemberListView]) {
        [self prepareForModalSegue:segue data:_membership meta:self.dismisser];
    }
}


#pragma mark - OTableViewControllerDelegate conformance

- (void)loadState
{
    if ([self.data isKindOfClass:OMembership.class]) {
        _membership = self.data;
        _origo = _membership.origo;
        _member = _membership.member;
    } else if ([self.data isKindOfClass:OMember.class]) {
        _member = self.data;
    }
    
    self.state.actionIsDisplay = YES;
    [self.state setTargetForOrigoType:(_origo ? _origo.type : self.meta)];
    [self.state setAspectForMember:_member];
}


- (void)loadData
{
    [self setData:_origo forSectionWithKey:kOrigoSection];
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    return nil;
}

@end
