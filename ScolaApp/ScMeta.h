//
//  ScAppEnv.h
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ScServerConnection;

@interface ScMeta : NSObject {
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
extern NSString * const kUserDefaultsKeyLastFetchDate;

extern NSString * const kKeyEntityId;
extern NSString * const kKeyEntityClass;

@property (strong, readonly) NSString *deviceId;

@property (nonatomic, readonly) BOOL is_iPadDevice;
@property (nonatomic, readonly) BOOL is_iPodDevice;
@property (nonatomic, readonly) BOOL is_iPhoneDevice;
@property (nonatomic, readonly) BOOL isSimulatorDevice;

@property (nonatomic) BOOL isInternetConnectionWiFi;
@property (nonatomic) BOOL isInternetConnectionWWAN;

@property (weak, readonly) NSManagedObjectContext *managedObjectContext;

+ (ScMeta *)m;

+ (void)setUserDefault:(id)object forKey:(NSString *)key;
+ (id)userDefaultForKey:(NSString *)key;
+ (void)removeUserDefaultForKey:(NSString *)key;

- (NSString *)bundleVersion;
- (NSString *)displayLanguage;
- (NSString *)authToken;

- (BOOL)isInternetConnectionAvailable;

- (NSArray *)entitiesToPersistToServer;
- (NSArray *)entitiesToDeleteFromServer;
- (void)didPersistEntitiesToServer;
- (void)didDeleteEntitiesFromServer;

@end
