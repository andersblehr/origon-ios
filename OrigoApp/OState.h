//
//  OState.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OTableViewController.h"

#import "OTableViewListDelegate.h"

extern NSString * const kViewControllerAuth;
extern NSString * const kViewControllerCalendar;
extern NSString * const kViewControllerMember;
extern NSString * const kViewControllerMemberList;
extern NSString * const kViewControllerMessageList;
extern NSString * const kViewControllerOrigo;
extern NSString * const kViewControllerOrigoList;
extern NSString * const kViewControllerSetting;
extern NSString * const kViewControllerSettingList;
extern NSString * const kViewControllerTaskList;

extern NSString * const kActionSetup;
extern NSString * const kActionSignIn;
extern NSString * const kActionActivate;
extern NSString * const kActionRegister;
extern NSString * const kActionList;
extern NSString * const kActionDisplay;
extern NSString * const kActionEdit;
extern NSString * const kActionInput;

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

- (BOOL)viewControllerIs:(NSString *)viewControllerId;
- (BOOL)actionIs:(NSString *)action;
- (BOOL)targetIs:(NSString *)target;

- (NSString *)asString;

@end
