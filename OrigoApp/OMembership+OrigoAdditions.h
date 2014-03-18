//
//  OMembership+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *kMembershipStatusInvited;
extern NSString *kMembershipStatusWaiting;
extern NSString *kMembershipStatusActive;
extern NSString *kMembershipStatusRejected;
extern NSString *kMembershipStatusExpired;

@interface OMembership (OrigoAdditions)

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
