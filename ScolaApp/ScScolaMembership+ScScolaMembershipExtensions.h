//
//  ScScolaMembership+ScScolaMembershipExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 02.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScScolaMembership.h"

@interface ScScolaMembership (ScScolaMembershipExtensions)

- (void)setIsActive:(BOOL)isActive;
- (void)setIsAdmin:(BOOL)isAdmin;
- (void)setIsRole:(BOOL)isRole forRole:(NSString *)roleLabel;

- (BOOL)isActive;
- (BOOL)isAdmin;
- (BOOL)isRole:(NSString *)roleLabel;

@end
