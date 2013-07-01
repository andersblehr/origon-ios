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
#import "OReplicator.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextField.h"
#import "OTextView.h"

#import "OMember+OrigoExtensions.h"
#import "OMembership.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"

static NSInteger const kSectionKeyOrigo = 0;


@implementation OOrigoViewController

#pragma mark - Selector implementations

- (void)signOut
{
    [[OMeta m] userDidSignOut];
    
    [self.dismisser dismissModalViewControllerWithIdentifier:self.viewControllerId];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_origo) {
        self.title = [_origo isOfType:kOrigoTypeResidence] ? [OStrings titleForOrigoType:kOrigoTypeResidence] : _origo.name;
    } else {
        self.title = [OStrings titleForOrigoType:self.meta];
    }
}


#pragma mark - OTableViewController custom accesors

- (BOOL)canEdit
{
    return [self actionIs:kActionRegister] || [_origo userIsAdmin] || (![_origo hasAdmin] && [_origo userIsCreator]);
}


#pragma mark - UIViewController custom accessors

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialiseState
{
    if ([self.data isKindOfClass:OMembership.class]) {
        _membership = self.data;
        _origo = _membership.origo;
        _member = _membership.member;
    } else if ([self.data isKindOfClass:OMember.class]) {
        _member = self.data;
    }
    
    self.state.target = _origo ? _origo : self.meta;
    self.cancelRegistrationImpliesSignOut = [_origo isOfType:kOrigoTypeResidence] && !_member.activeSince;
}


- (void)initialiseDataSource
{
    id origoDataSource = _origo ? _origo : kEntityRegistrationCell;
    
    [self setData:origoDataSource forSectionWithKey:kSectionKeyOrigo];
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return NO;
}


#pragma mark - OTableViewInputDelegate conformance

- (BOOL)inputIsValid
{
    BOOL isValid = NO;
    
    if ([self targetIs:kOrigoTypeResidence]) {
        isValid = [self.detailCell hasValidValueForKey:kPropertyKeyAddress];
    } else {
        isValid = [self.detailCell hasValidValueForKey:kPropertyKeyName];
    }
    
    return isValid;
}


- (void)processInput
{
    [self.detailCell writeEntity];
    
    if ([self actionIs:kActionRegister]) {
        if (!_membership) {
            _membership = [_origo addMember:_member];
        }
        
        [self presentModalViewControllerWithIdentifier:kViewControllerMemberList data:_membership dismisser:self.dismisser];
        
        if ([_member isUser]) {
            [[OMeta m].user makeActive];
            [[OMeta m].replicator replicate];
        }
    } else if ([self actionIs:kActionEdit]) {
        [self toggleEditMode];
    }
}


- (id)targetEntity
{
    _origo = [[OMeta m].context insertOrigoEntityOfType:self.meta];
    
    return _origo;
}

@end
