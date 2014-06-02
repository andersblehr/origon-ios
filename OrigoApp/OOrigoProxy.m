//
//  OOrigoProxy.m
//  OrigoApp
//
//  Created by Anders Blehr on 20.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OOrigoProxy.h"

NSString * const kOrigoTypeRoot = @"~";
NSString * const kOrigoTypeResidence = @"residence";
NSString * const kOrigoTypeFriends = @"friends";
NSString * const kOrigoTypeTeam = @"team";
NSString * const kOrigoTypeOrganisation = @"organisation";
NSString * const kOrigoTypeOther = @"other";
NSString * const kOrigoTypePreschoolClass = @"preschoolClass";
NSString * const kOrigoTypeSchoolClass = @"schoolClass";

NSString * const kContactRoleTeacher = @"teacher";
NSString * const kContactRoleTopicTeacher = @"topicTeacher";
NSString * const kContactRoleSpecialEducationTeacher = @"specialEducationTeacher";
NSString * const kContactRoleAssistantTeacher = @"assistantTeacher";
NSString * const kContactRoleHeadTeacher = @"headTeacher";
NSString * const kContactRoleChair = @"chair";
NSString * const kContactRoleDeputyChair = @"deputyChair";
NSString * const kContactRoleTreasurer = @"treasurer";
NSString * const kContactRoleCoach = @"coach";
NSString * const kContactRoleAssistantCoach = @"assistantCoach";

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
    
    self.address = formattedAddress;
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
    return [self proxyForEntityOfClass:[OOrigo class] meta:type];
}


+ (instancetype)proxyFromAddressBookAddress:(CFDictionaryRef)address
{
    return [[self alloc] initWithAddressBookAddress:address];
}


#pragma mark - OOrigo protocol conformance

- (NSSet *)allMemberships
{
    NSMutableSet *allMemberships = [NSMutableSet set];
    
    if ([self instance]) {
        [allMemberships unionSet:[[self instance] allMemberships]];
    }
    
    for (id<OMembership> membership in [self cachedProxiesForEntityClass:[OMembership class]]) {
        if ([membership.origo.entityId isEqualToString:self.entityId]) {
            [allMemberships addObject:membership];
        }
    }
    
    return allMemberships;
}


- (NSSet *)residents
{
    NSSet *residents = nil;

    if ([self isOfType:kOrigoTypeResidence]) {
        if ([self instance]) {
            residents = [[self instance] residents];
        } else {
            residents = [self members];
        }
    }
    
    return residents;
}


- (NSSet *)members
{
    id members = [NSMutableSet set];
    
    if ([self instance]) {
        members = [[self instance] members];
    } else {
        for (id<OMembership> membership in [self allMemberships]) {
            if ([membership isFull]) {
                [members addObject:membership.member];
            }
        }
    }
    
    return members;
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


- (BOOL)userCanEdit
{
    return [self instance] ? [[self instance] userCanEdit] : YES;
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


- (BOOL)isOfType:(NSString *)type
{
    return [self.type isEqualToString:type];
}


- (BOOL)isJuvenile
{
    BOOL isJuvenile = NO;
    
    if ([self instance]) {
        isJuvenile = [[self instance] isJuvenile];
    } else {
        isJuvenile = [[self ancestorConformingToProtocol:@protocol(OMember)] isJuvenile];
    }
    
    return isJuvenile;
}


- (BOOL)hasAddress
{
    return [self.address hasValue];
}


- (NSString *)shortAddress
{
    return [self.address lines][0];
}

@end
