//
//  OAddressFacade.m
//  OrigoApp
//
//  Created by Anders Blehr on 20.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OAddressFacade.h"

static NSString * const kPlaceholderStreet = @"{street}";
static NSString * const kPlaceholderCity = @"{city}";
static NSString * const kPlaceholderZip = @"{zip}";
static NSString * const kPlaceholderState = @"{state}";

static NSString * const kDefaultAddressTemplate = @"{street}\n{zip} {city}";
static NSString * const kAddressTemplatesByCountryCode =
        @"US|CA:{street}\n{city}, {state} {zip};" \
        @"GB:{street}\n{city}\n{state} {zip}";


@implementation OAddressFacade

#pragma mark - Auxiliary methods

- (void)formatAddressFromAddressBookDictionary:(CFDictionaryRef)dictionary
{
    _countryCode = [(NSString *)CFDictionaryGetValue(dictionary, kABPersonAddressCountryCodeKey) uppercaseString];
    
    if (!_countryCode) {
        _countryCode = [NSLocale countryCode];
    }
    
    NSArray *mappings = [kAddressTemplatesByCountryCode componentsSeparatedByString:kSeparatorList];
    
    for (NSString *mapping in mappings) {
        NSArray *keysAndValue = [mapping componentsSeparatedByString:kSeparatorMapping];
        NSArray *countryCodes = [keysAndValue[0] componentsSeparatedByString:kSeparatorAlternates];
        
        for (NSString *countryCode in countryCodes) {
            if (!_address && [countryCode isEqualToString:_countryCode]) {
                _address = keysAndValue[1];
            }
        }
    }
    
    if (!_address) {
        _address = kDefaultAddressTemplate;
    }

    _address = [_address stringByReplacingSubstring:kPlaceholderStreet withString:(NSString *)CFDictionaryGetValue(dictionary, kABPersonAddressStreetKey)];
    _address = [_address stringByReplacingSubstring:kPlaceholderCity withString:(NSString *)CFDictionaryGetValue(dictionary, kABPersonAddressCityKey)];
    _address = [_address stringByReplacingSubstring:kPlaceholderState withString:(NSString *)CFDictionaryGetValue(dictionary, kABPersonAddressStateKey)];
    _address = [_address stringByReplacingSubstring:kPlaceholderZip withString:(NSString *)CFDictionaryGetValue(dictionary, kABPersonAddressZIPKey)];
    
    _shortAddress = [_address lines][0];
}


#pragma mark - Initialisation

- (id)initWithAddressBookDictionary:(CFDictionaryRef)dictionary
{
    self = [super init];
    
    if (self) {
        [self formatAddressFromAddressBookDictionary:dictionary];
    }
    
    return self;
}

@end
