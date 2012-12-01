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

extern NSString * const kGenderFemale;
extern NSString * const kGenderMale;

extern NSUInteger const kCertainSchoolAge;
extern NSUInteger const kAgeOfMajority;

@class OTextView;
@class OMember, OReplicatedEntity;

@interface OMeta : NSObject <OServerConnectionDelegate> {
@private
    Reachability *_internetReachability;
    NSDate *_authTokenExpiryDate;
    
    NSMutableDictionary *_contextObservers;
    
    NSMutableSet *_dirtyEntities;
    NSMutableDictionary *_stagedServerEntities;
    NSMutableDictionary *_stagedServerEntityRefs;
}

@property (strong, nonatomic) NSString *userEmail;
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

@property (weak, nonatomic) OTextView *participatingTextView;
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
