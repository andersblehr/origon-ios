//
//  UIFont+OFontExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UIFont+OFontExtensions.h"

static CGFloat const kTitleFontSize = 16.f;
static CGFloat const kLabelFontSize = 12.f;
static CGFloat const kDetailFontSize = 14.f;
static CGFloat const kHeaderFontSize = 17.f;
static CGFloat const kFooterFontSize = 13.f;

static CGFloat const kFieldHeightScaleFactor = 1.22f;


@implementation UIFont (OFontExtensions)

#pragma mark - Font shorthands

+ (UIFont *)titleFont
{
    return [self boldSystemFontOfSize:kTitleFontSize];
}


+ (UIFont *)labelFont
{
    return [self boldSystemFontOfSize:kLabelFontSize];
}


+ (UIFont *)detailFont
{
    return [self systemFontOfSize:kDetailFontSize];
}


+ (UIFont *)headerFont
{
    return [self boldSystemFontOfSize:kHeaderFontSize];
}


+ (UIFont *)footerFont
{
    return [self systemFontOfSize:kFooterFontSize];
}


#pragma mark - Text field & line height

+ (CGFloat)titleFieldHeight
{
    return [[self titleFont] textFieldHeight];
}


+ (CGFloat)detailFieldHeight
{
    return [[self detailFont] textFieldHeight];
}


+ (CGFloat)detailLineHeight
{
    return [self detailFont].lineHeight + 1.f;
}


#pragma mark - Text field height

- (CGFloat)textFieldHeight
{
    return kFieldHeightScaleFactor * self.lineHeight;
}

@end
