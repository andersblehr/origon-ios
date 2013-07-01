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
#import "OValidator.h"

#import "OMember+OrigoExtensions.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"

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
NSString * const kActionSignIn = @"sign-in";
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


#pragma mark - State reflection

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
            _action = alternatingActions[1];
        } else if ([_action isEqualToString:alternatingActions[1]]) {
            _action = alternatingActions[0];
        }
        
        if (self != [OState s]) {
            [[OState s] reflectState:self];
        }
    }
}


#pragma mark - State inspection

- (BOOL)viewControllerIs:(NSString *)viewControllerId
{
    return [_viewController.viewControllerId isEqualToString:viewControllerId];
}


- (BOOL)actionIs:(NSString *)action
{
    BOOL isCurrent = NO;
    
    if ([action isEqualToString:kActionInput]) {
        isCurrent = isCurrent || [_action isEqualToString:kActionSignIn];
        isCurrent = isCurrent || [_action isEqualToString:kActionActivate];
        isCurrent = isCurrent || [_action isEqualToString:kActionRegister];
        isCurrent = isCurrent || [_action isEqualToString:kActionEdit];
    } else {
        isCurrent = [_action isEqualToString:action];
    }
    
    return isCurrent;
}


- (BOOL)targetIs:(NSString *)target
{
    BOOL isCurrent = NO;
    
    if ([target isEqualToString:kTargetHousehold]) {
        isCurrent = isCurrent || [_target isEqualToString:kTargetHousehold];
        isCurrent = isCurrent || [_target isEqualToString:kTargetUser];
        isCurrent = isCurrent || [_target isEqualToString:kTargetWard];
    } else if ([target isEqualToString:kOrigoTypeResidence]) {
        isCurrent = isCurrent || [_target isEqualToString:kOrigoTypeResidence];
        isCurrent = isCurrent || [_target isEqualToString:kTargetHousehold];
    } else {
        isCurrent = [_target isEqualToString:target];
    }
    
    return isCurrent;
}


#pragma mark - String representation

- (NSString *)asString
{
    NSString *viewController = [_viewController.viewControllerId uppercaseString];
    NSString *action = [_action uppercaseString];
    NSString *target = [_target uppercaseString];
    
    viewController = viewController ? viewController : @"DEFAULT";
    action = action ? action : @"DEFAULT";
    target = target ? target : @"DEFAULT";
    
    return [NSString stringWithFormat:@"[%@][%@][%@]", action, viewController, target];
}


#pragma mark - Custom property accessors

- (void)setTarget:(id)target
{
    if ([target isKindOfClass:OReplicatedEntity.class]) {
        _target = [target asTarget];
    } else if ([target isKindOfClass:NSString.class]) {
        _target = [OValidator valueIsEmailAddress:target] ? kTargetEmail : target;
    }
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
