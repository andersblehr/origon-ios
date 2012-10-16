//
//  ScMembership+ScMembershipExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 07.07.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMembership+ScMembershipExtensions.h"

#import "ScMeta.h"

#import "ScMember.h"
#import "ScScola.h"


@implementation ScMembership (ScMembershipExtensions)

#pragma mark - Wrapper accessors for NSNumber booleans

- (void)setIsActive_:(BOOL)isActive_
{
    self.isActive = [NSNumber numberWithBool:isActive_];
}


- (BOOL)isActive_
{
    return [self.isActive boolValue];
}


- (void)setIsAdmin_:(BOOL)isAdmin_
{
    self.isAdmin = [NSNumber numberWithBool:isAdmin_];
}


- (BOOL)isAdmin_
{
    return [self.isAdmin boolValue];
}


#pragma mark - Convenience methods

- (BOOL)hasContactRole
{
    return (self.contactRole != nil);
}


#pragma mark - Comparison

- (NSComparisonResult)compare:(ScMembership *)other
{
    return [self.member.name localizedCaseInsensitiveCompare:other.member.name];
}

@end
