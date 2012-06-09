//
//  NSDate+ScDateExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 09.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "NSDate+ScDateExtensions.h"

static NSInteger const kAgeOfMajority = 18;


@implementation NSDate (ScDateExtensions)

- (BOOL)isBirthDateOfMinor
{
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents *ageComponents = [calendar components:NSYearCalendarUnit fromDate:self toDate:now options:kNilOptions];
    
    return (ageComponents.year < kAgeOfMajority);
}

@end
