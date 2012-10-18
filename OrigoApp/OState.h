//
//  OState.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OState : NSObject {
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
@property (nonatomic) BOOL targetIsOrigo;

@property (nonatomic) BOOL aspectIsSelf;
@property (nonatomic) BOOL aspectIsDependent;
@property (nonatomic) BOOL aspectIsExternal;

+ (OState *)s;

- (void)saveCurrentStateForViewController:(NSString *)viewControllerId;
- (void)revertToSavedStateForViewController:(NSString *)viewControllerId;

- (NSString *)asString;

@end
