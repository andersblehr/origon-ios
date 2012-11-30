//
//  OMembership+OMembershipExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMembership.h"

extern NSString * const kMembershipIdFormat;
extern NSString * const kResidencyIdFormat;

@interface OMembership (OMembershipExtensions)

- (void)setIsActive_:(BOOL)isActive;
- (BOOL)isActive_;
- (void)setIsAdmin_:(BOOL)isAdmin;
- (BOOL)isAdmin_;

- (BOOL)hasContactRole;

@end
