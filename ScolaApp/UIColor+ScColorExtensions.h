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
    ScColorFieldBackground,
    ScColorLabel,
    ScColorSelectedLabel,
    ScColorText,
    ScColorSelectedText,
} ScColorType;

@interface UIColor (ScColorExtensions)

+ (UIColor *)colorWithType:(ScColorType)colorType;

+ (UIColor *)ashGrayColor;
+ (UIColor *)ghostWhiteColor;
+ (UIColor *)slateGrayColor;
+ (UIColor *)isabellineColor;

@end
