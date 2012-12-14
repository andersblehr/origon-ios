//
//  OMembership+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMembership+OrigoExtensions.h"

#import "OMeta.h"
#import "OState.h"

#import "OMember+OrigoExtensions.h"
#import "OOrigo+OrigoExtensions.h"


@implementation OMembership (OrigoExtensions)

#pragma mark - Convenience methods

- (BOOL)hasContactRole
{
    return (self.contactRole != nil);
}


#pragma mark - Comparison

- (NSComparisonResult)compare:(OMembership *)other
{
    NSComparisonResult comparisonResult = NSOrderedSame;

    if ([OState s].targetIsMember) {
        comparisonResult = [self.member.name localizedCaseInsensitiveCompare:other.member.name];
        
        if ([OState s].aspectIsResidence) {
            BOOL thisMemberIsMinor = [self.member isMinor];
            BOOL otherMemberIsMinor = [other.member isMinor];
            
            if ([self.origo isResidence] && (thisMemberIsMinor != otherMemberIsMinor)) {
                if (thisMemberIsMinor && !otherMemberIsMinor) {
                    comparisonResult = NSOrderedDescending;
                } else {
                    comparisonResult = NSOrderedAscending;
                }
            }
        }
    } else if ([OState s].targetIsOrigo) {
        comparisonResult = [self.origo.name localizedCaseInsensitiveCompare:other.origo.name];
    }

    return comparisonResult;
}

@end
