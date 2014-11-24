//
//  UIBarButtonItem+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSInteger const kBarButtonTagAcceptReject;
extern NSInteger const kBarButtonTagAction;
extern NSInteger const kbarButtonTagEdit;
extern NSInteger const kBarButtonTagFavourite;
extern NSInteger const kBarButtonTagGroups;
extern NSInteger const kBarButtonTagInfo;
extern NSInteger const kBarButtonTagLookup;
extern NSInteger const kBarButtonTagMap;
extern NSInteger const kBarButtonTagMultiRole;
extern NSInteger const kBarButtonTagPlus;
extern NSInteger const kBarButtonTagSettings;

extern NSInteger const kBarButtonTagBack;
extern NSInteger const kBarButtonTagCancel;
extern NSInteger const kBarButtonTagDone;
extern NSInteger const kBarButtonTagNext;
extern NSInteger const kBarButtonTagSignOut;

extern NSInteger const kBarButtonTagPhoneCall;
extern NSInteger const kBarButtonTagSendEmail;
extern NSInteger const kBarButtonTagSendText;


@interface UIBarButtonItem (OrigoAdditions)

+ (instancetype)acceptRejectButtonWithTarget:(id)target;
+ (instancetype)actionButtonWithTarget:(id)target;
+ (instancetype)editButtonWithTarget:(id)target;
+ (instancetype)groupsButtonWithTarget:(id)target;
+ (instancetype)infoButtonWithTarget:(id)target;
+ (instancetype)lookupButtonWithTarget:(id)target;
+ (instancetype)favouriteButtonWithTarget:(id)target isFavourite:(BOOL)isFavourite;
+ (instancetype)mapButtonWithTarget:(id)target;
+ (instancetype)multiRoleButtonWithTarget:(id)target on:(BOOL)on;
+ (instancetype)plusButtonWithTarget:(id)target;
+ (instancetype)settingsButtonWithTarget:(id)target;

+ (instancetype)backButtonWithTitle:(NSString *)title;
+ (instancetype)cancelButtonWithTarget:(id)target;
+ (instancetype)cancelButtonWithTarget:(id)target action:(SEL)action;
+ (instancetype)closeButtonWithTarget:(id)target;
+ (instancetype)doneButtonWithTarget:(id)target;
+ (instancetype)doneButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action;
+ (instancetype)nextButtonWithTarget:(id)target;
+ (instancetype)signOutButtonWithTarget:(id)target;
+ (instancetype)skipButtonWithTarget:(id)target;

+ (instancetype)sendTextButtonWithTarget:(id)target;
+ (instancetype)phoneCallButtonWithTarget:(id)target;
+ (instancetype)sendEmailButtonWithTarget:(id)target;

+ (instancetype)flexibleSpace;

@end
