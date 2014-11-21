//
//  NSDate+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kDateTimeFormatZulu;

@interface NSDate (OrigoAdditions)

+ (NSDate *)defaultDate;
+ (NSDate *)earliestValidBirthDate;
+ (NSDate *)latestValidBirthDate;

- (NSNumber *)serialisedDate;
+ (NSDate *)dateFromSerialisedDate:(NSNumber *)deserialisedDate;

- (NSString *)localisedDateString;
- (NSString *)localisedDateTimeString;
- (NSString *)localisedAgeString;

- (NSInteger)daysBeforeNow;
- (NSInteger)yearsBeforeNow;
- (NSInteger)yearsBeforeDate:(NSDate *)date;

- (BOOL)isBeforeDate:(NSDate *)date;
- (BOOL)isBirthDateOfMinor;

@end
