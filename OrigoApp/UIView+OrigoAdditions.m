//
//  UIView+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "UIView+OrigoAdditions.h"

CGFloat const kFadeAnimationDuration = 0.2f;

static CGFloat const kCellShadowRadius = 1.f;
static CGFloat const kCellShadowOffset = 0.f;
static CGFloat const kImageShadowRadius = 1.f;
static CGFloat const kImageShadowOffset = 1.5f;

static NSString * const kKeyPathShadowPath = @"shadowPath";

static UIView *_dimmerView = nil;


@implementation UIView (OrigoAdditions)

#pragma mark - Auxiliary methods

- (void)addShadowWithPath:(UIBezierPath *)path colour:(UIColor *)colour radius:(CGFloat)radius offset:(CGFloat)offset
{
    self.layer.shadowPath = path.CGPath;
    self.layer.shadowColor = colour.CGColor;
    self.layer.shadowOpacity = 1.f;
    self.layer.shadowRadius = radius;
    self.layer.shadowOffset = CGSizeMake(0.f, offset);
    
    self.layer.masksToBounds = NO;
}


#pragma mark - Dimming & undimming

- (void)dim
{
    _dimmerView = [[UIView alloc] initWithFrame:self.frame];
    _dimmerView.backgroundColor = [UIColor dimmedViewColour];
    _dimmerView.alpha = 0.f;
    
    [self addSubview:_dimmerView];
    
    [UIView animateWithDuration:kFadeAnimationDuration animations:^{
        _dimmerView.alpha = 1.f;
    } completion:^(BOOL finished) {
        _dimmerView.userInteractionEnabled = YES;
    }];
}


- (void)undim
{
    [UIView animateWithDuration:kFadeAnimationDuration animations:^{
        _dimmerView.alpha = 0.f;
    } completion:^(BOOL finished) {
        _dimmerView.userInteractionEnabled = NO;
    }];
    
    [_dimmerView removeFromSuperview];
    _dimmerView = nil;
}


#pragma mark - Shadow effects

- (void)addSeparatorsForTableViewCell
{
    [self addShadowWithPath:[UIBezierPath bezierPathWithRect:self.bounds] colour:[UIColor tableViewSeparatorColour] radius:kCellShadowRadius offset:kCellShadowOffset];
}


- (void)redrawSeparatorsForTableViewCell
{
    CGPathRef redrawnShadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
    
    CABasicAnimation *redrawAnimation = [CABasicAnimation animationWithKeyPath:kKeyPathShadowPath];
    redrawAnimation.duration = kCellAnimationDuration;
    redrawAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    redrawAnimation.fromValue = (__bridge id)self.layer.shadowPath;
    redrawAnimation.toValue = (__bridge id)redrawnShadowPath;
    
    [self.layer addAnimation:redrawAnimation forKey:nil];
    self.layer.shadowPath = redrawnShadowPath;
}


- (void)addDropShadowForPhotoFrame
{
    [self addShadowWithPath:[UIBezierPath bezierPathWithRect:CGRectMake(0.f, 0.f, kPhotoFrameWidth, kPhotoFrameWidth)] colour:[UIColor darkGrayColor] radius:kImageShadowRadius offset:kImageShadowOffset];
}

@end
