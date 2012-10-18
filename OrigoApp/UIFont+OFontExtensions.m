//
//  UIFont+OFontExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UIFont+OFontExtensions.h"

typedef enum {
    OFontStyleLabel,
    OFontStyleDetail,
    OFontStyleEditableDetail,
    OFontStyleTitle,
    OFontStyleEditableTitle,
    OFontStyleHeader,
    OFontStyleFooter,
} OFontStyle;

static CGFloat const kLabelFontSize = 12.f;
static CGFloat const kDetailFontSize = 14.f;
static CGFloat const kTitleFontSize = 16.f;
static CGFloat const kHeaderFontSize = 17.f;
static CGFloat const kFooterFontSize = 13.f;

static CGFloat const kEditingLineHeightScaleFactor = 1.22f;


@implementation UIFont (OFontExtensions)


#pragma mark - Auxiliary methods

+ (UIFont *)fontWithType:(OFontStyle)fontType
{
    UIFont *font = nil;
    
    if (fontType == OFontStyleLabel) {
        font = [UIFont boldSystemFontOfSize:kLabelFontSize];
    } else if (fontType == OFontStyleDetail) {
        font = [UIFont systemFontOfSize:kDetailFontSize];
    } else if (fontType == OFontStyleEditableDetail) {
        font = [UIFont systemFontOfSize:kDetailFontSize];
    } else if (fontType == OFontStyleTitle) {
        font = [UIFont boldSystemFontOfSize:kTitleFontSize];
    } else if (fontType == OFontStyleEditableTitle) {
        font = [UIFont boldSystemFontOfSize:kTitleFontSize];
    } else if (fontType == OFontStyleHeader) {
        font = [UIFont boldSystemFontOfSize:kHeaderFontSize];
    } else if (fontType == OFontStyleFooter) {
        font = [UIFont systemFontOfSize:kFooterFontSize];
    }
    
    return font;
}


#pragma mark - Predefined Origo fonts

+ (UIFont *)labelFont
{
    return [UIFont fontWithType:OFontStyleLabel];
}


+ (UIFont *)detailFont
{
    return [UIFont fontWithType:OFontStyleDetail];
}


+ (UIFont *)editableDetailFont
{
    return [UIFont fontWithType:OFontStyleEditableDetail];
}


+ (UIFont *)titleFont
{
    return [UIFont fontWithType:OFontStyleTitle];
}


+ (UIFont *)editableTitleFont
{
    return [UIFont fontWithType:OFontStyleEditableTitle];
}


+ (UIFont *)headerFont
{
    return [UIFont fontWithType:OFontStyleHeader];
}


+ (UIFont *)footerFont
{
    return [UIFont fontWithType:OFontStyleFooter];
}


#pragma mark - Scale for editing

- (CGFloat)lineHeightWhenEditing
{
    return kEditingLineHeightScaleFactor * self.lineHeight;
}

@end
