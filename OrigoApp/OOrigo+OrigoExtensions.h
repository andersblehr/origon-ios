//
//  OOrigo+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OOrigo.h"

extern NSString * const kOrigoTypeMemberRoot;
extern NSString * const kOrigoTypeResidence;
extern NSString * const kOrigoTypeOrganisation;
extern NSString * const kOrigoTypeSchoolClass;
extern NSString * const kOrigoTypePreschoolClass;
extern NSString * const kOrigoTypeSportsTeam;
extern NSString * const kOrigoTypeOther;

@class OMember, OMembership;

@interface OOrigo (OrigoExtensions)

- (NSComparisonResult)compare:(OOrigo *)other;

- (NSString *)displayAddress;
- (NSString *)displayPhoneNumber;
- (UIImage *)displayImage;

- (NSSet *)exposedMemberships;
- (NSSet *)exposedResidencies;

- (id)membershipForMember:(OMember *)member;
- (id)addAssociateMember:(OMember *)member;
- (id)addMember:(OMember *)member;
- (id)addResident:(OMember *)resident;

- (BOOL)isOfType:(NSString *)origoType;
- (BOOL)hasAdmin;
- (BOOL)hasMember:(OMember *)member;
- (BOOL)hasAssociateMember:(OMember *)member;
- (BOOL)indirectlyKnowsAboutMember:(OMember *)member;

- (BOOL)userCanEdit;
- (BOOL)userIsAdmin;
- (BOOL)userIsMember;

- (void)extricateIfRedundant;

@end
