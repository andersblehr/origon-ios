//
//  ScMember+ScMemberExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 16.05.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMember.h"

@interface ScMember (ScMemberExtensions)

- (BOOL)hasValidBirthDate;
- (BOOL)hasMobilPhone;
- (BOOL)isMinor;

//- (NSComparisonResult)compare:(ScMember *)other;

@end
