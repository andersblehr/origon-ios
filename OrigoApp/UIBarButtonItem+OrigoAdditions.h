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
+ (instancetype)editButtonWithTarget:(id)target;
+ (instancetype)mapButtonWithTarget:(id)target;
+ (instancetype)infoButtonWithTarget:(id)target;
+ (instancetype)actionButtonWithTarget:(id)target;
+ (instancetype)lookupButtonWithTarget:(id)target;
+ (instancetype)multiRoleButtonWithTarget:(id)target selected:(BOOL)selected;

+ (instancetype)nextButtonWithTarget:(id)target;
+ (instancetype)cancelButtonWithTarget:(id)target;
+ (instancetype)cancelButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action;
+ (instancetype)skipButtonWithTarget:(id)target;
+ (instancetype)doneButtonWithTarget:(id)target;
+ (instancetype)doneButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action;
+ (instancetype)signOutButtonWithTarget:(id)target;

+ (instancetype)sendTextButtonWithTarget:(id)target;
+ (instancetype)phoneCallButtonWithTarget:(id)target;
+ (instancetype)sendEmailButtonWithTarget:(id)target;

+ (instancetype)flexibleSpace;
+ (instancetype)buttonWithTitle:(NSString *)title;

@end
