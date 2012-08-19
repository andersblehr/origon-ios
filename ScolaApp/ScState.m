//
//  ScState.m
//  ScolaApp
//
//  Created by Anders Blehr on 28.07.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScState.h"

#import "ScMeta.h"


@implementation ScState

#pragma mark - Initialisation

- (id)init {
    self = [super init];
    
    if (self) {
        _action = ScStateActionDefault;
        _target = ScStateTargetDefault;
        _aspect = ScStateAspectDefault;
    }
    
    return self;
}


#pragma mark - State handling

- (ScState *)copy
{
    ScState *copy = [[ScState alloc] init];
    copy.action = _action;
    copy.target = _target;
    copy.aspect = _aspect;
    
    return copy;
}


- (void)setState:(ScState *)state
{
    _action = state.action;
    _target = state.target;
    _aspect = state.aspect;
}


#pragma mark - Generate string representation

- (NSString *)asString
{
    NSString *actionAsString = nil;
    NSString *targetAsString = nil;
    NSString *aspectAsString = nil;
    
    if (_action == ScStateActionDefault) {
        actionAsString = @"DEFAULT";
    } else if (_action == ScStateActionStartup) {
        actionAsString = @"STARTUP";
    } else if (_action == ScStateActionLogin) {
        actionAsString = @"LOGIN";
    } else if (_action == ScStateActionConfirm) {
        actionAsString = @"CONFIRM";
    } else if (_action == ScStateActionRegister) {
        actionAsString = @"REGISTER";
    } else if (_action == ScStateActionDisplay) {
        actionAsString = @"DISPLAY";
    } else if (_action == ScStateActionEdit) {
        actionAsString = @"EDIT";
    }
    
    if (_target == ScStateTargetDefault) {
        targetAsString = @"DEFAULT";
    } else if (_target == ScStateTargetUser) {
        targetAsString = @"USER";
    } else if (_target == ScStateTargetHousehold) {
        targetAsString = @"HOUSEHOLD";
    } else if (_target == ScStateTargetMemberships) {
        targetAsString = @"MEMBERSHIPS";
    } else if (_target == ScStateTargetMember) {
        targetAsString = @"MEMBER";
    } else if (_target == ScStateTargetScola) {
        targetAsString = @"SCOLA";
    }
    
    if (_aspect == ScStateAspectDefault) {
        aspectAsString = @"DEFAULT";
    } else if (_aspect == ScStateAspectHome) {
        aspectAsString = @"HOME";
    } else if (_aspect == ScStateAspectHousehold) {
        aspectAsString = @"HOUSEHOLD";
    } else if (_aspect == ScStateAspectScola) {
        aspectAsString = @"SCOLA";
    }
    
    return [NSString stringWithFormat:@"[%@][%@][%@]", actionAsString, targetAsString, aspectAsString];
}


#pragma mark - State action properties

- (BOOL)actionIsStartup
{
    return (_action == ScStateActionStartup);
}


- (BOOL)actionIsLogin
{
    return (_action == ScStateActionLogin);
}


- (BOOL)actionIsConfirm
{
    return (_action == ScStateActionConfirm);
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


- (BOOL)actionIsInputAction
{
    return (self.actionIsLogin || self.actionIsConfirm || self.actionIsRegister || self.actionIsEdit);
}


#pragma mark - State target properties

- (BOOL)targetIsUser
{
    return (_target == ScStateTargetUser);
}


- (BOOL)targetIsHousehold
{
    return (_target == ScStateTargetHousehold);
}


- (BOOL)targetIsMemberships
{
    return (_target == ScStateTargetMemberships);
}


- (BOOL)targetIsMember
{
    return (_target == ScStateTargetMember);
}


- (BOOL)targetIsScola
{
    return (_target == ScStateTargetScola);
}


#pragma mark - State aspect properties

- (BOOL)aspectIsHome
{
    return (_aspect == ScStateAspectHome);
}


- (BOOL)aspectIsHousehold
{
    return (_aspect == ScStateAspectHousehold);
}


- (BOOL)aspectIsScola
{
    return (_aspect == ScStateAspectScola);
}

@end
