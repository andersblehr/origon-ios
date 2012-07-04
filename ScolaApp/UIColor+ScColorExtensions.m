//
//  UIColor+ScColorExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 04.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "UIColor+ScColorExtensions.h"

typedef enum {
    ScColorCellBackground,
    ScColorSelectedCellBackground,
    ScColorEditableTextFieldBackground,
    ScColorTitleText,
    ScColorLabelText,
    ScColorSelectedLabelText,
    ScColorDetailText,
    ScColorSelectedDetailText,
    ScColorImagePlaceholderBackground,
    ScColorImagePlaceholderText,
    ScColorHeaderText,
    ScColorFooterText,
} ScColorCategory;


@implementation UIColor (ScColorExtensions)


#pragma mark - Auxiliary methods

+ (UIColor *)colorForCategory:(ScColorCategory)colorCategory
{
    UIColor *color = nil;
    
    if (colorCategory == ScColorCellBackground) {
        color = [UIColor isabellineColor];
    } else if (colorCategory == ScColorSelectedCellBackground) {
        color = [UIColor ashGrayColor];
    } else if (colorCategory == ScColorEditableTextFieldBackground) {
        color = [UIColor ghostWhiteColor];
    } else if (colorCategory == ScColorTitleText) {
        color = [UIColor whiteColor];
    } else if (colorCategory == ScColorLabelText) {
        color = [UIColor slateGrayColor];
    } else if (colorCategory == ScColorSelectedLabelText) {
        color = [UIColor lightTextColor];
    } else if (colorCategory == ScColorDetailText) {
        color = [UIColor darkTextColor];
    } else if (colorCategory == ScColorSelectedDetailText) {
        color = [UIColor whiteColor];
    } else if (colorCategory == ScColorImagePlaceholderBackground) {
        color = [UIColor colorWithWhite:0.93f alpha:1.f];
    } else if (colorCategory == ScColorImagePlaceholderText) {
        color = [UIColor whiteColor];
    } else if (colorCategory == ScColorHeaderText) {
        color = [UIColor ghostWhiteColor];
    } else if (colorCategory == ScColorFooterText) {
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


#pragma mark - Scola colour palette

+ (UIColor *)cellBackgroundColor
{
    return [UIColor colorForCategory:ScColorCellBackground];
}


+ (UIColor *)selectedCellBackgroundColor
{
    return [UIColor colorForCategory:ScColorSelectedCellBackground];
}


+ (UIColor *)editableTextFieldBackgroundColor
{
    return [UIColor colorForCategory:ScColorEditableTextFieldBackground];
}


+ (UIColor *)titleTextColor
{
    return [UIColor colorForCategory:ScColorTitleText];
}


+ (UIColor *)labelTextColor
{
    return [UIColor colorForCategory:ScColorLabelText];
}


+ (UIColor *)selectedLabelTextColor
{
    return [UIColor colorForCategory:ScColorSelectedLabelText];
}


+ (UIColor *)detailTextColor
{
    return [UIColor colorForCategory:ScColorDetailText];
}


+ (UIColor *)selectedDetailTextColor
{
    return [UIColor colorForCategory:ScColorSelectedDetailText];
}


+ (UIColor *)imagePlaceholderBackgroundColor
{
    return [UIColor colorForCategory:ScColorImagePlaceholderBackground];
}


+ (UIColor *)imagePlaceholderTextColor
{
    return [UIColor colorForCategory:ScColorImagePlaceholderText];
}


+ (UIColor *)headerTextColor
{
    return [UIColor colorForCategory:ScColorHeaderText];
}


+ (UIColor *)footerTextColor
{
    return [UIColor colorForCategory:ScColorFooterText];
}

@end
