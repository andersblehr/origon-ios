//
//  OUtil.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OUtil : NSObject

+ (void)setImageForOrigo:(id<OOrigo>)origo inTableViewCell:(OTableViewCell *)cell;
+ (void)setImageForMember:(id<OMember>)member inTableViewCell:(OTableViewCell *)cell;
+ (void)setTonedDownIconWithFileName:(NSString *)iconName inTableViewCell:(OTableViewCell *)cell;

+ (NSString *)rootIdFromMemberId:(NSString *)memberId;
+ (NSString *)genderTermForGender:(NSString *)gender isJuvenile:(BOOL)isJuvenile;

+ (NSString *)memberInfoFromMembership:(id<OMembership>)membership;
+ (NSString *)associationInfoForMember:(id<OMember>)member;
+ (NSString *)guardianInfoForMember:(id<OMember>)member;

+ (NSString *)commaSeparatedListOfItems:(id)items conjoinLastItem:(BOOL)conjoinLastItem;
+ (NSString *)commaSeparatedListOfMembers:(id)members conjoinLastItem:(BOOL)conjoinLastItem;

+ (NSArray *)sortedGroupsOfResidents:(id)residents excluding:(id<OMember>)excludedResident;
+ (NSString *)sortKeyWithPropertyKey:(NSString *)propertyKey relationshipKey:(NSString *)relationshipKey;

+ (NSComparisonResult)compareOrigo:(id<OOrigo>)origo withOrigo:(id<OOrigo>)otherOrigo;

@end
