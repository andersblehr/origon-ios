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

- (NSString *)about;

- (BOOL)isMinor;
- (BOOL)hasMobilPhone;
- (BOOL)hasEmailAddress;

@end
