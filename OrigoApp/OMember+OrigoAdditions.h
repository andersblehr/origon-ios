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

- (NSSet *)residencies;
- (NSSet *)participancies;
- (NSSet *)allMemberships;

- (id<OOrigo>)root;
- (id<OOrigo>)residence;
- (NSArray *)residences;
- (NSArray *)addresses;
- (NSArray *)origos;
//- (NSString *)association;

- (id<OMember>)partner;
- (NSArray *)wards;
- (NSArray *)parents;
- (NSArray *)guardians;
- (NSArray *)peers;
- (NSArray *)peersNotInSet:(id)set;
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
- (BOOL)isJuvenile;
- (BOOL)isTeenOrOlder;
- (BOOL)isOlderThan:(NSInteger)age;
- (BOOL)hasAddress;
- (BOOL)hasParent:(id<OMember>)member;
- (BOOL)hasParentWithGender:(NSString *)gender;
- (BOOL)guardiansAreParents;

- (NSArray *)pronoun;
- (NSArray *)parentNoun;

- (NSString *)givenName;
- (NSString *)givenNameWithParentTitle;
- (NSString *)givenNameWithRolesForOrigo:(id<OOrigo>)origo;
- (NSString *)publicName;
- (NSString *)appellationUseGivenName:(BOOL)useGivenName;

@end


@interface OMember (OrigoAdditions) <OMember>

@end
