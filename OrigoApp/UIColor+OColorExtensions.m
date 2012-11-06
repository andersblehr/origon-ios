//
//  UIColor+OColorExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UIColor+OColorExtensions.h"


@implementation UIColor (OColorExtensions)

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


+ (UIColor *)offWhiteColor
{
    return [UIColor colorWithWhite:0.93f alpha:1.f];
}


#pragma mark - Background colours

+ (UIColor *)cellBackgroundColor
{
    return [UIColor isabellineColor];
}


+ (UIColor *)selectedCellBackgroundColor
{
    return [UIColor ashGrayColor];
}


+ (UIColor *)titleBackgroundColor
{
    return [UIColor ashGrayColor];
}


+ (UIColor *)editableTextFieldBackgroundColor
{
    return [UIColor ghostWhiteColor];
}


+ (UIColor *)imagePlaceholderBackgroundColor
{
    return [UIColor offWhiteColor];
}


#pragma mark - Text colours

+ (UIColor *)titleTextColor
{
    return [UIColor whiteColor];
}


+ (UIColor *)editableTitleTextColor
{
    return [UIColor darkTextColor];
}


+ (UIColor *)labelTextColor
{
    return [UIColor slateGrayColor];
}


+ (UIColor *)selectedLabelTextColor
{
    return [UIColor lightTextColor];
}


+ (UIColor *)detailTextColor
{
    return [UIColor darkTextColor];
}


+ (UIColor *)selectedDetailTextColor
{
    return [UIColor whiteColor];
}


+ (UIColor *)imagePlaceholderTextColor
{
    return [UIColor whiteColor];
}


+ (UIColor *)headerTextColor
{
    return [UIColor ghostWhiteColor];
}


+ (UIColor *)footerTextColor
{
    return [UIColor lightTextColor];
}

@end
