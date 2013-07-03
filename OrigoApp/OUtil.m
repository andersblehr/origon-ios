//
//  OUtil.m
//  OrigoApp
//
//  Created by Anders Blehr on 26.05.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OUtil.h"

#import "NSDate+OrigoExtensions.h"
#import "NSString+OrigoExtensions.h"

#import "OLogging.h"
#import "OMeta.h"


@implementation OUtil

#pragma mark - Convenience methods

+ (BOOL)isSupportedCountryCode:(NSString *)countryCode
{
    return [[[OMeta m] supportedCountryCodes] containsObject:countryCode];
}


+ (NSString *)localisedCountryNameFromCountryCode:(NSString *)countryCode
{
    NSString *country = nil;
    
    if (countryCode) {
        country = [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:countryCode];
    }
    
    return country;
}


+ (NSString *)sortKeyWithPropertyKey:(NSString *)propertyKey relationshipKey:(NSString *)relationshipKey
{
    NSString *sortKey = nil;
    
    if (relationshipKey) {
        sortKey = [NSString stringWithFormat:@"%@.%@", relationshipKey, propertyKey];
    } else {
        sortKey = propertyKey;
    }
    
    return sortKey;
}

@end
