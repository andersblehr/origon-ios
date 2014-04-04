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

- (void)formatAddressFromAddressBookDictionary:(CFDictionaryRef)dictionary
{
    NSString *address = kDefaultAddressTemplate;
    NSString *countryCode = [(NSString *)CFDictionaryGetValue(dictionary, kABPersonAddressCountryCodeKey) uppercaseString];
    
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
    
    address = [address stringByReplacingSubstring:kPlaceholderStreet withString:(NSString *)CFDictionaryGetValue(dictionary, kABPersonAddressStreetKey)];
    address = [address stringByReplacingSubstring:kPlaceholderCity withString:(NSString *)CFDictionaryGetValue(dictionary, kABPersonAddressCityKey)];
    address = [address stringByReplacingSubstring:kPlaceholderState withString:(NSString *)CFDictionaryGetValue(dictionary, kABPersonAddressStateKey)];
    address = [address stringByReplacingSubstring:kPlaceholderZip withString:(NSString *)CFDictionaryGetValue(dictionary, kABPersonAddressZIPKey)];
    
    [self setValue:address forKey:kPropertyKeyAddress];
    [self setValue:countryCode forKey:kPropertyKeyCountryCode];
}


#pragma mark - Initialisation

- (id)initWithAddressBookDictionary:(CFDictionaryRef)dictionary
{
    self = [super initWithEntityClass:[OOrigo class] type:kOrigoTypeResidence];
    
    if (self) {
        [self formatAddressFromAddressBookDictionary:dictionary];
    }
    
    return self;
}


#pragma mark - Custom accessors

//- (void)setTelephone:(NSString *)telephone
//{
//    [self setValue:telephone forKey:kPropertyKeyTelephone];
//}
//
//
//- (NSString *)telephone
//{
//    return [self valueForKey:kPropertyKeyTelephone];
//}


#pragma mark - Informal OOrigo protocol conformance

- (NSString *)shortAddress
{
    return [[self valueForKey:kPropertyKeyAddress] lines][0];
}

@end
