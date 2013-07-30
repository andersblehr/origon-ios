//
//  NSDate+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "NSDate+OrigoExtensions.h"

NSString * const kDateTimeFormatZulu = @"yyyy-MM-dd'T'HH:mm:ss'Z'";

static NSString * const kDefaultDate = @"1976-04-01T20:00:00Z";

static NSInteger const kMinimumRealisticUserAge = 6;
static NSInteger const kMaximumRealisticUserAge = 100;


@implementation NSDate (OrigoExtensions)

#pragma mark - Auxiliary methods

- (NSDateComponents *)dateComponentsBeforeDate:(NSDate *)date;
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    return [calendar components:NSYearCalendarUnit fromDate:self toDate:date options:kNilOptions];
}


#pragma mark - Specific dates

+ (NSDate *)defaultDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = kDateTimeFormatZulu;
    
    return [dateFormatter dateFromString:kDefaultDate];
}


+ (NSDate *)earliestValidBirthDate
{
    NSDateComponents *earliestBirthDateOffset = [[NSDateComponents alloc] init];
    earliestBirthDateOffset.year = -kMaximumRealisticUserAge;
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *now = [NSDate date];
    
    return [calendar dateByAddingComponents:earliestBirthDateOffset toDate:now options:kNilOptions];
}


+ (NSDate *)latestValidBirthDate
{
    NSDate *now = [NSDate date];
    NSDate *latestValidBirthDate = now;
    
    if ([[OState s] actionIs:kActionRegister] && [[OState s] targetIs:kTargetUser]) {
        NSDateComponents *latestBirthDateOffset = [[NSDateComponents alloc] init];
        latestBirthDateOffset.year = -kMinimumRealisticUserAge;
        
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        latestValidBirthDate = [calendar dateByAddingComponents:latestBirthDateOffset toDate:now options:kNilOptions];
    }
    
    return latestValidBirthDate;
}


#pragma mark - Converting from back-end date format

+ (NSDate *)dateWithDeserialisedDate:(NSNumber *)deserialisedDate
{
    return [NSDate dateWithTimeIntervalSince1970:[deserialisedDate doubleValue] / 1000];
}


#pragma mark - Localised date formatting

- (NSString *)localisedDateString
{
    return [NSDateFormatter localizedStringFromDate:self dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
}


#pragma mark - Convenience methods

- (NSInteger)daysBeforeNow
{
    return [self dateComponentsBeforeDate:[NSDate date]].day;
}


- (NSInteger)yearsBeforeNow
{
    return [self yearsBeforeDate:[NSDate date]];
}


- (NSInteger)yearsBeforeDate:(NSDate *)date
{
    return [self dateComponentsBeforeDate:date].year;
}


- (BOOL)isBirthDateOfMinor
{
    return ([self yearsBeforeNow] < kAgeOfMajority);
}

@end
