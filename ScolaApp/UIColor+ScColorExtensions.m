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
    ScColorDisabledEditableTextFieldBackground,
    ScColorLabelText,
    ScColorSelectedLabelText,
    ScColorDetailText,
    ScColorSelectedDetailText,
    ScColorImagePlaceholderBackground,
    ScColorImagePlaceholderText,
} ScColorStyle;


@implementation UIColor (ScColorExtensions)


#pragma mark - Auxiliary methods

+ (UIColor *)colorWithType:(ScColorStyle)colorType
{
    UIColor *color = nil;
    
    if (colorType == ScColorCellBackground) {
        color = [UIColor isabellineColor];
    } else if (colorType == ScColorSelectedCellBackground) {
        color = [UIColor ashGrayColor];
    } else if (colorType == ScColorEditableTextFieldBackground) {
        color = [UIColor ghostWhiteColor];
    } else if (colorType == ScColorDisabledEditableTextFieldBackground) {
        color = [UIColor colorWithRed:248/255.f green:248/255.f blue:255/255.f alpha:0.99f];
    } else if (colorType == ScColorLabelText) {
        color = [UIColor slateGrayColor];
    } else if (colorType == ScColorSelectedLabelText) {
        color = [UIColor lightTextColor];
    } else if (colorType == ScColorDetailText) {
        color = [UIColor darkTextColor];
    } else if (colorType == ScColorSelectedDetailText) {
        color = [UIColor whiteColor];
    } else if (colorType == ScColorImagePlaceholderBackground) {
        color = [UIColor ashGrayColor];
    } else if (colorType == ScColorImagePlaceholderText) {
        color = [UIColor colorWithWhite:0.85f alpha:1.f];
    }
    
    return color;
}


#pragma mark - Scola color palette

+ (UIColor *)cellBackgroundColor
{
    return [UIColor colorWithType:ScColorCellBackground];
}


+ (UIColor *)selectedCellBackgroundColor
{
    return [UIColor colorWithType:ScColorSelectedCellBackground];
}


+ (UIColor *)editableTextFieldBackgroundColor
{
    return [UIColor colorWithType:ScColorEditableTextFieldBackground];
}


+ (UIColor *)disabledEditableTextFieldBackgroundColor
{
    return [UIColor colorWithType:ScColorDisabledEditableTextFieldBackground];
}


+ (UIColor *)labelTextColor
{
    return [UIColor colorWithType:ScColorLabelText];
}


+ (UIColor *)selectedLabelTextColor
{
    return [UIColor colorWithType:ScColorSelectedLabelText];
}


+ (UIColor *)detailTextColor
{
    return [UIColor colorWithType:ScColorDetailText];
}


+ (UIColor *)selectedDetailTextColor
{
    return [UIColor colorWithType:ScColorSelectedDetailText];
}


+ (UIColor *)imagePlaceholderBackgroundColor
{
    return [UIColor colorWithType:ScColorImagePlaceholderBackground];
}


+ (UIColor *)imagePlaceholderTextColor
{
    return [UIColor colorWithType:ScColorImagePlaceholderText];
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
