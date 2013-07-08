//
//  UIFont+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface UIFont (OrigoExtensions)

+ (UIFont *)titleFont;
+ (UIFont *)labelFont;
+ (UIFont *)detailFont;
+ (UIFont *)headerFont;
+ (UIFont *)footerFont;

+ (CGFloat)titleFieldHeight;
+ (CGFloat)detailFieldHeight;
+ (CGFloat)detailLineHeight;

- (CGFloat)textFieldHeight;
- (NSInteger)lineCountWithText:(NSString *)text textWidth:(CGFloat)textWidth;

@end
