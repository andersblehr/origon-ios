//
//  ScMember+ScMemberExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 16.05.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMember+ScMemberExtensions.h"

static NSInteger const kAgeOfMajority = 18;

@implementation ScMember (ScMemberExtensions)

- (BOOL)isMinor
{
    BOOL isMinor = NO;
    
    if (self.dateOfBirth) {
        NSDate *now = [NSDate date];
        NSDateComponents *ageComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:self.dateOfBirth toDate:now options:kNilOptions];
        
        isMinor = (ageComponents.year < kAgeOfMajority);
    }
    
    return isMinor;
}

@end
