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

+ (instancetype)barButtonWithIcon:(NSString *)iconFile target:(id)target action:(SEL)action
{
    UIImage *image = [UIImage imageNamed:iconFile];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.bounds = CGRectMake(0.f, 0.f, image.size.width, image.size.height);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    return [[self alloc] initWithCustomView:button];
}


+ (instancetype)cancelButtonWithTitle:(NSString *)title target:(id)target
{
    return [[self alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:target action:@selector(didCancelEditing)];
}


#pragma mark - Navigation bar buttons

+ (instancetype)settingsButtonWithTarget:(id)target
{
    return [[self alloc] initWithImage:[UIImage imageNamed:kIconFileSettings] style:UIBarButtonItemStylePlain target:target action:@selector(openSettings)];
}


+ (instancetype)plusButtonWithTarget:(id)target
{
    UIBarButtonItem *button = nil;
    
    if ([OMeta systemIs_iOS6x]) {
        button = [[self alloc] initWithImage:[UIImage imageNamed:kIconFilePlus] style:UIBarButtonItemStylePlain target:target action:@selector(addItem)];
    } else {
        button = [[self alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:target action:@selector(addItem)];
    }
    
    return button;
}


+ (instancetype)actionButtonWithTarget:(id)target
{
    UIBarButtonItem *button = nil;
    
    if ([OMeta systemIs_iOS6x]) {
        button = [[self alloc] initWithImage:[UIImage imageNamed:kIconFileAction] style:UIBarButtonItemStylePlain target:target action:@selector(presentActionSheet)];
    } else {
        button = [[self alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:target action:@selector(presentActionSheet)];
    }
    
    return button;
}


+ (instancetype)lookupButtonWithTarget:(id)target
{
    UIBarButtonItem *button = nil;
    
    SEL action = @selector(performLookupAction);
    
    if ([OMeta systemIs_iOS6x]) {
        button = [[self alloc] initWithImage:[UIImage imageNamed:kIconFileLookup] style:UIBarButtonItemStylePlain target:target action:action];
    } else {
        button = [[self alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:target action:action];
    }
    
    return button;
}


+ (instancetype)nextButtonWithTarget:(id)target
{
    return [[self alloc] initWithTitle:NSLocalizedString(@"Next", @"") style:UIBarButtonItemStylePlain target:target action:@selector(moveToNextInputField)];
}


+ (instancetype)editButtonWithTarget:(id)target
{
    return [[self alloc] initWithTitle:NSLocalizedString(@"Edit", @"") style:UIBarButtonItemStylePlain target:target action:@selector(didBeginEditing)];
}


+ (instancetype)cancelButtonWithTarget:(id)target
{
    return [self cancelButtonWithTitle:NSLocalizedString(@"Cancel", @"") target:target];
}


+ (instancetype)skipButtonWithTarget:(id)target
{
    return [self cancelButtonWithTitle:NSLocalizedString(@"Skip", @"") target:target];
}


+ (instancetype)doneButtonWithTarget:(id)target
{
    return [[self alloc] initWithTitle:NSLocalizedString(@"Done", @"") style:UIBarButtonItemStyleDone target:target action:@selector(didFinishEditing)];
}


+ (instancetype)signOutButtonWithTarget:(id)target
{
    return [[self alloc] initWithTitle:NSLocalizedString(@"Log out", @"") style:UIBarButtonItemStylePlain target:target action:@selector(signOut)];
}


#pragma mark - Toolbar buttons

+ (instancetype)sendTextButtonWithTarget:(id)target
{
    UIBarButtonItem *button = nil;
    SEL action = @selector(processTextRequest);
    
    if ([OMeta systemIs_iOS6x]) {
        button = [self barButtonWithIcon:kIconFileSendText_iOS6x target:target action:action];
    } else {
        button = [[self alloc] initWithImage:[UIImage imageNamed:kIconFileSendText] style:UIBarButtonItemStylePlain target:[OMeta m].switchboard action:action];
    }
    
    return button;
}


+ (instancetype)phoneCallButtonWithTarget:(id)target
{
    UIBarButtonItem *button = nil;
    SEL action = @selector(processCallRequest);
    
    if ([OMeta systemIs_iOS6x]) {
        button = [self barButtonWithIcon:kIconFilePlacePhoneCall_iOS6x target:target action:action];
    } else {
        button = [[self alloc] initWithImage:[UIImage imageNamed:kIconFilePlacePhoneCall] style:UIBarButtonItemStylePlain target:[OMeta m].switchboard action:action];
    }
    
    return button;
}


+ (instancetype)sendEmailButtonWithTarget:(id)target
{
    UIBarButtonItem *button = nil;
    SEL action = @selector(processEmailRequest);
    
    if ([OMeta systemIs_iOS6x]) {
        button = [self barButtonWithIcon:kIconFileSendEmail_iOS6x target:target action:action];
    } else {
        button = [[self alloc] initWithImage:[UIImage imageNamed:kIconFileSendEmail] style:UIBarButtonItemStylePlain target:[OMeta m].switchboard action:action];
    }
    
    return button;
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
