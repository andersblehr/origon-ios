//
//  OMember+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

#import "OMember.h"

extern NSString * const kMemberTypeGuardian;

@interface OMember (OrigoExtensions)

- (OMembership *)rootMembership;
- (OMembership *)initialResidency;
- (NSSet *)allMemberships;
- (NSSet *)fullMemberships;
- (NSSet *)residencies;
- (NSSet *)participancies;

- (NSSet *)wards;
- (NSSet *)housemates;
- (NSSet *)housemateResidences;

- (BOOL)isActive;
- (void)makeActive;

- (BOOL)isUser;
- (BOOL)isWardOfUser;
- (BOOL)isManagedByUser;
- (BOOL)isKnownByUser;
- (BOOL)isMale;
- (BOOL)isMinor;
- (BOOL)isTeenOrOlder;
- (BOOL)isOlderThan:(NSInteger)age;
- (BOOL)isMemberOfOrigoOfType:(NSString *)origoType;
- (BOOL)hasParentWithGender:(NSString *)gender;

- (NSString *)givenName;
- (NSArray *)pronoun;
- (NSString *)appellation;

- (UIImage *)listCellImage;

@end
