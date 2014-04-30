//
//  UIBarButtonItem+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "UIBarButtonItem+OrigoAdditions.h"

static UIBarButtonItem *_flexibleSpace = nil;


@implementation UIBarButtonItem (OrigoAdditions)

#pragma mark - Auxiliary methods

+ (instancetype)barButtonWithIcon:(NSString *)iconFile action:(SEL)action
{
    UIImage *image = [UIImage imageNamed:iconFile];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.bounds = CGRectMake(0.f, 0.f, image.size.width, image.size.height);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:[OMeta m].switchboard action:action forControlEvents:UIControlEventTouchUpInside];
    
    return [[self alloc] initWithCustomView:button];
}


+ (instancetype)cancelButtonWithTitle:(NSString *)title
{
    return [[self alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:[OState s].viewController action:@selector(didCancelEditing)];
}


#pragma mark - Navigation bar buttons

+ (instancetype)settingsButton
{
    return [[self alloc] initWithImage:[UIImage imageNamed:kIconFileSettings] style:UIBarButtonItemStylePlain target:[OState s].viewController action:@selector(openSettings)];
}


+ (instancetype)plusButton
{
    UIBarButtonItem *button = nil;
    
    if ([OMeta systemIs_iOS6x]) {
        button = [[self alloc] initWithImage:[UIImage imageNamed:kIconFilePlus] style:UIBarButtonItemStylePlain target:[OState s].viewController action:@selector(addItem)];
    } else {
        button = [[self alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:[OState s].viewController action:@selector(addItem)];
    }
    
    return button;
}


+ (instancetype)actionButton
{
    UIBarButtonItem *button = nil;
    
    if ([OMeta systemIs_iOS6x]) {
        button = [[self alloc] initWithImage:[UIImage imageNamed:kIconFileAction] style:UIBarButtonItemStylePlain target:[OState s].viewController action:@selector(presentActionSheet)];
    } else {
        button = [[self alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:[OState s].viewController action:@selector(presentActionSheet)];
    }
    
    return button;
}


+ (instancetype)lookupButton
{
    UIBarButtonItem *button = nil;
    
    if ([OMeta systemIs_iOS6x]) {
        button = [[self alloc] initWithImage:[UIImage imageNamed:kIconFileLookup] style:UIBarButtonItemStylePlain target:[OState s].viewController action:@selector(performLookup)];
    } else {
        button = [[self alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:[OState s].viewController action:@selector(performLookup)];
    }
    
    return button;
}


+ (instancetype)nextButton
{
    return [[self alloc] initWithTitle:NSLocalizedString(@"Next", @"") style:UIBarButtonItemStylePlain target:[OState s].viewController action:@selector(moveToNextInputField)];
}


+ (instancetype)editButton
{
    return [[self alloc] initWithTitle:NSLocalizedString(@"Edit", @"") style:UIBarButtonItemStylePlain target:[OState s].viewController action:@selector(didBeginEditing)];
}


+ (instancetype)cancelButton
{
    return [self cancelButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
}


+ (instancetype)skipButton
{
    return [self cancelButtonWithTitle:NSLocalizedString(@"Skip", @"")];
}


+ (instancetype)doneButton
{
    return [[self alloc] initWithTitle:NSLocalizedString(@"Done", @"") style:UIBarButtonItemStyleDone target:[OState s].viewController action:@selector(didFinishEditing)];
}


+ (instancetype)signOutButton
{
    return [[self alloc] initWithTitle:NSLocalizedString(@"Log out", @"") style:UIBarButtonItemStylePlain target:[OMeta m] action:@selector(signOut)];
}


#pragma mark - Toolbar buttons

+ (instancetype)sendTextButton
{
    UIBarButtonItem *barButtonItem = nil;
    SEL action = @selector(processTextRequest);
    
    if ([OMeta systemIs_iOS6x]) {
        barButtonItem = [self barButtonWithIcon:kIconFileSendText_iOS6x action:action];
    } else {
        barButtonItem = [[self alloc] initWithImage:[UIImage imageNamed:kIconFileSendText] style:UIBarButtonItemStylePlain target:[OMeta m].switchboard action:action];
    }
    
    return barButtonItem;
}


+ (instancetype)phoneCallButton
{
    UIBarButtonItem *barButtonItem = nil;
    SEL action = @selector(processCallRequest);
    
    if ([OMeta systemIs_iOS6x]) {
        barButtonItem = [self barButtonWithIcon:kIconFilePlacePhoneCall_iOS6x action:action];
    } else {
        barButtonItem = [[self alloc] initWithImage:[UIImage imageNamed:kIconFilePlacePhoneCall] style:UIBarButtonItemStylePlain target:[OMeta m].switchboard action:action];
    }
    
    return barButtonItem;
}


+ (instancetype)sendEmailButton
{
    UIBarButtonItem *barButtonItem = nil;
    SEL action = @selector(processEmailRequest);
    
    if ([OMeta systemIs_iOS6x]) {
        barButtonItem = [self barButtonWithIcon:kIconFileSendEmail_iOS6x action:action];
    } else {
        barButtonItem = [[self alloc] initWithImage:[UIImage imageNamed:kIconFileSendEmail] style:UIBarButtonItemStylePlain target:[OMeta m].switchboard action:action];
    }
    
    return barButtonItem;
}


#pragma mark - Other buttons

+ (instancetype)flexibleSpace
{
    if (!_flexibleSpace) {
        _flexibleSpace = [[self alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    }
    
    return _flexibleSpace;
}


+ (instancetype)buttonWithTitle:(NSString *)title
{
    return [[self alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:nil action:nil];
}

@end
