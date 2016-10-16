//
//  OOrigoProxy.m
//  Origon
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
    self.location = countryCode;
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

+ (instancetype)residenceProxyUseDefaultName:(BOOL)useDefaultName
{
    OOrigoProxy *proxy = [self proxyForEntityOfClass:[OOrigo class] meta:kOrigoTypeResidence];
    
    if (useDefaultName) {
        proxy.name = kPlaceholderDefault;
    }
    
    return proxy;
}


+ (instancetype)residenceProxyFromAddress:(CFDictionaryRef)address
{
    OOrigoProxy *proxy = [[self alloc] initWithAddressBookAddress:address];
    proxy.name = kPlaceholderDefault;
    
    return proxy;
}


#pragma mark - OEntityProxy overrides

- (NSString *)inputCellReuseIdentifier
{
    return [[super inputCellReuseIdentifier] stringByAppendingString:self.type separator:kSeparatorHash];
}


- (id)instantiate
{
    OOrigo *instance = [super instantiate];
    instance.origoId = instance.entityId;
    
    return instance;
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
    id members = nil;
    
    if ([self instance]) {
        members = [[self instance] members];
    } else {
        members = [NSMutableArray array];
        NSSet *memberships = [self allMemberships];
        
        if (memberships.count) {
            for (id<OMembership> membership in memberships) {
                if (![membership isAssociate]) {
                    [members addObject:membership.member];
                }
            }
        } else if (![self isPrivate]) {
            id<OMember> member = [self ancestorConformingToProtocol:@protocol(OMember)];
            
            if ([self isCommunity]) {
                for (id<OMember> elder in [[member primaryResidence] elders]) {
                    [members addObject:elder];
                }
            } else {
                [members addObject:member];
            }
        }
        
        members = [members sortedArrayUsingSelector:@selector(compare:)];
    }
    
    return members;
}


- (NSArray *)regulars
{
    return [self instance] ? [[self instance] regulars] : [self members];
}


- (NSArray *)guardians
{
    id guardians = nil;
    
    if ([self instance]) {
        guardians = [[self instance] guardians];
    } else if ([self isJuvenile]) {
        guardians = [NSMutableSet set];
        
        for (id<OMember> member in [self members]) {
            [guardians addObjectsFromArray:[member guardians]];
        }
        
        guardians = [[guardians allObjects] sortedArrayUsingSelector:@selector(compare:)];
    }
    
    return guardians;
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


- (id<OMembership>)userMembership
{
    return [self membershipForMember:[OMeta m].user];
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


- (BOOL)isStandard
{
    return [self isOfType:kOrigoTypeStandard];
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


- (BOOL)isOrganised
{
    return [OUtil isOrganisedOrigowithType:self.type];
}


- (BOOL)isJuvenile
{
    BOOL isJuvenile = NO;
    
    if ([self instance]) {
        isJuvenile = [[self instance] isJuvenile];
    } else {
        if (self.isForMinors) {
            isJuvenile = [self.isForMinors boolValue];
        } else if (![self isResidence]) {
            isJuvenile = [[self ancestorConformingToProtocol:@protocol(OMember)] isJuvenile];
        }
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
    return [self hasAddress] ? [self.address lines][0] : OLocalizedString(@"-no address-", @"");
}

@end
