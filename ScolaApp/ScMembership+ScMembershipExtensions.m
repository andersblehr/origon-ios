//
//  ScMembership+ScMembershipExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 07.07.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMembership+ScMembershipExtensions.h"

#import "ScMember.h"

@implementation ScMembership (ScMembershipExtensions)


#pragma mark - Comparison

- (NSComparisonResult)compare:(ScMembership *)other
{
    return [self.member.name compare:other.member.name];
}

@end
