//
//  OUtil.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OUtil : NSObject

+ (NSString *)keyValueString:(NSString *)keyValueString setValue:(id)value forKey:(NSString *)key;
+ (NSString *)keyValueString:(NSString *)keyValueString valueForKey:(NSString *)key;

+ (NSString *)labelForElders:(NSArray *)elders conjoin:(BOOL)conjoin;
+ (NSString *)commaSeparatedListOfNouns:(id)nouns conjoin:(BOOL)conjoin;
+ (NSString *)commaSeparatedListOfNames:(id)names conjoin:(BOOL)conjoin;
+ (NSString *)commaSeparatedListOfMembers:(id)members conjoin:(BOOL)conjoin;
+ (NSString *)commaSeparatedListOfMembers:(id)members conjoin:(BOOL)conjoin subjective:(BOOL)subjective;
+ (NSString *)commaSeparatedListOfMembers:(id)members inOrigo:(id<OOrigo>)origo subjective:(BOOL)subjective;
+ (NSString *)commaSeparatedListOfMembers:(id)members withRolesInOrigo:(id<OOrigo>)origo;

+ (NSDictionary *)isUniqueByGivenNameFromMembers:(id)members;
+ (NSArray *)singleMemberPerPrimaryResidenceFromMembers:(NSArray *)members includeUser:(BOOL)includeUser;
+ (NSArray *)sortedGroupsOfResidents:(id)residents excluding:(id<OMember>)excludedResident;

+ (NSComparisonResult)compareOrigo:(id<OOrigo>)origo withOrigo:(id<OOrigo>)otherOrigo;

+ (BOOL)isOrganisedOrigoWithType:(NSString *)type;

@end
