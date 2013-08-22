//
//  OState.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OState.h"

NSString * const kIdentifierAuth = @"auth";
NSString * const kIdentifierCalendar = @"calendar";
NSString * const kIdentifierMember = @"member";
NSString * const kIdentifierMemberList = @"members";
NSString * const kIdentifierMessageList = @"messages";
NSString * const kIdentifierOrigo = @"origo";
NSString * const kIdentifierOrigoList = @"origos";
NSString * const kIdentifierSetting = @"setting";
NSString * const kIdentifierSettingList = @"settings";
NSString * const kIdentifierTaskList = @"tasks";

NSString * const kActionLoad = @"load";
NSString * const kActionSignIn = @"sign-in";
NSString * const kActionActivate = @"activate";
NSString * const kActionRegister = @"register";
NSString * const kActionList = @"list";
NSString * const kActionDisplay = @"display";
NSString * const kActionEdit = @"edit";
NSString * const kActionInput = @"input";

NSString * const kTargetStrings = @"strings";
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
        s = [[OState alloc] initWithViewController:nil];
    }
    
    return s;
}


#pragma mark - State reflection & toggling

- (void)reflectState:(OState *)state
{
    if (state != self) {
        _viewController = state.viewController;
        _action = state.action;
        _target = state.target;
    }
}


- (void)toggleAction:(NSArray *)alternatingActions
{
    if ([alternatingActions count] == 2) {
        if ([_action isEqualToString:alternatingActions[0]]) {
            self.action = alternatingActions[1];
        } else if ([_action isEqualToString:alternatingActions[1]]) {
            self.action = alternatingActions[0];
        }
    }
}


#pragma mark - State inspection

- (BOOL)actionIs:(NSString *)action
{
    BOOL actionIsCurrent = NO;
    
    if ([action isEqualToString:kActionInput]) {
        actionIsCurrent = actionIsCurrent || [_action isEqualToString:kActionSignIn];
        actionIsCurrent = actionIsCurrent || [_action isEqualToString:kActionActivate];
        actionIsCurrent = actionIsCurrent || [_action isEqualToString:kActionRegister];
        actionIsCurrent = actionIsCurrent || [_action isEqualToString:kActionEdit];
    } else {
        actionIsCurrent = [_action isEqualToString:action];
    }
    
    return actionIsCurrent;
}


- (BOOL)targetIs:(NSString *)target
{
    BOOL targetIsCurrent = NO;
    
    if ([target isEqualToString:kTargetHousehold]) {
        targetIsCurrent = targetIsCurrent || [_target isEqualToString:kTargetHousehold];
        targetIsCurrent = targetIsCurrent || [_target isEqualToString:kTargetUser];
        targetIsCurrent = targetIsCurrent || [_target isEqualToString:kTargetWard];
    } else if ([target isEqualToString:kOrigoTypeResidence]) {
        targetIsCurrent = targetIsCurrent || [_target isEqualToString:kOrigoTypeResidence];
        targetIsCurrent = targetIsCurrent || [_target isEqualToString:kTargetHousehold];
    } else {
        targetIsCurrent = [_target isEqualToString:target];
    }
    
    return targetIsCurrent;
}


- (BOOL)isCurrent
{
    return (self.viewController == [OState s].viewController);
}


#pragma mark - String representation

- (NSString *)asString
{
    NSString *viewController = [_viewController.identifier uppercaseString];
    NSString *action = [_action uppercaseString];
    NSString *target = [_target uppercaseString];
    
    viewController = viewController ? viewController : @"DEFAULT";
    action = action ? action : @"DEFAULT";
    target = target ? target : @"DEFAULT";
    
    return [NSString stringWithFormat:@"[%@][%@][%@]", action, viewController, target];
}


#pragma mark - Custom property accessors

- (void)setAction:(NSString *)action
{
    _action = action;
    
    [[OState s] reflectState:self];
}


- (void)setTarget:(id)target
{
    if ([target isKindOfClass:OReplicatedEntity.class]) {
        _target = [target asTarget];
    } else if ([target isKindOfClass:NSString.class]) {
        _target = [OValidator valueIsEmailAddress:target] ? kTargetEmail : target;
    }
    
    [[OState s] reflectState:self];
}


- (id<OTableViewListDelegate>)listDelegate
{
    id listDelegate = nil;

    if ([_viewController conformsToProtocol:@protocol(OTableViewListDelegate)]) {
        listDelegate = (id<OTableViewListDelegate>)_viewController;
    }
    
    return listDelegate;
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
