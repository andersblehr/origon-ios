//
//  ScState.h
//  ScolaApp
//
//  Created by Anders Blehr on 28.07.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ScStateActionNone,
    ScStateActionInit,
    ScStateActionLogin,
    ScStateActionActivate,
    ScStateActionRegister,
    ScStateActionList,
    ScStateActionDisplay,
    ScStateActionEdit,
} ScStateAction;

typedef enum {
    ScStateTargetNone,
    ScStateTargetMember,
    ScStateTargetScola,
} ScStateTarget;

typedef enum {
    ScStateAspectNone,
    ScStateAspectSelf,
    ScStateAspectDependent,
    ScStateAspectExternal,
} ScStateAspect;


@interface ScState : NSObject {
@private
    NSMutableDictionary *_savedStates;
}

@property (nonatomic) BOOL actionIsLogin;
@property (nonatomic) BOOL actionIsActivate;
@property (nonatomic) BOOL actionIsRegister;
@property (nonatomic) BOOL actionIsList;
@property (nonatomic) BOOL actionIsDisplay;
@property (nonatomic) BOOL actionIsEdit;
@property (nonatomic, readonly) BOOL actionIsInput;

@property (nonatomic) BOOL targetIsMember;
@property (nonatomic) BOOL targetIsScola;

@property (nonatomic) BOOL aspectIsSelf;
@property (nonatomic) BOOL aspectIsDependent;
@property (nonatomic) BOOL aspectIsExternal;

+ (ScState *)s;

- (void)saveCurrentStateForViewController:(NSString *)viewControllerId;
- (void)revertToSavedStateForViewController:(NSString *)viewControllerId;

- (NSString *)asString;

@end
