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
    return [UIFont boldSystemFontOfSize:kTitleFontSize];
}


+ (UIFont *)labelFont
{
    return [UIFont boldSystemFontOfSize:kLabelFontSize];
}


+ (UIFont *)detailFont
{
    return [UIFont systemFontOfSize:kDetailFontSize];
}


+ (UIFont *)headerFont
{
    return [UIFont boldSystemFontOfSize:kHeaderFontSize];
}


+ (UIFont *)footerFont
{
    return [UIFont systemFontOfSize:kFooterFontSize];
}


#pragma mark - Text field height

- (CGFloat)textFieldHeight
{
    return kFieldHeightScaleFactor * self.lineHeight;
}


- (CGFloat)textViewLineHeight
{
    return [self textFieldHeight] - 1.f;
}

@end
