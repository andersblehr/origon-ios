//
//  OValidator.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OValidator.h"

static NSArray *_nameKeys = nil;
static NSArray *_dateKeys = nil;
static NSArray *_emailKeys = nil;
static NSArray *_phoneNumberKeys = nil;
static NSArray *_passwordKeys = nil;
static NSArray *_inferredKeys = nil;
static NSArray *_keysWithDefaultValues = nil;

static NSDictionary *_keyMappings = nil;

static NSInteger const kMinimumPassordLength = 6;
static NSInteger const kMinimumPhoneNumberLength = 5;


@implementation OValidator

#pragma mark - Key categorisation

+ (NSArray *)nameKeys
{
    if (!_nameKeys) {
        _nameKeys = @[kPropertyKeyName, kInterfaceKeyResidenceName];
    }

    return _nameKeys;
}


+ (NSArray *)dateKeys
{
    if (!_dateKeys) {
        _dateKeys = @[kPropertyKeyDateOfBirth];
    }
    
    return _dateKeys;
}


+ (NSArray *)emailKeys
{
    if (!_emailKeys) {
        _emailKeys = @[kInterfaceKeyAuthEmail, kPropertyKeyEmail];
    }
    
    return _emailKeys;
}


+ (NSArray *)phoneNumberKeys
{
    if (!_phoneNumberKeys) {
        _phoneNumberKeys = @[kPropertyKeyMobilePhone, kPropertyKeyTelephone];
    }
    
    return _phoneNumberKeys;
}


+ (NSArray *)passwordKeys
{
    if (!_passwordKeys) {
        _passwordKeys = @[kInterfaceKeyPassword, kInterfaceKeyRepeatPassword];
    }
    
    return _passwordKeys;
}


+ (NSArray *)inferredKeys
{
    if (!_inferredKeys) {
        _inferredKeys = @[kInterfaceKeyAge];
    }
    
    return _inferredKeys;
}


#pragma mark - Key mapping

+ (NSDictionary *)keyMappings
{
    if (!_keyMappings) {
        _keyMappings = @{
            kInterfaceKeyResidenceName : kPropertyKeyName,
            kInterfaceKeyPurpose : kPropertyKeyDescriptionText
        };
    }
    
    return _keyMappings;
}


+ (NSString *)propertyKeyForKey:(NSString *)key
{
    return [[[OValidator keyMappings] allKeys] containsObject:key] ? _keyMappings[key] : key;
}


#pragma mark - Default value for given key

+ (NSString *)defaultValueForKey:(NSString *)key
{
    if (!_keysWithDefaultValues) {
        _keysWithDefaultValues = @[kInterfaceKeyResidenceName];
    }
    
    id defaultValue = nil;
    
    if ([_keysWithDefaultValues containsObject:key]) {
        defaultValue = [OStrings stringForKey:key withKeyPrefix:kKeyPrefixDefault];
    }
    
    return defaultValue;
}


#pragma mark - Validation

+ (BOOL)value:(id)value isValidForKey:(NSString *)key
{
    BOOL valueIsValid = NO;
    
    if (value) {
        NSString *propertyKey = [OValidator propertyKeyForKey:key];
        
        if ([[OValidator nameKeys] containsObject:propertyKey]) {
            valueIsValid = [self valueIsName:value];
        } else if ([[OValidator dateKeys] containsObject:propertyKey]) {
            valueIsValid = YES;
        } else if ([[OValidator phoneNumberKeys] containsObject:propertyKey]) {
            valueIsValid = ([value length] >= kMinimumPhoneNumberLength);
        } else if ([[OValidator emailKeys] containsObject:propertyKey]) {
            valueIsValid = [self valueIsEmailAddress:value];
        } else if ([[OValidator passwordKeys] containsObject:propertyKey]) {
            valueIsValid = ([value length] >= kMinimumPassordLength);
        }
    }
    
    return valueIsValid;
}


+ (BOOL)valueIsEmailAddress:(id)value
{
    BOOL valueIsEmailAddress = NO;
    
    if (value && [value isKindOfClass:[NSString class]]) {
        NSInteger atLocation = [value rangeOfString:@"@"].location;
        NSInteger dotLocation = [value rangeOfString:@"." options:NSBackwardsSearch].location;
        NSInteger spaceLocation = [value rangeOfString:@" "].location;
        
        valueIsEmailAddress = (atLocation != NSNotFound);
        valueIsEmailAddress = valueIsEmailAddress && (dotLocation != NSNotFound);
        valueIsEmailAddress = valueIsEmailAddress && (dotLocation > atLocation);
        valueIsEmailAddress = valueIsEmailAddress && (spaceLocation == NSNotFound);
    }
    
    return valueIsEmailAddress;
}


+ (BOOL)valueIsName:(id)value
{
    BOOL valueIsName = NO;
    
    if ([value isKindOfClass:[NSString class]]) {
        valueIsName = [value hasValue];
        
        if ([[OState s].viewController.identifier isEqualToString:kIdentifierMember]) {
            valueIsName = valueIsName && ([value rangeOfString:kSeparatorSpace].location > 0);
        }
    }
    
    return valueIsName;
}

@end
