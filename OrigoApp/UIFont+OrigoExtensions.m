//
//  UIFont+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UIFont+OrigoExtensions.h"

static CGFloat const kTitleFontSize_iOS6x = 16.f;
static CGFloat const kTitleFontSize = 17.f;
static CGFloat const kLabelFontSize_iOS6x = 12.f;
static CGFloat const kLabelFontSize = 14.f;
static CGFloat const kDetailFontSize = 14.f;
static CGFloat const kHeaderFontSize_iOS6x = 17.f;
static CGFloat const kHeaderFontSize = 15.f;
static CGFloat const kFooterFontSize = 13.f;

static CGFloat const kLineToFieldHeightFactor_iOS6x = 1.22f;
static CGFloat const kLineToFieldHeightFactor = 1.34f;


@implementation UIFont (OrigoExtensions)

#pragma mark - Font shorthands

+ (UIFont *)titleFont
{
    UIFont *titleFont = nil;
    
    if ([OMeta systemIs_iOS6x]) {
        titleFont = [self boldSystemFontOfSize:kTitleFontSize_iOS6x];
    } else {
        titleFont = [self systemFontOfSize:kTitleFontSize];
    }
    
    return titleFont;
}


+ (UIFont *)labelFont
{
    UIFont *labelFont = nil;
    
    if ([OMeta systemIs_iOS6x]) {
        labelFont = [self boldSystemFontOfSize:kLabelFontSize_iOS6x];
    } else {
        labelFont = [self systemFontOfSize:kLabelFontSize];
    }
    
    return labelFont;
}


+ (UIFont *)detailFont
{
    return [self systemFontOfSize:kDetailFontSize];
}


+ (UIFont *)headerFont
{
    UIFont *headerFont = nil;
    
    if ([OMeta systemIs_iOS6x]) {
        headerFont = [self boldSystemFontOfSize:kHeaderFontSize_iOS6x];
    } else {
        headerFont = [self systemFontOfSize:kHeaderFontSize];
    }
    
    return headerFont;
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
    CGFloat lineToFieldHeightFactor = [OMeta systemIs_iOS6x] ? kLineToFieldHeightFactor_iOS6x : kLineToFieldHeightFactor;
    
    return lineToFieldHeightFactor * self.lineHeight;
}

@end
