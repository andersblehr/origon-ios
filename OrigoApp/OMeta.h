//
//  OMeta.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Reachability.h"

#import "OServerConnectionDelegate.h"

extern NSString * const kGenderFemale;
extern NSString * const kGenderMale;

extern NSUInteger const kCertainSchoolAge;
extern NSUInteger const kAgeOfMajority;

extern NSString * const kBundleId;
extern NSString * const kLanguageHungarian;

extern NSString * const kAuthViewControllerId;
extern NSString * const kTabBarControllerId;
extern NSString * const kOrigoListViewControllerId;
extern NSString * const kOrigoViewControllerId;
extern NSString * const kMemberListViewControllerId;
extern NSString * const kMemberViewControllerId;

extern NSString * const kIconFileOrigo;
extern NSString * const kIconFileHousehold;
extern NSString * const kIconFileMan;
extern NSString * const kIconFileWoman;
extern NSString * const kIconFileBoy;
extern NSString * const kIconFileGirl;
extern NSString * const kIconFileInfant;

extern NSString * const kOrigoTypeMemberRoot;
extern NSString * const kOrigoTypeResidence;
extern NSString * const kOrigoTypeOrganisation;
extern NSString * const kOrigoTypeSchoolClass;
extern NSString * const kOrigoTypePreschoolClass;
extern NSString * const kOrigoTypeSportsTeam;
extern NSString * const kOrigoTypeDefault;

extern NSString * const kKeyPathAuthInfo;
extern NSString * const kKeyPathDirtyEntities;
extern NSString * const kKeyPathEntityClass;
extern NSString * const kKeyPathEntityId;
extern NSString * const kKeyPathOrigo;
extern NSString * const kKeyPathOrigoId;
extern NSString * const kKeyPathSignIn;
extern NSString * const kKeyPathAuthEmail;
extern NSString * const kKeyPathPassword;
extern NSString * const kKeyPathActivation;
extern NSString * const kKeyPathActivationCode;
extern NSString * const kKeyPathRepeatPassword;
extern NSString * const kKeyPathPasswordHash;
extern NSString * const kKeyPathIsListed;
extern NSString * const kKeyPathName;
extern NSString * const kKeyPathMobilePhone;
extern NSString * const kKeyPathEmail;
extern NSString * const kKeyPathDateOfBirth;
extern NSString * const kKeyPathAddress;
extern NSString * const kKeyPathTelephone;

extern NSString * const kKeyPathStringDate;

@class OTableViewCell;
@class OMember, OReplicatedEntity;

@interface OMeta : NSObject <OServerConnectionDelegate> {
@private
    Reachability *_internetReachability;
    NSDate *_authTokenExpiryDate;
    
    NSMutableSet *_dirtyEntities;
    NSMutableDictionary *_stagedEntities;
    NSMutableDictionary *_stagedRelationshipRefs;
}

@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSString *userEmail;
@property (strong, nonatomic, readonly) OMember *user;

@property (strong, nonatomic, readonly) NSString *deviceId;
@property (strong, nonatomic, readonly) NSString *authToken;
@property (strong, nonatomic, readonly) NSString *appVersion;
@property (strong, nonatomic, readonly) NSString *displayLanguage;
@property (strong, nonatomic) NSString *lastReplicationDate;

@property (nonatomic, readonly) BOOL deviceIs_iPad;
@property (nonatomic, readonly) BOOL deviceIs_iPod;
@property (nonatomic, readonly) BOOL deviceIs_iPhone;
@property (nonatomic, readonly) BOOL deviceIsSimulator;

@property (nonatomic, readonly) BOOL internetConnectionIsWiFi;
@property (nonatomic, readonly) BOOL internetConnectionIsWWAN;

@property (strong, nonatomic, readonly) UIDatePicker *sharedDatePicker;
@property (weak, nonatomic) OTableViewCell *participatingCell;

@property (weak, nonatomic, readonly) NSManagedObjectContext *context;

+ (OMeta *)m;

- (BOOL)internetConnectionIsAvailable;

- (void)userDidSignIn;
- (void)userDidSignOut;
- (BOOL)userIsAllSet;
- (BOOL)userIsSignedIn;
- (BOOL)userIsRegistered;

- (NSSet *)dirtyEntities;
- (void)stageEntity:(OReplicatedEntity *)entity;
- (void)stageRelationshipRefs:(NSDictionary *)relationshipRefs forEntity:(OReplicatedEntity *)entity;
- (OReplicatedEntity *)stagedEntityWithId:(NSString *)entityId;
- (NSDictionary *)stagedRelationshipRefsForEntity:(OReplicatedEntity *)entity;

@end
