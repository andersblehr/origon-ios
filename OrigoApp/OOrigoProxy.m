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
    
    [self facade].address = address;
    [self facade].countryCode = countryCode;
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
    return [self proxyForEntityOfClass:self type:type];
}


+ (instancetype)proxyFromAddressBookEntry:(CFDictionaryRef)entry
{
    return [[self alloc] initWithAddressBookEntry:entry];
}


#pragma mark - Informal OOrigo protocol conformance

- (BOOL)isOfType:(NSString *)type
{
    return [[self valueForKey:kPropertyKeyType] isEqualToString:type];
}


- (BOOL)hasAddress
{
    return ([self valueForKey:kPropertyKeyAddress] != nil);
}


- (NSString *)shortAddress
{
    return [[self valueForKey:kPropertyKeyAddress] lines][0];
}

@end
