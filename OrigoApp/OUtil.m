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


@implementation OUtil

+ (BOOL)stringHoldsValidName:(NSString *)string
{
    BOOL holdsValidName = NO;
    
    if (string) {
        holdsValidName = ([string length] > 0);
        holdsValidName = holdsValidName && ([string rangeOfString:kSeparatorSpace].location > 0);
    }
    
    return holdsValidName;
}


+ (BOOL)stringHoldsValidEmailAddress:(NSString *)string
{
    BOOL holdsValidEmailAddress = NO;
    
    if (string) {
        NSUInteger atLocation = [string rangeOfString:@"@"].location;
        NSUInteger dotLocation = [string rangeOfString:@"." options:NSBackwardsSearch].location;
        NSUInteger spaceLocation = [string rangeOfString:@" "].location;
        
        holdsValidEmailAddress = (atLocation != NSNotFound);
        holdsValidEmailAddress = holdsValidEmailAddress && (dotLocation != NSNotFound);
        holdsValidEmailAddress = holdsValidEmailAddress && (dotLocation > atLocation);
        holdsValidEmailAddress = holdsValidEmailAddress && (spaceLocation == NSNotFound);
    }
    
    return holdsValidEmailAddress;
}


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
    
    if ([self stringHoldsValidName:fullName]) {
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
