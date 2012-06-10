//
//  UIView+ScViewExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 21.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "UIView+ScViewExtensions.h"


static CGFloat const kShadowRadius = 5.f;
static CGFloat const kShadowOffset = 5.f;


@implementation UIView (ScShadowEffects)

- (void)addGradientLayer
{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    
    gradientLayer.frame = self.bounds;
    gradientLayer.colors = [NSArray arrayWithObjects:(id)[UIColor clearColor].CGColor, (id)[[UIColor blackColor] colorWithAlphaComponent:0.f].CGColor, nil];
    
    [self.layer addSublayer:gradientLayer];
}


- (void)addSHadowWithOffset:(CGFloat)yOffset pathRect:(CGRect)rect
{
    self.layer.masksToBounds = NO;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 1.f;
    self.layer.shadowRadius = kShadowRadius;
    self.layer.shadowOffset = CGSizeMake(0.f, yOffset);
    self.layer.shadowPath = [UIBezierPath bezierPathWithRect:rect].CGPath;
}


- (void)addShadow
{
    [self addSHadowWithOffset:kShadowOffset pathRect:self.bounds];
}


- (void)addTopShadow
{
    CGRect shadowPathRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height - kShadowRadius);
    
    [self addSHadowWithOffset:0.f pathRect:shadowPathRect];
}


- (void)addCentreShadow
{
    CGRect shadowPathRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y + kShadowRadius, self.bounds.size.width, self.bounds.size.height - 2 * kShadowRadius);
    
    [self addSHadowWithOffset:0.f pathRect:shadowPathRect];
}


- (void)addBottomShadow
{
    CGRect shadowPathRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y + kShadowRadius, self.bounds.size.width, self.bounds.size.height - kShadowRadius);
    
    [self addSHadowWithOffset:kShadowOffset pathRect:shadowPathRect];
    
}


- (void)addPencilShadow
{
    self.layer.masksToBounds = NO;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.7f;
    self.layer.shadowRadius = 0.5f;
    self.layer.shadowOffset = CGSizeMake(0.f, 0.5f);
    self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
}

@end
