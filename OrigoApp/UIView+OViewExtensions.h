//
//  UIView+OViewExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface UIView (OViewExtensions)

- (void)addGradientLayer;

- (void)addShadowForBottomTableViewCell;
- (void)addShadowForContainedTableViewCell;
- (void)addShadowForEditableTextField;
- (void)addShadowForPhotoFrame;
- (void)removeShadow;

@end
