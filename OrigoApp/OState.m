//
//  OState.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OState.h"

#import "OMeta.h"
#import "OStrings.h"

#import "OMember+OrigoExtensions.h"
#import "OOrigo+OrigoExtensions.h"

#import "OAuthViewController.h"
#import "OMemberListViewController.h"
#import "OMemberViewController.h"
#import "OOrigoListViewController.h"
#import "OOrigoViewController.h"
#import "OCalendarViewController.h"
#import "OTaskListViewController.h"
#import "OMessageListViewController.h"
#import "OSettingListViewController.h"

NSString * const kViewControllerAuth = @"auth";
NSString * const kViewControllerCalendar = @"calendar";
NSString * const kViewControllerMember = @"member";
NSString * const kViewControllerMemberList = @"members";
NSString * const kViewControllerMessageList = @"messages";
NSString * const kViewControllerOrigo = @"origo";
NSString * const kViewControllerOrigoList = @"origos";
NSString * const kViewControllerSetting = @"setting";
NSString * const kViewControllerSettingList = @"settings";
NSString * const kViewControllerTaskList = @"tasks";

NSString * const kActionSetup = @"setup";
NSString * const kActionSignIn = @"signin";
NSString * const kActionActivate = @"activate";
NSString * const kActionRegister = @"register";
NSString * const kActionList = @"list";
NSString * const kActionDisplay = @"display";
NSString * const kActionEdit = @"edit";
NSString * const kActionInput = @"input";

NSString * const kTargetEmail = @"email";
NSString * const kTargetUser = @"user";
NSString * const kTargetWard = @"ward";
NSString * const kTargetHousehold = @"household";
NSString * const kTargetExternal = @"external";

static OState *s = nil;


@implementation OState

#pragma mark - Instantiation & initialisation

- (id)initWithViewController:(OTableViewController *)viewController
{
    self = [super init];
    
    if (self && viewController) {
        _viewController = viewController;
    }
    
    return self;
}


+ (OState *)s
{
    if (!s) {
        s = [[self alloc] initWithViewController:nil];
    }
    
    return s;
}


#pragma mark - Utility methods

- (void)reflectState:(OState *)state
{
    _viewController = state.viewController;
}


- (void)toggleEditState
{
    if ([_viewController actionIs:kActionDisplay]) {
        _viewController.action = kActionEdit;
    } else if ([_viewController actionIs:kActionEdit]) {
        _viewController.action = kActionDisplay;
    }
}


#pragma mark - State inspection

- (BOOL)viewControllerIs:(NSString *)viewControllerId
{
    return [_viewController.viewControllerId isEqualToString:viewControllerId];
}


- (BOOL)actionIs:(NSString *)action
{
    BOOL actionIsCurrent = NO;
    
    if ([action isEqualToString:kActionInput]) {
        actionIsCurrent = actionIsCurrent || [_viewController actionIs:kActionSignIn];
        actionIsCurrent = actionIsCurrent || [_viewController actionIs:kActionActivate];
        actionIsCurrent = actionIsCurrent || [_viewController actionIs:kActionRegister];
        actionIsCurrent = actionIsCurrent || [_viewController actionIs:kActionEdit];
    } else {
        actionIsCurrent = [_viewController actionIs:action];
    }
    
    return actionIsCurrent;
}


- (BOOL)targetIs:(NSString *)target
{
    BOOL targetIsCurrent = NO;
    
    if ([target isEqualToString:kTargetHousehold]) {
        targetIsCurrent = targetIsCurrent || [_viewController targetIs:kTargetUser];
        targetIsCurrent = targetIsCurrent || [_viewController targetIs:kTargetWard];
        targetIsCurrent = targetIsCurrent || [_viewController targetIs:kTargetHousehold];
    } else {
        targetIsCurrent = [_viewController targetIs:target];
    }
    
    return targetIsCurrent;
}


#pragma mark - String representation

- (NSString *)asString
{
    NSString *viewController = [_viewController.viewControllerId uppercaseString];
    NSString *action = [_viewController.action uppercaseString];
    NSString *target = [_viewController.target uppercaseString];
    
    viewController = viewController ? viewController : @"DEFAULT";
    action = action ? action : @"DEFAULT";
    target = target ? target : @"DEFAULT";
    
    return [NSString stringWithFormat:@"[%@][%@][%@]", action, viewController, target];
}


#pragma mark - Custom property accessors

- (id<OTableViewListCellDelegate>)listCellDelegate
{
    id listCellDelegate = nil;

    if ([_viewController conformsToProtocol:@protocol(OTableViewListCellDelegate)]) {
        listCellDelegate = (id<OTableViewListCellDelegate>)_viewController;
    }
    
    return listCellDelegate;
}


- (id<OTableViewInputDelegate, UITextFieldDelegate, UITextViewDelegate>)inputDelegate
{
    id inputDelegate = nil;
    
    if ([_viewController conformsToProtocol:@protocol(OTableViewInputDelegate)] ||
        [_viewController conformsToProtocol:@protocol(UITextFieldDelegate)] ||
        [_viewController conformsToProtocol:@protocol(UITextViewDelegate)]) {
        inputDelegate = (id<UITextFieldDelegate, UITextViewDelegate>)_viewController;
    }
    
    return inputDelegate;
}

@end
