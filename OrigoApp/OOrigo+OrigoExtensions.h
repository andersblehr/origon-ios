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
extern NSString * const kOrigoTypeAssociation;
extern NSString * const kOrigoTypeSchoolClass;
extern NSString * const kOrigoTypePreschoolClass;
extern NSString * const kOrigoTypeSportsTeam;
extern NSString * const kOrigoTypeOther;

@class OMember, OMembership;

@interface OOrigo (OrigoExtensions)

- (NSSet *)allMemberships;
- (NSSet *)fullMemberships;
- (NSSet *)residencies;
- (NSSet *)participancies;

- (OMembership *)addMember:(OMember *)member;
- (OMembership *)addAssociateMember:(OMember *)member;
- (OMembership *)membershipForMember:(OMember *)member;
- (OMembership *)associateMembershipForMember:(OMember *)member;

- (BOOL)isOfType:(NSString *)origoType;
- (BOOL)hasAdmin;
- (BOOL)hasMember:(OMember *)member;
- (BOOL)hasAssociateMember:(OMember *)member;
- (BOOL)memberIsContact:(OMember *)member;
- (BOOL)knowsAboutMember:(OMember *)member;
- (BOOL)indirectlyKnowsAboutMember:(OMember *)member;
- (BOOL)hasResidentsInCommonWithResidence:(OOrigo *)residence;

- (BOOL)userCanEdit;
- (BOOL)userIsAdmin;
- (BOOL)userIsMember;

- (UIImage *)listCellImage;

@end
