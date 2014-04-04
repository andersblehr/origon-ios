//
//  OMember+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OMember (OrigoAdditions)

- (NSSet *)allMemberships;
- (NSSet *)residencies;

- (OOrigo *)rootOrigo;
- (OOrigo *)residence;
- (NSArray *)residences;
- (NSArray *)origos;

- (OMember *)partner;
- (NSSet *)wards;
- (NSSet *)parents;
- (NSSet *)siblings;
- (NSSet *)guardians;
- (NSSet *)peers;
- (NSSet *)peersNotInOrigo:(OOrigo *)origo;
- (NSSet *)housemates;
- (NSSet *)housematesNotInResidence:(OOrigo *)residence;
- (NSSet *)housemateResidences;

- (BOOL)isActive;
- (void)makeActive;

- (BOOL)isUser;
- (BOOL)isWardOfUser;
- (BOOL)isHousemateOfUser;
- (BOOL)isManagedByUser;
- (BOOL)isKnownByUser;
- (BOOL)isMale;
- (BOOL)isJuvenile;
- (BOOL)isTeenOrOlder;
- (BOOL)isOlderThan:(NSInteger)age;
- (BOOL)hasParent:(OMember *)member;
- (BOOL)hasParentWithGender:(NSString *)gender;
- (BOOL)guardiansAreParents;

- (NSArray *)pronoun;
- (NSArray *)parentNoun;

- (NSString *)age;
- (NSString *)appellation;
- (NSString *)givenName;
- (NSString *)givenNameWithParentTitle;
- (NSString *)givenNameWithContactRoleForOrigo:(OOrigo *)origo;
- (NSString *)shortAddress;
- (NSString *)shortDetails;
- (UIImage *)smallImage;

@end
