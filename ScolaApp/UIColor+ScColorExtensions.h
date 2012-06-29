//
//  UIColor+ScColorExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 04.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ScColorBackground,
    ScColorSelectedBackground,
    ScColorEditingBackground,
    ScColorLabel,
    ScColorSelectedLabel,
    ScColorText,
    ScColorSelectedText,
    ScColorImagePlaceholder,
    ScColorImagePlaceholderText,
} ScColorType;

@interface UIColor (ScColorExtensions)

+ (UIColor *)colorWithType:(ScColorType)colorType;

+ (UIColor *)ashGrayColor;
+ (UIColor *)ghostWhiteColor;
+ (UIColor *)slateGrayColor;
+ (UIColor *)isabellineColor;

@end
