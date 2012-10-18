//
//  UIColor+OColorExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UIColor+OColorExtensions.h"

typedef enum {
    OColorCellBackground,
    OColorSelectedCellBackground,
    OColorEditableTextFieldBackground,
    OColorTitleText,
    OColorLabelText,
    OColorSelectedLabelText,
    OColorDetailText,
    OColorSelectedDetailText,
    OColorImagePlaceholderBackground,
    OColorImagePlaceholderText,
    OColorHeaderText,
    OColorFooterText,
} OColorCategory;


@implementation UIColor (OColorExtensions)


#pragma mark - Auxiliary methods

+ (UIColor *)colorForCategory:(OColorCategory)colorCategory
{
    UIColor *color = nil;
    
    if (colorCategory == OColorCellBackground) {
        color = [UIColor isabellineColor];
    } else if (colorCategory == OColorSelectedCellBackground) {
        color = [UIColor ashGrayColor];
    } else if (colorCategory == OColorEditableTextFieldBackground) {
        color = [UIColor ghostWhiteColor];
    } else if (colorCategory == OColorTitleText) {
        color = [UIColor whiteColor];
    } else if (colorCategory == OColorLabelText) {
        color = [UIColor slateGrayColor];
    } else if (colorCategory == OColorSelectedLabelText) {
        color = [UIColor lightTextColor];
    } else if (colorCategory == OColorDetailText) {
        color = [UIColor darkTextColor];
    } else if (colorCategory == OColorSelectedDetailText) {
        color = [UIColor whiteColor];
    } else if (colorCategory == OColorImagePlaceholderBackground) {
        color = [UIColor colorWithWhite:0.93f alpha:1.f];
    } else if (colorCategory == OColorImagePlaceholderText) {
        color = [UIColor whiteColor];
    } else if (colorCategory == OColorHeaderText) {
        color = [UIColor ghostWhiteColor];
    } else if (colorCategory == OColorFooterText) {
        color = [UIColor lightTextColor];
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


#pragma mark - Origo colour palette

+ (UIColor *)cellBackgroundColor
{
    return [UIColor colorForCategory:OColorCellBackground];
}


+ (UIColor *)selectedCellBackgroundColor
{
    return [UIColor colorForCategory:OColorSelectedCellBackground];
}


+ (UIColor *)editableTextFieldBackgroundColor
{
    return [UIColor colorForCategory:OColorEditableTextFieldBackground];
}


+ (UIColor *)titleTextColor
{
    return [UIColor colorForCategory:OColorTitleText];
}


+ (UIColor *)labelTextColor
{
    return [UIColor colorForCategory:OColorLabelText];
}


+ (UIColor *)selectedLabelTextColor
{
    return [UIColor colorForCategory:OColorSelectedLabelText];
}


+ (UIColor *)detailTextColor
{
    return [UIColor colorForCategory:OColorDetailText];
}


+ (UIColor *)selectedDetailTextColor
{
    return [UIColor colorForCategory:OColorSelectedDetailText];
}


+ (UIColor *)imagePlaceholderBackgroundColor
{
    return [UIColor colorForCategory:OColorImagePlaceholderBackground];
}


+ (UIColor *)imagePlaceholderTextColor
{
    return [UIColor colorForCategory:OColorImagePlaceholderText];
}


+ (UIColor *)headerTextColor
{
    return [UIColor colorForCategory:OColorHeaderText];
}


+ (UIColor *)footerTextColor
{
    return [UIColor colorForCategory:OColorFooterText];
}

@end
