//
//  OMembership+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMembership.h"

extern NSString * const kMembershipTypeMemberRoot;
extern NSString * const kMembershipTypeResidency;
extern NSString * const kMembershipTypeStandard;
extern NSString * const kMembershipTypeAssociate;

@interface OMembership (OrigoExtensions)

- (BOOL)hasContactRole;
- (BOOL)isStandard;
- (BOOL)isResidency;
- (BOOL)isAssociate;

- (void)makeStandard;
- (void)makeResidency;
- (void)makeAssociate;
- (void)alignWithOrigo;

@end
