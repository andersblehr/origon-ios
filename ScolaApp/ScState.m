//
//  ScState.m
//  ScolaApp
//
//  Created by Anders Blehr on 28.07.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScState.h"

#import "ScMeta.h"


static ScState *s = nil;


@implementation ScState

#pragma mark - Initialisation & factory method

- (id)init {
    self = [super init];
    
    if (self) {
        _action = ScStateActionDefault;
        _target = ScStateTargetDefault;
        _aspect = ScStateAspectDefault;
    }
    
    return self;
}


+ (ScState *)s
{
    if (s == nil) {
        s = [[super allocWithZone:nil] init];
    }
    
    return s;
}


#pragma mark - Remember view initial state

- (void)saveCurrentStateForViewController:(NSString *)viewControllerId
{
    ScState *currentState = [[ScState alloc] init];
    currentState.action = _action;
    currentState.target = _target;
    currentState.aspect = _aspect;
    
    if (!_savedStates) {
        _savedStates = [[NSMutableDictionary alloc] init];
    }
    
    [_savedStates setObject:currentState forKey:viewControllerId];
}


- (void)revertToSavedStateForViewController:(NSString *)viewControllerId
{
    ScState *savedState = [_savedStates objectForKey:viewControllerId];
    
    _action = savedState.action;
    _target = savedState.target;
    _aspect = savedState.aspect;
}


#pragma mark - State string representation

- (NSString *)asString
{
    NSString *actionAsString = nil;
    NSString *targetAsString = nil;
    NSString *aspectAsString = nil;
    
    if (_action == ScStateActionStartup) {
        actionAsString = @"STARTUP";
    } else if (self.actionIsLogin) {
        actionAsString = @"LOGIN";
    } else if (self.actionIsActivate) {
        actionAsString = @"CONFIRM";
    } else if (self.actionIsRegister) {
        actionAsString = @"REGISTER";
    } else if (self.actionIsDisplay) {
        actionAsString = @"DISPLAY";
    } else if (self.actionIsEdit) {
        actionAsString = @"EDIT";
    } else {
        actionAsString = @"DEFAULT";
    }
    
    if (self.targetIsMember) {
        targetAsString = @"MEMBER";
    } else if (self.targetIsMemberships) {
        targetAsString = @"MEMBERSHIPS";
    } else if (self.targetIsResidence) {
        targetAsString = @"RESIDENCE";
    } else if (self.targetIsResidence) {
        targetAsString = @"SCOLA";
    } else {
        targetAsString = @"DEFAULT";
    }
    
    if (self.aspectIsSelf) {
        aspectAsString = @"SELF";
    } else if (self.aspectIsExternal) {
        aspectAsString = @"EXTERNAL";
    } else {
        aspectAsString = @"DEFAULT";
    }
    
    return [NSString stringWithFormat:@"[%@][%@][%@]", actionAsString, targetAsString, aspectAsString];
}


#pragma mark - State action properties

- (BOOL)actionIsLogin
{
    return (_action == ScStateActionLogin);
}


- (BOOL)actionIsActivate
{
    return (_action == ScStateActionActivate);
}


- (BOOL)actionIsRegister
{
    return (_action == ScStateActionRegister);
}


- (BOOL)actionIsDisplay
{
    return (_action == ScStateActionDisplay);
}


- (BOOL)actionIsEdit
{
    return (_action == ScStateActionEdit);
}


- (BOOL)actionIsInput
{
    return (self.actionIsLogin || self.actionIsActivate || self.actionIsRegister || self.actionIsEdit);
}


#pragma mark - State target properties

- (BOOL)targetIsMember
{
    return (_target == ScStateTargetMember);
}


- (BOOL)targetIsMemberships
{
    return (_target == ScStateTargetMemberships);
}


- (BOOL)targetIsResidence
{
    return (_target == ScStateTargetResidence);
}


- (BOOL)targetIsScola
{
    return (_target == ScStateTargetScola);
}


#pragma mark - State aspect properties

- (BOOL)aspectIsSelf
{
    return (_aspect == ScStateAspectSelf);
}


- (BOOL)aspectIsExternal
{
    return (_aspect == ScStateAspectExternal);
}

@end
