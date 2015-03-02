//
//  OOrigoProxy.m
//  OrigoApp
//
//  Created by Anders Blehr on 20.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OOrigoProxy.h"

static NSString * const kPlaceholderStreet = @"{street}";
static NSString * const kPlaceholderCity = @"{city}";
static NSString * const kPlaceholderZip = @"{zip}";
static NSString * const kPlaceholderState = @"{state}";

static NSString * const kDefaultAddressTemplate = @"{street}\n{zip} {city}";
static NSString * const kAddressTemplatesByCountryCode =
        @"ES:{street}\n{zip} {city}\n{state};" \
        @"GB:{street}\n{city}\n{state} {zip};" \
        @"US|CA:{street}\n{city}, {state} {zip}";


@implementation OOrigoProxy

#pragma mark - Auxiliary methods

- (void)formatAddressFromAddressBookAddress:(CFDictionaryRef)address
{
    NSString *formattedAddress = kDefaultAddressTemplate;
    NSString *countryCode = [(NSString *)CFDictionaryGetValue(address, kABPersonAddressCountryCodeKey) uppercaseString];
    
    if (!countryCode) {
        countryCode = [NSLocale countryCode];
    }
    
    NSArray *mappings = [kAddressTemplatesByCountryCode componentsSeparatedByString:kSeparatorList];
    
    for (NSString *mapping in mappings) {
        NSArray *keysAndValue = [mapping componentsSeparatedByString:kSeparatorMapping];
        NSArray *countryCodes = [keysAndValue[0] componentsSeparatedByString:kSeparatorAlternates];
        
        for (NSString *countryCode in countryCodes) {
            if (!formattedAddress && [countryCode isEqualToString:countryCode]) {
                formattedAddress = keysAndValue[1];
            }
        }
    }
    
    formattedAddress = [formattedAddress stringByReplacingSubstring:kPlaceholderStreet withString:(NSString *)CFDictionaryGetValue(address, kABPersonAddressStreetKey)];
    formattedAddress = [formattedAddress stringByReplacingSubstring:kPlaceholderCity withString:(NSString *)CFDictionaryGetValue(address, kABPersonAddressCityKey)];
    formattedAddress = [formattedAddress stringByReplacingSubstring:kPlaceholderState withString:(NSString *)CFDictionaryGetValue(address, kABPersonAddressStateKey)];
    formattedAddress = [formattedAddress stringByReplacingSubstring:kPlaceholderZip withString:(NSString *)CFDictionaryGetValue(address, kABPersonAddressZIPKey)];
    
    self.address = [formattedAddress stringByRemovingRedundantWhitespaceKeepNewlines:YES];
    self.countryCode = countryCode;
}


#pragma mark - Selector implementations

- (NSComparisonResult)compare:(id<OOrigo>)other
{
    return [OUtil compareOrigo:self withOrigo:other];
}


#pragma mark - Initialisation

- (instancetype)initWithAddressBookAddress:(CFDictionaryRef)address
{
    self = [[self class] proxyForEntityOfClass:[OOrigo class] meta:kOrigoTypeResidence];
    
    if (self) {
        [self formatAddressFromAddressBookAddress:address];
    }
    
    return self;
}


#pragma mark - Factory methods

+ (instancetype)proxyWithType:(NSString *)type
{
    OOrigoProxy *proxy = [self proxyForEntityOfClass:[OOrigo class] meta:type];
    
    if ([proxy isResidence]) {
        proxy.name = kPlaceholderDefaultValue;
    }
    
    return proxy;
}


+ (instancetype)proxyFromAddressBookAddress:(CFDictionaryRef)address
{
    OOrigoProxy *proxy = [[self alloc] initWithAddressBookAddress:address];
    proxy.name = kPlaceholderDefaultValue;
    
    return proxy;
}


#pragma mark - OEntityProxy overrides

- (id)defaultValueForKey:(NSString *)key
{
    return [self instance] ? [[self instance] defaultValueForKey:key] : kPlaceholderDefaultValue;
}


- (void)expire
{
    for (id<OMembership> membership in [self allMemberships]) {
        [[membership proxy] expire];
    }
    
    [super expire];
}


#pragma mark - OOrigo protocol conformance

- (NSSet *)allMemberships
{
    NSMutableSet *allMemberships = [NSMutableSet set];
    
    if ([self instance]) {
        [allMemberships unionSet:[[self instance] allMemberships]];
    }
    
    for (id<OMembership> membership in [[self class] cachedProxiesForEntityClass:[OMembership class]]) {
        if ([membership.origo.entityId isEqualToString:self.entityId]) {
            [allMemberships addObject:membership];
        }
    }
    
    return allMemberships;
}


