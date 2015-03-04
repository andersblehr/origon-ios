//
//  OUtil.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OUtil : NSObject

+ (NSString *)keyValueString:(NSString *)keyValueString setValue:(id)value forKey:(NSString *)key;
+ (NSString *)keyValueString:(NSString *)keyValueString valueForKey:(NSString *)key;

+ (NSString *)labelForElders:(NSArray *)elders conjoin:(BOOL)conjoin;
+ (NSString *)commaSeparatedListOfStrings:(id)strings conjoin:(BOOL)conjoin;
+ (NSString *)commaSeparatedListOfStrings:(id)strings conjoin:(BOOL)conjoin conditionallyLowercase:(BOOL)conditionallyLowercase;
+ (NSString *)commaSeparatedListOfMembers:(id)members conjoin:(BOOL)conjoin;
+ (NSString *)commaSeparatedListOfMembers:(id)members conjoin:(BOOL)conjoin subjective:(BOOL)subjective;
+ (NSString *)commaSeparatedListOfMembers:(id)members inOrigo:(id<OOrigo>)origo subjective:(BOOL)subjective;
+ (NSString *)commaSeparatedListOfMembers:(id)members withRolesInOrigo:(id<OOrigo>)origo;

+ (NSDictionary *)isUniqueByGivenNameFromMembers:(id)members;
+ (NSArray *)singleMemberPerPrimaryResidenceFromMembers:(NSArray *)members includeUser:(BOOL)includeUser;
+ (NSArray *)sortedGroupsOfResidents:(id)residents excluding:(id<OMember>)excludedResident;
+ (NSString *)sortKeyWithPropertyKey:(NSString *)propertyKey relationshipKey:(NSString *)relationshipKey;

+ (NSComparisonResult)compareOrigo:(id<OOrigo>)origo withOrigo:(id<OOrigo>)otherOrigo;

@end
