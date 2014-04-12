//
//  UIBarButtonItem+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIBarButtonItem (OrigoAdditions)

+ (instancetype)settingsButton;
+ (instancetype)plusButton;
+ (instancetype)actionButton;
+ (instancetype)lookupButton;
+ (instancetype)nextButton;
+ (instancetype)editButton;
+ (instancetype)cancelButton;
+ (instancetype)skipButton;
+ (instancetype)doneButton;
+ (instancetype)signOutButton;

+ (instancetype)sendTextButton;
+ (instancetype)phoneCallButton;
+ (instancetype)sendEmailButton;

+ (instancetype)flexibleSpace;
+ (instancetype)buttonWithTitle:(NSString *)title;

@end
