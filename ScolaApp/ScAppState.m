//
//  ScAppState.m
//  ScolaApp
//
//  Created by Anders Blehr on 28.07.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScAppState.h"

@implementation ScAppState


#pragma mark - Initialisation

- (id)init {
    self = [super init];
    
    if (self) {
        self.target = ScAppStateTargetNone;
        self.action = ScAppStateActionNone;
    }
    
    return self;
}


#pragma mark - State target setters

- (void)setTargetIsUser:(BOOL)isUser
{
    if (isUser) {
        self.target = ScAppStateTargetUser;
    } else {
        self.target = ScAppStateTargetNone;
    }
}


- (void)setTargetIsMemberships:(BOOL)isMemberships {
    if (isMemberships) {
        self.target = ScAppStateTargetMemberships;
    } else {
        self.target = ScAppStateTargetNone;
    }
}


- (void)setTargetIsMember:(BOOL)isMember {
    if (isMember) {
        self.target = ScAppStateTargetMember;
    } else {
        self.target = ScAppStateTargetNone;
    }
}


- (void)setTargetIsHousehold:(BOOL)isHousehold {
    if (isHousehold) {
        self.target = ScAppStateTargetHousehold;
    } else {
        self.target = ScAppStateTargetNone;
    }
}


- (void)setTargetIsScola:(BOOL)isScola {
    if (isScola) {
        self.target = ScAppStateTargetScola;
    } else {
        self.target = ScAppStateTargetNone;
    }
}


#pragma mark - State action setters

- (void)setActionIsLogin:(BOOL)isLogin {
    if (isLogin) {
        self.action = ScAppStateActionLogin;
    } else {
        self.action = ScAppStateActionNone;
    }
}


- (void)setActionIsConfirmSignUp:(BOOL)isConfirmSignUp {
    if (isConfirmSignUp) {
        self.action = ScAppStateActionConfirmSignUp;
    } else {
        self.action = ScAppStateActionNone;
    }
}


- (void)setActionIsRegister:(BOOL)isRegister {
    if (isRegister) {
        self.action = ScAppStateActionRegister;
    } else {
        self.action = ScAppStateActionNone;
    }
}


- (void)setActionIsDisplay:(BOOL)isDisplay {
    if (isDisplay) {
        self.action = ScAppStateActionDisplay;
    } else {
        self.action = ScAppStateActionNone;
    }
}

@end
