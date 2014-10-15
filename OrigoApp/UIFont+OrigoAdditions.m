//
//  UIFont+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
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
static CGFloat const kLineToHeaderHeightFactor = 1.5f;


@implementation UIFont (OrigoAdditions)

#pragma mark - Auxiliary methods

+ (instancetype)iOS7SystemFontOfSize:(CGFloat)size
{
    return [self fontWithName:kiOS7SystemFontName size:size];
}


+ (instancetype)iOS7MediumSystemFontOfSize:(CGFloat)size
{
    return [self fontWithName:kiOS7MediumSystemFontName size:size];
}


#pragma mark - Font shorthands

+ (instancetype)navigationBarTitleFont
{
    return [self iOS7MediumSystemFontOfSize:kNavigationBarTitleFontSize];
}


+ (instancetype)navigationBarSubtitleFont
{
    return [self iOS7SystemFontOfSize:kNavigationBarSubtitleFontSize];
}


+ (instancetype)plainHeaderFont
{
    return [self listTextFont];
}


+ (instancetype)headerFont
{
    return [self iOS7SystemFontOfSize:kHeaderFontSize];
}


+ (instancetype)footerFont
{
    return [self iOS7SystemFontOfSize:kFooterFontSize];
}


+ (instancetype)titleFont
{
    return [self iOS7SystemFontOfSize:kTitleFontSize];
}


+ (instancetype)detailFont
{
    return [self iOS7SystemFontOfSize:kDetailFontSize];
}


+ (instancetype)listTextFont
{
    return [self iOS7SystemFontOfSize:kListTextFontSize];
}


+ (instancetype)listDetailTextFont
{
    return [self iOS7SystemFontOfSize:kListDetailFontSize];
}


+ (instancetype)alternateListTextFont
{
    return [self iOS7SystemFontOfSize:kAlternateListFontSize];
}


#pragma mark - Text field & line height

+ (CGFloat)titleFieldHeight
{
    return [[self titleFont] inputFieldHeight];
}


+ (CGFloat)detailFieldHeight
{
    return [[self detailFont] inputFieldHeight];
}


+ (CGFloat)detailLineHeight
{
    return [[self detailFont] lineHeight] + 1.f;
}


#pragma mark - Height computation

- (CGFloat)headerHeight
{
    return kLineToHeaderHeightFactor * self.lineHeight;
}


- (CGFloat)inputFieldHeight
{
    return kLineToFieldHeightFactor * self.lineHeight;
}

@end
