//
//  OState.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OState.h"

#import "OMeta.h"

#import "OMember+OrigoExtensions.h"
#import "OOrigo.h"

static OState *s = nil;


@implementation OState

#pragma mark - Auxiliary methods

- (void)setAction:(OStateAction)action activate:(BOOL)activate
{
    _action = activate ? action : _action;

    if (!(self == s)) {
        [[OState s] setAction:action activate:activate];
    }
}


- (void)setTarget:(OStateTarget)target activate:(BOOL)activate
{
    _target = activate ? target : _target;
    
    if (!(self == s)) {
        [[OState s] setTarget:target activate:activate];
    }
}


- (void)setAspect:(OStateAspect)aspect activate:(BOOL)activate
{
    _aspect = activate ? aspect : _aspect;
    
    if (!(self == s)) {
        [[OState s] setAspect:aspect activate:activate];
    }
}


#pragma mark - Instantiation & initialisation

- (id)copyWithZone:(NSZone *)zone
{
    OState *copy = [[OState alloc] init];
    
    copy.action = _action;
    copy.target = _target;
    copy.aspect = _aspect;
    
    return copy;
}


- (id)init
{
    self = [super init];
    
    if (self) {
        _action = OStateActionNone;
        _target = OStateTargetNone;
        _aspect = OStateAspectNone;
    }
    
    return self;
}


+ (OState *)s
{
    if (!s) {
        s = [[self alloc] init];
    }
    
    return s;
}


- (void)reflect:(OState *)state
{
    _action = state.action;
    _target = state.target;
    _aspect = state.aspect;
}


#pragma mark - Entity to aspect mappings

- (void)setAspectForMember:(OMember *)member
{
    OStateAspect aspect = [OState s].aspect;
    
    if (member) {
        if ([member isUser]) {
            aspect = OStateAspectSelf;
        } else if ([[[OMeta m].user wards] containsObject:member]) {
            aspect = OStateAspectWard;
        }
    }
    
    [self setAspect:aspect activate:YES];
}


- (void)setAspectForOrigo:(OOrigo *)origo
{
    OStateAspect aspect = [OState s].aspect;
    
    if (origo) {
        if ([origo.type isEqualToString:kOrigoTypeResidence]) {
            aspect = OStateAspectResidence;
        } else if ([origo.type isEqualToString:kOrigoTypeOrganisation]) {
            aspect = OStateAspectOrganisation;
        } else if ([origo.type isEqualToString:kOrigoTypeSchoolClass]) {
            aspect = OStateAspectClass;
        } else if ([origo.type isEqualToString:kOrigoTypePreschoolClass]) {
            aspect = OStateAspectPreschool;
        } else if ([origo.type isEqualToString:kOrigoTypeSportsTeam]) {
            aspect = OStateAspectTeam;
        }
    }
    
    [self setAspect:aspect activate:YES];
}


#pragma mark - Toggle between edit & display action

- (void)toggleEdit
{
    if (self.actionIsDisplay) {
        self.actionIsEdit = YES;
    } else if (self.actionIsEdit) {
        self.actionIsDisplay = YES;
    }
}


#pragma mark - State string representation

- (NSString *)asString
{
    NSString *actionAsString = nil;
    NSString *targetAsString = nil;
    NSString *aspectAsString = nil;
    
    if (self.actionIsSetup) {
        actionAsString = @"SETUP";
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
    } else if (self.targetIsEmail) {
        targetAsString = @"EMAIL";
    } else if (self.targetIsSetting) {
        targetAsString = @"SETTING";
    } else {
        targetAsString = @"NONE";
    }
    
    if (self.aspectIsSelf) {
        aspectAsString = @"SELF";
    } else if (self.aspectIsWard) {
        aspectAsString = @"WARD";
    } else if (self.aspectIsExternal) {
        aspectAsString = @"EXTERNAL";
    } else if (self.aspectIsResidence) {
        aspectAsString = @"RESIDENCE";
    } else if (self.aspectIsOrganisation) {
        aspectAsString = @"ORGANISATION";
    } else if (self.aspectIsClass) {
        aspectAsString = @"CLASS";
    } else if (self.aspectIsPreschool) {
        aspectAsString = @"PRESCHOOL";
    } else if (self.aspectIsTeam) {
        aspectAsString = @"TEAM";
    } else {
        aspectAsString = @"NONE";
    }
    
    return [NSString stringWithFormat:@"[%@][%@][%@]", actionAsString, targetAsString, aspectAsString];
}


#pragma mark - Convenience property accessors

- (void)setActionIsSetup:(BOOL)actionIsSetup
{
    [self setAction:OStateActionSetup activate:actionIsSetup];
}


