//
//  OState.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OState.h"

#import "OMeta.h"

static OState *s = nil;


@implementation OState

#pragma mark - Auxiliary methods

- (void)setAction:(OStateAction)action active:(BOOL)active
{
    if (active) {
        _action = action;
    } else if (_action == action) {
        _action = OStateActionNone;
    }
}


- (void)setTarget:(OStateTarget)target active:(BOOL)active
{
    if (active) {
        _target = target;
    } else if (_target == target) {
        _target = OStateTargetNone;
    }
}


- (void)setAspect:(OStateAspect)aspect active:(BOOL)active
{
    if (active) {
        _aspect = aspect;
    } else if (_aspect == aspect) {
        _aspect = OStateAspectNone;
    }
}


#pragma mark - Initialisation & factory method

- (id)init {
    self = [super init];
    
    if (self) {
        _action = OStateActionInit;
        _target = OStateTargetNone;
        _aspect = OStateAspectNone;
    }
    
    return self;
}


+ (OState *)s
{
    if (s == nil) {
        s = [[super allocWithZone:nil] init];
    }
    
    return s;
}


#pragma mark - State string representation

- (NSString *)asString
{
    NSString *actionAsString = nil;
    NSString *targetAsString = nil;
    NSString *aspectAsString = nil;
    
    if (_action == OStateActionInit) {
        actionAsString = @"INIT";
    } else if (self.actionIsLogin) {
        actionAsString = @"LOGIN";
    } else if (self.actionIsActivate) {
        actionAsString = @"ACTIVATE";
    } else if (self.actionIsRegister) {
        actionAsString = @"REGISTER";
    } else if (self.actionIsList) {
        actionAsString = @"LIST";
    } else if (self.actionIsDisplay) {
        actionAsString = @"DISPLAY";
    } else if (self.actionIsEdit) {
        actionAsString = @"EDIT";
    } else {
        actionAsString = @"NONE";
    }
    
    if (self.targetIsMember) {
        targetAsString = @"MEMBER";
    } else if (self.targetIsOrigo) {
        targetAsString = @"ORIGO";
    } else {
        targetAsString = @"NONE";
    }
    
    if (self.aspectIsSelf) {
        aspectAsString = @"SELF";
    } else if (self.aspectIsWard) {
        aspectAsString = @"WARD";
    } else if (self.aspectIsExternal) {
        aspectAsString = @"EXTERNAL";
    } else {
        aspectAsString = @"NONE";
    }
    
    return [NSString stringWithFormat:@"[%@][%@][%@]", actionAsString, targetAsString, aspectAsString];
}


#pragma mark - Convenience property accessors

- (void)setActionIsLogin:(BOOL)actionIsLogin
{
    [self setAction:OStateActionLogin active:actionIsLogin];
}


- (BOOL)actionIsLogin
{
    return (_action == OStateActionLogin);
}


- (void)setActionIsActivate:(BOOL)actionIsActivate
{
    [self setAction:OStateActionActivate active:actionIsActivate];
}


- (BOOL)actionIsActivate
{
    return (_action == OStateActionActivate);
}


- (void)setActionIsRegister:(BOOL)actionIsRegister
{
    [self setAction:OStateActionRegister active:actionIsRegister];
}


- (BOOL)actionIsRegister
{
    return (_action == OStateActionRegister);
}


- (void)setActionIsList:(BOOL)actionIsList
{
    [self setAction:OStateActionList active:actionIsList];
}


- (BOOL)actionIsList
{
    return (_action == OStateActionList);
}


- (void)setActionIsDisplay:(BOOL)actionIsDisplay
{
    [self setAction:OStateActionDisplay active:actionIsDisplay];
}


- (BOOL)actionIsDisplay
{
    return (_action == OStateActionDisplay);
}


- (void)setActionIsEdit:(BOOL)actionIsEdit
{
    [self setAction:OStateActionEdit active:actionIsEdit];
}


- (BOOL)actionIsEdit
{
    return (_action == OStateActionEdit);
}


- (BOOL)actionIsInput
{
    BOOL actionIsInput = NO;
    
    actionIsInput = actionIsInput || self.actionIsLogin;
    actionIsInput = actionIsInput || self.actionIsActivate;
    actionIsInput = actionIsInput || self.actionIsRegister;
    actionIsInput = actionIsInput || self.actionIsEdit;

    return actionIsInput;
}


#pragma mark - State target properties

- (void)setTargetIsMember:(BOOL)targetIsMember
{
    [self setTarget:OStateTargetMember active:targetIsMember];
}


- (BOOL)targetIsMember
{
    return (_target == OStateTargetMember);
}


- (void)setTargetIsOrigo:(BOOL)targetIsOrigo
{
    [self setTarget:OStateTargetOrigo active:targetIsOrigo];
}


- (BOOL)targetIsOrigo
{
    return (_target == OStateTargetOrigo);
}


#pragma mark - State aspect properties

- (void)setAspectIsSelf:(BOOL)aspectIsSelf
{
    [self setAspect:OStateAspectSelf active:aspectIsSelf];
}


- (BOOL)aspectIsSelf
{
    return (_aspect == OStateAspectSelf);
}


- (void)setAspectIsWard:(BOOL)aspectIsWard
{
    [self setAspect:OStateAspectWard active:aspectIsWard];
}


- (BOOL)aspectIsWard
{
    return (_aspect == OStateAspectWard);
}


- (void)setAspectIsExternal:(BOOL)aspectIsExternal
{
    [self setAspect:OStateAspectExternal active:aspectIsExternal];
}


- (BOOL)aspectIsExternal
{
    return (_aspect == OStateAspectExternal);
}

@end