//
//  UIBarButtonItem+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIBarButtonItem (OrigoAdditions)

+ (UIBarButtonItem *)settingsButton;
+ (UIBarButtonItem *)plusButton;
+ (UIBarButtonItem *)actionButton;
+ (UIBarButtonItem *)lookupButton;
+ (UIBarButtonItem *)nextButton;
+ (UIBarButtonItem *)editButton;
+ (UIBarButtonItem *)cancelButton;
+ (UIBarButtonItem *)skipButton;
+ (UIBarButtonItem *)doneButton;
+ (UIBarButtonItem *)signOutButton;

+ (UIBarButtonItem *)sendTextButton;
+ (UIBarButtonItem *)phoneCallButton;
+ (UIBarButtonItem *)sendEmailButton;

+ (UIBarButtonItem *)flexibleSpace;

@end
