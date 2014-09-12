//
//  UIView+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "UIView+OrigoAdditions.h"

CGFloat const kFadeAnimationDuration = 0.2f;

static CGFloat const kImageShadowRadius = 1.f;
static CGFloat const kImageShadowOffset = 1.5f;


@implementation UIView (OrigoAdditions)

#pragma mark - Auxiliary methods

- (void)setHairlinesHidden:(BOOL)hidden inSubviewsOfView:(UIView *)view
{
    for (UIView *subview in view.subviews) {
        if ([subview isMemberOfClass:[UIImageView class]]) {
            if (subview.frame.size.height < 1.f) {
                subview.hidden = hidden;
            }
        } else {
            [self setHairlinesHidden:hidden inSubviewsOfView:subview];
        }
    }
}


- (void)dumpSubviewsFromView:(UIView *)view
{
    static NSInteger level = 0;
    
    NSMutableString *padding = [NSMutableString string];
    
    for (NSInteger i = 0; i < level; i++) {
        [padding appendString:@" "];
    }
    
    NSLog(@"%@+%@", padding, view);
    
    level++;
    
    for (UIView *subview in view.subviews) {
        [self dumpSubviewsFromView:subview];
    }
    
    level--;
}


#pragma mark - Hiding hairline subviews

- (void)setHairlinesHidden:(BOOL)hidden
{
    [self setHairlinesHidden:hidden inSubviewsOfView:self];
}


#pragma mark - Shadow effects

- (void)addDropShadowForPhotoFrame
{
    self.layer.shadowPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.f, 0.f, kPhotoFrameWidth, kPhotoFrameWidth)].CGPath;
    self.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    self.layer.shadowOpacity = 1.f;
    self.layer.shadowRadius = kImageShadowRadius;
    self.layer.shadowOffset = CGSizeMake(0.f, kImageShadowOffset);
    self.layer.masksToBounds = NO;
}


#pragma mark - DEBUG: Dumping subviews

- (void)dumpSubviewsUsingTitle:(NSString *)title;
{
    NSLog(@"==== START DUMP: %@ ====", title);
    [self dumpSubviewsFromView:self];
    NSLog(@"===== END DUMP: %@ =====", title);
}

@end
