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

+ (NSString *)memberInfoFromMembership:(id<OMembership>)membership;
+ (NSString *)associationInfoForMember:(id<OMember>)member;
+ (NSString *)guardianInfoForMember:(id<OMember>)member;

+ (NSString *)commaSeparatedListOfItems:(id)items conjoinLastItem:(BOOL)conjoinLastItem;
+ (NSString *)commaSeparatedListOfStrings:(id)strings conjoinLastItem:(BOOL)conjoinLastItem;
+ (NSString *)commaSeparatedListOfMembers:(id)members;
+ (NSString *)commaSeparatedListOfMembers:(id)members inOrigo:(id<OOrigo>)origo;
+ (NSString *)commaSeparatedListOfMembers:(id)members withRolesInOrigo:(id<OOrigo>)origo;

+ (NSArray *)eligibleOrigoTypesForOrigo:(id<OOrigo>)origo;
+ (NSArray *)sortedGroupsOfResidents:(id)residents excluding:(id<OMember>)excludedResident;
+ (NSString *)sortKeyWithPropertyKey:(NSString *)propertyKey relationshipKey:(NSString *)relationshipKey;

+ (NSComparisonResult)compareOrigo:(id<OOrigo>)origo withOrigo:(id<OOrigo>)otherOrigo;

@end
