//
//  OUtil.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OUtil.h"


@implementation OUtil

#pragma mark - Convenience methods

+ (BOOL)origoTypeIsJuvenile:(NSString *)origoType
{
    BOOL isJuvenile = NO;
    
    isJuvenile = isJuvenile || [origoType isEqualToString:kOrigoTypePreschoolClass];
    isJuvenile = isJuvenile || [origoType isEqualToString:kOrigoTypeSchoolClass];
    isJuvenile = isJuvenile || [origoType isEqualToString:kOrigoTypePlaymates];
    isJuvenile = isJuvenile || [origoType isEqualToString:kOrigoTypeMinorTeam];
    
    return isJuvenile;
}


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


+ (NSString *)givenNameFromFullName:(NSString *)fullName
{
    NSString *givenName = nil;
    
    if ([OValidator valueIsName:fullName]) {
        NSArray *names = [fullName componentsSeparatedByString:kSeparatorSpace];
        
        if ([[OMeta m] shouldUseEasternNameOrder]) {
            givenName = names[1];
        } else {
            givenName = names[0];
        }
    }
    
    return givenName;
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
