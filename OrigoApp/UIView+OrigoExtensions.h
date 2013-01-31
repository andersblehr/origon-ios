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

- (void)addDropShadowForInternalTableViewCell;
- (void)addDropShadowForTrailingTableViewCell;
- (void)addDropShadowForPhotoFrame;

- (void)hasDropShadow:(BOOL)hasDropShadow;
- (void)redrawDropShadow;

@end
