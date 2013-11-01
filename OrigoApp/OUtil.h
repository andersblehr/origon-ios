//
//  OUtil.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface OUtil : NSObject

+ (BOOL)origoTypeIsJuvenile:(NSString *)origoType;
+ (BOOL)isSupportedCountryCode:(NSString *)countryCode;

+ (NSString *)commaSeparatedListOfItems:(NSArray *)items conjoinLastItem:(BOOL)conjoinLastItem;
+ (NSString *)localisedCountryNameFromCountryCode:(NSString *)countryCode;
+ (NSString *)givenNameFromFullName:(NSString *)fullName;
+ (NSString *)sortKeyWithPropertyKey:(NSString *)propertyKey relationshipKey:(NSString *)relationshipKey;

@end
