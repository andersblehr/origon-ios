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


@protocol OOrigo <OEntity>

@optional
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *descriptionText;
@property (nonatomic) NSString *address;
@property (nonatomic) NSString *telephone;
@property (nonatomic) NSString *countryCode;
@property (nonatomic, readonly) NSString *type;

- (NSSet *)allMemberships;
- (NSSet *)residents;
- (NSSet *)members;
- (NSSet *)contacts;
- (NSSet *)regulars;
- (NSSet *)guardians;
- (NSSet *)elders;

- (id<OMembership>)addMember:(id<OMember>)member;
- (id<OMembership>)addAssociateMember:(id<OMember>)member;
- (id<OMembership>)membershipForMember:(id<OMember>)member;
- (id<OMembership>)associateMembershipForMember:(id<OMember>)member;

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
- (BOOL)hasMember:(id<OMember>)member;
- (BOOL)hasContact:(id<OMember>)contact;
- (BOOL)hasAssociateMember:(id<OMember>)associateMember;
- (BOOL)knowsAboutMember:(id<OMember>)member;
- (BOOL)indirectlyKnowsAboutMember:(id<OMember>)member;
- (BOOL)hasResidentsInCommonWithResidence:(id<OOrigo>)residence;

- (NSString *)singleLineAddress;
- (NSString *)shortAddress;
- (UIImage *)smallImage;

@end


@interface OOrigo (OrigoAdditions) <OOrigo>

+ (instancetype)instanceWithId:(NSString *)entityId type:(NSString *)type;

@end
