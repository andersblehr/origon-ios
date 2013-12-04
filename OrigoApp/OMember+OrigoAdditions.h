//
//  OMember+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern NSString * const kMemberTypeGuardian;

@interface OMember (OrigoAdditions)

- (OMembership *)rootMembership;
- (OMembership *)initialResidency;
- (NSSet *)allMemberships;
- (NSSet *)fullMemberships;
- (NSSet *)residencies;
- (NSSet *)participancies;
- (NSArray *)sortedOrigos;

- (OMember *)partner;
- (NSSet *)wards;
- (NSSet *)parents;
- (NSSet *)guardians;
- (NSSet *)housemates;
- (NSSet *)housemateResidences;

- (BOOL)isActive;
- (void)makeActive;

- (BOOL)isUser;
- (BOOL)isWardOfUser;
- (BOOL)isHousemateOfUser;
- (BOOL)isManagedByUser;
- (BOOL)isKnownByUser;
- (BOOL)isMale;
- (BOOL)isMinor;
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
