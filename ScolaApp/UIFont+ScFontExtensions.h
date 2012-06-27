//
//  UIFont+ScFontExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 26.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ScFontTypeLabel,
    ScFontTypeDetail,
    ScFontTypeEditableDetail,
    ScFontTypeTitle,
    ScFontTypeEditableTitle,
} ScFontType;

@interface UIFont (ScFontExtensions)

+ (UIFont *)fontWithType:(ScFontType)fontType;
+ (CGFloat)lineHeightForFontWithType:(ScFontType)fontType;

- (CGFloat)displayLineHeight;
- (CGFloat)editingLineHeight;

@end
