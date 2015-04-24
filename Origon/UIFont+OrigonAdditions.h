//
//  UIFont+OrigonAdditions.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIFont (OrigonAdditions)

+ (instancetype)navigationBarTitleFont;
+ (instancetype)navigationBarSubtitleFont;
+ (instancetype)plainHeaderFont;
+ (instancetype)headerFont;
+ (instancetype)footerFont;
+ (instancetype)titleFont;
+ (instancetype)detailFont;
+ (instancetype)boldDetailFont;
+ (instancetype)listTextFont;
+ (instancetype)listDetailTextFont;
+ (instancetype)notificationFont;

+ (CGFloat)titleFieldHeight;
+ (CGFloat)detailFieldHeight;
+ (CGFloat)detailLineHeight;

- (CGFloat)headerHeight;
- (CGFloat)inputFieldHeight;

@end
