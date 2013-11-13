//
//  OOrigo+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern NSString * const kOrigoTypeMemberRoot;
extern NSString * const kOrigoTypeResidence;
extern NSString * const kOrigoTypeFriends;
extern NSString * const kOrigoTypeTeam;
extern NSString * const kOrigoTypeOrganisation;
extern NSString * const kOrigoTypeOther;
extern NSString * const kOrigoTypePreschoolClass;
extern NSString * const kOrigoTypeSchoolClass;
extern NSString * const kOrigoTypePlaymates;
extern NSString * const kOrigoTypeMinorTeam;

@interface OOrigo (OrigoExtensions)

- (NSSet *)allMemberships;
- (NSSet *)fullMemberships;
- (NSSet *)regularMemberships;
- (NSSet *)contactMemberships;
- (NSSet *)residencies;
- (NSSet *)participancies;
- (NSSet *)members;
- (NSSet *)contacts;
- (NSSet *)guardians;
- (NSSet *)elders;

- (OMembership *)addMember:(OMember *)member;
- (OMembership *)addAssociateMember:(OMember *)member;
- (OMembership *)membershipForMember:(OMember *)member;
- (OMembership *)associateMembershipForMember:(OMember *)member;

- (BOOL)userCanEdit;
- (BOOL)userIsAdmin;
- (BOOL)userIsMember;
- (BOOL)userIsContact;

- (BOOL)isOfType:(NSString *)origoType;
- (BOOL)isOrganised;
- (BOOL)isJuvenile;
- (BOOL)hasAdmin;
- (BOOL)hasContacts;
- (BOOL)hasMember:(OMember *)member;
- (BOOL)hasContact:(OMember *)contact;
- (BOOL)hasAssociateMember:(OMember *)associateMember;
- (BOOL)knowsAboutMember:(OMember *)member;
- (BOOL)indirectlyKnowsAboutMember:(OMember *)member;
- (BOOL)hasResidentsInCommonWithResidence:(OOrigo *)residence;

- (NSString *)displayName;
- (NSString *)singleLineAddress;
- (NSString *)shortAddress;
- (UIImage *)smallImage;

@end
