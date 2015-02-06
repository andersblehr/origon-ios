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

static NSArray *_nameKeys = nil;
static NSArray *_dateKeys = nil;
static NSArray *_emailKeys = nil;
static NSArray *_phoneNumberKeys = nil;
static NSArray *_passwordKeys = nil;
static NSArray *_defaultableKeys = nil;

static NSDictionary *_keyMappings = nil;


@implementation OValidator

#pragma mark - Key categorisation

+ (BOOL)isNameKey:(NSString *)key
{
    if (!_nameKeys) {
        _nameKeys = @[kPropertyKeyName, kMappedKeyFullName, kMappedKeyResidenceName];
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
        _dateKeys = @[kPropertyKeyActiveSince, kPropertyKeyDateCreated, kPropertyKeyDateExpires, kPropertyKeyDateReplicated, kPropertyKeyLastSeen];
    }
    
    return [self isAgeKey:key] || [_dateKeys containsObject:key];
}


+ (BOOL)isEmailKey:(NSString *)key
{
    if (!_emailKeys) {
        _emailKeys = @[kExternalKeyAuthEmail, kPropertyKeyEmail];
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
        _passwordKeys = @[kExternalKeyPassword, kExternalKeyRepeatPassword, kExternalKeyOldPassword, kExternalKeyNewPassword, kExternalKeyRepeatNewPassword];
    }
    
    return [_passwordKeys containsObject:key];
}


+ (BOOL)isAlternatingLabelKey:(NSString *)key
{
    return [self isAgeKey:key];
}


+ (BOOL)isAlternatingInputFieldKey:(NSString *)key
{
    return [self isAgeKey:key] || [self isPhoneNumberKey:key];
}


+ (BOOL)isDefaultableKey:(NSString *)key
{
    if (!_defaultableKeys) {
        _defaultableKeys = @[kMappedKeyResidenceName, kMappedKeyListName];
    }
    
    return [_defaultableKeys containsObject:key];
}


#pragma mark - Key indirection

+ (NSDictionary *)referenceForEntity:(id<OEntity>)entity
{
    NSMutableDictionary *reference = [NSMutableDictionary dictionary];
    
    reference[kExternalKeyEntityClass] = NSStringFromClass(entity.entityClass);
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
    return [NSString stringWithFormat:@"%@Ref", key];
}


+ (NSString *)unmappedKeyForKey:(NSString *)key
{
    if (!_keyMappings) {
        _keyMappings = @{
            kMappedKeyClub : kPropertyKeyDescriptionText,
            kMappedKeyFullName : kPropertyKeyName,
            kMappedKeyInstitution : kPropertyKeyDescriptionText,
            kMappedKeyListName : kPropertyKeyName,
            kMappedKeyPreschoolClass : kPropertyKeyName,
            kMappedKeyPreschool : kPropertyKeyDescriptionText,
            kMappedKeyResidenceName : kPropertyKeyName,
            kMappedKeySchool : kPropertyKeyDescriptionText,
            kMappedKeySchoolClass : kPropertyKeyName,
            kMappedKeyStudyGroup : kPropertyKeyName,
            kMappedKeyTeam : kPropertyKeyName,
        };
    }
    
    return [[_keyMappings allKeys] containsObject:key] ? _keyMappings[key] : key;
}


#pragma mark - Validation

+ (BOOL)value:(id)value isValidForKey:(NSString *)key
{
    BOOL valueIsValid = NO;
    
    if (value) {
        key = [self unmappedKeyForKey:key];
        
        if ([self isNameKey:key]) {
            valueIsValid = [self isNameValue:value];
        } else if ([self isDateKey:key]) {
            valueIsValid = YES;
        } else if ([self isPhoneNumberKey:key]) {
            valueIsValid = [value length] >= kMinimumPhoneNumberLength;
        } else if ([self isEmailKey:key]) {
            valueIsValid = [self isEmailValue:value];
        } else if ([self isPasswordKey:key]) {
            valueIsValid = [value length] >= kMinimumPassordLength;
            
            if (!valueIsValid) {
                [OAlert showAlertWithTitle:NSLocalizedString(@"Password too short", @"") text:[NSString stringWithFormat:NSLocalizedString(@"The password must be at least %@ characters long.", @""), @(kMinimumPassordLength)]];
            }
        } else {
            valueIsValid = [value hasValue];
        }
    }
    
    return valueIsValid;
}


+ (BOOL)isEmailValue:(id)value
{
    BOOL isEmailValue = NO;
    
    if (value && [value isKindOfClass:[NSString class]]) {
        NSInteger atLocation = [value rangeOfString:@"@"].location;
        NSInteger dotLocation = [value rangeOfString:@"." options:NSBackwardsSearch].location;
        NSInteger spaceLocation = [value rangeOfString:@" "].location;
        
        isEmailValue = atLocation != NSNotFound;
        isEmailValue = isEmailValue && dotLocation != NSNotFound;
        isEmailValue = isEmailValue && dotLocation > atLocation;
        isEmailValue = isEmailValue && spaceLocation == NSNotFound;
    }
    
    return isEmailValue;
}


+ (BOOL)isNameValue:(id)value
{
    BOOL isName = NO;
    
    if ([value isKindOfClass:[NSString class]]) {
        isName = [value hasValue];
        
        if ([[OState s].viewController.identifier isEqualToString:kIdentifierMember]) {
            isName = isName && [value rangeOfString:kSeparatorSpace].location != NSNotFound;
        }
    }
    
    return isName;
}

@end
