//
//  ScMembership+ScMembershipExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 07.07.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMembership.h"

@interface ScMembership (ScMembershipExtensions)

- (void)setIsActive_:(BOOL)isActive;
- (BOOL)isActive_;
- (void)setIsAdmin_:(BOOL)isAdmin;
- (BOOL)isAdmin_;

- (BOOL)hasContactRole;

@end
