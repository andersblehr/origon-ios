//
//  NSDate+ODateExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (ODateExtensions)

+ (NSDate *)dateWithDeserialisedDate:(NSNumber *)deserialisedDate;

- (NSString *)localisedDateString;

- (NSInteger)yearsBeforeNow;
- (BOOL)isBirthDateOfMinor;

@end
