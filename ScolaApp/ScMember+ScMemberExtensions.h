//
//  ScMember+ScMemberExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 16.05.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMember.h"

@class ScScola;

@interface ScMember (ScMemberExtensions)

- (void)setDidRegister_:(BOOL)didRegister_;
- (BOOL)didRegister_;

- (ScScola *)memberRoot;

- (NSString *)about;
- (NSString *)details;

- (BOOL)isMale;
- (BOOL)isMinor;
- (BOOL)isUser;

- (BOOL)hasPhone;
- (BOOL)hasMobilePhone;
- (BOOL)hasAddress;
- (BOOL)hasEmailAddress;

@end
