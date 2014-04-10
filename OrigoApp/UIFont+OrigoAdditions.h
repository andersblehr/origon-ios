//
//  UIFont+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIFont (OrigoAdditions)

+ (instancetype)navigationBarTitleFont;
+ (instancetype)navigationBarSubtitleFont;
+ (instancetype)plainHeaderFont;
+ (instancetype)headerFont;
+ (instancetype)footerFont;
+ (instancetype)titleFont;
+ (instancetype)detailFont;
+ (instancetype)listTextFont;
+ (instancetype)listDetailTextFont;
+ (instancetype)alternateListTextFont;

+ (CGFloat)titleFieldHeight;
+ (CGFloat)detailFieldHeight;
+ (CGFloat)detailLineHeight;

- (CGFloat)inputFieldHeight;

@end
