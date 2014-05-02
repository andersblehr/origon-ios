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
    
    if (self.instance) {
        allMemberships = [self.instance allMemberships];
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
    
    if (self.instance) {
        residencies = [[self.instance residencies] mutableCopy];
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
    
    if (self.instance) {
        residence = [self.instance residence];
    } else {
        NSArray *residences = [self residences];
        
        if ([residences count]) {
            residence = residence[0];
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
    
    if (self.instance) {
        residences = [[self.instance residences] mutableCopy];
    } else {
        residences = [NSMutableArray array];
        
        for (id<OMembership> residency in [self residencies]) {
            [residences addObject:residency.origo];
        }
    }
    
    return self.instance ? residences : [residences sortedArrayUsingSelector:@selector(compare:)];
}


- (BOOL)isJuvenile
{
    BOOL isJuvenile = NO;
    
    if (self.instance) {
        isJuvenile = [self.instance isJuvenile];
    } else {
        NSDate *dateOfBirth = [self valueForKey:kPropertyKeyDateOfBirth];
        
        if (dateOfBirth) {
            isJuvenile = [dateOfBirth isBirthDateOfMinor];
        } else {
            isJuvenile = [[self valueForKey:kPropertyKeyIsMinor] boolValue];
        }
    }
    
    return isJuvenile;
}


- (NSString *)givenName
{
    return [OUtil givenNameFromFullName:[self valueForKey:kPropertyKeyName]];
}

@end
