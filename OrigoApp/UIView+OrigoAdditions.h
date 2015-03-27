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

+ (UIView *)infoNotificationView;
+ (UIView *)joinRequestNotificationView;

- (void)setHairlinesHidden:(BOOL)hide;
- (void)addDropShadowForPhotoFrame;

- (void)dumpSubviewsUsingTitle:(NSString *)title;

@end
