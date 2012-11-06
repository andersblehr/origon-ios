//
//  OMember+OMemberExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMember.h"

@class OOrigo;

@interface OMember (OMemberExtensions)

- (void)setDidRegister_:(BOOL)didRegister_;
- (BOOL)didRegister_;
- (NSString *)name_;

- (NSString *)details;
- (UIImage *)image;

- (BOOL)isUser;
- (BOOL)isFemale;
- (BOOL)isMale;
- (BOOL)isMinor;
- (BOOL)isTeenOrOlder;
- (BOOL)isOfPreschoolAge;

- (BOOL)hasPhone;
- (BOOL)hasMobilePhone;
- (BOOL)hasAddress;
- (BOOL)hasEmail;
- (BOOL)hasWard:(OMember *)ward;

- (NSSet *)housemates;
- (NSSet *)wards;

- (OMembership *)rootMembership;
- (NSSet *)origoMemberships;

- (BOOL)isMemberOfOrigoOfType:(NSString *)origoType;

@end
