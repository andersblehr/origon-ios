//
//  OState.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    OStateActionNone,
    OStateActionLogin,
    OStateActionActivate,
    OStateActionRegister,
    OStateActionList,
    OStateActionDisplay,
    OStateActionEdit,
} OStateAction;

typedef enum {
    OStateTargetNone,
    OStateTargetMember,
    OStateTargetOrigo,
    OStateTargetSetting,
} OStateTarget;

typedef enum {
    OStateAspectNone,
    OStateAspectSelf,
    OStateAspectWard,
    OStateAspectExternal,
    OStateAspectResidence,
    OStateAspectOrganisation,
    OStateAspectClass,
    OStateAspectPreschool,
    OStateAspectTeam,
} OStateAspect;

@class OMember, OOrigo;

@interface OState : NSObject

@property (nonatomic) OStateAction action;
@property (nonatomic) OStateTarget target;
@property (nonatomic) OStateAspect aspect;

@property (nonatomic) BOOL actionIsLogin;
@property (nonatomic) BOOL actionIsActivate;
@property (nonatomic) BOOL actionIsRegister;
@property (nonatomic) BOOL actionIsList;
@property (nonatomic) BOOL actionIsDisplay;
@property (nonatomic) BOOL actionIsEdit;
@property (nonatomic, readonly) BOOL actionIsInput;

@property (nonatomic) BOOL targetIsMember;
@property (nonatomic) BOOL targetIsOrigo;
@property (nonatomic) BOOL targetIsSetting;

@property (nonatomic) BOOL aspectIsNone;
@property (nonatomic) BOOL aspectIsSelf;
@property (nonatomic) BOOL aspectIsWard;
@property (nonatomic) BOOL aspectIsExternal;
@property (nonatomic) BOOL aspectIsResidence;
@property (nonatomic) BOOL aspectIsOrganisation;
@property (nonatomic) BOOL aspectIsClass;
@property (nonatomic) BOOL aspectIsPreschool;
@property (nonatomic) BOOL aspectIsTeam;

+ (OState *)s;

- (NSString *)asString;

- (void)setAspectForMember:(OMember *)member;
- (void)setAspectForOrigo:(OOrigo *)origo;
- (void)setAspectForOrigoType:(NSString *)origoType;

@end
