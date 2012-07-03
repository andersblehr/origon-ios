//
//  UIFont+ScFontExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 26.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "UIFont+ScFontExtensions.h"

typedef enum {
    ScFontStyleLabel,
    ScFontStyleDetail,
    ScFontStyleEditableDetail,
    ScFontStyleTitle,
    ScFontStyleEditableTitle,
    ScFontStyleHeader,
    ScFontStyleFooter,
} ScFontStyle;

static CGFloat const kLabelFontSize = 12.f;
static CGFloat const kDetailFontSize = 14.f;
static CGFloat const kTitleFontSize = 16.f;
static CGFloat const kHeaderFontSize = 17.f;
static CGFloat const kFooterFontSize = 13.f;

static CGFloat const kEditingLineHeightScaleFactor = 1.22f;


@implementation UIFont (ScFontExtensions)


#pragma mark - Auxiliary methods

+ (UIFont *)fontWithType:(ScFontStyle)fontType
{
    UIFont *font = nil;
    
    if (fontType == ScFontStyleLabel) {
        font = [UIFont boldSystemFontOfSize:kLabelFontSize];
    } else if (fontType == ScFontStyleDetail) {
        font = [UIFont boldSystemFontOfSize:kDetailFontSize];
    } else if (fontType == ScFontStyleEditableDetail) {
        font = [UIFont systemFontOfSize:kDetailFontSize];
    } else if (fontType == ScFontStyleTitle) {
        font = [UIFont boldSystemFontOfSize:kTitleFontSize];
    } else if (fontType == ScFontStyleEditableTitle) {
        font = [UIFont boldSystemFontOfSize:kTitleFontSize];
    } else if (fontType == ScFontStyleHeader) {
        font = [UIFont boldSystemFontOfSize:kHeaderFontSize];
    } else if (fontType == ScFontStyleFooter) {
        font = [UIFont systemFontOfSize:kFooterFontSize];
    }
    
    return font;
}


#pragma mark - Predefined Scola fonts

+ (UIFont *)labelFont
{
    return [UIFont fontWithType:ScFontStyleLabel];
}


+ (UIFont *)detailFont
{
    return [UIFont fontWithType:ScFontStyleDetail];
}


+ (UIFont *)editableDetailFont
{
    return [UIFont fontWithType:ScFontStyleEditableDetail];
}


+ (UIFont *)titleFont
{
    return [UIFont fontWithType:ScFontStyleTitle];
}


+ (UIFont *)editableTitleFont
{
    return [UIFont fontWithType:ScFontStyleEditableTitle];
}


+ (UIFont *)headerFont
{
    return [UIFont fontWithType:ScFontStyleHeader];
}


+ (UIFont *)footerFont
{
    return [UIFont fontWithType:ScFontStyleFooter];
}


#pragma mark - Scale for editing

- (CGFloat)lineHeightWhenEditing
{
    return kEditingLineHeightScaleFactor * self.lineHeight;
}

@end
