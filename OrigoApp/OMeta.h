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

extern NSUInteger const kCertainSchoolAge;
extern NSUInteger const kAgeOfMajority;

extern NSString * const kBundleId;
extern NSString * const kLanguageHungarian;

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

extern NSString * const kGenderFemale;
extern NSString * const kGenderMale;

extern NSString * const kAuthViewControllerId;
extern NSString * const kTabBarControllerId;
extern NSString * const kOrigoListViewControllerId;
extern NSString * const kOrigoViewControllerId;
extern NSString * const kMemberListViewControllerId;
extern NSString * const kMemberViewControllerId;

extern NSString * const kKeyPathAuthInfo;
extern NSString * const kKeyPathDirtyEntities;

extern NSString * const kKeyPathEntityClass;
extern NSString * const kKeyPathEntityId;
extern NSString * const kKeyPathOrigoId;


@class OMember, OReplicatedEntity;

@interface OMeta : NSObject <OServerConnectionDelegate> {
@private
    Reachability *_internetReachability;
    NSDate *_authTokenExpiryDate;
    
    NSMutableSet *_dirtyEntities;
    NSMutableDictionary *_stagedServerEntities;
    NSMutableDictionary *_stagedServerEntityRefs;
}

@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic, readonly) OMember *user;

@property (strong, nonatomic, readonly) NSString *deviceId;
@property (strong, nonatomic, readonly) NSString *authToken;
@property (strong, nonatomic, readonly) NSString *appVersion;
@property (strong, nonatomic, readonly) NSString *displayLanguage;
@property (strong, nonatomic) NSString *lastReplicationDate;

@property (nonatomic, readonly) BOOL is_iPadDevice;
@property (nonatomic, readonly) BOOL is_iPodDevice;
@property (nonatomic, readonly) BOOL is_iPhoneDevice;
@property (nonatomic, readonly) BOOL isSimulatorDevice;

@property (nonatomic, readonly) BOOL internetConnectionIsWiFi;
@property (nonatomic, readonly) BOOL internetConnectionIsWWAN;

@property (weak, nonatomic, readonly) NSManagedObjectContext *context;

+ (OMeta *)m;

- (BOOL)internetConnectionIsAvailable;

- (void)userDidSignIn;
- (void)userDidSignOut;
- (BOOL)userIsSignedIn;
- (BOOL)registrationIsComplete;

- (NSSet *)dirtyEntities;
- (void)stageServerEntity:(OReplicatedEntity *)entity;
- (void)stageServerEntityRefs:(NSDictionary *)entityRefs forEntity:(OReplicatedEntity *)entity;
- (OReplicatedEntity *)stagedServerEntityWithId:(NSString *)entityId;
- (NSDictionary *)stagedServerEntityRefsForEntity:(OReplicatedEntity *)entity;

@end
