//
//  UIView+ScViewExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 21.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface UIView (ScViewExtensions)

- (void)addGradientLayer;

- (void)addShadowForBottomTableViewCell;
- (void)addShadowForNonBottomTableViewCell;
- (void)addShadowForEditableTextField;
- (void)addShadowForPhotoFrame;
- (void)removeShadow;

@end
