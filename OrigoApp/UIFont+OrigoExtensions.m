//
//  UIFont+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UIFont+OrigoExtensions.h"

static NSString * const kiOS7SystemFontName = @"Helvetica Neue";

static CGFloat const kHeaderFontSize = 15.f;
static CGFloat const kFooterFontSize = 13.f;
static CGFloat const kTitleFontSize = 17.f;
static CGFloat const kDetailFontSize = 14.f;
static CGFloat const kListTextFontSize = 18.f;
static CGFloat const kListDetailFontSize = 12.f;

static CGFloat const kLineToFieldHeightFactor_iOS6x = 1.22f;
static CGFloat const kLineToFieldHeightFactor = 1.34f;


@implementation UIFont (OrigoExtensions)

#pragma mark - Auxiliary methods

+ (UIFont *)iOS7SystemFontOfSize:(CGFloat)size
{
    return [UIFont fontWithName:kiOS7SystemFontName size:size];
}


#pragma mark - Font shorthands

+ (UIFont *)headerFont
{
    return [self iOS7SystemFontOfSize:kHeaderFontSize];
}


+ (UIFont *)footerFont
{
    return [self iOS7SystemFontOfSize:kFooterFontSize];
}


+ (UIFont *)titleFont
{
    return [self iOS7SystemFontOfSize:kTitleFontSize];
}


+ (UIFont *)detailFont
{
    return [self iOS7SystemFontOfSize:kDetailFontSize];
}


+ (UIFont *)listTextFont
{
    return [self iOS7SystemFontOfSize:kListTextFontSize];
}


+ (UIFont *)listDetailFont
{
    return [self iOS7SystemFontOfSize:kListDetailFontSize];
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
    CGFloat lineToFieldHeightFactor = [OMeta systemIs_iOS6x] ? kLineToFieldHeightFactor_iOS6x : kLineToFieldHeightFactor;
    
    return lineToFieldHeightFactor * self.lineHeight;
}

@end
