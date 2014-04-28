//
//  UINavigationItem+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "UINavigationItem+OrigoAdditions.h"

static CGFloat const kNavigationBarHeight = 44.f;
static CGFloat const kNavigationBarButtonWidth = 61.f;

static CGFloat const kTitleHeadroom = 2.f;
static CGFloat const kTitleHeight = 24.f;


@implementation UINavigationItem (OrigoAdditions)

- (void)setTitle:(NSString *)title withSubtitle:(NSString *)subtitle
{
    CGFloat titleViewWidth = [OMeta screenWidth] - 2 * kNavigationBarButtonWidth;
    
    CGRect titleFrame = CGRectMake(0.f, kTitleHeadroom, titleViewWidth, kTitleHeight);
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:titleFrame];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont navigationBarTitleFont];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.text = title;
    titleLabel.adjustsFontSizeToFitWidth = YES;
    
    CGFloat subtitleHeight = kNavigationBarHeight - kTitleHeight;
    CGRect subtitleFrame = CGRectMake(0.f, kTitleHeight, titleViewWidth, subtitleHeight);
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:subtitleFrame];
    subtitleLabel.backgroundColor = [UIColor clearColor];
    subtitleLabel.font = [UIFont navigationBarSubtitleFont];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.textColor = [UIColor blackColor];
    subtitleLabel.text = subtitle;
    subtitleLabel.adjustsFontSizeToFitWidth = YES;
    
    CGRect titleViewFrame = CGRectMake(0.f, 0.f, titleViewWidth, kNavigationBarHeight);
    UIView* titleView = [[UIView alloc] initWithFrame:titleViewFrame];
    titleView.backgroundColor = [UIColor clearColor];
    [titleView addSubview:titleLabel];
    [titleView addSubview:subtitleLabel];
    
    self.titleView = titleView;
}


- (UISegmentedControl *)addSegmentedTitle:(NSString *)segmentedTitle
{
    NSArray *titleSegments = [segmentedTitle componentsSeparatedByString:kSeparatorSegments];
    UISegmentedControl *titleControl = [[UISegmentedControl alloc] initWithItems:titleSegments];
    [titleControl addTarget:[OState s].viewController action:@selector(didSelectTitleSegment) forControlEvents:UIControlEventValueChanged];
    
    self.titleView = titleControl;
    
    return titleControl;
}


- (void)appendRightBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    NSMutableArray *rightBarButtonItems = [self.rightBarButtonItems mutableCopy];
    
    if ([rightBarButtonItems count] == 1) {
        [rightBarButtonItems insertObject:barButtonItem atIndex:0];
    } else {
        rightBarButtonItems = [NSMutableArray arrayWithObject:barButtonItem];
    }
    
    [self setRightBarButtonItems:rightBarButtonItems animated:YES];
}

@end
