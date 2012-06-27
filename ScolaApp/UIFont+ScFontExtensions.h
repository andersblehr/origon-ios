//
//  UIFont+ScFontExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 26.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ScFontLabel,
    ScFontDetail,
    ScFontEditableDetail,
    ScFontTitle,
    ScFontEditableTitle,
} ScFontType;

@interface UIFont (ScFontExtensions)

+ (UIFont *)fontWithType:(ScFontType)fontType;
+ (CGFloat)lineHeightForFontWithType:(ScFontType)fontType;

- (CGFloat)displayLineHeight;
- (CGFloat)editingLineHeight;

@end
