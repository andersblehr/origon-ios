//
//  UIBarButtonItem+OBarButtonItemExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 03.11.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBarButtonItem (OBarButtonItemExtensions)

+ (UIBarButtonItem *)addButtonWithTarget:(id)target;
+ (UIBarButtonItem *)editButtonWithTarget:(id)target;
+ (UIBarButtonItem *)doneButtonWithTarget:(id)target;
+ (UIBarButtonItem *)cancelButtonWithTarget:(id)target;
+ (UIBarButtonItem *)signInButtonWithTarget:(id)target;
+ (UIBarButtonItem *)signOutButtonWithTarget:(id)target;
+ (UIBarButtonItem *)backButtonWithTitle:(NSString *)title;

@end
