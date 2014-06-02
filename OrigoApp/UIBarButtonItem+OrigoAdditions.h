//
//  UIBarButtonItem+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIBarButtonItem (OrigoAdditions)

+ (instancetype)settingsButtonWithTarget:(id)target;
+ (instancetype)plusButtonWithTarget:(id)target;
+ (instancetype)actionButtonWithTarget:(id)target;
+ (instancetype)lookupButtonWithTarget:(id)target;
+ (instancetype)nextButtonWithTarget:(id)target;
+ (instancetype)editButtonWithTarget:(id)target;
+ (instancetype)cancelButtonWithTarget:(id)target;
+ (instancetype)skipButtonWithTarget:(id)target;
+ (instancetype)doneButtonWithTarget:(id)target;
+ (instancetype)signOutButtonWithTarget:(id)target;

+ (instancetype)sendTextButtonWithTarget:(id)target;
+ (instancetype)phoneCallButtonWithTarget:(id)target;
+ (instancetype)sendEmailButtonWithTarget:(id)target;

+ (instancetype)flexibleSpace;
+ (instancetype)buttonWithTitle:(NSString *)title;

@end
