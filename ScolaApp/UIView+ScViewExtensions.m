//
//  UIView+ScViewExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 21.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "UIView+ScViewExtensions.h"


@implementation UIView (ScShadowEffects)

- (void)addGradientLayer
{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    
    gradientLayer.frame = self.bounds;
    gradientLayer.colors = [NSArray arrayWithObjects:(id)[UIColor clearColor].CGColor, (id)[[UIColor blackColor] colorWithAlphaComponent:0.3].CGColor, nil];
    
    [self.layer addSublayer:gradientLayer];
}


- (void)addShadow
{
    self.layer.masksToBounds = NO;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 1.0;
    self.layer.shadowRadius = 10.0;
    self.layer.shadowOffset = CGSizeMake(0.0, 3.0);
    self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
}

@end
