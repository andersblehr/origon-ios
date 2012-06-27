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
static CGFloat const kTitleFontSize = 16.f;

static CGFloat const kDisplayFontToLineHeightScaleFactor = 2.5f;
static CGFloat const kEditingFontToLineHeightScaleFactor = 3.f;


@implementation UIFont (ScFontExtensions)


#pragma mark - Font convenience methods

+ (UIFont *)fontWithType:(ScFontType)fontType
{
    UIFont *font = nil;
    
    if (fontType == ScFontLabel) {
        font = [UIFont boldSystemFontOfSize:kLabelFontSize];
    } else if (fontType == ScFontDetail) {
        font = [UIFont boldSystemFontOfSize:kDetailFontSize];
    } else if (fontType == ScFontEditableDetail) {
        font = [UIFont systemFontOfSize:kDetailFontSize];
    } else if (fontType == ScFontTitle) {
        font = [UIFont boldSystemFontOfSize:kTitleFontSize];
    } else if (fontType == ScFontEditableTitle) {
        font = [UIFont systemFontOfSize:kTitleFontSize];
    }
    
    return font;
}


+ (CGFloat)lineHeightForFontWithType:(ScFontType)fontType
{
    CGFloat height = 0.f;
    
    if ((fontType == ScFontEditableDetail) || (fontType == ScFontEditableTitle)) {
        height = [[UIFont fontWithType:fontType] editingLineHeight];
    } else {
        height = [[UIFont fontWithType:fontType] displayLineHeight];
    }
    
    return height;
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