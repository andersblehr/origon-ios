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

+ (UIColor *)athensGrayColor // Default table view background colour
{
    return [self colorWithRed:239/255.f green:239/255.f blue:244/255.f alpha:1.f];
}


+ (UIColor *)frenchGrayColor // Default table view separator colour
{
    return [self colorWithRed:200/255.f green:199/255.f blue:204/255.f alpha:1.f];
}


+ (UIColor *)blackRussianColor
{
    return [self colorWithRed:0/255.f green:0/255.f blue:25/255.f alpha:0.22f];
}


#pragma mark - iOS 7 default colours

+ (UIColor *)windowTintColor
{
    return [self pizazzColor];
}


+ (UIColor *)tableViewBackgroundColor
{
    return [self athensGrayColor];
}


+ (UIColor *)tableViewSeparatorColor
{
    return [self frenchGrayColor];
}


#pragma mark - iOS 6 navigation & toobar colour

+ (UIColor *)barTintColor
{
    return [self manateeColor];
}


#pragma mark - Background colours

+ (UIColor *)cellBackgroundColor
{
    return [self whiteColor];
}


+ (UIColor *)selectedCellBackgroundColor
{
    return [self tableViewSeparatorColor];
}


+ (UIColor *)titleBackgroundColor
{
    return [self windowTintColor];
}


+ (UIColor *)imagePlaceholderBackgroundColor
{
    return [self tableViewBackgroundColor];
}


#pragma mark - Text colours

+ (UIColor *)defaultTextColor
{
    return [self blackColor];
}


+ (UIColor *)headerTextColor
{
    return [self darkGrayColor];
}


+ (UIColor *)footerTextColor
{
    return [self darkGrayColor];
}


+ (UIColor *)titleTextColor
{
    return [self whiteColor];
}


+ (UIColor *)labelTextColor
{
    return [self windowTintColor];
}


+ (UIColor *)imagePlaceholderTextColor
{
    return [self whiteColor];
}


#pragma mark - Placeholder colours

+ (UIColor *)defaultPlaceholderColor
{
    return [OMeta systemIs_iOS6x] ? [self lightGrayColor] : [self blackRussianColor];
}


+ (UIColor *)titlePlaceholderColor
{
    return [self colorWithWhite:1.f alpha:0.6f];
}

@end
