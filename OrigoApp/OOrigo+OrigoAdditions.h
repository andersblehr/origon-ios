//
//  OOrigo+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kOrigoTypeCommunity;
extern NSString * const kOrigoTypePreschoolClass;
extern NSString * const kOrigoTypePrivate;
extern NSString * const kOrigoTypeResidence;
extern NSString * const kOrigoTypeSchoolClass;
extern NSString * const kOrigoTypeSports;
extern NSString * const kOrigoTypeStandard;
extern NSString * const kOrigoTypeStash;


@protocol OOrigo <OEntity>

@optional
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *descriptionText;
@property (nonatomic) NSString *address;
@property (nonatomic) NSString *telephone;
@property (nonatomic) NSString *location;
@property (nonatomic) NSString *type;
@property (nonatomic) NSString *joinCode;
@property (nonatomic) NSString *internalJoinCode;
@property (nonatomic) NSString *permissions;
@property (nonatomic) NSNumber *isForMinors;

@property (nonatomic, assign) BOOL membersCanEdit;
@property (nonatomic, assign) BOOL membersCanAdd;
@property (nonatomic, assign) BOOL membersCanDelete;

- (NSArray *)permissionKeys;
- (NSString *)defaultPermissions;
- (BOOL)hasPermissionWithKey:(NSString *)key;
- (void)setPermission:(BOOL)permission forKey:(NSString *)key;

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
- (NSArray *)parentContacts;
- (NSArray *)organisers;
- (NSArray *)organiserCandidates;
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
- (id<OMembership>)userMembership;

- (BOOL)userIsAdmin;
- (BOOL)userIsMember;
- (BOOL)userIsOrganiser;
- (BOOL)userIsParentContact;

- (BOOL)userCanEdit;
- (BOOL)userCanAdd;
- (BOOL)userCanDelete;

- (BOOL)isStash;
- (BOOL)isResidence;
- (BOOL)isPrivate;
- (BOOL)isPinned;
- (BOOL)isStandard;
- (BOOL)isCommunity;
- (BOOL)isOfType:(id)type;

- (BOOL)isOrganised;
- (BOOL)isJuvenile;
- (BOOL)hasAddress;
- (BOOL)hasTelephone;
- (BOOL)hasAdmin;
- (BOOL)hasRegulars;
- (BOOL)hasTeenRegulars;
- (BOOL)hasOrganisers;
- (BOOL)hasParentContacts;
- (BOOL)hasMember:(id<OMember>)member;
- (BOOL)knowsAboutMember:(id<OMember>)member;
- (BOOL)indirectlyKnowsAboutMember:(id<OMember>)member;
- (BOOL)hasMembersInCommonWithOrigo:(id<OOrigo>)residence;
- (BOOL)hasPendingJoinRequests;

- (NSArray *)recipientCandidates;
- (NSArray *)callRecipients;
- (NSArray *)textRecipients;
- (NSArray *)textRecipientsInSet:(id)set;
- (NSArray *)emailRecipients;
- (NSArray *)emailRecipientsInSet:(id)set;

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
