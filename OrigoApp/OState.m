//
//  OState.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OState.h"

NSString * const kActionLoad = @"load";
NSString * const kActionSignIn = @"sign-in";
NSString * const kActionActivate = @"activate";
NSString * const kActionRegister = @"register";
NSString * const kActionList = @"list";
NSString * const kActionPick = @"pick";
NSString * const kActionDisplay = @"display";
NSString * const kActionEdit = @"edit";
NSString * const kActionInput = @"input";

NSString * const kTargetEmail = @"email";
NSString * const kTargetUser = @"user";
NSString * const kTargetWard = @"ward";
NSString * const kTargetHousemate = @"housemate";
NSString * const kTargetJuvenile = @"juvenile";
NSString * const kTargetElder = @"elder";
NSString * const kTargetMember = @"member";
NSString * const kTargetMembers = @"members";
NSString * const kTargetGuardian = @"guardian";
NSString * const kTargetContact = @"contact";
NSString * const kTargetParentContact = @"parentContact";
NSString * const kTargetRelation = @"relation";
NSString * const kTargetSetting = @"setting";
NSString * const kTargetSettings = @"settings";

static NSString * const kAspectHousehold = @"h";
static NSString * const kAspectDefault = @"d";

static OState *_activeState = nil;


@implementation OState

#pragma mark - Auxiliary methods

- (void)setAspectForTarget:(id)target
{
    if ([target isKindOfClass:[OMember class]]) {
        if ([target isHousemateOfUser]) {
            _pivotMember = target;
            _aspect = kAspectHousehold;
        } else {
            _aspect = kAspectDefault;
        }
    } else if ([target isKindOfClass:[OOrigo class]]) {
        if ([target isOfType:kOrigoTypeResidence] && [target userIsMember]) {
            _aspect = kAspectHousehold;
        } else {
            _aspect = kAspectDefault;
        }
    } else if ([target isKindOfClass:[NSString class]]) {
        if (![target isEqualToString:kOrigoTypeResidence] && ![target isEqualToString:kTargetMember]) {
            _aspect = kAspectDefault;
        }
    }
}


#pragma mark - Instantiation & initialisation

- (id)initWithViewController:(OTableViewController *)viewController
{
    self = [super init];
    
    if (self && viewController) {
        _viewController = viewController;
        
        if (_activeState) {
            _aspect = _activeState->_aspect;
            _pivotMember = _activeState.pivotMember;
        }
        
        self.target = viewController.target;
    }
    
    return self;
}


+ (OState *)s
{
    if (!_activeState) {
        _activeState = [[OState alloc] initWithViewController:nil];
    }
    
    return _activeState;
}


#pragma mark - State handling

- (void)reflectState:(OState *)state
{
    if (state != self) {
        _viewController = state.viewController;
        _pivotMember = state.pivotMember;
        _aspect = state->_aspect;
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

- (BOOL)aspectIsHousehold
{
    return [_aspect isEqualToString:kAspectHousehold];
}


- (BOOL)actionIs:(NSString *)action
{
    BOOL actionsDidMatch = [_action isEqualToString:action];
    
    if (!actionsDidMatch) {
        if ([action isEqualToString:kActionInput]) {
            actionsDidMatch = actionsDidMatch || [_action isEqualToString:kActionSignIn];
            actionsDidMatch = actionsDidMatch || [_action isEqualToString:kActionActivate];
            actionsDidMatch = actionsDidMatch || [_action isEqualToString:kActionRegister];
            actionsDidMatch = actionsDidMatch || [_action isEqualToString:kActionEdit];
        }
    }
    
    return actionsDidMatch;
}


- (BOOL)targetIs:(NSString *)target
{
    BOOL targetsDidMatch = [_target isEqualToString:target];
    
    if (!targetsDidMatch) {
        if ([target isEqualToString:kTargetJuvenile]) {
            targetsDidMatch = targetsDidMatch || [_target isEqualToString:kTargetWard];
        } else if ([target isEqualToString:kTargetElder]) {
            targetsDidMatch = targetsDidMatch || [_target isEqualToString:kTargetGuardian];
            targetsDidMatch = targetsDidMatch || [_target isEqualToString:kTargetContact];
            targetsDidMatch = targetsDidMatch || [_target isEqualToString:kTargetParentContact];
        }
    }
    
    return targetsDidMatch;
}


- (BOOL)isCurrent
{
    return (self.viewController == _activeState.viewController);
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


#pragma mark - Custom accessors

- (void)setAction:(NSString *)action
{
    _action = action;
    
    [_activeState reflectState:self];
}


- (void)setTarget:(id)target
{
    if ([target isKindOfClass:[OEntityProxy class]]) {
        if ([target isInstantiated]) {
            target = [target proxy].entity;
        } else {
            target = [target facade].type;
        }
    }
    
    [self setAspectForTarget:target];
    
    if ([target isKindOfClass:[OReplicatedEntity class]]) {
        _target = [target asTarget];
    } else if ([target isKindOfClass:[NSString class]]) {
        _target = [OValidator valueIsEmailAddress:target] ? kTargetEmail : target;
    }
    
    [_activeState reflectState:self];
}

@end
