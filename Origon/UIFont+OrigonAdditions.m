//
//  UIFont+OrigonAdditions.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "UIFont+OrigonAdditions.h"

static NSString * const kGlobalFontName = @"HelveticaNeue";
static NSString * const kGlobalBoldFontName = @"HelveticaNeue-Bold";
static NSString * const kGlobalMediumFontName = @"HelveticaNeue-Medium";

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
    return [self fontWithName:kGlobalMediumFontName size:kNavigationBarTitleFontSize];
}


+ (instancetype)navigationBarSubtitleFont
{
    return [self fontWithName:kGlobalFontName size:kNavigationBarSubtitleFontSize];
}


+ (instancetype)plainHeaderFont
{
    return [self listTextFont];
}


+ (instancetype)headerFont
{
    return [self fontWithName:kGlobalFontName size:kHeaderFontSize];
}


+ (instancetype)footerFont
{
    return [self fontWithName:kGlobalFontName size:kFooterFontSize];
}


+ (instancetype)titleFont
{
    return [self fontWithName:kGlobalFontName size:kTitleFontSize];
}


+ (instancetype)detailFont
{
    return [self fontWithName:kGlobalFontName size:kDetailFontSize];
}


+ (instancetype)boldDetailFont
{
    return [self fontWithName:kGlobalBoldFontName size:kDetailFontSize];
}


+ (instancetype)listTextFont
{
    return [self fontWithName:kGlobalFontName size:kListTextFontSize];
}


+ (instancetype)listDetailTextFont
{
    return [self fontWithName:kGlobalFontName size:kListDetailFontSize];
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
