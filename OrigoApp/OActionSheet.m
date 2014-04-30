//
//  OActionSheet.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OActionSheet.h"

@implementation OActionSheet

#pragma mark - Initialisation

- (instancetype)initWithPrompt:(NSString *)prompt delegate:(id<UIActionSheetDelegate>)delegate tag:(NSInteger)tag
{
    self = [super initWithTitle:prompt delegate:delegate cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

    if (self) {
        self.tag = tag;
        
        _buttonTags = [NSMutableArray array];
    }
    
    return self;
}


#pragma mark - Tagged button handling

- (NSInteger)addButtonWithTitle:(NSString *)title tag:(NSInteger)tag
{
    [_buttonTags addObject:@(tag)];
    
    return [super addButtonWithTitle:title];
}


- (NSInteger)tagForButtonIndex:(NSInteger)buttonIndex
{
    return [_buttonTags[buttonIndex] integerValue];
}


- (void)show
{
    [self addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    self.cancelButtonIndex = self.numberOfButtons - 1;
    
    UIViewController *viewController = (UIViewController *)[OState s].viewController;
    UIView *containerView = nil;
    
    if (viewController.navigationController) {
        containerView = viewController.navigationController.view;
    } else {
        containerView = viewController.view;
    }
    
    [self showInView:containerView];
}


#pragma mark - UIActionSheet overrides

- (NSInteger)addButtonWithTitle:(NSString *)title
{
    return [self addButtonWithTitle:title tag:[_buttonTags count]];
}

@end
