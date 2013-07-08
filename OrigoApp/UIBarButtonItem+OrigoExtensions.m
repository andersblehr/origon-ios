//
//  UIBarButtonItem+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "UIBarButtonItem+OrigoExtensions.h"


@implementation UIBarButtonItem (OrigoExtensions)

#pragma mark - Toolbar flexible space

+ (UIBarButtonItem *)flexibleSpace
{
    static UIBarButtonItem *flexibleSpace = nil;
    
    if (!flexibleSpace) {
        flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    }
    
    return flexibleSpace;
}


#pragma mark - Convenience methods

+ (UIBarButtonItem *)addButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:target action:nil];
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
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:target action:nil];
}


+ (UIBarButtonItem *)chatButtonWithTarget:(id)target
{
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"08-chat.png"] landscapeImagePhone:[UIImage imageNamed:@"08-chat.png"] style:UIBarButtonItemStylePlain target:target action:@selector(signOut)];
}


#pragma mark - Custom back button

+ (UIBarButtonItem *)backButtonWithTitle:(NSString *)title
{
    return [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:nil action:nil];
}

@end
