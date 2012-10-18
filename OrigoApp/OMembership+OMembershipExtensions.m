//
//  OMembership+OMembershipExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMembership+OMembershipExtensions.h"

#import "OMeta.h"

#import "OMember.h"
#import "OOrigo.h"


@implementation OMembership (OMembershipExtensions)

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

- (NSComparisonResult)compare:(OMembership *)other
{
    return [self.member.name localizedCaseInsensitiveCompare:other.member.name];
}

@end
