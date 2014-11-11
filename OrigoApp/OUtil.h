//
//  OUtil.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OUtil : NSObject

+ (NSString *)rootIdFromMemberId:(NSString *)memberId;
+ (NSString *)genderTermForGender:(NSString *)gender isJuvenile:(BOOL)isJuvenile;

+ (NSString *)commaSeparatedListOfStrings:(id)strings conjoin:(BOOL)conjoin;
+ (NSString *)commaSeparatedListOfStrings:(id)strings conjoin:(BOOL)conjoin conditionallyLowercase:(BOOL)conditionallyLowercase;
+ (NSString *)commaSeparatedListOfMembers:(id)members conjoin:(BOOL)conjoin;
+ (NSString *)commaSeparatedListOfMembers:(id)members conjoin:(BOOL)conjoin subjective:(BOOL)subjective;
+ (NSString *)commaSeparatedListOfMembers:(id)members inOrigo:(id<OOrigo>)origo conjoin:(BOOL)conjoin;
+ (NSString *)commaSeparatedListOfMembers:(id)members withRolesInOrigo:(id<OOrigo>)origo;

+ (NSDictionary *)isUniqueByGivenNameFromMembers:(id)members;
+ (NSArray *)eligibleOrigoTypesForOrigo:(id<OOrigo>)origo;
+ (NSArray *)sortedGroupsOfResidents:(id)residents excluding:(id<OMember>)excludedResident;
+ (NSString *)sortKeyWithPropertyKey:(NSString *)propertyKey relationshipKey:(NSString *)relationshipKey;

+ (NSComparisonResult)compareOrigo:(id<OOrigo>)origo withOrigo:(id<OOrigo>)otherOrigo;

@end
