//
//  OUtil.m
//  OrigoApp
//
//  Created by Anders Blehr on 26.05.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OUtil.h"

#import "NSString+OrigoExtensions.h"

#import "OMeta.h"
#import "OValidator.h"


@implementation OUtil

+ (BOOL)isSupportedCountryCode:(NSString *)countryCode
{
    return [[OMeta m].supportedCountryCodes containsObject:countryCode];
}


+ (NSString *)countryFromCountryCode:(NSString *)countryCode
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
        
        if ([OMeta m].shouldUseEasternNameOrder) {
            givenName = names[1];
        } else {
            givenName = names[0];
        }
    }
    
    return givenName;
}

@end
