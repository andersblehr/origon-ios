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
@property (nonatomic) NSString *fatherId;
@property (nonatomic) NSString *motherId;

@property (nonatomic) NSString *passwordHash;
@property (nonatomic) id<OSettings> settings;

- (NSSet *)allMemberships;
- (NSSet *)residencies;

- (id<OOrigo>)root;
- (id<OOrigo>)residence;
- (NSArray *)residences;
- (NSArray *)origosIncludeResidences:(BOOL)includeResidences;

- (id<OMember>)partner;
- (NSSet *)wards;
- (NSSet *)parents;
- (NSSet *)siblings;
- (NSSet *)guardians;
- (NSSet *)peers;
- (NSSet *)peersNotInOrigo:(id<OOrigo>)origo;
- (NSSet *)housemates;
- (NSSet *)housematesNotInResidence:(id<OOrigo>)residence;
- (NSSet *)housemateResidences;

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

- (NSString *)age;
- (NSString *)appellation;
- (NSString *)givenName;
- (NSString *)givenNameWithParentTitle;
- (NSString *)givenNameWithContactRoleForOrigo:(id<OOrigo>)origo;
- (NSString *)shortAddress;
- (NSString *)shortDetails;
- (UIImage *)smallImage;

@end


@interface OMember (OrigoAdditions) <OMember>

@end
