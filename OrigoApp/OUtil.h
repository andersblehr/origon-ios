//
//  OUtil.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OUtil : NSObject

+ (NSString *)commaSeparatedListOfItems:(NSArray *)items conjoinLastItem:(BOOL)conjoinLastItem;
+ (NSString *)localisedCountryNameFromCountryCode:(NSString *)countryCode;
+ (NSString *)givenNameFromFullName:(NSString *)fullName;
+ (NSString *)sortKeyWithPropertyKey:(NSString *)propertyKey relationshipKey:(NSString *)relationshipKey;

+ (BOOL)name:(NSString *)name matchesName:(NSString *)otherName;

@end
