//
//  OMembershipProxy.m
//  OrigoApp
//
//  Created by Anders Blehr on 01.05.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OMembershipProxy.h"

NSString * const kMembershipTypeRoot = @"~";
NSString * const kMembershipTypeResidency = @"R";
NSString * const kMembershipTypeParticipancy = @"P";
NSString * const kMembershipTypeAssociate = @"A";

NSString * const kMembershipStatusInvited = @"I";
NSString * const kMembershipStatusWaiting = @"W";
NSString * const kMembershipStatusActive = @"A";
NSString * const kMembershipStatusRejected = @"R";
NSString * const kMembershipStatusExpired = @"-";

NSString * const kRoleTypeMemberRole = @"M";
NSString * const kRoleTypeOrganiserRole = @"O";
NSString * const kRoleTypeParentRole = @"P";


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
