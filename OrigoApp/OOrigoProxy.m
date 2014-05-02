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

- (void)formatAddressFromAddressBookEntry:(CFDictionaryRef)entry
{
    NSString *address = kDefaultAddressTemplate;
    NSString *countryCode = [(NSString *)CFDictionaryGetValue(entry, kABPersonAddressCountryCodeKey) uppercaseString];
    
    if (!countryCode) {
        countryCode = [NSLocale countryCode];
    }
    
    NSArray *mappings = [kAddressTemplatesByCountryCode componentsSeparatedByString:kSeparatorList];
    
    for (NSString *mapping in mappings) {
        NSArray *keysAndValue = [mapping componentsSeparatedByString:kSeparatorMapping];
        NSArray *countryCodes = [keysAndValue[0] componentsSeparatedByString:kSeparatorAlternates];
        
        for (NSString *countryCode in countryCodes) {
            if (!address && [countryCode isEqualToString:countryCode]) {
                address = keysAndValue[1];
            }
        }
    }
    
    address = [address stringByReplacingSubstring:kPlaceholderStreet withString:(NSString *)CFDictionaryGetValue(entry, kABPersonAddressStreetKey)];
    address = [address stringByReplacingSubstring:kPlaceholderCity withString:(NSString *)CFDictionaryGetValue(entry, kABPersonAddressCityKey)];
    address = [address stringByReplacingSubstring:kPlaceholderState withString:(NSString *)CFDictionaryGetValue(entry, kABPersonAddressStateKey)];
    address = [address stringByReplacingSubstring:kPlaceholderZip withString:(NSString *)CFDictionaryGetValue(entry, kABPersonAddressZIPKey)];
    
    self.address = address;
    self.countryCode = countryCode;
}


#pragma mark - Selector implementations

- (NSComparisonResult)compare:(id<OOrigo>)other
{
    return [OUtil compareOrigo:self withOrigo:other];
}


#pragma mark - Initialisation

- (instancetype)initWithAddressBookEntry:(CFDictionaryRef)entry
{
    self = [[self class] proxyForEntityOfClass:[OOrigo class] type:kOrigoTypeResidence];
    
    if (self) {
        [self formatAddressFromAddressBookEntry:entry];
    }
    
    return self;
}


#pragma mark - Factory methods

+ (instancetype)proxyWithType:(NSString *)type
{
    return [self proxyForEntityOfClass:[OOrigo class] type:type];
}


+ (instancetype)proxyFromAddressBookEntry:(CFDictionaryRef)entry
{
    return [[self alloc] initWithAddressBookEntry:entry];
}


#pragma mark - OOrigo protocol conformance

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


- (id<OMembership>)addMember:(id<OMember>)member
{
    id<OMembership> membership = nil;
    
    if (self.instance) {
        membership = [self.instance addMember:member];
    } else {
        membership = [self membershipForMember:member];
        
        if (!membership) {
            membership = [OMembershipProxy proxyForMember:member inOrigo:self];
        }
    }
    
    return membership;
}


- (id<OMembership>)membershipForMember:(id<OMember>)member
{
    id<OMembership> membershipForMember = nil;
    
    if (self.instance) {
        membershipForMember = [self.instance membershipForMember:member];
    } else {
        for (id<OMembership> membership in [self allMemberships]) {
            if (!membership && [membership.member.entityId isEqualToString:member.entityId]) {
                membershipForMember = membership;
            }
        }
    }
    
    return membershipForMember;
}


- (BOOL)userIsMember
{
    return [[self ancestorConformingToProtocol:@protocol(OMember)] isUser];
}


- (BOOL)isOfType:(NSString *)type
{
    return [[self valueForKey:kPropertyKeyType] isEqualToString:type];
}


- (BOOL)hasAddress
{
    return [self hasValueForKey:kPropertyKeyAddress];
}


- (NSString *)shortAddress
{
    return [[self valueForKey:kPropertyKeyAddress] lines][0];
}

@end
