//
//  OMembership+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

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


@interface OMembership (OrigoAdditions) <OMembership>

@end
