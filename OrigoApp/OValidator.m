//
//  OValidator.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OValidator.h"

static NSArray *_nameKeys = nil;
static NSArray *_dateKeys = nil;
static NSArray *_emailKeys = nil;
static NSArray *_phoneNumberKeys = nil;
static NSArray *_passwordKeys = nil;

static NSDictionary *_keyMappings = nil;

static NSInteger const kMinimumPassordLength = 6;
static NSInteger const kMinimumPhoneNumberLength = 5;


@implementation OValidator

#pragma mark - Key categorisation

+ (BOOL)isNameKey:(NSString *)key
{
    if (!_nameKeys) {
        _nameKeys = @[kPropertyKeyName, kInterfaceKeyResidenceName];
    }
    
    return [_nameKeys containsObject:key];
}


+ (BOOL)isAgeKey:(NSString *)key
{
    return [key isEqualToString:kPropertyKeyDateOfBirth];
}


+ (BOOL)isDateKey:(NSString *)key
{
    if (!_dateKeys) {
        _dateKeys = [NSArray array];
    }
    
    return [self isAgeKey:key] || [_dateKeys containsObject:key];
}


+ (BOOL)isEmailKey:(NSString *)key
{
    if (!_emailKeys) {
        _emailKeys = @[kInterfaceKeyAuthEmail, kPropertyKeyEmail];
    }
    
    return [_emailKeys containsObject:key];
}


+ (BOOL)isPhoneNumberKey:(NSString *)key
{
    if (!_phoneNumberKeys) {
        _phoneNumberKeys = @[kPropertyKeyMobilePhone, kPropertyKeyTelephone];
    }
    
    return [_phoneNumberKeys containsObject:key];
}


+ (BOOL)isPasswordKey:(NSString *)key
{
    if (!_passwordKeys) {
        _passwordKeys = @[kInterfaceKeyPassword, kInterfaceKeyRepeatPassword];
    }
    
    return [_passwordKeys containsObject:key];
}


+ (BOOL)isAlternatingLabelKey:(NSString *)key
{
    return [self isAgeKey:key];
}


+ (BOOL)isAlternatingInputFieldKey:(NSString *)key
{
    return [self isAlternatingLabelKey:key] || [self isPhoneNumberKey:key];
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
    return [[[self keyMappings] allKeys] containsObject:key] ? _keyMappings[key] : key;
}


#pragma mark - Validation

+ (BOOL)value:(id)value isValidForKey:(NSString *)key
{
    BOOL valueIsValid = NO;
    
    if (value) {
        NSString *propertyKey = [self propertyKeyForKey:key];
        
        if ([self isNameKey:propertyKey]) {
            valueIsValid = [self valueIsName:value];
        } else if ([self isDateKey:propertyKey]) {
            valueIsValid = YES;
        } else if ([self isPhoneNumberKey:propertyKey]) {
            valueIsValid = ([value length] >= kMinimumPhoneNumberLength);
        } else if ([self isEmailKey:propertyKey]) {
            valueIsValid = [self valueIsEmailAddress:value];
        } else if ([self isPasswordKey:propertyKey]) {
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
