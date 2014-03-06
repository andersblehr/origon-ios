//
//  OActivityIndicator.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OActivityIndicator.h"

static CGFloat const kNavigationBarHeight = 72.f;
static CGFloat const kHUDSideLength = 70.f;
static CGFloat const kHUDCornerRadius = 5.f;

static CGFloat const kAlphaDimmedBackground = 0.4f;
static CGFloat const kAlphaInvisible = 0.f;
static CGFloat const kAlphaVisible = 1.f;

static CGFloat const kFadeAnimationDuration = 0.2f;


@implementation OActivityIndicator

#pragma mark - Singleton instantiation & initialisation

- (id)init
{
    self = [super initWithFrame:[OState s].viewController.view.window.frame];
    
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:kAlphaDimmedBackground];
        self.alpha = kAlphaInvisible;
        
        UIView *HUDView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, kHUDSideLength, kHUDSideLength)];
        HUDView.backgroundColor = [UIColor alertViewBackgroundColour];
        HUDView.layer.cornerRadius = kHUDCornerRadius;
        
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityView.color = [UIColor darkGrayColor];
        [activityView startAnimating];
        
        [[OState s].viewController.view.window addSubview:self];
        [self addSubview:HUDView];
        [self addSubview:activityView];
        
        HUDView.center = CGPointMake(self.center.x, self.center.y - kNavigationBarHeight / 2);
        activityView.center = HUDView.center;
    }
    
    return self;
}


- (void)startAnimating
{
    if (self.alpha == kAlphaInvisible) {
        [UIView animateWithDuration:kFadeAnimationDuration animations:^{
            self.alpha = kAlphaVisible;
        } completion:^(BOOL finished) {
            self.userInteractionEnabled = YES;
        }];
    }
    
    _isAnimating = YES;
}


- (void)stopAnimating
{
    if (self.alpha == kAlphaVisible) {
        [UIView animateWithDuration:kFadeAnimationDuration animations:^{
            self.alpha = kAlphaInvisible;
        } completion:^(BOOL finished) {
            self.userInteractionEnabled = NO;
        }];
    }
    
    _isAnimating = NO;
}

@end
