//
//  OMember+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMember.h"

#import <CoreLocation/CoreLocation.h>

@interface OMember (OrigoExtensions)

- (NSComparisonResult)compare:(OMember *)other;

- (OMembership *)rootMembership;
- (OMembership *)initialResidency;
- (NSSet *)allMemberships;
- (NSSet *)fullMemberships;
- (NSSet *)residencies;
- (NSSet *)participancies;

- (NSSet *)wards;
- (NSSet *)housemates;
- (NSSet *)housemateResidences;

- (BOOL)isActive;
- (void)makeActive;

- (BOOL)isUser;
- (BOOL)isKnownByUser;
- (BOOL)isFemale;
- (BOOL)isMale;
- (BOOL)isMinor;
- (BOOL)isOfPreschoolAge;
- (BOOL)isTeenOrOlder;
- (BOOL)isMemberOfOrigoOfType:(NSString *)origoType;

- (BOOL)hasAddress;
- (BOOL)hasWard:(OMember *)candidate;
- (BOOL)hasHousemate:(OMember *)candidate;

- (UIImage *)listCellImage;

@end
