//
//  OMember+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

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

- (NSComparisonResult)compare:(id<OMember>)other;
- (NSComparisonResult)subjectiveCompare:(id<OMember>)other;

- (NSSet *)allMemberships;
- (NSSet *)residencies;
- (NSSet *)participancies;
- (NSSet *)listings;

- (id<OOrigo>)root;
- (id<OOrigo>)primaryResidence;
- (id<OOrigo>)defaultContactList;
- (NSArray *)residences;
- (NSArray *)addresses;
- (NSArray *)origos;
- (NSArray *)lists;

- (id<OMember>)mother;
- (id<OMember>)father;
- (id<OMember>)partner;
- (NSArray *)wards;
- (NSArray *)wardsInOrigo:(id<OOrigo>)origo;
- (NSArray *)parents;
- (NSArray *)parentCandidatesWithGender:(NSString *)gender;
- (NSArray *)guardians;
- (NSArray *)peers;
- (NSArray *)peersNotInSet:(id)set;
- (NSArray *)allHousemates;
- (NSArray *)housemates;
- (NSArray *)housemateResidences;
- (NSArray *)housematesNotInResidence:(id<OOrigo>)residence;

- (BOOL)isActive;
- (void)makeActive;

- (BOOL)isUser;
- (BOOL)isWardOfUser;
- (BOOL)isHousemateOfUser;
- (BOOL)isKnownByUser;
- (BOOL)isManagedByUser;
- (BOOL)isManaged;
- (BOOL)isMale;
- (BOOL)isListedOnly;
- (BOOL)isJuvenile;
- (BOOL)isTeenOrOlder;
- (BOOL)isOlderThan:(NSInteger)age;
- (BOOL)isOutOfBounds;
- (BOOL)hasAddress;
- (BOOL)hasParent:(id<OMember>)member;
- (BOOL)hasParentWithGender:(NSString *)gender;
- (BOOL)hasGuardian:(id<OMember>)member;
- (BOOL)guardiansAreParents;

- (NSArray *)pronoun;
- (NSArray *)parentNoun;

- (NSString *)lastName;
- (NSString *)shortName;
- (NSString *)givenName;
- (NSString *)givenNameWithParentTitle;
- (NSString *)givenNameWithRolesForOrigo:(id<OOrigo>)origo;
- (NSString *)displayNameInOrigo:(id<OOrigo>)origo;

@end


@interface OMember (OrigoAdditions) <OMember>

@end
