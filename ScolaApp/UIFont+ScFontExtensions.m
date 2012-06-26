//
//  UIFont+ScFontExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 26.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "UIFont+ScFontExtensions.h"

static CGFloat const kLabelFontSize = 12.f;
static CGFloat const kDetailFontSize = 14.f;

static CGFloat const kDisplayFontToLineHeightScaleFactor = 2.5f;
static CGFloat const kEditingFontToLineHeightScaleFactor = 3.f;


@implementation UIFont (ScFontExtensions)


#pragma mark - Standard fonts

+ (UIFont *)labelFont
{
    return [UIFont boldSystemFontOfSize:kLabelFontSize];
}


+ (UIFont *)detailFont
{
    return [UIFont boldSystemFontOfSize:kDetailFontSize];
}


+ (UIFont *)editableDetailFont
{
    return [UIFont systemFontOfSize:kDetailFontSize];
}


#pragma mark - Font size implications

+ (CGFloat)labelLineHeight
{
    return [[UIFont labelFont] displayLineHeight];
}


+ (CGFloat)detailLineHeight
{
    return [[UIFont detailFont] displayLineHeight];
}


+ (CGFloat)editableDetailLineHeight
{
    return [[UIFont editableDetailFont] editingLineHeight];
}


- (CGFloat)displayLineHeight
{
    return kDisplayFontToLineHeightScaleFactor * self.xHeight;
}


- (CGFloat)editingLineHeight
{
    return kEditingFontToLineHeightScaleFactor * self.xHeight;
}

@end
