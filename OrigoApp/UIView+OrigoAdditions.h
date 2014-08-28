//
//  UIView+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern CGFloat const kFadeAnimationDuration;

@interface UIView (OrigoAdditions)

- (void)dim;
- (void)undim;

- (void)addSeparatorsForTableViewCell;
- (void)redrawSeparatorsForTableViewCell;

- (void)addDropShadowForPhotoFrame;

@end
