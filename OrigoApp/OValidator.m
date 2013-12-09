//
//  OValidator.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OValidator.h"

NSString * const kDefaultsKeyAuthInfo = @"origo.auth.info";
NSString * const kDefaultsKeyDirtyEntities = @"origo.state.dirtyEntities";
NSString * const kDefaultsKeyStringDate = @"origo.strings.date";
NSString * const kDefaultsKeyStringLanguage = @"origo.strings.language";

NSString * const kJSONKeyActivationCode = @"activationCode";
NSString * const kJSONKeyDeviceId = @"deviceId";
NSString * const kJSONKeyEmail = @"email";
NSString * const kJSONKeyEntityClass = @"entityClass";
NSString * const kJSONKeyPasswordHash = @"passwordHash";

NSString * const kInterfaceKeyActivate = @"activate";
NSString * const kInterfaceKeyActivationCode = @"activationCode";
NSString * const kInterfaceKeyAuthEmail = @"authEmail";
NSString * const kInterfaceKeyPassword = @"password";
NSString * const kInterfaceKeyPurpose = @"purpose";
NSString * const kInterfaceKeyResidenceName = @"residenceName";
NSString * const kInterfaceKeyRepeatPassword = @"repeatPassword";
NSString * const kInterfaceKeySignIn = @"signIn";

NSString * const kPropertyKeyAddress = @"address";
NSString * const kPropertyKeyCountry = @"country";
NSString * const kPropertyKeyDateOfBirth = @"dateOfBirth";
NSString * const kPropertyKeyDescriptionText = @"descriptionText";
NSString * const kPropertyKeyEmail = @"email";
NSString * const kPropertyKeyEntityId = @"entityId";
NSString * const kPropertyKeyFatherId = @"fatherId";
NSString * const kPropertyKeyGender = @"gender";
NSString * const kPropertyKeyHashCode = @"hashCode";
NSString * const kPropertyKeyIsAwaitingDeletion = @"isAwaitingDeletion";
NSString * const kPropertyKeyIsExpired = @"isExpired";
NSString * const kPropertyKeyIsJuvenile = @"isJuvenile";
NSString * const kPropertyKeyMobilePhone = @"mobilePhone";
NSString * const kPropertyKeyMotherId = @"motherId";
NSString * const kPropertyKeyName = @"name";
NSString * const kPropertyKeyOrigoId = @"origoId";
NSString * const kPropertyKeyPasswordHash = @"passwordHash";
NSString * const kPropertyKeyTelephone = @"telephone";

NSString * const kRelationshipKeyMember = @"member";
NSString * const kRelationshipKeyOrigo = @"origo";

static NSArray *_nameKeys = nil;
static NSArray *_dateKeys = nil;
static NSArray *_emailKeys = nil;
static NSArray *_phoneNumberKeys = nil;
static NSArray *_passwordKeys = nil;
static NSArray *_defaultableKeys = nil;

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


+ (BOOL)isDefaultableKey:(NSString *)key
{
    if (!_defaultableKeys) {
        _defaultableKeys = @[kInterfaceKeyResidenceName];
    }
    
    return [_defaultableKeys containsObject:key];
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
    return [[[OValidator keyMappings] allKeys] containsObject:key] ? _keyMappings[key] : key;
}


#pragma mark - Default value for given key

+ (NSString *)defaultValueForKey:(NSString *)key
{
    id defaultValue = nil;
    
    if ([self isDefaultableKey:key]) {
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
    } else {
        valueIsValid = [self isDefaultableKey:key];
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
