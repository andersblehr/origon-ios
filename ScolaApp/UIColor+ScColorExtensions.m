//
//  UIColor+ScColorExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 04.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "UIColor+ScColorExtensions.h"

@implementation UIColor (ScColorExtensions)


#pragma mark - Scola colour palette

+ (UIColor *)colorWithType:(ScColorType)colorType
{
    UIColor *color = nil;
    
    if (colorType == ScColorBackground) {
        color = [UIColor isabellineColor];
    } else if (colorType == ScColorSelectedBackground) {
        color = [UIColor ashGrayColor];
    } else if (colorType == ScColorFieldBackground) {
        color = [UIColor ghostWhiteColor];
    } else if (colorType == ScColorLabel) {
        color = [UIColor slateGrayColor];
    } else if (colorType == ScColorSelectedLabel) {
        color = [UIColor lightTextColor];
    } else if (colorType == ScColorText) {
        color = [UIColor darkTextColor];
    } else if (colorType == ScColorSelectedText) {
        color = [UIColor whiteColor];
    }
    
    return color;
}


#pragma mark - RGB shorthands

+ (UIColor *)ashGrayColor
{
    return [UIColor colorWithRed:178/255.f green:190/255.f blue:181/255.f alpha:1.f];
}


+ (UIColor *)ghostWhiteColor
{
    return [UIColor colorWithRed:248/255.f green:248/255.f blue:255/255.f alpha:1.f];
}


+ (UIColor *)slateGrayColor
{
    return [UIColor colorWithRed:112/255.f green:128/255.f blue:144/255.f alpha:1.f];
}


+ (UIColor *)isabellineColor
{
    return [UIColor colorWithRed:240/255.f green:244/255.f blue:236/255.f alpha:1.f];
}

@end
