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

NSString * const kViewIdAuth = @"auth";
NSString * const kViewIdCalendar = @"calendar";
NSString * const kViewIdMember = @"member";
NSString * const kViewIdMemberList = @"members";
NSString * const kViewIdMessageList = @"messages";
NSString * const kViewIdOrigo = @"origo";
NSString * const kViewIdOrigoList = @"origos";
NSString * const kViewIdSetting = @"setting";
NSString * const kViewIdSettingList = @"settings";
NSString * const kViewIdTaskList = @"tasks";

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
NSString * const kTargetHousemate = @"housemate";
NSString * const kTarget3rdParty = @"3rdParty";

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

- (void)reflect:(OState *)state
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

- (BOOL)viewIs:(NSString *)viewId
{
    return [_viewController.viewId isEqualToString:viewId];
}


- (BOOL)actionIs:(NSString *)action
{
    BOOL actionIsCurrent = NO;
    
    if ([action isEqualToString:kActionInput]) {
        actionIsCurrent = actionIsCurrent || [self.viewController actionIs:kActionSignIn];
        actionIsCurrent = actionIsCurrent || [self.viewController actionIs:kActionActivate];
        actionIsCurrent = actionIsCurrent || [self.viewController actionIs:kActionRegister];
        actionIsCurrent = actionIsCurrent || [self.viewController actionIs:kActionEdit];
    } else {
        actionIsCurrent = [_viewController actionIs:action];
    }
    
    return actionIsCurrent;
}


- (BOOL)targetIs:(NSString *)target
{
    return [_viewController targetIs:target];
}


#pragma mark - String representation

- (NSString *)asString
{
    NSString *viewId = [_viewController.viewId uppercaseString];
    NSString *action = [_viewController.action uppercaseString];
    NSString *target = [_viewController.target uppercaseString];
    
    viewId = viewId ? viewId : @"DEFAULT";
    action = action ? action : @"DEFAULT";
    target = target ? target : @"DEFAULT";
    
    return [NSString stringWithFormat:@"[%@][%@][%@]", action, viewId, target];
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
