//
//  UIColor+ScColorExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 04.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (ScColorExtensions)

+ (UIColor *)cellBackgroundColor;
+ (UIColor *)selectedCellBackgroundColor;
+ (UIColor *)editableTextFieldBackgroundColor;
+ (UIColor *)disabledEditableTextFieldBackgroundColor;
+ (UIColor *)labelTextColor;
+ (UIColor *)selectedLabelTextColor;
+ (UIColor *)detailTextColor;
+ (UIColor *)selectedDetailTextColor;
+ (UIColor *)imagePlaceholderBackgroundColor;
+ (UIColor *)imagePlaceholderTextColor;
+ (UIColor *)headerTextColor;
+ (UIColor *)footerTextColor;

+ (UIColor *)ashGrayColor;
+ (UIColor *)ghostWhiteColor;
+ (UIColor *)slateGrayColor;
+ (UIColor *)isabellineColor;

@end
