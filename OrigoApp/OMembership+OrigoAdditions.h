//
//  OMembership+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kMembershipTypeOwnership;
extern NSString * const kMembershipTypeFavourite;
extern NSString * const kMembershipTypeListing;
extern NSString * const kMembershipTypeResidency;
extern NSString * const kMembershipTypeParticipancy;
extern NSString * const kMembershipTypeAssociate;

extern NSString * const kMembershipStatusListed;
extern NSString * const kMembershipStatusInvited;
extern NSString * const kMembershipStatusWaiting;
extern NSString * const kMembershipStatusActive;
extern NSString * const kMembershipStatusExpired;

extern NSString * const kAffiliationTypeMemberRole;
extern NSString * const kAffiliationTypeOrganiserRole;
extern NSString * const kAffiliationTypeParentRole;
extern NSString * const kAffiliationTypeGroup;


@protocol OMembership <OEntity>

@optional
@property (nonatomic) id<OOrigo> origo;
@property (nonatomic) id<OMember> member;
@property (nonatomic) NSString *type;
@property (nonatomic) NSNumber *isAdmin;
@property (nonatomic) NSString *status;
@property (nonatomic) NSString *affiliations;

- (BOOL)needsAccepting;
- (BOOL)isActive;
- (BOOL)isShared;
- (BOOL)isMirrored;
- (BOOL)isHidden;

- (BOOL)isOwnership;
- (BOOL)isFavourite;
- (BOOL)isListing;
- (BOOL)isResidency;
- (BOOL)isParticipancy;
- (BOOL)isCommunityMembership;
- (BOOL)isAssociate;

- (BOOL)hasAffiliationOfType:(NSString *)type;
- (void)addAffiliation:(NSString *)affiliation ofType:(NSString *)type;
- (void)removeAffiliation:(NSString *)affiliation ofType:(NSString *)type;
- (NSString *)typeOfAffiliation:(NSString *)affiliation;
- (NSArray *)affiliationsOfType:(NSString *)type;

- (NSArray *)memberRoles;
- (NSArray *)organiserRoles;
- (NSArray *)parentRoles;
- (NSArray *)roles;
- (NSArray *)groups;

- (void)promote;
- (void)demote;

@end


@interface OMembership (OrigoAdditions) <OMembership>

- (void)alignWithOrigoIsAssociate:(BOOL)isAssociate;

@end
