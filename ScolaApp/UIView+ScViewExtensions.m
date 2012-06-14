//
//  UIView+ScViewExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 21.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "UIView+ScViewExtensions.h"


static CGFloat const kShadowRadius = 3.75f;
static CGFloat const kVerticalShadowOffset = 5.f;


@implementation UIView (ScViewExtensions)

#pragma mark - Gradient layer

- (void)addGradientLayer
{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    
    gradientLayer.frame = self.bounds;
    gradientLayer.colors = [NSArray arrayWithObjects:(id)[UIColor clearColor].CGColor, (id)[[UIColor blackColor] colorWithAlphaComponent:0.f].CGColor, nil];
    
    [self.layer addSublayer:gradientLayer];
}


#pragma mark - Shadows

- (void)projectShadowOfRectangle:(CGRect)rectangle
{
    self.layer.masksToBounds = NO;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 1.f;
    self.layer.shadowRadius = kShadowRadius;
    self.layer.shadowOffset = CGSizeMake(0.f, kVerticalShadowOffset);
    self.layer.shadowPath = [UIBezierPath bezierPathWithRect:rectangle].CGPath;
}


- (void)addShadow
{
    [self projectShadowOfRectangle:self.bounds];
}


- (void)addShadowForMiddleOrTopTableViewCell
{
    [self projectShadowOfRectangle:CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height - 2.75f * kShadowRadius)];
}

@end
