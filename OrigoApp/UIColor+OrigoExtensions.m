//
//  UIColor+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UIColor+OrigoExtensions.h"


@implementation UIColor (OrigoExtensions)

#pragma mark - Core iOS 7 palette RGB shorthands

+ (UIColor *)manateeColor // Grey
{
    return [self colorWithRed:142/255.f green:142/255.f blue:147/255.f alpha:1.f];
}


+ (UIColor *)radicalRedColor
{
    return [self colorWithRed:255/255.f green:45/255.f blue:85/255.f alpha:1.f];
}


+ (UIColor *)redOrangeColor
{
    return [self colorWithRed:255/255.f green:59/255.f blue:48/255.f alpha:1.f];
}


+ (UIColor *)pizazzColor // Orange
{
    return [self colorWithRed:255/255.f green:149/255.f blue:0/255.f alpha:1.f];
}


+ (UIColor *)supernovaColor // Yellow
{
    return [self colorWithRed:255/255.f green:204/255.f blue:0/255.f alpha:1.f];
}


+ (UIColor *)emeraldColor // Green
{
    return [self colorWithRed:76/255.f green:217/255.f blue:100/255.f alpha:1.f];
}


+ (UIColor *)malibuColor // Bright blue
{
    return [self colorWithRed:90/255.f green:200/255.f blue:250/255.f alpha:1.f];
}


+ (UIColor *)curiousBlueColor // Soft blue
{
    return [self colorWithRed:52/255.f green:170/255.f blue:220/255.f alpha:1.f];
}


+ (UIColor *)azureRadianceColor // Standard UI blue
{
    return [self colorWithRed:0/255.f green:122/255.f blue:255/255.f alpha:1.f];
}


+ (UIColor *)indigoColor
{
    return [self colorWithRed:88/255.f green:86/255.f blue:214/255.f alpha:1.f];
}


#pragma mark - Other iOS 7 RGB shorthands

+ (UIColor *)athensGrayColor // Standard table view background colour
{
    return [self colorWithRed:239/255.f green:239/255.f blue:244/255.f alpha:1.f];
}


+ (UIColor *)gainsboroColor // Approximation of selected cell background colour
{
    return [self colorWithRed:220/255.f green:220/255.f blue:220/255.f alpha:1.f];
}


#pragma mark - RGB shorthands used in iOS 6 version

+ (UIColor *)ashGreyColor
{
    return [self colorWithRed:178/255.f green:190/255.f blue:181/255.f alpha:1.f];
}


+ (UIColor *)ghostWhiteColor
{
    return [self colorWithRed:248/255.f green:248/255.f blue:255/255.f alpha:1.f];
}


+ (UIColor *)slateGreyColor
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


#pragma mark - Window tint colour

+ (UIColor *)windowTintColor
{
    return [self pizazzColor];
}


#pragma mark - Background colours

+ (UIColor *)cellBackgroundColor
{
    return [self isabellineColor];
}


+ (UIColor *)selectedCellBackgroundColor
{
    return [self ashGreyColor];
}


+ (UIColor *)titleBackgroundColor
{
    return [OMeta systemIs_iOS6x] ? [self ashGreyColor] : [self windowTintColor];
}


+ (UIColor *)editableTextFieldBackgroundColor
{
    return [OMeta systemIs_iOS6x] ? [self ghostWhiteColor] : [self whiteColor];
}


+ (UIColor *)imagePlaceholderBackgroundColor
{
    return [OMeta systemIs_iOS6x] ? [self offWhiteColor] : [self athensGrayColor];
}


#pragma mark - Text colours

+ (UIColor *)titleTextColor
{
    return [self whiteColor];
}


+ (UIColor *)editableTitleTextColor
{
    return [self detailTextColor];
}


+ (UIColor *)labelTextColor
{
    return [OMeta systemIs_iOS6x] ? [self slateGreyColor] : [self windowTintColor];
}


+ (UIColor *)selectedLabelTextColor
{
    return [self lightTextColor];
}


+ (UIColor *)detailTextColor
{
    return [OMeta systemIs_iOS6x] ? [self darkTextColor] : [self blackColor];
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
    return [OMeta systemIs_iOS6x] ? [self ghostWhiteColor] : [self darkGrayColor];
}


+ (UIColor *)footerTextColor
{
    return [OMeta systemIs_iOS6x] ? [self lightTextColor] : [self darkGrayColor];
}


#pragma mark - Placeholder colours

+ (UIColor *)titlePlaceholderColor
{
    return [self lightTextColor];
}


+ (UIColor *)detailPlaceholderColor
{
    return [self lightGrayColor];
}

@end
