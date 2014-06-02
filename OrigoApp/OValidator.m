//
//  OValidator.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OValidator.h"

static NSInteger const kMinimumPassordLength = 6;
static NSInteger const kMinimumPhoneNumberLength = 5;

static NSString * const kReferenceKeyFormat = @"%@Ref";

static NSArray *_nameKeys = nil;
static NSArray *_dateKeys = nil;
static NSArray *_emailKeys = nil;
static NSArray *_phoneNumberKeys = nil;
static NSArray *_passwordKeys = nil;

static NSDictionary *_keyMappings = nil;


@implementation OValidator

#pragma mark - Key categorisation

+ (BOOL)isNameKey:(NSString *)key
{
    if (!_nameKeys) {
        _nameKeys = @[kPropertyKeyName, kUnboundKeyResidenceName];
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
        _dateKeys = @[kPropertyKeyActiveSince, kPropertyKeyDateCreated, kPropertyKeyDateExpires, kPropertyKeyDateReplicated];
    }
    
    return [self isAgeKey:key] || [_dateKeys containsObject:key];
}


+ (BOOL)isEmailKey:(NSString *)key
{
    if (!_emailKeys) {
        _emailKeys = @[kUnboundKeyAuthEmail, kPropertyKeyEmail];
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
        _passwordKeys = @[kUnboundKeyPassword, kUnboundKeyRepeatPassword];
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


#pragma mark - Key indirection

+ (NSDictionary *)referenceForEntity:(id<OEntity>)entity
{
    NSMutableDictionary *reference = [NSMutableDictionary dictionary];
    
    reference[kUnboundKeyEntityClass] = NSStringFromClass(entity.entityClass);
    reference[kPropertyKeyEntityId] = entity.entityId;
    
    if ([entity conformsToProtocol:@protocol(OMember)]) {
        NSString *email = [entity valueForKey:kPropertyKeyEmail];
        
        if (email) {
            reference[kPropertyKeyEmail] = email;
        }
    }
    
    return reference;
}


+ (NSString *)referenceKeyForKey:(NSString *)key
{
    return [NSString stringWithFormat:kReferenceKeyFormat, key];
}


+ (NSString *)propertyKeyForKey:(NSString *)key
{
    if (!_keyMappings) {
        _keyMappings = @{
            kUnboundKeyGivenName : kPropertyKeyName,
            kUnboundKeyPurpose : kPropertyKeyDescriptionText,
            kUnboundKeyResidenceName : kPropertyKeyName
        };
    }
    
    return [[_keyMappings allKeys] containsObject:key] ? _keyMappings[key] : key;
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
