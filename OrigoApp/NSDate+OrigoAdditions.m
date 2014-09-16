//
//  NSDate+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "NSDate+OrigoAdditions.h"

NSString * const kDateTimeFormatZulu = @"yyyy-MM-dd'T'HH:mm:ss'Z'";

static NSString * const kDefaultDate = @"1976-04-01T20:00:00Z";

static NSInteger const kMinimumRealisticUserAge = 6;
static NSInteger const kMaximumRealisticUserAge = 100;

static NSCalendar *_calendar = nil;


@implementation NSDate (OrigoAdditions)

#pragma mark - Auxiliary methods

+ (NSCalendar *)calendar
{
    if (!_calendar) {
        _calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    }
    
    return _calendar;
}


- (NSDateComponents *)dateComponentsBeforeDate:(NSDate *)date;
{
    return [[[self class] calendar] components:NSYearCalendarUnit fromDate:self toDate:date options:kNilOptions];
}


#pragma mark - Specific dates

+ (instancetype)defaultDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = kDateTimeFormatZulu;
    
    return [dateFormatter dateFromString:kDefaultDate];
}


+ (instancetype)earliestValidBirthDate
{
    NSDateComponents *earliestBirthDateOffset = [[NSDateComponents alloc] init];
    earliestBirthDateOffset.year = -kMaximumRealisticUserAge;
    
    NSDate *now = [self date];
    
    return [[self calendar] dateByAddingComponents:earliestBirthDateOffset toDate:now options:kNilOptions];
}


+ (NSDate *)latestValidBirthDate
{
    NSDate *now = [self date];
    NSDate *latestValidBirthDate = now;
    
    if ([[OState s] targetIs:kTargetUser]) {
        NSDateComponents *latestBirthDateOffset = [[NSDateComponents alloc] init];
        latestBirthDateOffset.year = -kMinimumRealisticUserAge;
        
        latestValidBirthDate = [[self calendar] dateByAddingComponents:latestBirthDateOffset toDate:now options:kNilOptions];
    }
    
    return latestValidBirthDate;
}


#pragma mark - Converting from back-end date format

- (NSNumber *)serialisedDate
{
    return [NSNumber numberWithLongLong:[self timeIntervalSince1970] * 1000];
}


+ (NSDate *)dateFromSerialisedDate:(NSNumber *)serialisedDate
{
    return [self dateWithTimeIntervalSince1970:[serialisedDate doubleValue] / 1000];
}


#pragma mark - Localised date formatting

- (NSString *)localisedDateString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDoesRelativeDateFormatting:YES];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    return [dateFormatter stringFromDate:self];
}


- (NSString *)localisedDateTimeString
{
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDoesRelativeDateFormatting:YES];
    [timeFormatter setDateStyle:NSDateFormatterNoStyle];
    [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
    [timeFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    return [NSString stringWithFormat:NSLocalizedString(@"%@ at %@", @""), [self localisedDateString], [timeFormatter stringFromDate:self]];
}


- (NSString *)localisedAgeString
{
    return [NSString stringWithFormat:NSLocalizedString(@"%d years", @""), [self yearsBeforeNow]];
}


#pragma mark - Convenience methods

- (NSInteger)daysBeforeNow
{
    return [self dateComponentsBeforeDate:[[self class] date]].day;
}


- (NSInteger)yearsBeforeNow
{
    return [self yearsBeforeDate:[[self class] date]];
}


- (NSInteger)yearsBeforeDate:(NSDate *)date
{
    return [self dateComponentsBeforeDate:date].year;
}


- (BOOL)isBirthDateOfMinor
{
    return [self yearsBeforeNow] < kAgeOfMajority;
}

@end
