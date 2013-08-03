//
//  OState.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern NSString * const kVCIdentifierAuth;
extern NSString * const kVCIdentifierCalendar;
extern NSString * const kVCIdentifierMember;
extern NSString * const kVCIdentifierMemberList;
extern NSString * const kVCIdentifierMessageList;
extern NSString * const kVCIdentifierOrigo;
extern NSString * const kVCIdentifierOrigoList;
extern NSString * const kVCIdentifierSetting;
extern NSString * const kVCIdentifierSettingList;
extern NSString * const kVCIdentifierTaskList;

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

- (NSString *)asString;

@end
