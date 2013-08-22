//
//  OState.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern NSString * const kIdentifierAuth;
extern NSString * const kIdentifierCalendar;
extern NSString * const kIdentifierMember;
extern NSString * const kIdentifierMemberList;
extern NSString * const kIdentifierMessageList;
extern NSString * const kIdentifierOrigo;
extern NSString * const kIdentifierOrigoList;
extern NSString * const kIdentifierSetting;
extern NSString * const kIdentifierSettingList;
extern NSString * const kIdentifierTaskList;

extern NSString * const kActionLoad;
extern NSString * const kActionSignIn;
extern NSString * const kActionActivate;
extern NSString * const kActionRegister;
extern NSString * const kActionList;
extern NSString * const kActionDisplay;
extern NSString * const kActionEdit;
extern NSString * const kActionInput;

extern NSString * const kTargetStrings;
extern NSString * const kTargetEmail;
extern NSString * const kTargetUser;
extern NSString * const kTargetWard;
extern NSString * const kTargetHousehold;
extern NSString * const kTargetExternal;

@interface OState : NSObject

@property (weak, nonatomic, readonly) OTableViewController *viewController;
@property (strong, nonatomic) NSString *action;
@property (strong, nonatomic) id target;

@property (weak, nonatomic, readonly) id<OTableViewListDelegate> listDelegate;
@property (weak, nonatomic, readonly) id<OTableViewInputDelegate, UITextFieldDelegate, UITextViewDelegate> inputDelegate;

- (id)initWithViewController:(OTableViewController *)viewController;

+ (OState *)s;

- (void)reflectState:(OState *)state;
- (void)toggleAction:(NSArray *)alternatingActions;

- (BOOL)actionIs:(NSString *)action;
- (BOOL)targetIs:(NSString *)target;
- (BOOL)isCurrent;

- (NSString *)asString;

@end