- (BOOL)actionIsSetup
{
    return (_action == OStateActionSetup);
}


- (void)setActionIsLogin:(BOOL)actionIsLogin
{
    [self setAction:OStateActionLogin activate:actionIsLogin];
}


- (BOOL)actionIsLogin
{
    return (_action == OStateActionLogin);
}


- (void)setActionIsActivate:(BOOL)actionIsActivate
{
    [self setAction:OStateActionActivate activate:actionIsActivate];
}


- (BOOL)actionIsActivate
{
    return (_action == OStateActionActivate);
}


- (void)setActionIsRegister:(BOOL)actionIsRegister
{
    [self setAction:OStateActionRegister activate:actionIsRegister];
}


- (BOOL)actionIsRegister
{
    return (_action == OStateActionRegister);
}


- (void)setActionIsList:(BOOL)actionIsList
{
    [self setAction:OStateActionList activate:actionIsList];
}


- (BOOL)actionIsList
{
    return (_action == OStateActionList);
}


- (void)setActionIsDisplay:(BOOL)actionIsDisplay
{
    [self setAction:OStateActionDisplay activate:actionIsDisplay];
}


- (BOOL)actionIsDisplay
{
    return (_action == OStateActionDisplay);
}


- (void)setActionIsEdit:(BOOL)actionIsEdit
{
    [self setAction:OStateActionEdit activate:actionIsEdit];
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
    [self setTarget:OStateTargetMember activate:targetIsMember];
}


- (BOOL)targetIsMember
{
    return (_target == OStateTargetMember);
}


- (void)setTargetIsOrigo:(BOOL)targetIsOrigo
{
    [self setTarget:OStateTargetOrigo activate:targetIsOrigo];
}


- (BOOL)targetIsOrigo
{
    return (_target == OStateTargetOrigo);
}


- (void)setTargetIsEmail:(BOOL)targetIsEmail
{
    [self setTarget:OStateTargetEmail activate:targetIsEmail];
}


- (BOOL)targetIsEmail
{
    return (_target == OStateTargetEmail);
}


- (void)setTargetIsSetting:(BOOL)targetIsSetting
{
    [self setTarget:OStateTargetSetting activate:targetIsSetting];
}


- (BOOL)targetIsSetting
{
    return (_target == OStateTargetSetting);
}


#pragma mark - State aspect properties

- (void)setAspectIsNone:(BOOL)aspectIsNone
{
    [self setAspect:_aspect activate:NO];
}


- (BOOL)aspectIsNone
{
    return (_aspect == OStateAspectNone);
}


- (void)setAspectIsSelf:(BOOL)aspectIsSelf
{
    [self setAspect:OStateAspectSelf activate:aspectIsSelf];
}


- (BOOL)aspectIsSelf
{
    return (_aspect == OStateAspectSelf);
}


- (void)setAspectIsWard:(BOOL)aspectIsWard
{
    [self setAspect:OStateAspectWard activate:aspectIsWard];
}


- (BOOL)aspectIsWard
{
    return (_aspect == OStateAspectWard);
}


- (void)setAspectIsExternal:(BOOL)aspectIsExternal
{
    [self setAspect:OStateAspectExternal activate:aspectIsExternal];
}


- (BOOL)aspectIsExternal
{
    return (_aspect == OStateAspectExternal);
}


- (void)setAspectIsResidence:(BOOL)aspectIsResidence
{
    [self setAspect:OStateAspectResidence activate:aspectIsResidence];
}


- (BOOL)aspectIsResidence
{
    return (_aspect == OStateAspectResidence);
}


- (void)setAspectIsOrganisation:(BOOL)aspectIsOrganisation
{
    [self setAspect:OStateAspectOrganisation activate:aspectIsOrganisation];
}


- (BOOL)aspectIsOrganisation
{
    return (_aspect == OStateAspectOrganisation);
}


- (void)setAspectIsClass:(BOOL)aspectIsClass
{
    [self setAspect:OStateAspectClass activate:aspectIsClass];
}


- (BOOL)aspectIsClass
{
    return (_aspect == OStateAspectClass);
}


- (void)setAspectIsPreschool:(BOOL)aspectIsPreschool
{
    [self setAspect:OStateAspectPreschool activate:aspectIsPreschool];
}


- (BOOL)aspectIsPreschool
{
    return (_aspect == OStateAspectPreschool);
}


- (void)setAspectIsTeam:(BOOL)aspectIsTeam
{
    [self setAspect:OStateAspectTeam activate:aspectIsTeam];
}


- (BOOL)aspectIsTeam
{
    return (_aspect == OStateAspectTeam);
}

@end
