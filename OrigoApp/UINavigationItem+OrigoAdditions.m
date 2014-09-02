//
//  UINavigationItem+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "UINavigationItem+OrigoAdditions.h"

static CGFloat const kNavigationBarReservedWidth = 160.f;

static CGFloat const kTitleHeight = 24.f;
static CGFloat const kTitleHeadroom = 10.5f;
static CGFloat const kTitleHeadroomWithSubtitle = 2.f;

static NSInteger const kViewTagTitleField = 10;
static NSInteger const kViewTagSubtitleLabel = 11;


@implementation UINavigationItem (OrigoAdditions)

#pragma mark - Editable title with subtitle

- (id)setTitle:(NSString *)title editable:(BOOL)editable withSubtitle:(NSString *)subtitle
{
    CGFloat titleViewWidth = [OMeta screenWidth] - kNavigationBarReservedWidth;
    UITextField *titleField = nil;
    UILabel *subtitleLabel = nil;
    
    BOOL needsAddTitleField = NO;
    BOOL needsAddSubtitleLabel = NO;
    
    if (self.titleView) {
        titleField = (UITextField *)[self.titleView viewWithTag:kViewTagTitleField];
        subtitleLabel = (UILabel *)[self.titleView viewWithTag:kViewTagSubtitleLabel];
    }
    
    if (titleField) {
        titleField.text = title;
    } else {
        titleField = [[UITextField alloc] initWithFrame:CGRectZero];
        titleField.adjustsFontSizeToFitWidth = YES;
        titleField.backgroundColor = [UIColor clearColor];
        titleField.font = [UIFont navigationBarTitleFont];
        titleField.returnKeyType = UIReturnKeyDone;
        titleField.tag = kViewTagTitleField;
        titleField.text = title;
        titleField.textAlignment = NSTextAlignmentCenter;
        titleField.textColor = [UIColor blackColor];
        
        needsAddTitleField = YES;
    }
    
    if (subtitle && subtitleLabel) {
        subtitleLabel.text = subtitle;
    } else if (subtitle) {
        CGFloat subtitleHeight = kToolbarBarHeight - kTitleHeight;
        CGRect subtitleFrame = CGRectMake(0.f, kTitleHeight, titleViewWidth, subtitleHeight);
        subtitleLabel = [[UILabel alloc] initWithFrame:subtitleFrame];
        subtitleLabel.adjustsFontSizeToFitWidth = YES;
        subtitleLabel.backgroundColor = [UIColor clearColor];
        subtitleLabel.font = [UIFont navigationBarSubtitleFont];
        subtitleLabel.tag = kViewTagSubtitleLabel;
        subtitleLabel.text = subtitle;
        subtitleLabel.textAlignment = NSTextAlignmentCenter;
        subtitleLabel.textColor = [UIColor blackColor];
        
        needsAddSubtitleLabel = YES;
    } else if (subtitleLabel) {
        [subtitleLabel removeFromSuperview];
        subtitleLabel = nil;
    }
    
    CGFloat headroom = subtitle ? kTitleHeadroomWithSubtitle : kTitleHeadroom;
    titleField.frame = CGRectMake(0.f, headroom, titleViewWidth, kTitleHeight);;
    titleField.userInteractionEnabled = editable;
    
    if (!self.titleView) {
        CGRect titleViewFrame = CGRectMake(0.f, 0.f, titleViewWidth, kToolbarBarHeight);
        self.titleView = [[UIView alloc] initWithFrame:titleViewFrame];
        self.titleView.backgroundColor = [UIColor clearColor];
    }
    
    if (needsAddTitleField) {
        [self.titleView addSubview:titleField];
    }
    
    if (needsAddSubtitleLabel) {
        [self.titleView addSubview:subtitleLabel];
    }
    
    self.title = title;
    
    return titleField;
}


#pragma mark - Additional right bar button items

- (void)addRightBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    [self addRightBarButtonItem:barButtonItem append:NO];
}


- (void)addRightBarButtonItem:(UIBarButtonItem *)barButtonItem append:(BOOL)append
{
    NSMutableArray *rightBarButtonItems = [self.rightBarButtonItems mutableCopy];
    
    if ([rightBarButtonItems count]) {
        if (append) {
            [rightBarButtonItems insertObject:barButtonItem atIndex:0];
        } else {
            [rightBarButtonItems addObject:barButtonItem];
        }
    } else {
        rightBarButtonItems = [NSMutableArray arrayWithObject:barButtonItem];
    }
    
    [self setRightBarButtonItems:rightBarButtonItems animated:YES];
}

@end
