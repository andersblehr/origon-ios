//
//  UIDatePicker+ODatePickerExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDatePicker (ODatePickerExtensions)

- (void)setEarliestValidBirthDate;
- (void)setLatestValidBirthDate;
- (void)setToDefaultDate;

@end
