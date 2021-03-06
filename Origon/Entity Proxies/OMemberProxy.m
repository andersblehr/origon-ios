//
//  OMemberProxy.m
//  Origon
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


- (id)instantiate
{
    OMember *instance = [super instantiate];
    [instance stash];
    
    if (![instance isUser]) {
        id<OOrigo> baseOrigo = [OState s].baseOrigo;
        id<OMember> baseMember = [OState s].baseMember;
        
        if ([baseOrigo isPrivate]) {
            instance.createdIn = kOrigoTypePrivate;
            
            if ([baseMember isJuvenile] && [instance isJuvenile]) {
                instance.createdIn = [instance.createdIn stringByAppendingString:baseMember.givenName separator:kSeparatorList];
            }
        } else {
            instance.createdIn = [baseOrigo.entityId stringByAppendingString:[baseOrigo displayName] separator:kSeparatorList];
        }
    }
    
    return instance;
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
    
    for (id<OMembership> membership in [[self class] cachedProxiesForEntityClass:[OMembership class]]) {
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


- (id<OOrigo>)primaryResidence
{
    id<OOrigo> primaryResidence = nil;
    
    if ([self instance]) {
        primaryResidence = [[self instance] primaryResidence];
    } else {
        NSArray *residences = [self residences];
        
        if (residences.count) {
            primaryResidence = residences[0];
        } else {
            primaryResidence = [OOrigoProxy residenceProxyUseDefaultName:YES];
            [primaryResidence addMember:self];
        }
    }
    
    return primaryResidence;
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


- (NSArray *)addresses
{
    id addresses = nil;
    
    if ([self instance]) {
        addresses = [[self instance] addresses];
    } else {
        addresses = [NSMutableArray array];
        
        for (OOrigo *residence in [self residences]) {
            if ([residence hasAddress] || [residence hasTelephone]) {
                [addresses addObject:residence];
            }
        }
    }
    
    return [self instance] ? addresses : [addresses sortedArrayUsingSelector:@selector(compare:)];
}


- (NSArray *)wards
{
    id wards = nil;
    
    if ([self instance]) {
        wards = [[self instance] wards];
    } else {
        wards = [NSMutableArray array];
        
        for (id<OMember> housemate in [self housemates]) {
            if ([housemate isJuvenile]) {
                [wards addObject:housemate];
            }
        }
    }
    
    return wards;
}


- (NSArray *)guardians
{
    id guardians = nil;
    
    if ([self instance]) {
        guardians = [[self instance] guardians];
    } else {
        guardians = [NSMutableArray array];
        
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
        housemates = [NSMutableSet set];
        
        for (id<OOrigo> residence in [self residences]) {
            for (id<OMember> resident in [residence residents]) {
                if (resident != self) {
                    [housemates addObject:resident];
                }
            }
        }
        
        housemates = [[housemates allObjects] sortedArrayUsingSelector:@selector(compare:)];
    }
    
    return housemates;
}


- (BOOL)isActive
{
    return self.activeSince ? YES : NO;
}


- (BOOL)isWardOfUser
{
    return [self instance] ? [[self instance] isWardOfUser] : [self.dateOfBirth isBirthDateOfMinor];
}


- (BOOL)userCanEdit
{
    return [self instance] ? [[self instance] userCanEdit] : ![self isReplicated];
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


- (NSString *)givenName
{
    return [self.name givenName];
}


- (NSString *)displayNameInOrigo:(id<OOrigo>)origo
{
    return [self isJuvenile] ? [self givenName] : self.name;
}

@end
