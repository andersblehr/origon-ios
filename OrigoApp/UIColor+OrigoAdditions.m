//
//  UIColor+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "UIColor+OrigoAdditions.h"

static CGFloat const kAlphaDimmedBackground = 0.4f;


@implementation UIColor (OrigoAdditions)

#pragma mark - Core iOS 7 palette RGB shorthands

+ (instancetype)manateeColour // Grey
{
    return [self colorWithRed:142/255.f green:142/255.f blue:147/255.f alpha:1.f];
}


+ (instancetype)radicalRedColour
{
    return [self colorWithRed:255/255.f green:45/255.f blue:85/255.f alpha:1.f];
}


+ (instancetype)redOrangeColour
{
    return [self colorWithRed:255/255.f green:59/255.f blue:48/255.f alpha:1.f];
}


+ (instancetype)pizazzColour // Orange
{
    return [self colorWithRed:255/255.f green:149/255.f blue:0/255.f alpha:1.f];
}


+ (instancetype)supernovaColour // Yellow
{
    return [self colorWithRed:255/255.f green:204/255.f blue:0/255.f alpha:1.f];
}


+ (instancetype)emeraldColour // Green
{
    return [self colorWithRed:76/255.f green:217/255.f blue:100/255.f alpha:1.f];
}


+ (instancetype)malibuColour // Bright blue
{
    return [self colorWithRed:90/255.f green:200/255.f blue:250/255.f alpha:1.f];
}


+ (instancetype)curiousBlueColour // Soft blue
{
    return [self colorWithRed:52/255.f green:170/255.f blue:220/255.f alpha:1.f];
}


+ (instancetype)azureRadianceColour // Standard UI blue
{
    return [self colorWithRed:0/255.f green:122/255.f blue:255/255.f alpha:1.f];
}


+ (instancetype)indigoColour
{
    return [self colorWithRed:88/255.f green:86/255.f blue:214/255.f alpha:1.f];
}


#pragma mark - iOS 7 default colours


+ (instancetype)toolbarColour
{
    return [self colorWithRed:248/255.f green:248/255.f blue:248/255.f alpha:0.99f];
}


+ (instancetype)toolbarHairlineColour
{
    return [self lightGrayColor];
}


+ (instancetype)tableViewBackgroundColour
{
    return [self colorWithRed:239/255.f green:239/255.f blue:244/255.f alpha:1.f];
}


+ (instancetype)tableViewSeparatorColour
{
    return [self colorWithRed:200/255.f green:199/255.f blue:204/255.f alpha:1.f];
}


+ (instancetype)cellBackgroundColour
{
    return [self whiteColor];
}


+ (instancetype)selectedCellBackgroundColour
{
    return [self tableViewSeparatorColour];
}


+ (instancetype)alertViewBackgroundColour
{
    return [self colorWithRed:226.f/255 green:226.f/255 blue:226.f/255 alpha:1.f];
}


#pragma mark - Interface colours

+ (instancetype)windowTintColour
{
    return [self pizazzColour];
}


+ (instancetype)titleBackgroundColour
{
    return [self windowTintColour];
}


+ (instancetype)titlePlaceholderColour
{
    return [self colorWithWhite:1.f alpha:0.6f];
}


+ (instancetype)imagePlaceholderBackgroundColour
{
    return [self tableViewBackgroundColour];
}


+ (instancetype)iOS6BarButtonItemColour
{
    return [self colorWithRed:255/255.f green:192/255.f blue:104/255.f alpha:1.f];
}


#pragma mark - Text colours

+ (instancetype)textColour
{
    return [self blackColor];
}


+ (instancetype)dimmedTextColour
{
    return [self lightGrayColor];
}


+ (instancetype)notificationTextColour
{
    return [self windowTintColour];
}


+ (instancetype)placeholderTextColour
{
    UIColor *placeholderTextColor = nil;
    
    if ([OMeta systemIs_iOS6x]) {
        placeholderTextColor = [self lightGrayColor];
    } else {
        placeholderTextColor = [self colorWithRed:0/255.f green:0/255.f blue:25/255.f alpha:0.22f];
    }
    
    return placeholderTextColor;
}


+ (instancetype)headerTextColour
{
    return [self darkGrayColor];
}


+ (instancetype)footerTextColour
{
    return [self darkGrayColor];
}


+ (instancetype)titleTextColour
{
    return [self whiteColor];
}


+ (instancetype)labelTextColour
{
    return [self windowTintColour];
}


+ (instancetype)imagePlaceholderTextColour
{
    return [self whiteColor];
}


#pragma mark - Dimmed view colour

+ (instancetype)dimmedViewColour
{
    return [[UIColor blackColor] colorWithAlphaComponent:kAlphaDimmedBackground];
}

@end
