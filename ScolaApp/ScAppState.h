//
//  ScAppState.h
//  ScolaApp
//
//  Created by Anders Blehr on 28.07.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ScAppStateTargetNone,
    ScAppStateTargetUser,
    ScAppStateTargetMemberships,
    ScAppStateTargetMember,
    ScAppStateTargetHousehold,
    ScAppStateTargetScola,
} ScAppStateTarget;

typedef enum {
    ScAppStateActionNone,
    ScAppStateActionLogin,
    ScAppStateActionConfirmSignUp,
    ScAppStateActionRegister,
    ScAppStateActionDisplay,
} ScAppStateAction;

@interface ScAppState : NSObject

@property (nonatomic) ScAppStateTarget target;
@property (nonatomic) ScAppStateAction action;

@property (nonatomic) BOOL targetIsUser;
@property (nonatomic) BOOL targetIsMemberships;
@property (nonatomic) BOOL targetIsMember;
@property (nonatomic) BOOL targetIsHousehold;
@property (nonatomic) BOOL targetIsScola;

@property (nonatomic) BOOL actionIsLogin;
@property (nonatomic) BOOL actionIsConfirmSignUp;
@property (nonatomic) BOOL actionIsRegister;
@property (nonatomic) BOOL actionIsDisplay;

@end
