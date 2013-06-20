//
//  UIView+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface UIView (OrigoExtensions)

- (void)addGradientLayer;

- (void)addDropShadowForTableViewCellTrailing:(BOOL)trailing;
- (void)addDropShadowForPhotoFrame;

- (void)toggleDropShadow:(BOOL)isVisible;
- (void)redrawDropShadow;

@end
