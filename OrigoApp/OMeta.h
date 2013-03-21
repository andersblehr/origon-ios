//
//  OMeta.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Reachability.h"

extern NSString * const kGenderFemale;
extern NSString * const kGenderMale;

extern NSUInteger const kAgeThresholdToddler;
extern NSUInteger const kAgeThresholdInSchool;
extern NSUInteger const kAgeThresholdTeen;
extern NSUInteger const kAgeThresholdMajority;

extern NSString * const kBundleId;
extern NSString * const kLanguageHungarian;

extern NSString * const kAuthViewControllerId;
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

extern NSString * const kPrefixDateProperty;
extern NSString * const kPrefixOrigoType;

extern NSString * const kInputKeyActivate;
extern NSString * const kInputKeyActivationCode;
extern NSString * const kInputKeyAuthEmail;
extern NSString * const kInputKeyPassword;
extern NSString * const kInputKeyRepeatPassword;
extern NSString * const kInputKeySignIn;

extern NSString * const kJSONKeyEntityClass;
extern NSString * const kJSONKeyIsListed;
extern NSString * const kJSONKeyPasswordHash;

extern NSString * const kPropertyKeyAddress;
extern NSString * const kPropertyKeyCountry;
extern NSString * const kPropertyKeyDateOfBirth;
extern NSString * const kPropertyKeyEmail;
extern NSString * const kPropertyKeyEntityId;
extern NSString * const kPropertyKeyHashCode;
extern NSString * const kPropertyKeyIsAwaitingDeletion;
extern NSString * const kPropertyKeyIsExpired;
extern NSString * const kPropertyKeyMobilePhone;
extern NSString * const kPropertyKeyName;
extern NSString * const kPropertyKeyOrigoId;
extern NSString * const kPropertyKeyTelephone;

extern NSString * const kRelationshipKeyMember;
extern NSString * const kRelationshipKeyOrigo;

extern NSString * const kDefaultsKeyAuthInfo;
extern NSString * const kDefaultsKeyDirtyEntities;
extern NSString * const kDefaultsKeyRegistrationAborted;
extern NSString * const kDefaultsKeyStringDate;

@class OEntityReplicator;
@class OMember, OReplicatedEntity;

@interface OMeta : NSObject {
@private
    Reachability *_internetReachability;
    NSDate *_authTokenExpiryDate;
}

@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSString *userEmail;
@property (strong, nonatomic, readonly) OMember *user;

@property (nonatomic, readonly) BOOL userIsAllSet;
@property (nonatomic, readonly) BOOL userIsSignedIn;
@property (nonatomic, readonly) BOOL userIsRegistered;

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

@property (weak, nonatomic, readonly) NSManagedObjectContext *context;
@property (strong, nonatomic, readonly) OEntityReplicator *replicator;
@property (strong, nonatomic, readonly) UIDatePicker *sharedDatePicker;

+ (OMeta *)m;

- (BOOL)internetConnectionIsAvailable;

- (void)userDidSignIn;
- (void)userDidSignOut;

- (void)setGlobalDefault:(id)globalDefault forKey:(NSString *)key;
- (void)setUserDefault:(id)userDefault forKey:(NSString *)key;
- (id)globalDefaultForKey:(NSString *)key;
- (id)userDefaultForKey:(NSString *)key;

@end
