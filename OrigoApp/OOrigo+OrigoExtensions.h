//
//  OOrigo+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OOrigo.h"

@class OMember, OMembership;

@interface OOrigo (OrigoExtensions)

- (id)addNewMember;
- (id)addMember:(OMember *)member;
- (id)addResident:(OMember *)resident;

- (BOOL)isMemberRoot;
- (BOOL)isResidence;
- (BOOL)hasAddress;
- (BOOL)hasTelephone;

- (BOOL)hasAdmin;
- (BOOL)userIsMember;
- (BOOL)userIsAdmin;
- (BOOL)hasMemberWithEmail:(NSString *)email;
- (OMembership *)userMembership;

- (NSComparisonResult)compare:(OOrigo *)other;

@end
