//
//  OMember+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMember.h"

@class OOrigo;

@interface OMember (OrigoExtensions)

- (NSString *)displayNameAndAge;
- (NSString *)displayContactDetails;

- (BOOL)isUser;
- (BOOL)isFemale;
- (BOOL)isMale;
- (BOOL)isMinor;
- (BOOL)isTeenOrOlder;
- (BOOL)isOfPreschoolAge;

- (BOOL)hasAddress;
- (BOOL)hasWard:(OMember *)ward;

- (NSSet *)wards;
- (NSSet *)housemates;
- (NSSet *)housemateResidences;

- (OMemberResidency *)initialResidency;
- (OMembership *)rootMembership;
- (NSSet *)origoMemberships;
- (BOOL)isMemberOfOrigoOfType:(NSString *)origoType;

- (NSComparisonResult)compare:(OMember *)other;

@end