- (NSArray *)residents
{
    id residents = nil;

    if ([self instance]) {
        residents = [[self instance] residents];
    } else if ([self isResidence]) {
        if ([self isReplicated]) {
            residents = [NSMutableArray array];
            
            for (id<OMember> member in [self members]) {
                if (![member isJuvenile]) {
                    [residents addObject:member];
                }
            }
        } else {
            residents = [self members];
        }
    }
    
    return residents;
}


- (NSArray *)members
{
    id members = [NSMutableArray array];
    
    if ([self instance]) {
        members = [[self instance] members];
    } else {
        NSSet *memberships = [self allMemberships];
        
        if ([memberships count]) {
            for (id<OMembership> membership in memberships) {
                if (![membership isAssociate]) {
                    [members addObject:membership.member];
                }
            }
        } else if (![self isPrivate]) {
            [members addObject:[self ancestorConformingToProtocol:@protocol(OMember)]];
        }
        
        members = [members sortedArrayUsingSelector:@selector(compare:)];
    }
    
    return members;
}


- (NSArray *)regulars
{
    return [self instance] ? [[self instance] regulars] : [self members];
}


- (NSArray *)elders
{
    id elders = nil;
    
    if ([self instance]) {
        elders = [[self instance] elders];
    } else {
        elders = [NSMutableArray array];
        
        for (id<OMember> resident in [self residents]) {
            if (![resident isJuvenile]) {
                [elders addObject:resident];
            }
        }
    }
    
    return elders;
}


- (id<OMembership>)addMember:(id<OMember>)member
{
    id<OMembership> membership = nil;
    
    if ([self instance] && [member instance]) {
        membership = [[self instance] addMember:[member instance]];
    } else {
        member = [member proxy];
        membership = [self membershipForMember:member];
        
        if (!membership) {
            membership = [OMembershipProxy proxyForMember:member inOrigo:self];
        }
    }
    
    return membership;
}


- (id<OMembership>)membershipForMember:(id<OMember>)member
{
    id<OMembership> targetMembership = nil;
    
    if ([self instance] && [member instance]) {
        targetMembership = [[self instance] membershipForMember:[member instance]];
    } else {
        for (id<OMembership> membership in [self allMemberships]) {
            if (!targetMembership && [membership.member.entityId isEqualToString:member.entityId]) {
                targetMembership = membership;
            }
        }
    }
    
    return targetMembership;
}


- (BOOL)userIsAdmin
{
    return [self instance] ? [[self instance] userIsAdmin] : YES;
}


- (BOOL)userIsMember
{
    BOOL userIsMember = NO;
    
    if ([self instance]) {
        userIsMember = [[self instance] userIsMember];
    } else {
        userIsMember = [[self ancestorConformingToProtocol:@protocol(OMember)] isUser];
    }
    
    return userIsMember;
}


- (BOOL)isStash
{
    return [self isOfType:kOrigoTypeStash];
}


- (BOOL)isResidence
{
    return [self isOfType:kOrigoTypeResidence];
}


- (BOOL)isPrivate
{
    return [self isOfType:kOrigoTypePrivate];
}


- (BOOL)isCommunity
{
    return [self isOfType:kOrigoTypeCommunity];
}


- (BOOL)isOfType:(id)type
{
    BOOL isOfType = NO;
    
    if ([self instance]) {
        isOfType = [[self instance] isOfType:type];
    } else {
        if ([type isKindOfClass:[NSString class]]) {
            isOfType = [self.type isEqualToString:type];
        } else if ([type isKindOfClass:[NSArray class]]) {
            for (NSString *origoType in type) {
                isOfType = isOfType || [self isOfType:origoType];
            }
        }
    }
    
    return isOfType;
}


- (BOOL)isJuvenile
{
    BOOL isJuvenile = NO;
    
    if ([self instance]) {
        isJuvenile = [[self instance] isJuvenile];
    } else if (![self isResidence]) {
        isJuvenile = [[self ancestorConformingToProtocol:@protocol(OMember)] isJuvenile];
    }
    
    return isJuvenile;
}


- (BOOL)hasAddress
{
    return [self.address hasValue];
}


- (BOOL)hasTelephone
{
    return [self.telephone hasValue];
}


- (BOOL)hasMember:(id<OMember>)member
{
    BOOL hasMember = NO;
    
    if ([self instance] && [member instance]) {
        hasMember = [[self instance] hasMember:[member instance]];
    } else if (![self instance]) {
        hasMember = [[self members] containsObject:[member proxy]];
    }
    
    return hasMember;
}


- (NSString *)shortAddress
{
    return [self.address lines][0];
}

@end
