//
//  UIBarButtonItem+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UIBarButtonItem+OrigoAdditions.h"

static UIBarButtonItem *_flexibleSpace = nil;


@implementation UIBarButtonItem (OrigoAdditions)

#pragma mark - Auxiliary methods

+ (UIBarButtonItem *)barButtonWithIcon:(NSString *)iconFile action:(SEL)action
{
    UIImage *image = [UIImage imageNamed:iconFile];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.bounds = CGRectMake(0.f, 0.f, image.size.width, image.size.height);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:[OMeta m].switchboard action:action forControlEvents:UIControlEventTouchUpInside];
    
    return [[UIBarButtonItem alloc] initWithCustomView:button];
}


+ (UIBarButtonItem *)cancelButtonWithTitle:(NSString *)title
{
    return [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:[OState s].viewController action:@selector(didCancelEditing)];
}


#pragma mark - Bar button shorthands

+ (UIBarButtonItem *)settingsButton
{
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:kIconFileSettings] style:UIBarButtonItemStylePlain target:[OState s].viewController action:@selector(openSettings)];
}


+ (UIBarButtonItem *)plusButton
{
    UIBarButtonItem *button = nil;
    
    if ([OMeta systemIs_iOS6x]) {
        button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:kIconFilePlus] style:UIBarButtonItemStylePlain target:[OState s].viewController action:@selector(addItem)];
    } else {
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:[OState s].viewController action:@selector(addItem)];
    }
    
    return button;
}


+ (UIBarButtonItem *)actionButton
{
    UIBarButtonItem *button = nil;
    
    if ([OMeta systemIs_iOS6x]) {
        button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:kIconFileAction] style:UIBarButtonItemStylePlain target:[OState s].viewController action:@selector(presentActionSheet)];
    } else {
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:[OState s].viewController action:@selector(presentActionSheet)];
    }
    
    return button;
}


+ (UIBarButtonItem *)lookupButton
{
    UIBarButtonItem *button = nil;
    
    if ([OMeta systemIs_iOS6x]) {
        button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:kIconFileLookup] style:UIBarButtonItemStylePlain target:[OState s].viewController action:@selector(performLookup)];
    } else {
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:[OState s].viewController action:@selector(performLookup)];
    }
    
    return button;
}


+ (UIBarButtonItem *)nextButton
{
    return [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", @"") style:UIBarButtonItemStylePlain target:[OState s].viewController action:@selector(moveToNextInputField)];
}


+ (UIBarButtonItem *)cancelButton
{
    return [UIBarButtonItem cancelButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
}


+ (UIBarButtonItem *)skipButton
{
    return [UIBarButtonItem cancelButtonWithTitle:NSLocalizedString(@"Skip", @"")];
}


+ (UIBarButtonItem *)doneButton
{
    return [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"") style:UIBarButtonItemStyleDone target:[OState s].viewController action:@selector(didFinishEditing)];
}


+ (UIBarButtonItem *)signOutButton
{
    return [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Log out", @"") style:UIBarButtonItemStylePlain target:[OState s].viewController action:@selector(signOut)];
}


+ (UIBarButtonItem *)sendTextButton
{
    UIBarButtonItem *barButtonItem = nil;
    SEL action = @selector(processTextRequest);
    
    if ([OMeta systemIs_iOS6x]) {
        barButtonItem = [UIBarButtonItem barButtonWithIcon:kIconFileSendText_iOS6x action:action];
    } else {
        barButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:kIconFileSendText] style:UIBarButtonItemStylePlain target:[OMeta m].switchboard action:action];
    }
    
    return barButtonItem;
}


+ (UIBarButtonItem *)phoneCallButton
{
    UIBarButtonItem *barButtonItem = nil;
    SEL action = @selector(processCallRequest);
    
    if ([OMeta systemIs_iOS6x]) {
        barButtonItem = [UIBarButtonItem barButtonWithIcon:kIconFilePlacePhoneCall_iOS6x action:action];
    } else {
        barButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:kIconFilePlacePhoneCall] style:UIBarButtonItemStylePlain target:[OMeta m].switchboard action:action];
    }
    
    return barButtonItem;
}


+ (UIBarButtonItem *)sendEmailButton
{
    UIBarButtonItem *barButtonItem = nil;
    SEL action = @selector(processEmailRequest);
    
    if ([OMeta systemIs_iOS6x]) {
        barButtonItem = [UIBarButtonItem barButtonWithIcon:kIconFileSendEmail_iOS6x action:action];
    } else {
        barButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:kIconFileSendEmail] style:UIBarButtonItemStylePlain target:[OMeta m].switchboard action:action];
    }
    
    return barButtonItem;
}


+ (UIBarButtonItem *)flexibleSpace
{
    if (!_flexibleSpace) {
        _flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    }
    
    return _flexibleSpace;
}

@end
