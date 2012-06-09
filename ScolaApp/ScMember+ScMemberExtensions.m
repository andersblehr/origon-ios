//
//  ScMember+ScMemberExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 16.05.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMember+ScMemberExtensions.h"

#import "NSDate+ScDateExtensions.h"


@implementation ScMember (ScMemberExtensions)


#pragma mark - Meta information

- (BOOL)hasMobilPhone
{
    return (self.mobilePhone.length > 0);
}


- (BOOL)isMinor
{
    return [self.dateOfBirth isBirthDateOfMinor];
}


#pragma mark - Comparison

- (NSComparisonResult)compare:(ScMember *)other
{
    return [self.name compare:other.name];
}

@end
