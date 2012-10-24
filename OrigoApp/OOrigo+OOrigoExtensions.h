//
//  OOrigo+OOrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OOrigo.h"

@class OMember, OMembership;

@interface OOrigo (OOrigoExtensions)

- (id)addMember:(OMember *)member;
- (id)addResident:(OMember *)resident;

- (BOOL)isMemberRoot;
- (BOOL)isResidence;

- (BOOL)userIsAdmin;
- (BOOL)hasAddress;
- (BOOL)hasTelephone;
- (BOOL)hasMemberWithId:(NSString *)memberId;

- (NSString *)details;
- (NSString *)singleLineAddress;
- (NSString *)multiLineAddress;
- (NSInteger)numberOfLinesInAddress;

- (NSComparisonResult)compare:(OOrigo *)other;

@end
