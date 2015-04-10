//
//  UIBarButtonItem+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSInteger const kBarButtonTagAcceptDecline;
extern NSInteger const kBarButtonTagAction;
extern NSInteger const kBarButtonTagDirections;
extern NSInteger const kBarButtonTagEdit;
extern NSInteger const kBarButtonTagFavourite;
extern NSInteger const kBarButtonTagGroups;
extern NSInteger const kBarButtonTagRecipientGroups;
extern NSInteger const kBarButtonTagInfo;
extern NSInteger const kBarButtonTagLocation;
extern NSInteger const kBarButtonTagLookup;
extern NSInteger const kBarButtonTagMultiRole;
extern NSInteger const kBarButtonTagNavigation;
extern NSInteger const kBarButtonTagPlus;
extern NSInteger const kBarButtonTagSettings;

extern NSInteger const kBarButtonTagBack;
extern NSInteger const kBarButtonTagCancel;
extern NSInteger const kBarButtonTagDone;
extern NSInteger const kBarButtonTagLogout;
extern NSInteger const kBarButtonTagNext;

extern NSInteger const kBarButtonTagPhoneCall;
extern NSInteger const kBarButtonTagSendEmail;
extern NSInteger const kBarButtonTagSendText;


@interface UIBarButtonItem (OrigoAdditions)

+ (instancetype)acceptDeclineButtonWithTarget:(id)target;
+ (instancetype)actionButtonWithTarget:(id)target;
+ (instancetype)editButtonWithTarget:(id)target;
+ (instancetype)systemEditButtonWithTarget:(id)target;
+ (instancetype)groupsButtonWithTarget:(id)target;
+ (instancetype)recipientGroupsButtonWithTarget:(id)target;
+ (instancetype)infoButtonWithTarget:(id)target;
+ (instancetype)lookupButtonWithTarget:(id)target;
+ (instancetype)favouriteButtonWithTarget:(id)target isFavourite:(BOOL)isFavourite;
+ (instancetype)locationButtonWithTarget:(id)target;
+ (instancetype)directionsButtonWithTarget:(id)target;
+ (instancetype)navigationButtonWithTarget:(id)target;
+ (instancetype)plusButtonWithTarget:(id)target;
+ (instancetype)addToOrigoButtonWithTarget:(id)target;
+ (instancetype)settingsButtonWithTarget:(id)target;

+ (instancetype)backButtonWithTitle:(NSString *)title;
+ (instancetype)cancelButtonWithTarget:(id)target;
+ (instancetype)cancelButtonWithTarget:(id)target action:(SEL)action;
+ (instancetype)closeButtonWithTarget:(id)target;
+ (instancetype)doneButtonWithTarget:(id)target;
+ (instancetype)doneButtonWithTitle:(NSString *)title target:(id)target;
+ (instancetype)doneButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action;
+ (instancetype)nextButtonWithTarget:(id)target;
+ (instancetype)logoutButtonWithTarget:(id)target;
+ (instancetype)skipButtonWithTarget:(id)target;

+ (instancetype)sendTextButtonWithTarget:(id)target;
+ (instancetype)callButtonWithTarget:(id)target;
+ (instancetype)sendEmailButtonWithTarget:(id)target;

+ (instancetype)flexibleSpace;

@end
