//
//  UIBarButtonItem+OBarButtonItemExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 03.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UIBarButtonItem+OBarButtonItemExtensions.h"

#import "OStrings.h"


@implementation UIBarButtonItem (OBarButtonItemExtensions)

+ (UIBarButtonItem *)addButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:target action:@selector(addItem)];
}


+ (UIBarButtonItem *)editButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithTitle:[OStrings stringForKey:strButtonEdit] style:UIBarButtonItemStylePlain target:target action:@selector(startEditing)];
}


+ (UIBarButtonItem *)doneButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithTitle:[OStrings stringForKey:strButtonDone] style:UIBarButtonItemStyleDone target:target action:@selector(didFinishEditing)];
}


+ (UIBarButtonItem *)cancelButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithTitle:[OStrings stringForKey:strButtonCancel] style:UIBarButtonItemStylePlain target:target action:@selector(cancelEditing)];
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
