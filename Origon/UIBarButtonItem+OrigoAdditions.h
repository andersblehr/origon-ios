//
//  UIBarButtonItem+OrigoAdditions.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSInteger const kBarButtonItemTagAcceptDecline;
extern NSInteger const kBarButtonItemTagAction;
extern NSInteger const kBarButtonItemTagDirections;
extern NSInteger const kBarButtonItemTagEdit;
extern NSInteger const kBarButtonItemTagFavourite;
extern NSInteger const kBarButtonItemTagGroups;
extern NSInteger const kBarButtonItemTagRecipientGroups;
extern NSInteger const kBarButtonItemTagInfo;
extern NSInteger const kBarButtonItemTagLocation;
extern NSInteger const kBarButtonItemTagLookup;
extern NSInteger const kBarButtonItemTagNavigation;
extern NSInteger const kBarButtonItemTagPlus;
extern NSInteger const kBarButtonItemTagJoin;
extern NSInteger const kBarButtonItemTagSettings;

extern NSInteger const kBarButtonItemTagBack;
extern NSInteger const kBarButtonItemTagCancel;
extern NSInteger const kBarButtonItemTagDone;
extern NSInteger const kBarButtonItemTagLogout;
extern NSInteger const kBarButtonItemTagNext;

extern NSInteger const kBarButtonItemTagPhoneCall;
extern NSInteger const kBarButtonItemTagSendEmail;
extern NSInteger const kBarButtonItemTagSendText;


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
+ (instancetype)joinButtonWithTarget:(id)target;
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
