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

+ (instancetype)proxyForEntityOfClass:(Class)entityClass type:(NSString *)type
{
    id proxy = [super proxyForEntityOfClass:entityClass type:type];
    
    if ([type isEqualToString:kTargetJuvenile]) {
        [proxy setValue:@YES forKeyPath:kPropertyKeyIsMinor];
    }
    
    return proxy;
}


#pragma mark - OMember protocol conformance

- (NSSet *)allMemberships
{
    NSSet *allMemberships = nil;
    
    if ([self instance]) {
        allMemberships = [[self instance] allMemberships];
    } else {
        if (![self hasValueForKey:kRelationshipKeyMemberships]) {
            [self setValue:[NSMutableSet set] forKey:kRelationshipKeyMemberships];
        }
        
        allMemberships = [self valueForKey:kRelationshipKeyMemberships];
    }
    
    return allMemberships;
}


- (NSSet *)residencies
{
    NSMutableSet *residencies = nil;
    
    if ([self instance]) {
        residencies = [[[self instance] residencies] mutableCopy];
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
    NSMutableArray *residences = nil;
    
    if ([self instance]) {
        residences = [[[self instance] residences] mutableCopy];
    } else {
        residences = [NSMutableArray array];
        
        for (id<OMembership> residency in [self residencies]) {
            [residences addObject:residency.origo];
        }
    }
    
    return [self instance] ? residences : [residences sortedArrayUsingSelector:@selector(compare:)];
}


- (NSSet *)guardians
{
    NSMutableSet *guardians = nil;
    
    if ([self instance]) {
        guardians = [[[self instance] guardians] mutableCopy];
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


- (NSSet *)housemates
{
    NSMutableSet *housemates = nil;
    
    if ([self instance]) {
        housemates = [[[self instance] housemates] mutableCopy];
    } else {
        housemates = [NSMutableSet set];
        
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
    return [OUtil givenNameFromFullName:self.name];
}

@end
