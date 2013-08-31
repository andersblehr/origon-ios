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
static NSArray *_phoneKeys = nil;
static NSArray *_emailKeys = nil;
static NSArray *_passwordKeys = nil;
static NSArray *_inferredKeys = nil;

static NSDictionary *_keyMappings = nil;

static NSInteger const kMinimumPassordLength = 6;
static NSInteger const kMinimumPhoneNumberLength = 5;


@implementation OValidator

#pragma mark - Key categorisation

+ (NSArray *)nameKeys
{
    if (!_nameKeys) {
        _nameKeys = @[kPropertyKeyName];
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


+ (NSArray *)phoneKeys
{
    if (!_phoneKeys) {
        _phoneKeys = @[kPropertyKeyMobilePhone, kPropertyKeyTelephone];
    }
    
    return _phoneKeys;
}


+ (NSArray *)emailKeys
{
    if (!_emailKeys) {
        _emailKeys = @[kInterfaceKeyAuthEmail, kPropertyKeyEmail];
    }
    
    return _emailKeys;
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

+ (NSString *)propertyKeyForKey:(NSString *)key
{
    if (!_keyMappings) {
        _keyMappings = @{kInterfaceKeyPurpose : kPropertyKeyDescriptionText};
    }
    
    return [[_keyMappings allKeys] containsObject:key] ? _keyMappings[key] : key;
}


#pragma mark - Validation

+ (BOOL)value:(id)value isValidForKey:(NSString *)key
{
    BOOL valueIsValid = NO;
    
    if (value) {
        if ([[OValidator nameKeys] containsObject:key]) {
            valueIsValid = [self valueIsName:value];
        } else if ([[OValidator dateKeys] containsObject:key]) {
            valueIsValid = YES;
        } else if ([[OValidator phoneKeys] containsObject:key]) {
            valueIsValid = ([value length] >= kMinimumPhoneNumberLength);
        } else if ([[OValidator emailKeys] containsObject:key]) {
            valueIsValid = [self valueIsEmailAddress:value];
        } else if ([[OValidator passwordKeys] containsObject:key]) {
            valueIsValid = ([value length] >= kMinimumPassordLength);
        }
    }
    
    return valueIsValid;
}


+ (BOOL)valueIsEmailAddress:(id)value
{
    BOOL valueIsEmailAddress = NO;
    
    if (value && [value isKindOfClass:NSString.class]) {
        NSUInteger atLocation = [value rangeOfString:@"@"].location;
        NSUInteger dotLocation = [value rangeOfString:@"." options:NSBackwardsSearch].location;
        NSUInteger spaceLocation = [value rangeOfString:@" "].location;
        
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
    
    if ([value isKindOfClass:NSString.class]) {
        valueIsName = [value hasValue];
        valueIsName = valueIsName && ([value rangeOfString:kSeparatorSpace].location > 0);
    }
    
    return valueIsName;
}

@end
