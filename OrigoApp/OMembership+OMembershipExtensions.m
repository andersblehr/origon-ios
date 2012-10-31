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

#import "OMember+OMemberExtensions.h"
#import "OOrigo+OOrigoExtensions.h"


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
    NSComparisonResult comparisonResult = [self.member.name localizedCaseInsensitiveCompare:other.member.name];
    
    BOOL thisMemberIsMinor = [self.member isMinor];
    BOOL otherMemberIsMinor = [other.member isMinor];
    
    if ([self.origo isResidence] && (thisMemberIsMinor != otherMemberIsMinor)) {
        if (thisMemberIsMinor && !otherMemberIsMinor) {
            comparisonResult = NSOrderedDescending;
        } else {
            comparisonResult = NSOrderedAscending;
        }
    }

    return comparisonResult;
}

@end
