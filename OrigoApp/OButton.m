//
//  OButton.m
//  OrigoApp
//
//  Created by Anders Blehr on 17/02/15.
//  Copyright (c) 2015 Rhelba Source. All rights reserved.
//

#import "OButton.h"

@implementation OButton

#pragma mark - Initialization

- (id)initWithTitle:(NSString *)title target:(id)target action:(SEL)action
{
    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        self.backgroundColor = [UIColor globalTintColour];
        self.titleLabel.font = [UIFont detailFont];
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self setTitle:title forState:UIControlStateNormal];
        [self addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    }
    
    return self;
}


#pragma mark - UIControl overrides

- (void)setHighlighted:(BOOL)highlighted
{
    static UIView *_dimmerView = nil;
    
    [super setHighlighted:highlighted];
    
    if (highlighted && !_dimmerView) {
        _dimmerView = [[UIView alloc] initWithFrame:self.bounds];
        _dimmerView.backgroundColor = [UIColor dimmedViewColour];
        
        [self addSubview:_dimmerView];
    } else if (!highlighted && _dimmerView) {
        [_dimmerView removeFromSuperview];
        _dimmerView = nil;
    }
}

@end
