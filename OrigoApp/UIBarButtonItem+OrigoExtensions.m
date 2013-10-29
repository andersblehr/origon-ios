//
//  UIBarButtonItem+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UIBarButtonItem+OrigoExtensions.h"


@implementation UIBarButtonItem (OrigoExtensions)

#pragma mark - Bar button shorthands

+ (UIBarButtonItem *)settingsButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:kIconFileSettings] style:UIBarButtonItemStylePlain target:target action:@selector(openSettings)];
}


+ (UIBarButtonItem *)plusButtonWithTarget:(id)target
{
    UIBarButtonItem *button = nil;
    
    if ([OMeta systemIs_iOS6x]) {
        button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:kIconFilePlus] style:UIBarButtonItemStylePlain target:target action:@selector(addItem)];
    } else {
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:target action:@selector(addItem)];
    }
    
    return button;
}


+ (UIBarButtonItem *)actionButtonWithTarget:(id)target
{
    UIBarButtonItem *button = nil;
    
    if ([OMeta systemIs_iOS6x]) {
        button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:kIconFileAction] style:UIBarButtonItemStylePlain target:target action:@selector(presentActionSheet)];
    } else {
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:target action:@selector(presentActionSheet)];
    }
    
    return button;
}


+ (UIBarButtonItem *)nextButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithTitle:[OStrings stringForKey:strButtonNext] style:UIBarButtonItemStylePlain target:target action:@selector(moveToNextInputField)];
}


+ (UIBarButtonItem *)cancelButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithTitle:[OStrings stringForKey:strButtonCancel] style:UIBarButtonItemStylePlain target:target action:@selector(didCancelEditing)];
}


+ (UIBarButtonItem *)doneButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithTitle:[OStrings stringForKey:strButtonDone] style:UIBarButtonItemStyleDone target:target action:@selector(didFinishEditing)];
}


+ (UIBarButtonItem *)signOutButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithTitle:[OStrings stringForKey:strButtonSignOut] style:UIBarButtonItemStylePlain target:target action:@selector(signOut)];
}


+ (UIBarButtonItem *)sendEmailButtonWithTarget:(id)target
{
    NSString *iconFile = [OMeta systemIs_iOS6x] ? kIconFileSendEmail_iOS6x : kIconFileSendEmail;
    
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:iconFile] style:UIBarButtonItemStylePlain target:target action:@selector(processEmailRequest)];
}


+ (UIBarButtonItem *)sendTextButtonWithTarget:(id)target
{
    NSString *iconFile = [OMeta systemIs_iOS6x] ? kIconFileSendText_iOS6x : kIconFileSendText;
    
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:iconFile] style:UIBarButtonItemStylePlain target:target action:@selector(processTextRequest)];
}


+ (UIBarButtonItem *)phoneCallButtonWithTarget:(id)target
{
    NSString *iconFile = [OMeta systemIs_iOS6x] ? kIconFilePlacePhoneCall_iOS6x : kIconFilePlacePhoneCall;
    
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:iconFile] style:UIBarButtonItemStylePlain target:target action:@selector(processPhoneCallRequest)];
}


+ (UIBarButtonItem *)flexibleSpace
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}


#pragma mark - Custom back button

+ (UIBarButtonItem *)backButtonWithTitle:(NSString *)title
{
    return [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:nil action:nil];
}

@end
