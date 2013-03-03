//
//  OOrigoViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OOrigoViewController.h"

#import "NSManagedObjectContext+OrigoExtensions.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextField.h"
#import "OTextView.h"

#import "OMember.h"
#import "OMembership.h"
#import "OOrigo+OrigoExtensions.h"

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
            if (_membership) {
                _member.activeSince = [NSDate date];
            } else {
                if ([_origo isOfType:kOrigoTypeResidence]) {
                    _membership = [_origo addResident:_member];
                } else {
                    _membership = [_origo addMember:_member];
                }
            }
            
            [self.view endEditing:YES];
            [self presentModalViewControllerWithIdentifier:kMemberListViewControllerId data:_membership dismisser:self.dismisser];
        } else if (self.state.actionIsEdit) {
            [self toggleEditMode];
        }
    } else {
        [self.detailCell shakeCellShouldVibrate:NO];
    }
}


- (void)signOut
{
    [[OMeta m] userDidSignOut];
    
    [self.dismisser dismissModalViewControllerWithIdentitifier:kOrigoViewControllerId];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_origo) {
        self.title = [_origo isOfType:kOrigoTypeResidence] ? [OStrings stringForKey:strTermAddress] : _origo.name;
    } else {
        if ([self.meta isEqualToString:kOrigoTypeOther]) {
            self.title = [OStrings stringForKey:strViewTitleNewOrigo];
        } else {
            self.title = [OStrings stringForKey:self.meta];
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _addressView = [self.detailCell textFieldForKey:kPropertyKeyAddress];
    _telephoneField = [self.detailCell textFieldForKey:kPropertyKeyTelephone];
    
    OLogState;
}


#pragma mark - OTableViewController overrides

- (BOOL)canEdit
{
    return [_origo userIsAdmin];
}


- (BOOL)cancelRegistrationImpliesSignOut
{
    return ([_origo isOfType:kOrigoTypeResidence] && !_member.activeSince);
}


#pragma mark - UIViewController overrides

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialise
{
    if ([self.data isKindOfClass:OMembership.class]) {
        _membership = self.data;
        _origo = _membership.origo;
        _member = _membership.member;
    } else if ([self.data isKindOfClass:OMember.class]) {
        _member = self.data;
    }
    
    self.aspectCarrier = _origo ? _origo : self.meta;
}


- (void)populateDataSource
{
    id origoDataSource = _origo ? _origo : kEmptyDetailCellPlaceholder;
    
    [self setData:origoDataSource forSectionWithKey:kOrigoSection];
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    return nil;
}

@end
