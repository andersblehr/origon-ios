//
//  ScMeta.h
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Reachability.h"

@class ScServerConnection;

@interface ScMeta : NSObject {
@private
    UIManagedDocument *managedDocument;
    
    NSMutableSet *entitiesToPersistToServer;
    NSMutableSet *entitiesToDeleteFromServer;
    
    Reachability *internetReachability;
}

extern NSString * const kBundleID;

extern NSString * const kUserDefaultsKeyAuthId;
extern NSString * const kUserDefaultsKeyAuthToken;
extern NSString * const kUserDefaultsKeyAuthExpiryDate;
extern NSString * const kUserDefaultsKeyAuthInfo;
extern NSString * const kUserDefaultsKeyDeviceId;
extern NSString * const kUserDefaultsKeyLastFetchDate;

extern NSString * const kKeyEntityId;
extern NSString * const kKeyEntityClass;

@property (nonatomic, readonly) BOOL is_iPadDevice;
@property (nonatomic, readonly) BOOL is_iPodDevice;
@property (nonatomic, readonly) BOOL is_iPhoneDevice;
@property (nonatomic, readonly) BOOL isSimulatorDevice;

@property (nonatomic, readonly) BOOL isInternetConnectionWiFi;
@property (nonatomic, readonly) BOOL isInternetConnectionWWAN;

@property (strong, readonly) NSString *deviceId;
@property (strong, readonly) NSString *appVersion;
@property (strong, readonly) NSString *displayLanguage;
@property (strong, readonly) NSString *authToken;

@property (weak, readonly) NSManagedObjectContext *managedObjectContext;

+ (ScMeta *)m;

+ (void)setUserDefault:(id)object forKey:(NSString *)key;
+ (id)userDefaultForKey:(NSString *)key;
+ (void)removeUserDefaultForKey:(NSString *)key;

- (void)checkInternetReachability;
- (BOOL)isInternetConnectionAvailable;

- (NSArray *)entitiesToPersistToServer;
- (NSArray *)entitiesToDeleteFromServer;
- (void)didPersistEntitiesToServer;
- (void)didDeleteEntitiesFromServer;

@end
