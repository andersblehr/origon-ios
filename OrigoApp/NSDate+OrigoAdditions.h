//
//  NSDate+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern NSString * const kDateTimeFormatZulu;

@interface NSDate (OrigoAdditions)

+ (NSDate *)defaultDate;
+ (NSDate *)earliestValidBirthDate;
+ (NSDate *)latestValidBirthDate;
+ (NSDate *)dateWithDeserialisedDate:(NSNumber *)deserialisedDate;

- (NSString *)asString;

- (NSInteger)daysBeforeNow;
- (NSInteger)yearsBeforeNow;
- (NSInteger)yearsBeforeDate:(NSDate *)date;

- (BOOL)isBirthDateOfMinor;

@end
