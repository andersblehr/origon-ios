//
//  OState.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OTableViewController.h"

#import "OTableViewListCellDelegate.h"

extern NSString * const kViewIdAuth;
extern NSString * const kViewIdCalendar;
extern NSString * const kViewIdMember;
extern NSString * const kViewIdMemberList;
extern NSString * const kViewIdMessageList;
extern NSString * const kViewIdOrigo;
extern NSString * const kViewIdOrigoList;
extern NSString * const kViewIdSetting;
extern NSString * const kViewIdSettingList;
extern NSString * const kViewIdTaskList;

extern NSString * const kActionSetup;
extern NSString * const kActionLogin;
extern NSString * const kActionActivate;
extern NSString * const kActionRegister;
extern NSString * const kActionList;
extern NSString * const kActionDisplay;
extern NSString * const kActionEdit;
extern NSString * const kActionInput;

extern NSString * const kTargetEmail;
extern NSString * const kTargetUser;
extern NSString * const kTargetWard;
extern NSString * const kTargetHousemate;
extern NSString * const kTarget3rdParty;

@interface OState : NSObject

@property (weak, nonatomic, readonly) OTableViewController *viewController;
@property (weak, nonatomic, readonly) id<OTableViewListCellDelegate> listCellDelegate;
@property (weak, nonatomic, readonly) id<OTableViewInputDelegate, UITextFieldDelegate, UITextViewDelegate> inputDelegate;

- (id)initWithViewController:(OTableViewController *)viewController;

+ (OState *)s;

- (void)reflect:(OState *)state;
- (void)toggleEditState;

- (BOOL)viewIs:(NSString *)viewId;
- (BOOL)actionIs:(NSString *)action;
- (BOOL)targetIs:(NSString *)target;

- (NSString *)asString;

@end
