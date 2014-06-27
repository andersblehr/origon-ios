//
//  OValidator.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OValidator : NSObject

+ (BOOL)isNameKey:(NSString *)key;
+ (BOOL)isGivenNameKey:(NSString *)key;
+ (BOOL)isAgeKey:(NSString *)key;
+ (BOOL)isDateKey:(NSString *)key;
+ (BOOL)isEmailKey:(NSString *)key;
+ (BOOL)isPhoneNumberKey:(NSString *)key;
+ (BOOL)isPasswordKey:(NSString *)key;
+ (BOOL)isAlternatingLabelKey:(NSString *)key;
+ (BOOL)isAlternatingInputFieldKey:(NSString *)key;

+ (NSDictionary *)referenceForEntity:(id<OEntity>)entity;
+ (NSString *)referenceKeyForKey:(NSString *)key;
+ (NSString *)keyMappingForKey:(NSString *)key;

+ (BOOL)value:(id)value isValidForKey:(NSString *)key;
+ (BOOL)isEmailValue:(id)value;
+ (BOOL)isNameValue:(id)value;

@end
