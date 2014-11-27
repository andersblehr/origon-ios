//
//  OSettings+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OSettings+OrigoAdditions.h"

static NSString * const kCodedSettingKeySuffix = @"Code";


@implementation OSettings (OrigoAdditions)

#pragma mark - Auxiliary methods

- (BOOL)valueIsCodedForSettingKey:(NSString *)settingKey
{
    return NO;
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
    return codedValue;
}


#pragma mark - Instance access

+ (instancetype)settings
{
    OSettings *settings = nil;
    
    if ([OMeta m].user) {
        settings = [OMeta m].user.settings;
    
        if (!settings) {
            settings = [[OMeta m].context insertEntityOfClass:self inOrigo:[[OMeta m].user stash]];
            [OMeta m].user.settings = settings;
        }
    }
    
    return settings;
}


#pragma mark - Convenience methods

- (NSArray *)settingKeys
{
    return [NSArray array];
}


- (NSArray *)settingListKeys
{
    NSMutableArray *settingListKeys = [NSMutableArray array];
    
    BOOL hasHiddenOrigos = [[[OMeta m].user hiddenOrigos] count] > 0;
    
    if (!hasHiddenOrigos) {
        for (OMember *ward in [[OMeta m].user wards]) {
            hasHiddenOrigos = hasHiddenOrigos || [[ward hiddenOrigos] count] > 0;
        }
    }
    
    if (hasHiddenOrigos) {
        [settingListKeys addObject:kTargetHiddenOrigos];
    }
    
    if ([[[OMeta m].user registeredDevices] count] > 1) {
        [settingListKeys addObject:kTargetDevices];
    }
    
    return settingListKeys;
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
