//
//  ScMember+ScMemberExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 16.05.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMember+ScMemberExtensions.h"

static int const kMinimumRealisticAge = 5;
static int const kMaximumRealisticAge = 110;

static NSInteger const kAgeOfMajority = 18;


@implementation ScMember (ScMemberExtensions)


#pragma mark - Meta information

- (BOOL)hasValidBirthDate
{
    NSDate *now = [NSDate date];
    
    BOOL isValid = ([self.dateOfBirth compare:now] == NSOrderedAscending);
    
    if (isValid) {
        NSDateComponents *ageComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:self.dateOfBirth toDate:now options:kNilOptions];
        NSInteger providedAge = ageComponents.year;
        
        isValid = isValid && (providedAge >= kMinimumRealisticAge);
        isValid = isValid && (providedAge <= kMaximumRealisticAge);
    }
    
    return isValid;
}


- (BOOL)hasMobilPhone
{
    return (self.mobilePhone.length > 0);
}


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


#pragma mark - Comparison

- (NSComparisonResult)compare:(ScMember *)other
{
    return [self.name compare:other.name];
}

@end
