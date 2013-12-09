//
//  UIFont+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UIFont+OrigoAdditions.h"

static NSString * const kiOS7SystemFontName = @"HelveticaNeue";
static NSString * const kiOS7MediumSystemFontName = @"HelveticaNeue-Medium";

static CGFloat const kNavigationBarTitleFontSize = 17.f;
static CGFloat const kNavigationBarSubtitleFontSize = 11.f;
static CGFloat const kHeaderFontSize = 15.f;
static CGFloat const kFooterFontSize = 13.f;
static CGFloat const kTitleFontSize = 17.f;
static CGFloat const kDetailFontSize = 14.f;
static CGFloat const kListTextFontSize = 18.f;
static CGFloat const kListDetailFontSize = 12.f;
static CGFloat const kAlternateListFontSize = 17.f;

static CGFloat const kLineToFieldHeightFactor = 1.34f;
static CGFloat const kLineToFieldHeightFactor_iOS6x = 1.22f;


@implementation UIFont (OrigoAdditions)

#pragma mark - Auxiliary methods

+ (UIFont *)iOS7SystemFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:kiOS7SystemFontName size:size];
}


+ (UIFont *)iOS7MediumSystemFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:kiOS7MediumSystemFontName size:size];
}


#pragma mark - Font shorthands

+ (UIFont *)navigationBarTitleFont
{
    return [UIFont iOS7MediumSystemFontOfSize:kNavigationBarTitleFontSize];
}


+ (UIFont *)navigationBarSubtitleFont
{
    return [UIFont iOS7SystemFontOfSize:kNavigationBarSubtitleFontSize];
}


+ (UIFont *)headerFont
{
    return [UIFont iOS7SystemFontOfSize:kHeaderFontSize];
}


+ (UIFont *)footerFont
{
    return [UIFont iOS7SystemFontOfSize:kFooterFontSize];
}


+ (UIFont *)titleFont
{
    return [UIFont iOS7SystemFontOfSize:kTitleFontSize];
}


+ (UIFont *)detailFont
{
    return [UIFont iOS7SystemFontOfSize:kDetailFontSize];
}


+ (UIFont *)listTextFont
{
    return [UIFont iOS7SystemFontOfSize:kListTextFontSize];
}


+ (UIFont *)listDetailFont
{
    return [UIFont iOS7SystemFontOfSize:kListDetailFontSize];
}


+ (UIFont *)alternateListFont
{
    return [UIFont iOS7SystemFontOfSize:kAlternateListFontSize];
}


#pragma mark - Text field & line height

+ (CGFloat)titleFieldHeight
{
    return [[UIFont titleFont] inputFieldHeight];
}


+ (CGFloat)detailFieldHeight
{
    return [[UIFont detailFont] inputFieldHeight];
}


+ (CGFloat)detailLineHeight
{
    return [UIFont detailFont].lineHeight + 1.f;
}


#pragma mark - Text field height

- (CGFloat)inputFieldHeight
{
    CGFloat lineToFieldHeightFactor = [OMeta systemIs_iOS6x] ? kLineToFieldHeightFactor_iOS6x : kLineToFieldHeightFactor;
    
    return lineToFieldHeightFactor * self.lineHeight;
}

@end
