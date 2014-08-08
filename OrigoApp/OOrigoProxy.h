//
//  OOrigoProxy.h
//  OrigoApp
//
//  Created by Anders Blehr on 20.03.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kOrigoTypeFriends;
extern NSString * const kOrigoTypeGeneral;
extern NSString * const kOrigoTypeOrganisation;
extern NSString * const kOrigoTypePreschoolClass;
extern NSString * const kOrigoTypeResidence;
extern NSString * const kOrigoTypeRoot;
extern NSString * const kOrigoTypeSchoolClass;
extern NSString * const kOrigoTypeStudentGroup;
extern NSString * const kOrigoTypeTeam;


@protocol OOrigo <OEntity>

@optional
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *descriptionText;
@property (nonatomic) NSString *address;
@property (nonatomic) NSString *telephone;
@property (nonatomic) NSString *countryCode;
@property (nonatomic) NSString *type;

- (NSSet *)allMemberships;

- (NSArray *)residents;
- (NSArray *)members;
- (NSArray *)organisers;
- (NSArray *)parentContacts;
- (NSArray *)regulars;
- (NSArray *)guardians;
- (NSArray *)elders;

- (id<OMembership>)addMember:(id<OMember>)member;
- (id<OMembership>)addAssociateMember:(id<OMember>)member;
- (id<OMembership>)membershipForMember:(id<OMember>)member;
- (id<OMembership>)associateMembershipForMember:(id<OMember>)member;

- (BOOL)userCanEdit;
- (BOOL)userIsAdmin;
- (BOOL)userIsMember;
- (BOOL)userIsOrganiser;
- (BOOL)userIsParentContact;
- (BOOL)userIsMemberContact;

- (BOOL)isOfType:(NSString *)type;
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
- (BOOL)hasResidentsInCommonWithResidence:(id<OOrigo>)residence;

- (NSString *)singleLineAddress;
- (NSString *)shortAddress;

@end


@interface OOrigoProxy : OEntityProxy<OOrigo>

+ (instancetype)proxyWithType:(NSString *)type;
+ (instancetype)proxyFromAddressBookAddress:(CFDictionaryRef)address;

@end
