//
//  UIDatePicker+ScDatePickerExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 09.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDatePicker (ScDatePickerExtensions)

- (void)setEarlistValidBirthDate;
- (void)setLatestValidBirthDate;
- (void)setTo01April1976;

@end
