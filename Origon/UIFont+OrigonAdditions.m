//
//  UIFont+OrigonAdditions.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "UIFont+OrigonAdditions.h"

static CGFloat const kNavigationBarTitleFontSize = 17.f;
static CGFloat const kNavigationBarSubtitleFontSize = 11.f;
static CGFloat const kHeaderFontSize = 15.f;
static CGFloat const kFooterFontSize = 13.f;
static CGFloat const kTitleFontSize = 17.f;
static CGFloat const kDetailFontSize = 14.f;
static CGFloat const kListTextFontSize = 18.f;
static CGFloat const kListDetailFontSize = 12.f;
static CGFloat const kNotificationFontSize = 13.f;

static CGFloat const kLineToFieldHeightFactor = 1.34f;
static CGFloat const kLineToHeaderHeightFactor = 1.5f;


@implementation UIFont (OrigonAdditions)

#pragma mark - Font shorthands

+ (instancetype)navigationBarTitleFont
{
    return [self boldSystemFontOfSize:kNavigationBarTitleFontSize];
}


+ (instancetype)navigationBarSubtitleFont
{
    return [self systemFontOfSize:kNavigationBarSubtitleFontSize];
}


+ (instancetype)plainHeaderFont
{
    return [self listTextFont];
}


+ (instancetype)headerFont
{
    return [self systemFontOfSize:kHeaderFontSize];
}


+ (instancetype)footerFont
{
    return [self systemFontOfSize:kFooterFontSize];
}


+ (instancetype)titleFont
{
    return [self systemFontOfSize:kTitleFontSize];
}


+ (instancetype)detailFont
{
    return [self systemFontOfSize:kDetailFontSize];
}


+ (instancetype)boldDetailFont
{
    return [self boldSystemFontOfSize:kDetailFontSize];
}


+ (instancetype)listTextFont
{
    return [self systemFontOfSize:kListTextFontSize];
}


+ (instancetype)listDetailTextFont
{
    return [self systemFontOfSize:kListDetailFontSize];
}


+ (instancetype)notificationFont
{
    return [self italicSystemFontOfSize:kNotificationFontSize];
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
