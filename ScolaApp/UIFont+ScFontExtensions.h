//
//  UIFont+ScFontExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 26.06.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIFont (ScFontExtensions)

+ (UIFont *)labelFont;
+ (UIFont *)detailFont;
+ (UIFont *)editableDetailFont;

+ (CGFloat)labelLineHeight;
+ (CGFloat)detailLineHeight;
+ (CGFloat)editableDetailLineHeight;

- (CGFloat)displayLineHeight;
- (CGFloat)editingLineHeight;

@end
