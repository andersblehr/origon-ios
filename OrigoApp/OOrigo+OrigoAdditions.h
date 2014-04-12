//
//  OOrigo+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kOrigoTypeRoot;
extern NSString * const kOrigoTypeResidence;
extern NSString * const kOrigoTypeFriends;
extern NSString * const kOrigoTypeTeam;
extern NSString * const kOrigoTypeOrganisation;
extern NSString * const kOrigoTypeOther;
extern NSString * const kOrigoTypePreschoolClass;
extern NSString * const kOrigoTypeSchoolClass;

extern NSString * const kContactRoleTeacher;
extern NSString * const kContactRoleTopicTeacher;
extern NSString * const kContactRoleSpecialEducationTeacher;
extern NSString * const kContactRoleAssistantTeacher;
extern NSString * const kContactRoleHeadTeacher;
extern NSString * const kContactRoleChair;
extern NSString * const kContactRoleDeputyChair;
extern NSString * const kContactRoleTreasurer;
extern NSString * const kContactRoleCoach;
extern NSString * const kContactRoleAssistantCoach;

@interface OOrigo (OrigoAdditions)

+ (instancetype)instanceWithId:(NSString *)entityId type:(NSString *)type;

- (NSSet *)allMemberships;
- (NSSet *)residents;
- (NSSet *)members;
- (NSSet *)contacts;
- (NSSet *)regulars;
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
- (BOOL)hasAddress;
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
