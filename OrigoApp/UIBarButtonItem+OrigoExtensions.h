//
//  UIBarButtonItem+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface UIBarButtonItem (OrigoExtensions)

+ (UIBarButtonItem *)flexibleSpace;

+ (UIBarButtonItem *)addButtonWithTarget:(id)target;
+ (UIBarButtonItem *)nextButtonWithTarget:(id)target;
+ (UIBarButtonItem *)cancelButtonWithTarget:(id)target;
+ (UIBarButtonItem *)doneButtonWithTarget:(id)target;
+ (UIBarButtonItem *)signOutButtonWithTarget:(id)target;
+ (UIBarButtonItem *)actionButtonWithTarget:(id)target;
+ (UIBarButtonItem *)chatButtonWithTarget:(id)target;

+ (UIBarButtonItem *)backButtonWithTitle:(NSString *)title;

@end
