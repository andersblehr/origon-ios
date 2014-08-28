//
//  OActivityIndicator.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OActivityIndicator.h"

static CGFloat const kNavigationBarHeight = 72.f;
static CGFloat const kHUDSideLength = 70.f;
static CGFloat const kHUDCornerRadius = 5.f;


@implementation OActivityIndicator

#pragma mark - Initialisation

- (instancetype)init
{
    UIViewController *viewController = (UIViewController *)[OState s].viewController;
    
    self = [super initWithFrame:viewController.view.window.frame];
    
    if (self) {
        self.backgroundColor = [UIColor dimmedViewColour];
        self.alpha = 0.f;
        
        UIView *HUDView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, kHUDSideLength, kHUDSideLength)];
        HUDView.backgroundColor = [UIColor alertViewBackgroundColour];
        HUDView.layer.cornerRadius = kHUDCornerRadius;
        
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityView.color = [UIColor darkGrayColor];
        [activityView startAnimating];
        
        [viewController.view.window addSubview:self];
        [self addSubview:HUDView];
        [self addSubview:activityView];
        
        HUDView.center = CGPointMake(self.center.x, self.center.y - kNavigationBarHeight / 2);
        activityView.center = HUDView.center;
    }
    
    return self;
}


#pragma mark - Starting & stopping animation

- (void)startAnimating
{
    if (self.alpha == 0.f) {
        [UIView animateWithDuration:kFadeAnimationDuration animations:^{
            self.alpha = 1.f;
        } completion:^(BOOL finished) {
            self.userInteractionEnabled = YES;
        }];
    }
    
    _isAnimating = YES;
}


- (void)stopAnimating
{
    if (self.alpha == 1.f) {
        [UIView animateWithDuration:kFadeAnimationDuration animations:^{
            self.alpha = 0.f;
        } completion:^(BOOL finished) {
            self.userInteractionEnabled = NO;
        }];
    }
    
    _isAnimating = NO;
}

@end
