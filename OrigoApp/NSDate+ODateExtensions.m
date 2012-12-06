//
//  NSDate+ODateExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "NSDate+ODateExtensions.h"

#import "OMeta.h"

NSString * const kDateTimeFormatZulu = @"yyyy-MM-dd'T'HH:mm:ss'Z'";


@implementation NSDate (ODateExtensions)

#pragma mark - Auxiliary methods

- (NSDateComponents *)dateComponentsBeforeNow
{
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    return [calendar components:NSYearCalendarUnit fromDate:self toDate:now options:kNilOptions];
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
    return [self dateComponentsBeforeNow].day;
}


- (NSInteger)yearsBeforeNow
{
    return [self dateComponentsBeforeNow].year;
}


- (BOOL)isBirthDateOfMinor
{
    return ([self yearsBeforeNow] < kAgeOfMajority);
}

@end
