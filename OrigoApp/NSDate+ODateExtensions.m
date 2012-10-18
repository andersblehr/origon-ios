//
//  NSDate+ODateExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "NSDate+ODateExtensions.h"

static NSInteger const kAgeOfMajority = 18;


@implementation NSDate (ScDateExtensions)

+ (NSDate *)dateWithDeserialisedDate:(NSNumber *)deserialisedDate
{
    return [NSDate dateWithTimeIntervalSince1970:[deserialisedDate doubleValue] / 1000];
}


- (NSString *)localisedDateString
{
    return [NSDateFormatter localizedStringFromDate:self dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
}


- (NSInteger)yearsBeforeNow
{
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents *ageComponents = [calendar components:NSYearCalendarUnit fromDate:self toDate:now options:kNilOptions];
    
    return ageComponents.year;
}


- (BOOL)isBirthDateOfMinor
{
    return ([self yearsBeforeNow] < kAgeOfMajority);
}

@end
