//
//  UIBarButtonItem+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface UIBarButtonItem (OrigoAdditions)

+ (UIBarButtonItem *)settingsButton;
+ (UIBarButtonItem *)plusButton;
+ (UIBarButtonItem *)actionButton;
+ (UIBarButtonItem *)lookupButton;
+ (UIBarButtonItem *)nextButton;
+ (UIBarButtonItem *)cancelButton;
+ (UIBarButtonItem *)doneButton;
+ (UIBarButtonItem *)signOutButton;
+ (UIBarButtonItem *)sendTextButton;
+ (UIBarButtonItem *)phoneCallButton;
+ (UIBarButtonItem *)sendEmailButton;
+ (UIBarButtonItem *)flexibleSpace;

@end
