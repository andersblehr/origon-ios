//
//  OMeta.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern NSInteger const kAgeThresholdToddler;
extern NSInteger const kAgeThresholdInSchool;
extern NSInteger const kAgeThresholdTeen;
extern NSInteger const kAgeOfConsent;
extern NSInteger const kAgeOfMajority;

extern NSString * const kProtocolHTTP;
extern NSString * const kProtocolHTTPS;
extern NSString * const kProtocolTel;

extern NSString * const kIconFileOrigo;
extern NSString * const kIconFileHousehold;
extern NSString * const kIconFileMan;
extern NSString * const kIconFileWoman;
extern NSString * const kIconFileBoy;
extern NSString * const kIconFileGirl;
extern NSString * const kIconFileInfant;
extern NSString * const kIconFileSettings;
extern NSString * const kIconFilePlus;
extern NSString * const kIconFileAction;
extern NSString * const kIconFileLookup;
extern NSString * const kIconFilePlacePhoneCall;
extern NSString * const kIconFilePlacePhoneCall_iOS6x;
extern NSString * const kIconFileSendText;
extern NSString * const kIconFileSendText_iOS6x;
extern NSString * const kIconFileSendEmail;
extern NSString * const kIconFileSendEmail_iOS6x;
extern NSString * const kIconFileLocationArrow;

extern NSString * const kGenderMale;
extern NSString * const kGenderFemale;

@interface OMeta : NSObject {
@private
    Reachability *_internetReachability;
    
    OMember *_user;
    OLocator *_locator;
    OReplicator *_replicator;
    OSwitchboard *_switchboard;
    OPhoneNumberFormatter *_phoneNumberFormatter;
    
    NSNumber *_isSignedIn;
    NSString *_authToken;
    NSDate *_authTokenExpiryDate;
}

@property (nonatomic, readonly) BOOL internetConnectionIsWiFi;
@property (nonatomic, readonly) BOOL internetConnectionIsWWAN;
@property (nonatomic, readonly) BOOL userDidJustSignUp;

@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSString *userEmail;
@property (strong, nonatomic) NSString *deviceId;
@property (strong, nonatomic) NSString *lastReplicationDate;

@property (strong, nonatomic, readonly) NSString *appName;
@property (strong, nonatomic, readonly) NSString *appVersion;
@property (strong, nonatomic, readonly) NSString *authToken;
@property (strong, nonatomic, readonly) NSString *language;

@property (strong, nonatomic, readonly) OMember *user;
@property (strong, nonatomic, readonly) OLocator *locator;
@property (strong, nonatomic, readonly) OSettings *settings;
@property (strong, nonatomic, readonly) OReplicator *replicator;
@property (strong, nonatomic, readonly) OSwitchboard *switchboard;
@property (strong, nonatomic, readonly) OPhoneNumberFormatter *phoneNumberFormatter;

@property (weak, nonatomic, readonly) NSManagedObjectContext *context;

+ (OMeta *)m;

- (void)userDidSignUp;
- (void)userDidSignIn;
- (void)userDidSignOut;

- (BOOL)userIsSignedIn;
- (BOOL)userIsRegistered;
- (BOOL)userIsAllSet;

- (BOOL)internetConnectionIsAvailable;
- (BOOL)shouldUseEasternNameOrder;
+ (BOOL)deviceIsSimulator;
+ (BOOL)systemIs_iOS6x;
+ (BOOL)screenIsRetina;

+ (NSArray *)supportedLanguages;

@end
