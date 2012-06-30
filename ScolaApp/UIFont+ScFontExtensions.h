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
+ (UIFont *)titleFont;
+ (UIFont *)editableTitleFont;

- (CGFloat)lineHeight;
- (CGFloat)lineHeightWhenEditing;

@end
