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
@property (nonatomic) NSString *createdIn;
@property (nonatomic) NSString *fatherId;
@property (nonatomic) NSString *motherId;
@property (nonatomic) NSString *passwordHash;
@property (nonatomic) NSString *settings;

@property (nonatomic, assign) BOOL useEnglish;

- (NSArray *)settingKeys;
- (NSArray *)settingListKeys;
- (NSString *)defaultSettings;

- (NSComparisonResult)compare:(id<OMember>)other;
- (NSComparisonResult)subjectiveCompare:(id<OMember>)other;

- (NSArray *)favourites;
- (NSArray *)nonFavourites;
- (NSArray *)activeDevices;

- (NSArray *)textRecipients;
- (NSArray *)callRecipients;
- (NSArray *)emailRecipients;

- (NSSet *)allMemberships;
- (NSSet *)allMembershipsIncludeHidden:(BOOL)includeHidden;
- (NSSet *)residencies;
- (NSSet *)participancies;
- (NSSet *)participanciesIncludeHidden:(BOOL)includeHidden;
- (NSSet *)listings;
- (NSSet *)associateMemberships;

- (id<OOrigo>)stash;
- (id<OOrigo>)pinnedFriendList;
- (id<OOrigo>)primaryResidence;
- (NSArray *)residences;
- (NSArray *)addresses;
- (NSArray *)origos;
- (NSArray *)hiddenOrigos;
- (NSArray *)declinedOrigos;
- (NSArray *)mirroringOrigos;

- (id<OMember>)mother;
- (id<OMember>)father;
- (id<OMember>)partner;
- (NSArray *)wards;
- (NSArray *)wardsInOrigo:(id<OOrigo>)origo;
- (NSArray *)parents;
- (NSArray *)parentCandidatesWithGender:(NSString *)gender;
- (NSArray *)parentsOrGuardians;
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
- (BOOL)isManaged;
- (BOOL)isFavourite;
- (BOOL)isMale;
- (BOOL)isJuvenile;
- (BOOL)isTeenOrOlder;
- (BOOL)isOlderThan:(NSInteger)age;
- (BOOL)isOutOfBounds;
- (BOOL)hasAddress;
- (BOOL)hasTelephone;
- (BOOL)hasParent:(id<OMember>)member;
- (BOOL)hasParentWithGender:(NSString *)gender;
- (BOOL)hasGuardian:(id<OMember>)member;
- (BOOL)guardiansAreParents;
- (BOOL)userCanEdit;

- (NSArray *)pronoun;
- (NSArray *)parentNoun;

- (NSString *)lastName;
- (NSString *)shortName;
- (NSString *)givenName;
- (NSString *)givenNameWithParentTitle;
- (NSString *)givenNameWithRolesForOrigo:(id<OOrigo>)origo;
- (NSString *)displayNameInOrigo:(id<OOrigo>)origo;
- (NSString *)guardianInfo;
- (NSString *)recipientLabel;
- (NSString *)recipientLabelForRecipientType:(NSInteger)recipientType;

@end


@interface OMember (OrigoAdditions) <OMember>

+ (void)clearCachedPeers;

@end
