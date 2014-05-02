//
//  OUtil.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OUtil : NSObject

+ (NSString *)contactInfoForMember:(id<OMember>)member;
+ (UIImage *)smallImageForMember:(id<OMember>)member;
+ (UIImage *)smallImageForOrigo:(id<OOrigo>)origo;

+ (NSString *)rootIdFromMemberId:(NSString *)memberId;
+ (NSString *)commaSeparatedListOfItems:(NSArray *)items conjoinLastItem:(BOOL)conjoinLastItem;
+ (NSString *)localisedCountryNameFromCountryCode:(NSString *)countryCode;
+ (NSString *)givenNameFromFullName:(NSString *)fullName;
+ (NSString *)sortKeyWithPropertyKey:(NSString *)propertyKey relationshipKey:(NSString *)relationshipKey;

+ (NSComparisonResult)compareOrigo:(id<OOrigo>)origo withOrigo:(id<OOrigo>)otherOrigo;
+ (BOOL)fullName:(NSString *)fullName fuzzyMatchesFullName:(NSString *)otherFullName;

@end
