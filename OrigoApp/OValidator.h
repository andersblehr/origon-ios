//
//  OValidator.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface OValidator : NSObject

+ (NSArray *)nameKeys;
+ (NSArray *)dateKeys;
+ (NSArray *)phoneKeys;
+ (NSArray *)emailKeys;
+ (NSArray *)passwordKeys;
+ (NSArray *)inferredKeys;

+ (NSDictionary *)keyMappings;
+ (NSString *)propertyKeyForKey:(NSString *)key;
+ (NSString *)defaultValueForKey:(NSString *)key;

+ (BOOL)value:(id)value isValidForKey:(NSString *)key;
+ (BOOL)valueIsEmailAddress:(id)value;
+ (BOOL)valueIsName:(id)value;

@end
