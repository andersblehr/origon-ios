//
//  UIColor+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface UIColor (OrigoExtensions)

+ (UIColor *)toolbarShadowColour;
+ (UIColor *)tableViewBackgroundColour;
+ (UIColor *)tableViewSeparatorColour;
+ (UIColor *)cellBackgroundColour;
+ (UIColor *)selectedCellBackgroundColour;
+ (UIColor *)placeholderColour;

+ (UIColor *)windowTintColour;
+ (UIColor *)titleBackgroundColour;
+ (UIColor *)titlePlaceholderColour;
+ (UIColor *)imagePlaceholderBackgroundColour;
+ (UIColor *)iOS6BarButtonItemColour;

+ (UIColor *)textColour;
+ (UIColor *)headerTextColour;
+ (UIColor *)footerTextColour;
+ (UIColor *)titleTextColour;
+ (UIColor *)labelTextColour;
+ (UIColor *)imagePlaceholderTextColour;

@end
