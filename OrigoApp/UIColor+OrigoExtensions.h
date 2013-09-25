//
//  UIColor+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface UIColor (OrigoExtensions)

+ (UIColor *)windowTintColor;

+ (UIColor *)cellBackgroundColor;
+ (UIColor *)selectedCellBackgroundColor;
+ (UIColor *)titleBackgroundColor;
+ (UIColor *)editableTextFieldBackgroundColor;
+ (UIColor *)imagePlaceholderBackgroundColor;

+ (UIColor *)titleTextColor;
+ (UIColor *)editableTitleTextColor;
+ (UIColor *)labelTextColor;
+ (UIColor *)selectedLabelTextColor;
+ (UIColor *)detailTextColor;
+ (UIColor *)selectedDetailTextColor;
+ (UIColor *)imagePlaceholderTextColor;
+ (UIColor *)headerTextColor;
+ (UIColor *)footerTextColor;

+ (UIColor *)titlePlaceholderColor;
+ (UIColor *)detailPlaceholderColor;

@end
