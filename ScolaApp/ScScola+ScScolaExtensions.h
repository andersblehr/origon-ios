//
//  ScScola+ScScolaExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 18.04.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScScola.h"

@class ScMember, ScMembership;

@interface ScScola (ScScolaExtensions)

- (id)addMember:(ScMember *)member;
- (id)addResident:(ScMember *)resident;

- (BOOL)isMemberRoot;
- (BOOL)isResidence;

- (BOOL)userIsAdmin;
- (BOOL)hasMemberWithId:(NSString *)memberId;
- (BOOL)hasAddress;
- (BOOL)hasTelephone;

- (NSString *)singleLineAddress;
- (NSString *)multiLineAddress;
- (NSInteger)numberOfLinesInAddress;

- (NSComparisonResult)compare:(ScScola *)other;

@end
