//
//  OOrigoViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OOrigoViewController.h"

static NSInteger const kSectionKeyOrigo = 0;


@implementation OOrigoViewController

#pragma mark - Selector implementations

- (void)signOut
{
    [[OMeta m] userDidSignOut];
    
    [self.dismisser dismissModalViewController:self reload:YES];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_origo) {
        if ([_origo isOfType:kOrigoTypeResidence]) {
            self.title = [OStrings titleForOrigoType:_origo.type];
        } else {
            self.title = _origo.name;
        }
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
    return self.canEdit;
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    return [OStrings stringForKey:strFooterTapToEdit];
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
        
        [self presentModalViewControllerWithIdentifier:kVCIdentifierMemberList data:_membership];
    } else if ([self actionIs:kActionEdit]) {
        [self toggleEditMode];
    }
}


- (id)targetEntity
{
    _origo = [[OMeta m].context insertOrigoEntityOfType:self.meta];
    
    return _origo;
}


#pragma mark - OModalViewControllerDismisser conformance

- (BOOL)shouldRelayDismissalOfModalViewController:(OTableViewController *)viewController
{
    return [viewController.identifier isEqualToString:kVCIdentifierMemberList];
}

@end
