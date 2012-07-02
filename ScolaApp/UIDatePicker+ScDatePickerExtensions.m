//
//  UIDatePicker+ScDatePickerExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 09.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "UIDatePicker+ScDatePickerExtensions.h"

#import "ScMeta.h"

static int const kMinimumRealisticAge = 5;
static int const kMaximumRealisticAge = 110;


@implementation UIDatePicker (ScDatePickerExtensions)

- (void)setEarliestValidBirthDate
{
    NSDateComponents *earliestBirthDateOffset = [[NSDateComponents alloc] init];
    earliestBirthDateOffset.year = -kMaximumRealisticAge;
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *now = [NSDate date];
    
    self.minimumDate = [calendar dateByAddingComponents:earliestBirthDateOffset toDate:now options:kNilOptions];
}


- (void)setLatestValidBirthDate
{
    NSDate *now = [NSDate date];
    
    if ([ScMeta m].appState == ScAppStateUserRegistration) {
        NSDateComponents *latestBirthDateOffset = [[NSDateComponents alloc] init];
        latestBirthDateOffset.year = -kMinimumRealisticAge;
        
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        self.maximumDate = [calendar dateByAddingComponents:latestBirthDateOffset toDate:now options:kNilOptions];
    } else {
        self.maximumDate = now;
    }
}


- (void)setTo01April1976
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    NSDate *april1st1976 = [dateFormatter dateFromString:@"1976-04-01T20:00:00Z"];
    
    [self setDate:april1st1976 animated:YES];
}

@end
