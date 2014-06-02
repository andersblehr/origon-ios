//
//  OMembershipProxy.h
//  OrigoApp
//
//  Created by Anders Blehr on 01.05.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OEntityProxy.h"

extern NSString *kMembershipTypeRoot;
extern NSString *kMembershipTypeResidency;
extern NSString *kMembershipTypeParticipancy;
extern NSString *kMembershipTypeAssociate;

extern NSString *kMembershipStatusInvited;
extern NSString *kMembershipStatusWaiting;
extern NSString *kMembershipStatusActive;
extern NSString *kMembershipStatusRejected;
extern NSString *kMembershipStatusExpired;


@protocol OMembership <OEntity>

@optional
@property (nonatomic) id<OOrigo> origo;
@property (nonatomic) id<OMember> member;
@property (nonatomic) NSString *type;
@property (nonatomic) NSString *status;
@property (nonatomic) NSNumber *isAdmin;
@property (nonatomic) NSString *contactRole;
@property (nonatomic) NSString *contactType;

- (BOOL)isInvited;
- (BOOL)isActive;
- (BOOL)isRejected;

- (BOOL)isFull;
- (BOOL)isParticipancy;
- (BOOL)isResidency;
- (BOOL)isAssociate;
- (BOOL)hasContactRole;

- (void)promoteToFull;
- (void)demoteToAssociate;
- (void)alignWithOrigoIsAssociate:(BOOL)isAssociate;

@end


@interface OMembershipProxy : OEntityProxy<OMembership>

+ (instancetype)proxyForMember:(id<OMember>)member inOrigo:(id<OOrigo>)origo;

@end
