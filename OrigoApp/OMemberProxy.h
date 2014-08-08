//
//  OMemberProxy.h
//  OrigoApp
//
//  Created by Anders Blehr on 11.04.14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "OEntityProxy.h"

@protocol OMember <OEntity>

@optional
@property (nonatomic) NSString *name;
@property (nonatomic) NSDate *dateOfBirth;
@property (nonatomic) NSString *mobilePhone;
@property (nonatomic) NSString *email;
@property (nonatomic) NSString *gender;
@property (nonatomic) NSNumber *isMinor;
@property (nonatomic) NSData *photo;
@property (nonatomic) NSDate *activeSince;
@property (nonatomic) NSString *fatherId;
@property (nonatomic) NSString *motherId;

@property (nonatomic) NSString *passwordHash;
@property (nonatomic) id<OSettings> settings;

- (NSSet *)allMemberships;
- (NSSet *)residencies;
- (NSSet *)participancies;

- (id<OOrigo>)root;
- (id<OOrigo>)residence;
- (NSArray *)residences;
- (NSArray *)origosIncludeResidences:(BOOL)includeResidences;
- (NSArray *)addresses;

- (id<OMember>)partner;
- (NSArray *)wards;
- (NSArray *)parents;
- (NSArray *)guardians;
- (NSArray *)peers;
- (NSArray *)peersNotInOrigo:(id<OOrigo>)origo;
- (NSArray *)housemates;
- (NSArray *)housemateResidences;
- (NSArray *)housematesNotInResidence:(id<OOrigo>)residence;

- (BOOL)isActive;
- (void)makeActive;

- (BOOL)isUser;
- (BOOL)isWardOfUser;
- (BOOL)isHousemateOfUser;
- (BOOL)isManagedByUser;
- (BOOL)isKnownByUser;
- (BOOL)isMale;
- (BOOL)isJuvenile;
- (BOOL)isTeenOrOlder;
- (BOOL)isOlderThan:(NSInteger)age;
- (BOOL)hasAddress;
- (BOOL)hasParent:(id<OMember>)member;
- (BOOL)hasParentWithGender:(NSString *)gender;
- (BOOL)guardiansAreParents;

- (NSArray *)pronoun;
- (NSArray *)parentNoun;

- (NSString *)appellation;
- (NSString *)givenName;
- (NSString *)givenNameWithParentTitle;
- (NSString *)givenNameWithContactRolesForOrigo:(id<OOrigo>)origo;
- (NSString *)publicName;

@end


@interface OMemberProxy : OEntityProxy<OMember>

@end
