//
//  UIBarButtonItem+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 03.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UIBarButtonItem+OrigoExtensions.h"

#import "OLogging.h"
#import "OStrings.h"


@implementation UIBarButtonItem (OrigoExtensions)

+ (UIBarButtonItem *)addButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:target action:nil];
}


+ (UIBarButtonItem *)editButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithTitle:[OStrings stringForKey:strButtonEdit] style:UIBarButtonItemStylePlain target:target action:@selector(startEditing)];
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


+ (UIBarButtonItem *)backButtonWithTitle:(NSString *)title
{
    return [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:nil action:nil];
}

@end
