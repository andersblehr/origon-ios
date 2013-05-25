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

NSString * const kSettingKeyCountry = @"country";

static NSString * const kCodedSettingKeySuffix = @"Code";


@implementation OSettings (OrigoExtensions)

#pragma mark - Auxiliary methods

- (BOOL)valueIsCodedForSettingKey:(NSString *)settingKey
{
    return [settingKey isEqualToString:kSettingKeyCountry];
}


- (NSString *)decodedValueForSettingKey:(NSString *)settingKey
{
    NSString *codedSettingKey = [settingKey stringByAppendingString:kCodedSettingKeySuffix];
    NSString *codedValue = [self valueForKey:codedSettingKey];
    NSString *decodedValue = nil;
    
    if ([settingKey isEqualToString:kSettingKeyCountry]) {
        decodedValue = [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:codedValue];
    }
    
    return decodedValue;
}


#pragma mark - Convenience methods

- (NSArray *)settingKeys
{
    return @[kSettingKeyCountry];
}


- (NSString *)valueForSettingKey:(NSString *)settingKey
{
    NSString *value = nil;
    
    if ([self valueIsCodedForSettingKey:settingKey]) {
        value = [self decodedValueForSettingKey:settingKey];
    } else {
        value = [self valueForKey:settingKey];
    }
    
    return value;
}

@end
