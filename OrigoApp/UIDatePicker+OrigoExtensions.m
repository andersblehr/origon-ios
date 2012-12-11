//
//  UIDatePicker+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UIDatePicker+OrigoExtensions.h"

#import "NSDate+OrigoExtensions.h"

#import "OMeta.h"
#import "OState.h"

static int const kMinimumRealisticAge = 6;
static int const kMaximumRealisticAge = 100;


@implementation UIDatePicker (OrigoExtensions)

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
    
    if ([OState s].actionIsRegister &&
        [OState s].targetIsMember && [OState s].aspectIsSelf) {
        NSDateComponents *latestBirthDateOffset = [[NSDateComponents alloc] init];
        latestBirthDateOffset.year = -kMinimumRealisticAge;
        
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        self.maximumDate = [calendar dateByAddingComponents:latestBirthDateOffset toDate:now options:kNilOptions];
    } else {
        self.maximumDate = now;
    }
}


- (void)setToDefaultDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = kDateTimeFormatZulu;
    NSDate *april1st1976 = [dateFormatter dateFromString:@"1976-04-01T20:00:00Z"];
    
    [self setDate:april1st1976 animated:YES];
}

@end
