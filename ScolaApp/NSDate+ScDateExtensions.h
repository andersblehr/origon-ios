//
//  NSDate+ScDateExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 09.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (ScDateExtensions)

+ (NSDate *)dateWithDeserialisedDate:(NSNumber *)deserialisedDate;

- (NSString *)localisedDateString;

- (NSInteger)yearsBeforeNow;
- (BOOL)isBirthDateOfMinor;

@end
