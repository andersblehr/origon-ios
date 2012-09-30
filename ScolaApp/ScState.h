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
    ScStateActionActivate,
    ScStateActionRegister,
    ScStateActionDisplay,
    ScStateActionEdit,
} ScStateAction;

typedef enum {
    ScStateTargetDefault,
    ScStateTargetMember,
    ScStateTargetMemberships,
    ScStateTargetResidence,
    ScStateTargetScola,
} ScStateTarget;

typedef enum {
    ScStateAspectDefault,
    ScStateAspectSelf,
    ScStateAspectExternal,
} ScStateAspect;


@interface ScState : NSObject {
@private
    NSMutableDictionary *_savedStates;
}

@property (nonatomic) ScStateAction action;
@property (nonatomic) ScStateTarget target;
@property (nonatomic) ScStateAspect aspect;

@property (nonatomic, readonly) BOOL actionIsLogin;
@property (nonatomic, readonly) BOOL actionIsActivate;
@property (nonatomic, readonly) BOOL actionIsRegister;
@property (nonatomic, readonly) BOOL actionIsDisplay;
@property (nonatomic, readonly) BOOL actionIsEdit;
@property (nonatomic, readonly) BOOL actionIsInput;

@property (nonatomic, readonly) BOOL targetIsMember;
@property (nonatomic, readonly) BOOL targetIsMemberships;
@property (nonatomic, readonly) BOOL targetIsResidence;
@property (nonatomic, readonly) BOOL targetIsScola;

@property (nonatomic, readonly) BOOL aspectIsSelf;
@property (nonatomic, readonly) BOOL aspectIsExternal;

+ (ScState *)s;

- (void)saveCurrentStateForViewController:(NSString *)viewControllerId;
- (void)revertToSavedStateForViewController:(NSString *)viewControllerId;

- (NSString *)asString;

@end
