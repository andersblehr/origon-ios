//
//  OActionSheet.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OActionSheet.h"

@interface OActionSheet () <UIActionSheetDelegate> {
@private
    NSMutableArray *_buttonTags;
}

@property (nonatomic, strong) void (^action)(void);

@end


@implementation OActionSheet

#pragma mark - Block based action sheets

+ (void)singleButtonActionSheetWithButtonTitle:(NSString *)buttonTitle action:(void (^)(void))action
{
    OActionSheet *actionSheet = [[self alloc] initWithPrompt:nil delegate:nil tag:0];
    [actionSheet addButtonWithTitle:buttonTitle];
    actionSheet.delegate = actionSheet;
    actionSheet.action = action;
    
    [actionSheet show];
}


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
    return [self addButtonWithTitle:title tag:_buttonTags.count];
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        _action();
    }
}

@end
