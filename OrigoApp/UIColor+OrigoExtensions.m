//
//  UIColor+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UIColor+OrigoExtensions.h"


@implementation UIColor (OrigoExtensions)

#pragma mark - RGB shorthands

+ (UIColor *)ashGrayColor
{
    return [self colorWithRed:178/255.f green:190/255.f blue:181/255.f alpha:1.f];
}


+ (UIColor *)ghostWhiteColor
{
    return [self colorWithRed:248/255.f green:248/255.f blue:255/255.f alpha:1.f];
}


+ (UIColor *)slateGrayColor
{
    return [self colorWithRed:112/255.f green:128/255.f blue:144/255.f alpha:1.f];
}


+ (UIColor *)isabellineColor
{
    return [self colorWithRed:240/255.f green:244/255.f blue:236/255.f alpha:1.f];
}


+ (UIColor *)offWhiteColor
{
    return [self colorWithWhite:0.93f alpha:1.f];
}


#pragma mark - Background colours

+ (UIColor *)cellBackgroundColor
{
    return [self isabellineColor];
}


+ (UIColor *)selectedCellBackgroundColor
{
    return [self ashGrayColor];
}


+ (UIColor *)titleBackgroundColor
{
    return [self ashGrayColor];
}


+ (UIColor *)editableTextFieldBackgroundColor
{
    return [self ghostWhiteColor];
}


+ (UIColor *)imagePlaceholderBackgroundColor
{
    return [self offWhiteColor];
}


#pragma mark - Text colours

+ (UIColor *)titleTextColor
{
    return [self whiteColor];
}


+ (UIColor *)editableTitleTextColor
{
    return [self darkTextColor];
}


+ (UIColor *)labelTextColor
{
    return [self slateGrayColor];
}


+ (UIColor *)selectedLabelTextColor
{
    return [self lightTextColor];
}


+ (UIColor *)detailTextColor
{
    return [self darkTextColor];
}


+ (UIColor *)selectedDetailTextColor
{
    return [self whiteColor];
}


+ (UIColor *)imagePlaceholderTextColor
{
    return [self whiteColor];
}


+ (UIColor *)headerTextColor
{
    return [self ghostWhiteColor];
}


+ (UIColor *)footerTextColor
{
    return [self lightTextColor];
}


#pragma mark - Placeholder colours

+ (UIColor *)defaultPlaceholderColor
{
    return [self lightGrayColor];
}


+ (UIColor *)lightPlaceholderColor
{
    return [self lightTextColor];
}

@end
