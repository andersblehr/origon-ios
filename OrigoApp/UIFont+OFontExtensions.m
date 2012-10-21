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

+ (UIFont *)fontWithStyle:(OFontStyle)fontStyle
{
    UIFont *font = nil;
    
    if (fontStyle == OFontStyleLabel) {
        font = [UIFont boldSystemFontOfSize:kLabelFontSize];
    } else if (fontStyle == OFontStyleDetail) {
        font = [UIFont systemFontOfSize:kDetailFontSize];
    } else if (fontStyle == OFontStyleEditableDetail) {
        font = [UIFont systemFontOfSize:kDetailFontSize];
    } else if (fontStyle == OFontStyleTitle) {
        font = [UIFont boldSystemFontOfSize:kTitleFontSize];
    } else if (fontStyle == OFontStyleEditableTitle) {
        font = [UIFont boldSystemFontOfSize:kTitleFontSize];
    } else if (fontStyle == OFontStyleHeader) {
        font = [UIFont boldSystemFontOfSize:kHeaderFontSize];
    } else if (fontStyle == OFontStyleFooter) {
        font = [UIFont systemFontOfSize:kFooterFontSize];
    }
    
    return font;
}


#pragma mark - Predefined Origo fonts

+ (UIFont *)labelFont
{
    return [UIFont fontWithStyle:OFontStyleLabel];
}


+ (UIFont *)detailFont
{
    return [UIFont fontWithStyle:OFontStyleDetail];
}


+ (UIFont *)editableDetailFont
{
    return [UIFont fontWithStyle:OFontStyleEditableDetail];
}


+ (UIFont *)titleFont
{
    return [UIFont fontWithStyle:OFontStyleTitle];
}


+ (UIFont *)editableTitleFont
{
    return [UIFont fontWithStyle:OFontStyleEditableTitle];
}


+ (UIFont *)headerFont
{
    return [UIFont fontWithStyle:OFontStyleHeader];
}


+ (UIFont *)footerFont
{
    return [UIFont fontWithStyle:OFontStyleFooter];
}


#pragma mark - Scale for editing

- (CGFloat)lineHeightWhenEditing
{
    return kEditingLineHeightScaleFactor * self.lineHeight;
}

@end
