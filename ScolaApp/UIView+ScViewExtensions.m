//
//  UIView+ScViewExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 21.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "UIView+ScViewExtensions.h"

#import "UIColor+ScColorExtensions.h"


static CGFloat const kCellShadowRadius = 3.75f;
static CGFloat const kCellShadowOffset = 5.f;
static CGFloat const kFieldShadowRadius = 2.f;
static CGFloat const kFieldShadowOffset = 3.f;
static CGFloat const kFieldShadowCurlFactor = 7.f;
static CGFloat const kImageShadowRadius = 1.f;
static CGFloat const kImageShadowOffset = 1.5f;


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

- (void)addShadowWithPath:(UIBezierPath *)path colour:(UIColor *)colour radius:(CGFloat)radius offset:(CGFloat)offset
{
    self.layer.shadowPath = path.CGPath;
    self.layer.shadowColor = colour.CGColor;
    self.layer.shadowRadius = radius;
    self.layer.shadowOffset = CGSizeMake(0.f, offset);
    
    self.layer.masksToBounds = NO;
    self.layer.shadowOpacity = 1.f;
}


- (void)addShadowForBottomTableViewCell
{
    [self addShadowWithPath:[UIBezierPath bezierPathWithRect:self.bounds] colour:[UIColor blackColor] radius:kCellShadowRadius offset:kCellShadowOffset];
}


- (void)addShadowForContainedTableViewCell
{
    CGRect nonOverlappingShadowRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height - 2.75f * kCellShadowRadius);
    
    [self addShadowWithPath:[UIBezierPath bezierPathWithRect:nonOverlappingShadowRect] colour:[UIColor blackColor] radius:kCellShadowRadius offset:kCellShadowOffset];
}


- (void)addShadowForEditableTextField
{
    CGSize size = self.bounds.size;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0.f, 0.f)];
    [path addLineToPoint:CGPointMake(size.width, 0.f)];
    [path addLineToPoint:CGPointMake(size.width, size.height + kFieldShadowRadius)];
    [path addCurveToPoint:CGPointMake(0.f, size.height + kFieldShadowRadius) controlPoint1:CGPointMake(size.width - kFieldShadowCurlFactor, size.height + kFieldShadowRadius - kFieldShadowCurlFactor) controlPoint2:CGPointMake(kFieldShadowCurlFactor, size.height + kFieldShadowRadius - kFieldShadowCurlFactor)];
    
    [self addShadowWithPath:path colour:[UIColor darkGrayColor] radius:kFieldShadowRadius offset:kFieldShadowOffset];
}


- (void)addShadowForPhotoFrame
{
    [self addShadowWithPath:[UIBezierPath bezierPathWithRect:self.bounds] colour:[UIColor darkGrayColor] radius:kImageShadowRadius offset:kImageShadowOffset];
}


- (void)removeShadow
{
    [self addShadowWithPath:[UIBezierPath bezierPathWithRect:self.bounds] colour:[UIColor clearColor] radius:0.f offset:0.f];
}

@end
