//
//  UIView+OViewExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UIView+OViewExtensions.h"

#import "UIColor+OColorExtensions.h"

static CGFloat const kCellShadowRadius = 3.75f;
static CGFloat const kCellShadowOffset = 5.f;
static CGFloat const kFieldShadowRadius = 3.f;
static CGFloat const kFieldShadowOffset = 3.f;
static CGFloat const kFieldShadowHeightShrinkage = 1.f;
static CGFloat const kImageShadowRadius = 1.f;
static CGFloat const kImageShadowOffset = 1.5f;


@implementation UIView (OViewExtensions)

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


- (void)addDropShadowForTextField
{
    CGFloat fieldShadowOriginY = self.bounds.origin.y + kFieldShadowOffset;
    CGFloat fieldShadowHeight = self.bounds.size.height - kFieldShadowHeightShrinkage;
    
    [self addShadowWithPath:[UIBezierPath bezierPathWithRect:CGRectMake(self.bounds.origin.x, fieldShadowOriginY, self.bounds.size.width, fieldShadowHeight)] colour:[UIColor darkGrayColor] radius:kFieldShadowRadius offset:kFieldShadowOffset];
}


- (void)removeDropShadow
{
    [self addShadowWithPath:[UIBezierPath bezierPathWithRect:self.bounds] colour:[UIColor clearColor] radius:0.f offset:0.f];
}


#pragma mark - Gradient layer

- (void)addGradientLayer
{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    
    gradientLayer.frame = self.bounds;
    gradientLayer.colors = [NSArray arrayWithObjects:(id)[[UIColor blackColor] colorWithAlphaComponent:0.1f].CGColor, (id)[UIColor clearColor].CGColor, nil];
    
    [self.layer addSublayer:gradientLayer];
}


#pragma mark - Shadows

- (void)addDropShadowForInternalTableViewCell
{
    CGRect nonOverlappingShadowRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height - 2.75f * kCellShadowRadius);
    
    [self addShadowWithPath:[UIBezierPath bezierPathWithRect:nonOverlappingShadowRect] colour:[UIColor blackColor] radius:kCellShadowRadius offset:kCellShadowOffset];
}


- (void)addDropShadowForTrailingTableViewCell
{
    [self addShadowWithPath:[UIBezierPath bezierPathWithRect:self.bounds] colour:[UIColor blackColor] radius:kCellShadowRadius offset:kCellShadowOffset];
}


- (void)addDropShadowForPhotoFrame
{
    [self addShadowWithPath:[UIBezierPath bezierPathWithRect:self.bounds] colour:[UIColor darkGrayColor] radius:kImageShadowRadius offset:kImageShadowOffset];
}


- (void)hasDropShadow:(BOOL)hasShadow
{
    if (hasShadow) {
        if ([self isKindOfClass:UITextField.class] || [self isKindOfClass:UITextView.class]) {
            [self addDropShadowForTextField];
        } else {
            [self addDropShadowForTrailingTableViewCell];
        }
    } else {
        [self removeDropShadow];
    }
}


- (void)redrawDropShadow
{
    [self hasDropShadow:YES];
}

@end
