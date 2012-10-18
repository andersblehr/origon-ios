//
//  UIFont+OFontExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIFont (OFontExtensions)

+ (UIFont *)labelFont;
+ (UIFont *)detailFont;
+ (UIFont *)editableDetailFont;
+ (UIFont *)titleFont;
+ (UIFont *)editableTitleFont;
+ (UIFont *)headerFont;
+ (UIFont *)footerFont;

- (CGFloat)lineHeightWhenEditing;

@end
