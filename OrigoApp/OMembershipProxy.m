//
//  OMembershipProxy.m
//  OrigoApp
//
//  Created by Anders Blehr on 01.05.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OMembershipProxy.h"

NSString *kMembershipTypeMemberRoot = @"~";
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
    NSString *type = [origo isOfType:kOrigoTypeResidence] ? kMembershipTypeResidency : kMembershipTypeParticipancy;
    
    OMembershipProxy *proxy = [self proxyForEntityOfClass:[OMembership class] type:type];
    proxy.member = member;
    proxy.origo = origo;
    
    [(NSMutableSet *)[member allMemberships] addObject:proxy];
    [(NSMutableSet *)[origo allMemberships] addObject:proxy];
    
    return proxy;
}


#pragma mark - OEntityProxy overrides

- (BOOL)isCommitted
{
    return ([self instance] != nil);
}


- (id)commit
{
    if (![self.member isCommitted]) {
        [self.member commit];
    }
    
    if (![self.origo isCommitted]) {
        [self.origo commit];
    }
    
    if (![self instance]) {
        [self useInstance:[[self.origo instance] addMember:[self.member instance]]];
    }
    
    return [self instance];
}


#pragma mark - OMembership protocol conformance

- (BOOL)isResidency
{
    return [[self valueForKey:kPropertyKeyType] isEqualToString:kMembershipTypeResidency];
}

@end
