//
//  OValidator.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern NSString * const kDefaultsKeyAuthInfo;
extern NSString * const kDefaultsKeyDirtyEntities;
extern NSString * const kDefaultsKeyStringDate;
extern NSString * const kDefaultsKeyStringLanguage;

extern NSString * const kJSONKeyActivationCode;
extern NSString * const kJSONKeyDeviceId;
extern NSString * const kJSONKeyEmail;
extern NSString * const kJSONKeyEntityClass;
extern NSString * const kJSONKeyPasswordHash;

extern NSString * const kInterfaceKeyActivate;
extern NSString * const kInterfaceKeyActivationCode;
extern NSString * const kInterfaceKeyAuthEmail;
extern NSString * const kInterfaceKeyPassword;
extern NSString * const kInterfaceKeyPurpose;
extern NSString * const kInterfaceKeyRepeatPassword;
extern NSString * const kInterfaceKeyResidenceName;
extern NSString * const kInterfaceKeySignIn;

extern NSString * const kPropertyKeyAddress;
extern NSString * const kPropertyKeyCountry;
extern NSString * const kPropertyKeyDateOfBirth;
extern NSString * const kPropertyKeyDescriptionText;
extern NSString * const kPropertyKeyEmail;
extern NSString * const kPropertyKeyEntityId;
extern NSString * const kPropertyKeyFatherId;
extern NSString * const kPropertyKeyGender;
extern NSString * const kPropertyKeyHashCode;
extern NSString * const kPropertyKeyIsAwaitingDeletion;
extern NSString * const kPropertyKeyIsExpired;
extern NSString * const kPropertyKeyIsMinor;
extern NSString * const kPropertyKeyMobilePhone;
extern NSString * const kPropertyKeyMotherId;
extern NSString * const kPropertyKeyName;
extern NSString * const kPropertyKeyOrigoId;
extern NSString * const kPropertyKeyPasswordHash;
extern NSString * const kPropertyKeyTelephone;

extern NSString * const kRelationshipKeyMember;
extern NSString * const kRelationshipKeyOrigo;

@interface OValidator : NSObject

+ (BOOL)isNameKey:(NSString *)key;
+ (BOOL)isAgeKey:(NSString *)key;
+ (BOOL)isDateKey:(NSString *)key;
+ (BOOL)isEmailKey:(NSString *)key;
+ (BOOL)isPhoneNumberKey:(NSString *)key;
+ (BOOL)isPasswordKey:(NSString *)key;
+ (BOOL)isDefaultableKey:(NSString *)key;
+ (BOOL)isAlternatingLabelKey:(NSString *)key;
+ (BOOL)isAlternatingInputFieldKey:(NSString *)key;

+ (NSDictionary *)keyMappings;
+ (NSString *)propertyKeyForKey:(NSString *)key;
+ (NSString *)defaultValueForKey:(NSString *)key;

+ (BOOL)value:(id)value isValidForKey:(NSString *)key;
+ (BOOL)valueIsEmailAddress:(id)value;
+ (BOOL)valueIsName:(id)value;

@end
