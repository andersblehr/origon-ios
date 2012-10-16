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


@interface ScState ()

@property (nonatomic) ScStateAction action;
@property (nonatomic) ScStateTarget target;
@property (nonatomic) ScStateAspect aspect;

@end


@implementation ScState

#pragma mark - Auxiliary methods

- (void)setAction:(ScStateAction)action active:(BOOL)active
{
    if (active) {
        _action = action;
    } else {
        _action = ScStateActionNone;
    }
}


- (void)setTarget:(ScStateTarget)target active:(BOOL)active
{
    if (active) {
        _target = target;
    } else {
        _target = ScStateTargetNone;
    }
}


- (void)setAspect:(ScStateAspect)aspect active:(BOOL)active
{
    if (active) {
        _aspect = aspect;
    } else {
        _aspect = ScStateAspectNone;
    }
}


#pragma mark - Initialisation & factory method

- (id)init {
    self = [super init];
    
    if (self) {
        _action = ScStateActionInit;
        _target = ScStateTargetNone;
        _aspect = ScStateAspectNone;
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
    
    if (_action == ScStateActionInit) {
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
    } else if (self.targetIsScola) {
        targetAsString = @"SCOLA";
    } else {
        targetAsString = @"NONE";
    }
    
    if (self.aspectIsSelf) {
        aspectAsString = @"SELF";
    } else if (self.aspectIsDependent) {
        aspectAsString = @"DEPENDENT";
    } else if (self.aspectIsExternal) {
        aspectAsString = @"EXTERNAL";
    } else {
        aspectAsString = @"NONE";
    }
    
    return [NSString stringWithFormat:@"[%@][%@][%@]", actionAsString, targetAsString, aspectAsString];
}


#pragma mark - State action properties

- (void)setActionIsLogin:(BOOL)actionIsLogin
{
    [self setAction:ScStateActionLogin active:actionIsLogin];
}


- (BOOL)actionIsLogin
{
    return (_action == ScStateActionLogin);
}


- (void)setActionIsActivate:(BOOL)actionIsActivate
{
    [self setAction:ScStateActionActivate active:actionIsActivate];
}


- (BOOL)actionIsActivate
{
    return (_action == ScStateActionActivate);
}


- (void)setActionIsRegister:(BOOL)actionIsRegister
{
    [self setAction:ScStateActionRegister active:actionIsRegister];
}


- (BOOL)actionIsRegister
{
    return (_action == ScStateActionRegister);
}


- (void)setActionIsList:(BOOL)actionIsList
{
    [self setAction:ScStateActionList active:actionIsList];
}


- (BOOL)actionIsList
{
    return (_action == ScStateActionList);
}


- (void)setActionIsDisplay:(BOOL)actionIsDisplay
{
    [self setAction:ScStateActionDisplay active:actionIsDisplay];
}


- (BOOL)actionIsDisplay
{
    return (_action == ScStateActionDisplay);
}


- (void)setActionIsEdit:(BOOL)actionIsEdit
{
    [self setAction:ScStateActionEdit active:actionIsEdit];
}


- (BOOL)actionIsEdit
{
    return (_action == ScStateActionEdit);
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
    [self setTarget:ScStateTargetMember active:targetIsMember];
}


- (BOOL)targetIsMember
{
    return (_target == ScStateTargetMember);
}


- (void)setTargetIsScola:(BOOL)targetIsScola
{
    [self setTarget:ScStateTargetScola active:targetIsScola];
}


- (BOOL)targetIsScola
{
    return (_target == ScStateTargetScola);
}


#pragma mark - State aspect properties

- (void)setAspectIsSelf:(BOOL)aspectIsSelf
{
    [self setAspect:ScStateAspectSelf active:aspectIsSelf];
}


- (BOOL)aspectIsSelf
{
    return (_aspect == ScStateAspectSelf);
}


- (void)setAspectIsDependent:(BOOL)aspectIsDependent
{
    [self setAspect:ScStateAspectDependent active:aspectIsDependent];
}


- (BOOL)aspectIsDependent
{
    return (_aspect == ScStateAspectDependent);
}


- (void)setAspectIsExternal:(BOOL)aspectIsExternal
{
    [self setAspect:ScStateAspectExternal active:aspectIsExternal];
}


- (BOOL)aspectIsExternal
{
    return (_aspect == ScStateAspectExternal);
}

@end
