//
//  UIColor+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface UIColor (OrigoExtensions)

+ (UIColor *)barTintColor;
+ (UIColor *)windowTintColor;
+ (UIColor *)tableViewBackgroundColor;
+ (UIColor *)tableViewSeparatorColor;

+ (UIColor *)cellBackgroundColor;
+ (UIColor *)selectedCellBackgroundColor;
+ (UIColor *)titleBackgroundColor;
+ (UIColor *)imagePlaceholderBackgroundColor;

+ (UIColor *)defaultTextColor;
+ (UIColor *)headerTextColor;
+ (UIColor *)footerTextColor;
+ (UIColor *)titleTextColor;
+ (UIColor *)labelTextColor;
+ (UIColor *)imagePlaceholderTextColor;

+ (UIColor *)defaultPlaceholderColor;
+ (UIColor *)titlePlaceholderColor;

@end
