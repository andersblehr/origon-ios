//
//  UIView+ScViewExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 21.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "UIView+ScViewExtensions.h"

#import "UIColor+ScColorExtensions.h"


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


- (void)addCurlShadow
{
    CGSize size = self.bounds.size;
    CGFloat curlFactor = 7.0f;
    CGFloat shadowDepth = 2.0f;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0.f, 0.f)];
    [path addLineToPoint:CGPointMake(size.width, 0.f)];
    [path addLineToPoint:CGPointMake(size.width, size.height + shadowDepth)];
    [path addCurveToPoint:CGPointMake(0.f, size.height + shadowDepth) controlPoint1:CGPointMake(size.width - curlFactor, size.height + shadowDepth - curlFactor) controlPoint2:CGPointMake(curlFactor, size.height + shadowDepth - curlFactor)];
    
    self.layer.masksToBounds = NO;
    self.layer.shadowColor = [UIColor darkGrayColor].CGColor;
    self.layer.shadowOpacity = 1.f;
    self.layer.shadowRadius = 2.f;
    self.layer.shadowOffset = CGSizeMake(0.f, 3.f);
    self.layer.shadowPath = path.CGPath;
}

@end
