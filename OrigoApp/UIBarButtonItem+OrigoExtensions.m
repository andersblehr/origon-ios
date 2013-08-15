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
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"14-gear.png"] style:UIBarButtonItemStylePlain target:target action:@selector(openSettings)];
}


+ (UIBarButtonItem *)addButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:target action:@selector(addItem)];
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


+ (UIBarButtonItem *)actionButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:target action:@selector(presentActionSheet)];
}


+ (UIBarButtonItem *)sendEmailButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:kIconFileSendEmail] style:UIBarButtonItemStylePlain target:target action:@selector(processEmailRequest)];
}


+ (UIBarButtonItem *)sendTextButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:kIconFileSendText] style:UIBarButtonItemStylePlain target:target action:@selector(processTextRequest)];
}


+ (UIBarButtonItem *)phoneCallButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:kIconFilePlacePhoneCall] style:UIBarButtonItemStylePlain target:target action:@selector(processPhoneCallRequest)];
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
