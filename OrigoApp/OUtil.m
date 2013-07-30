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


+ (NSString *)collectiveAppellationForMemberList:(NSArray *)members
{
    NSMutableString *collectiveAppellation = nil;
    NSMutableArray *unsortedAppellations = [[NSMutableArray alloc] init];
    
    for (OMember *member in members) {
        [unsortedAppellations addObject:[member appellation]];
    }
    
    NSArray *sortedAppellations = [unsortedAppellations sortedArrayUsingSelector:@selector(localizedCompare:)];
    
    for (NSString *appellation in sortedAppellations) {
        if (!collectiveAppellation) {
            collectiveAppellation = [NSMutableString stringWithString:appellation];
        } else if ([sortedAppellations lastObject] == appellation) {
            [collectiveAppellation appendString:[OStrings stringForKey:strSeparatorAnd]];
            [collectiveAppellation appendString:appellation];
        } else {
            [collectiveAppellation appendString:kSeparatorComma];
            [collectiveAppellation appendString:appellation];
        }
    }
    
    return collectiveAppellation;
}


+ (NSString *)argumentWithABFormat:(NSString *)formatKey A:(NSString *)A B:(NSString *)B
{
    return [NSString stringWithFormat:[OStrings stringForKey:formatKey], A, B];
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
