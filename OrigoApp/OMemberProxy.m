//
//  OMemberProxy.m
//  OrigoApp
//
//  Created by Anders Blehr on 11.04.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OMemberProxy.h"


@implementation OMemberProxy

#pragma mark - OEntityProxy overrides

+ (instancetype)proxyForEntityOfClass:(Class)entityClass meta:(NSString *)meta
{
    id proxy = [super proxyForEntityOfClass:entityClass meta:meta];
    
    if ([meta isEqualToString:kTargetJuvenile]) {
        [proxy setValue:@YES forKey:kPropertyKeyIsMinor];
    }
    
    return proxy;
}


- (void)expire
{
    for (id<OMembership> membership in [self allMemberships]) {
        if ([membership isResidency] && ![membership.origo isReplicated]) {
            for (id<OMembership> coResidency in [membership.origo allMemberships]) {
                [[coResidency proxy] expire];
            }
            
            [[membership.origo proxy] expire];
        }
        
        [[membership proxy] expire];
    }
    
    [super expire];
}


#pragma mark - OMember protocol conformance

- (NSSet *)allMemberships
{
    NSMutableSet *allMemberships = [NSMutableSet set];
    
    if ([self instance]) {
        [allMemberships unionSet:[[self instance] allMemberships]];
    }
    
    for (id<OMembership> membership in [self cachedProxiesForEntityClass:[OMembership class]]) {
        if ([membership.member.entityId isEqualToString:self.entityId]) {
            [allMemberships addObject:membership];
        }
    }
    
    return allMemberships;
}


- (NSSet *)residencies
{
    id residencies = nil;
    
    if ([self instance]) {
        residencies = [[self instance] residencies];
    } else {
        residencies = [NSMutableSet set];
        
        for (id<OMembership> membership in [self allMemberships]) {
            if ([membership.type isEqualToString:kMembershipTypeResidency]) {
                [residencies addObject:membership];
            }
        }
    }
    
    return residencies;
}


- (id<OOrigo>)residence
{
    id<OOrigo> residence = nil;
    
    if ([self instance]) {
        residence = [[self instance] residence];
    } else {
        NSArray *residences = [self residences];
        
        if ([residences count]) {
            residence = residences[0];
        } else {
            residence = [OOrigoProxy proxyWithType:kOrigoTypeResidence];
            [residence addMember:self];
        }
    }
    
    return residence;
}


- (NSArray *)residences
{
    id residences = nil;
    
    if ([self instance]) {
        residences = [[self instance] residences];
    } else {
        residences = [NSMutableArray array];
        
        for (id<OMembership> residency in [self residencies]) {
            [residences addObject:residency.origo];
        }
    }
    
    return [self instance] ? residences : [residences sortedArrayUsingSelector:@selector(compare:)];
}


- (NSSet *)wards
{
    id wards = nil;
    
    if ([self instance]) {
        wards = [[self instance] wards];
    } else {
        wards = [NSMutableSet set];
        
        for (id<OMember> housemate in [self housemates]) {
            if ([housemate isJuvenile]) {
                [wards addObject:housemate];
            }
        }
    }
    
    return wards;
}


- (NSSet *)guardians
{
    id guardians = nil;
    
    if ([self instance]) {
        guardians = [[self instance] guardians];
    } else {
        guardians = [NSMutableSet set];
        
        for (id<OMember> housemate in [self housemates]) {
            if (![housemate isJuvenile]) {
                [guardians addObject:housemate];
            }
        }
    }
    
    return guardians;
}


- (NSArray *)housemates
{
    id housemates = nil;
    
    if ([self instance]) {
        housemates = [[self instance] housemates];
    } else {
        housemates = [NSMutableArray array];
        
        for (id<OOrigo> residence in [self residences]) {
            for (id<OMember> resident in [residence residents]) {
                if (resident != self) {
                    [housemates addObject:resident];
                }
            }
        }
    }
    
    return housemates;
}


- (BOOL)isActive
{
    return self.activeSince ? YES : NO;
}


- (BOOL)isManagedByUser
{
    return [self instance] ? [[self instance] isManagedByUser] : ![self isReplicated];
}


- (BOOL)isMale
{
    return [self instance] ? [[self instance] isMale] : [self.gender isEqualToString:kGenderMale];
}


- (BOOL)isJuvenile
{
    BOOL isJuvenile = NO;
    
    if ([self instance]) {
        isJuvenile = [[self instance] isJuvenile];
    } else {
        if (self.dateOfBirth) {
            isJuvenile = [self.dateOfBirth isBirthDateOfMinor];
        } else {
            isJuvenile = [self.isMinor boolValue];
        }
    }
    
    return isJuvenile;
}


- (BOOL)hasAddress
{
    BOOL hasAddress = NO;
    
    if ([self instance]) {
        hasAddress = [[self instance] hasAddress];
    } else {
        for (id<OOrigo> residence in [self residences]) {
            hasAddress = hasAddress || [residence hasAddress];
        }
    }
    
    return hasAddress;
}


- (NSString *)appellation
{
    return [self givenName];
}


- (NSString *)givenName
{
    return [self.name givenName];
}


- (NSString *)publicName
{
    return [self isJuvenile] ? [self givenName] : self.name;
}

@end
