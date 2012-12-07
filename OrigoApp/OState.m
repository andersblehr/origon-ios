//
//  OState.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OState.h"

#import "OMeta.h"

#import "OMember.h"
#import "OOrigo.h"

#import "OMember+OMemberExtensions.h"

static OState *s = nil;


@implementation OState

#pragma mark - Auxiliary methods

- (void)setAction:(OStateAction)action activate:(BOOL)activate
{
    _action = activate ? action : _action;
}


- (void)setTarget:(OStateTarget)target activate:(BOOL)activate
{
    _target = activate ? target : _target;
}


- (void)setAspect:(OStateAspect)aspect activate:(BOOL)activate
{
    _aspect = activate ? aspect : _aspect;
}


#pragma mark - Singleton instantiation & initialisation

+ (id)allocWithZone:(NSZone *)zone
{
    return [self s];
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


- (id)init {
    self = [super init];
    
    if (self) {
        _action = OStateActionLogin;
        _target = OStateTargetMember;
        _aspect = OStateAspectSelf;
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
    
    if (self.actionIsLogin) {
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


#pragma mark - Entity to aspect mappings

- (void)setAspectForMember:(OMember *)member
{
    OStateAspect aspect = OStateAspectExternal;
    
    if (member) {
        if ([member isUser]) {
            aspect = OStateAspectSelf;
        } else if ([[[OMeta m].user wards] containsObject:member]) {
            aspect = OStateAspectWard;
        }
    } else {
        aspect = OStateAspectSelf;
    }
    
    _aspect = aspect;
}


- (void)setAspectForOrigo:(OOrigo *)origo
{
    [self setAspectForOrigoType:origo.type];
}


- (void)setAspectForOrigoType:(NSString *)origoType
{
    OStateAspect aspect = OStateAspectNone;
    
    if ([origoType isEqualToString:kOrigoTypeResidence]) {
        aspect = OStateAspectResidence;
    } else if ([origoType isEqualToString:kOrigoTypeOrganisation]) {
        aspect = OStateAspectOrganisation;
    } else if ([origoType isEqualToString:kOrigoTypeSchoolClass]) {
        aspect = OStateAspectClass;
    } else if ([origoType isEqualToString:kOrigoTypePreschoolClass]) {
        aspect = OStateAspectPreschool;
    } else if ([origoType isEqualToString:kOrigoTypeSportsTeam]) {
        aspect = OStateAspectTeam;
    }
    
    _aspect = aspect;
}


#pragma mark - Convenience property accessors

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
