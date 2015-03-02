//
//  OMembershipProxy.m
//  OrigoApp
//
//  Created by Anders Blehr on 01.05.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OMembershipProxy.h"

@implementation OMembershipProxy

#pragma mark - Factory methods

+ (instancetype)proxyForMember:(id<OMember>)member inOrigo:(id<OOrigo>)origo
{
    NSString *meta = [origo isResidence] ? kMembershipTypeResidency : kMembershipTypeParticipancy;
    
    OMembershipProxy *proxy = [self proxyForEntityOfClass:[OMembership class] meta:meta];
    proxy.member = member;
    proxy.origo = origo;
    
    return proxy;
}


#pragma mark - OEntity protocol conformance

- (id)instantiate
{
    if (![self.member isCommitted]) {
        [self.member commit];
    }
    
    if (![self.origo isCommitted]) {
        [self.origo commit];
    }
    
    return [[self.origo instance] addMember:[self.member instance]];
}


#pragma mark - OMembership protocol conformance

- (BOOL)isShared
{
    return [self isParticipancy] || [self isResidency];
}


- (BOOL)isListing
{
    return [[self valueForKey:kPropertyKeyType] isEqualToString:kMembershipTypeListing];
}


- (BOOL)isResidency
{
    return [[self valueForKey:kPropertyKeyType] isEqualToString:kMembershipTypeResidency];
}


- (BOOL)isParticipancy
{
    return [[self valueForKey:kPropertyKeyType] isEqualToString:kMembershipTypeParticipancy];
}


- (BOOL)isAssociate
{
    return [[self valueForKey:kPropertyKeyType] isEqualToString:kMembershipTypeAssociate];
}

@end
