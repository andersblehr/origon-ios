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
