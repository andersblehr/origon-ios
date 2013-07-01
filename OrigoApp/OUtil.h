//
//  OUtil.h
//  OrigoApp
//
//  Created by Anders Blehr on 26.05.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OUtil : NSObject

+ (BOOL)isSupportedCountryCode:(NSString *)countryCode;
+ (NSString *)localisedCountryNameFromCountryCode:(NSString *)countryCode;

+ (NSString *)sortKeyWithPropertyKey:(NSString *)propertyKey relationshipKey:(NSString *)relationshipKey;

@end
