//
//  OState.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OStateAction) {
    OStateActionNone,
    OStateActionSetup,
    OStateActionLogin,
    OStateActionActivate,
    OStateActionRegister,
    OStateActionList,
    OStateActionDisplay,
    OStateActionEdit,
};

typedef NS_ENUM(NSInteger, OStateTarget) {
    OStateTargetNone,
    OStateTargetMember,
    OStateTargetOrigo,
    OStateTargetResidence,
    OStateTargetOrganisation,
    OStateTargetClass,
    OStateTargetPreschool,
    OStateTargetTeam,
    OStateTargetEmail,
    OStateTargetSetting,
};

typedef NS_ENUM(NSInteger, OStateAspect) {
    OStateAspectNone,
    OStateAspectSelf,
    OStateAspectWard,
    OStateAspectOrigo,
    OStateAspectExternal,
};

@class OMember, OOrigo;

@interface OState : NSObject

@property (nonatomic) OStateAction action;
@property (nonatomic) OStateTarget target;
@property (nonatomic) OStateAspect aspect;

@property (nonatomic) BOOL actionIsSetup;
@property (nonatomic) BOOL actionIsLogin;
@property (nonatomic) BOOL actionIsActivate;
@property (nonatomic) BOOL actionIsRegister;
@property (nonatomic) BOOL actionIsList;
@property (nonatomic) BOOL actionIsDisplay;
@property (nonatomic) BOOL actionIsEdit;
@property (nonatomic, readonly) BOOL actionIsInput;

@property (nonatomic) BOOL targetIsMember;
@property (nonatomic) BOOL targetIsOrigo;
@property (nonatomic) BOOL targetIsResidence;
@property (nonatomic) BOOL targetIsOrganisation;
@property (nonatomic) BOOL targetIsClass;
@property (nonatomic) BOOL targetIsPreschool;
@property (nonatomic) BOOL targetIsTeam;
@property (nonatomic) BOOL targetIsEmail;
@property (nonatomic) BOOL targetIsSetting;

@property (nonatomic) BOOL aspectIsSelf;
@property (nonatomic) BOOL aspectIsWard;
@property (nonatomic) BOOL aspectIsOrigo;
@property (nonatomic) BOOL aspectIsExternal;

+ (OState *)s;
- (void)reflect:(OState *)state;

- (void)setAspectForMember:(OMember *)member;
- (void)setTargetForOrigoType:(NSString *)origoType;

- (void)toggleEdit;

- (NSString *)asString;

@end
