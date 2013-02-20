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

- (id)addMember:(OMember *)member;
- (id)addResident:(OMember *)resident;

- (BOOL)isOfType:(NSString *)origoType;
- (BOOL)hasAdmin;
- (BOOL)hasMember:(OMember *)member;
- (BOOL)hasAssociateMember:(OMember *)member;

- (BOOL)userCanEdit;
- (BOOL)userIsAdmin;
- (BOOL)userIsMember;

- (NSComparisonResult)compare:(OOrigo *)other;

@end
