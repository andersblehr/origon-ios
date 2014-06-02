//
//  OMembershipProxy.m
//  OrigoApp
//
//  Created by Anders Blehr on 01.05.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OMembershipProxy.h"

NSString *kMembershipTypeRoot = @"~";
NSString *kMembershipTypeResidency = @"R";
NSString *kMembershipTypeParticipancy = @"P";
NSString *kMembershipTypeAssociate = @"A";

NSString *kMembershipStatusInvited = @"I";
NSString *kMembershipStatusWaiting = @"W";
NSString *kMembershipStatusActive = @"A";
NSString *kMembershipStatusRejected = @"R";
NSString *kMembershipStatusExpired = @"-";


@implementation OMembershipProxy

#pragma mark - Factory methods

+ (instancetype)proxyForMember:(id<OMember>)member inOrigo:(id<OOrigo>)origo
{
    NSString *meta = [origo isOfType:kOrigoTypeResidence] ? kMembershipTypeResidency : kMembershipTypeParticipancy;
    
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

- (BOOL)isFull
{
    return [self isParticipancy] || [self isResidency];
}


- (BOOL)isParticipancy
{
    return [[self valueForKey:kPropertyKeyType] isEqualToString:kMembershipTypeParticipancy];
}


- (BOOL)isResidency
{
    return [[self valueForKey:kPropertyKeyType] isEqualToString:kMembershipTypeResidency];
}


- (BOOL)isAssociate
{
    return [[self valueForKey:kPropertyKeyType] isEqualToString:kMembershipTypeAssociate];
}

@end
