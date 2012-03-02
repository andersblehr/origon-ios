//
//  ScScolaMembership+ScScolaMembershipExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 02.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScScolaMembership+ScScolaMembershipExtensions.h"

#import "ScLogging.h"


@implementation ScScolaMembership (ScScolaMembershipExtensions)


#pragma mark - Mapped accessors for NSNumber booleans

- (void)setIsActive:(BOOL)isActive
{
    self.isActiveN = [NSNumber numberWithBool:isActive];
}


- (void)setIsAdmin:(BOOL)isAdmin
{
    self.isAdminN = [NSNumber numberWithBool:isAdmin];
}


- (void)setIsRole:(BOOL)isRole forRole:(NSString *)roleLabel
{
    if ([self.role1Label isEqualToString:roleLabel]) {
        self.isRole1N = [NSNumber numberWithBool:isRole];
    } else if ([self.role2Label isEqualToString:roleLabel]) {
        self.isRole2N = [NSNumber numberWithBool:isRole];
    } else if ([self.role3Label isEqualToString:roleLabel]) {
        self.isRole3N = [NSNumber numberWithBool:isRole];
    } else {
        ScLogBreakage(@"Cannot set role status for unknown role '%@'.", roleLabel);
    }
}


- (BOOL)isActive
{
    return [self.isActiveN boolValue];
}


- (BOOL)isAdmin
{
    return [self.isAdminN boolValue];
}


- (BOOL)isRole:(NSString *)roleLabel
{
    BOOL isRoleWithLabel = NO;
    
    if ([self.role1Label isEqualToString:roleLabel]) {
        isRoleWithLabel = [self.isRole1N boolValue];
    } else if ([self.role2Label isEqualToString:roleLabel]) {
        isRoleWithLabel = [self.isRole2N boolValue];
    } else if ([self.role3Label isEqualToString:roleLabel]) {
        isRoleWithLabel = [self.isRole3N boolValue];
    } else {
        ScLogBreakage(@"Cannot set role status for unknown role '%@'.", roleLabel);
    }
    
    return isRoleWithLabel;
}

@end
