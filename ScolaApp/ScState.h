//
//  ScState.h
//  ScolaApp
//
//  Created by Anders Blehr on 28.07.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ScStateActionDefault,
    ScStateActionStartup,
    ScStateActionLogin,
    ScStateActionConfirm,
    ScStateActionRegister,
    ScStateActionDisplay,
    ScStateActionEdit,
} ScStateAction;

typedef enum {
    ScStateTargetDefault,
    ScStateTargetUser,
    ScStateTargetHousehold,
    ScStateTargetMemberships,
    ScStateTargetMember,
    ScStateTargetScola,
} ScStateTarget;

typedef enum {
    ScStateAspectDefault,
    ScStateAspectHome,
    ScStateAspectHousehold,
    ScStateAspectScola,
} ScStateAspect;


@interface ScState : NSObject

@property (nonatomic) ScStateAction action;
@property (nonatomic) ScStateTarget target;
@property (nonatomic) ScStateAspect aspect;

@property (nonatomic, readonly) BOOL actionIsStartup;
@property (nonatomic, readonly) BOOL actionIsLogin;
@property (nonatomic, readonly) BOOL actionIsConfirm;
@property (nonatomic, readonly) BOOL actionIsRegister;
@property (nonatomic, readonly) BOOL actionIsDisplay;
@property (nonatomic, readonly) BOOL actionIsEdit;

@property (nonatomic, readonly) BOOL targetIsUser;
@property (nonatomic, readonly) BOOL targetIsHousehold;
@property (nonatomic, readonly) BOOL targetIsMemberships;
@property (nonatomic, readonly) BOOL targetIsMember;
@property (nonatomic, readonly) BOOL targetIsScola;

@property (nonatomic, readonly) BOOL aspectIsHome;
@property (nonatomic, readonly) BOOL aspectIsHousehold;
@property (nonatomic, readonly) BOOL aspectIsScola;

- (ScState *)copy;
- (void)setToState:(ScState *)state;

- (NSString *)toString;

@end
