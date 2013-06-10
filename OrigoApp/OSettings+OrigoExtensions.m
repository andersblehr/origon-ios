//
//  OSettings+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 15.05.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OSettings+OrigoExtensions.h"

#import "OLocator.h"
#import "OMeta.h"
#import "OStrings.h"
#import "OUtil.h"

NSString * const kSettingKeyCountry = @"country";

static NSString * const kCodedSettingKeySuffix = @"Code";


@implementation OSettings (OrigoExtensions)

#pragma mark - Auxiliary methods

- (BOOL)valueIsCodedForSettingKey:(NSString *)settingKey
{
    return [settingKey isEqualToString:kSettingKeyCountry];
}


- (NSString *)normalisedKeyForSettingKey:(NSString *)settingKey
{
    NSString *normalisedKey = nil;
    
    if ([self valueIsCodedForSettingKey:settingKey]) {
        normalisedKey = [settingKey stringByAppendingString:kCodedSettingKeySuffix];
    } else {
        normalisedKey = settingKey;
    }
    
    return normalisedKey;
}


- (id)decodeCodedValue:(NSString *)codedValue forSettingKey:(NSString *)settingKey
{
    id decodedValue = codedValue;
    
    if ([settingKey isEqualToString:kSettingKeyCountry]) {
        NSString *country = [OUtil countryFromCountryCode:codedValue];
        
        if ([[OMeta m].supportedCountryCodes containsObject:codedValue]) {
            decodedValue = country;
        } else {
            decodedValue = [NSString stringWithFormat:@"(%@)", country];
        }
    }
    
    return decodedValue;
}


#pragma mark - Convenience methods

- (NSArray *)settingKeys
{
    return @[kSettingKeyCountry];
}


- (void)setValue:(id)value forSettingKey:(NSString *)settingKey
{
    [self setValue:value forKey:[self normalisedKeyForSettingKey:settingKey]];
}


- (id)valueForSettingKey:(NSString *)settingKey
{
    return [self valueForKey:[self normalisedKeyForSettingKey:settingKey]];
}


- (id)displayValueForSettingKey:(NSString *)settingKey
{
    id value = [self valueForSettingKey:settingKey];
    
    if ([self valueIsCodedForSettingKey:settingKey]) {
        value = [self decodeCodedValue:value forSettingKey:settingKey];
    }
    
    return value;
}

@end
