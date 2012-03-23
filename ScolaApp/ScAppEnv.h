//
//  ScAppEnv.h
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ScServerConnection;

@interface ScAppEnv : NSObject {
@private
    UIManagedDocument *managedDocument;
    
    NSMutableSet *entitiesToPersistToServer;
    NSMutableSet *entitiesToDeleteFromServer;
}

extern NSString * const kBundleID;

extern NSString * const kUserDefaultsKeyAuthId;
extern NSString * const kUserDefaultsKeyAuthToken;
extern NSString * const kUserDefaultsKeyAuthExpiryDate;
extern NSString * const kUserDefaultsKeyAuthInfo;
extern NSString * const kUserDefaultsKeyDeviceId;

extern NSString * const kKeyEntityId;
extern NSString * const kKeyEntityClass;

@property (strong, readonly) NSString *deviceId;
@property (strong, readonly) NSString *deviceType;
@property (strong, readonly) NSString *deviceName;

@property (nonatomic) BOOL isInternetConnectionWiFi;
@property (nonatomic) BOOL isInternetConnectionWWAN;

@property (weak, readonly) NSManagedObjectContext *managedObjectContext;

+ (ScAppEnv *)env;

- (NSString *)bundleVersion;
- (NSString *)displayLanguage;
- (NSString *)authToken;

- (BOOL)is_iPadDevice;
- (BOOL)is_iPhoneDevice;
- (BOOL)is_iPodTouchDevice;
- (BOOL)isSimulatorDevice;

- (BOOL)isInternetConnectionAvailable;

- (NSArray *)entitiesToPersistToServer;
- (NSArray *)entitiesToDeleteFromServer;
- (void)didPersistEntitiesToServer;
- (void)didDeleteEntitiesFromServer;

@end
