//
//  UIFont+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIFont (OrigoAdditions)

+ (UIFont *)navigationBarTitleFont;
+ (UIFont *)navigationBarSubtitleFont;
+ (UIFont *)plainHeaderFont;
+ (UIFont *)headerFont;
+ (UIFont *)footerFont;
+ (UIFont *)titleFont;
+ (UIFont *)detailFont;
+ (UIFont *)listTextFont;
+ (UIFont *)listDetailTextFont;
+ (UIFont *)alternateListTextFont;

+ (CGFloat)titleFieldHeight;
+ (CGFloat)detailFieldHeight;
+ (CGFloat)detailLineHeight;

- (CGFloat)inputFieldHeight;

@end
