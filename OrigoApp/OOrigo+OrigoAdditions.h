//
//  OOrigo+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kOrigoTypeAlumni;
extern NSString * const kOrigoTypeCommunity;
extern NSString * const kOrigoTypePreschoolClass;
extern NSString * const kOrigoTypePrivate;
extern NSString * const kOrigoTypeResidence;
extern NSString * const kOrigoTypeSchoolClass;
extern NSString * const kOrigoTypeStandard;
extern NSString * const kOrigoTypeStash;
extern NSString * const kOrigoTypeStudyGroup;
extern NSString * const kOrigoTypeTeam;


@protocol OOrigo <OEntity>

@optional
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *descriptionText;
@property (nonatomic) NSString *address;
@property (nonatomic) NSString *telephone;
@property (nonatomic) NSString *countryCode;
@property (nonatomic) NSString *type;
@property (nonatomic) NSString *permissions;

@property (nonatomic, assign) BOOL membersCanAdd;
@property (nonatomic, assign) BOOL membersCanDelete;
@property (nonatomic, assign) BOOL membersCanEdit;

- (NSArray *)permissionKeys;
- (NSString *)defaultPermissions;

- (NSComparisonResult)compare:(id<OOrigo>)other;

- (id<OMember>)owner;

- (NSSet *)allMemberships;
- (NSSet *)residencies;

- (NSArray *)residents;
- (NSArray *)members;
- (NSArray *)regulars;
- (NSArray *)guardians;
- (NSArray *)elders;
- (NSArray *)minors;
- (NSArray *)organisers;
- (NSArray *)parentContacts;
- (NSArray *)admins;
- (NSArray *)adminCandidates;
- (NSArray *)memberResidencesIncludeUser:(BOOL)includeUser;

- (NSArray *)memberRoles;
- (NSArray *)membersWithRole:(NSString *)role;
- (NSArray *)organiserRoles;
- (NSArray *)organisersWithRole:(NSString *)role;
- (NSArray *)parentRoles;
- (NSArray *)parentsWithRole:(NSString *)role;
- (NSArray *)holdersOfAffiliation:(NSString *)affiliation ofType:(NSString *)affiliationType;

- (NSArray *)groups;
- (NSArray *)membersOfGroup:(NSString *)group;

- (id<OMembership>)addMember:(id<OMember>)member;
- (id<OMembership>)addAssociateMember:(id<OMember>)member;
- (id<OMembership>)membershipForMember:(id<OMember>)member;
- (id<OMembership>)associateMembershipForMember:(id<OMember>)member;

- (BOOL)userIsAdmin;
- (BOOL)userIsMember;
- (BOOL)userIsOrganiser;
- (BOOL)userIsParentContact;

- (BOOL)isOfType:(id)type;
- (BOOL)isOrganised;
- (BOOL)isJuvenile;
- (BOOL)hasAddress;
- (BOOL)hasTelephone;
- (BOOL)hasAdmin;
- (BOOL)hasOrganisers;
- (BOOL)hasParentContacts;
- (BOOL)hasMember:(id<OMember>)member;
- (BOOL)knowsAboutMember:(id<OMember>)member;
- (BOOL)indirectlyKnowsAboutMember:(id<OMember>)member;
- (BOOL)hasMembersInCommonWithOrigo:(id<OOrigo>)residence;

- (NSArray *)recipientCandidates;
- (NSArray *)textRecipients;
- (NSArray *)callRecipients;
- (NSArray *)emailRecipients;

- (NSString *)displayName;
- (NSString *)displayPermissions;
- (NSString *)singleLineAddress;
- (NSString *)shortAddress;
- (NSString *)recipientLabel;
- (NSString *)recipientLabelForRecipientType:(NSInteger)recipientType;

- (void)convertToType:(NSString *)type;

@end


@interface OOrigo (OrigoAdditions) <OOrigo>

+ (instancetype)instanceWithId:(NSString *)entityId type:(NSString *)type;
+ (instancetype)instanceWithType:(NSString *)type;

@end
