//
//  ScMeta.h
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ScServerConnectionDelegate.h"

extern NSString * const kBundleId;
extern NSString * const kKeyEntityId;
extern NSString * const kKeyEntityClass;
extern NSString * const kKeyScolaId;

extern NSString * const kGenderFemale;
extern NSString * const kGenderMale;
extern NSString * const kGenderNoneGiven;

@class Reachability, ScCachedEntity, ScServerConnection;

@interface ScMeta : NSObject <ScServerConnectionDelegate> {
@private
    Reachability *internetReachability;
    
    NSDate *authTokenExpiryDate;
    
    NSMutableSet *scheduledEntities;
    NSMutableDictionary *importedEntities;
    NSMutableDictionary *importedEntityRefs;
}

@property (nonatomic) BOOL isUserLoggedIn;

@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSString *homeScolaId;
@property (strong, nonatomic) NSString *lastFetchDate;

@property (strong, readonly) NSString *deviceId;
@property (strong, readonly) NSString *authToken;
@property (strong, readonly) NSString *appVersion;
@property (strong, readonly) NSString *displayLanguage;

@property (nonatomic, readonly) BOOL is_iPadDevice;
@property (nonatomic, readonly) BOOL is_iPodDevice;
@property (nonatomic, readonly) BOOL is_iPhoneDevice;
@property (nonatomic, readonly) BOOL isSimulatorDevice;

@property (nonatomic, readonly) BOOL isInternetConnectionWiFi;
@property (nonatomic, readonly) BOOL isInternetConnectionWWAN;

@property (weak, readonly) NSManagedObjectContext *managedObjectContext;
@property (strong, readonly) NSSet *entitiesScheduledForPersistence;

+ (ScMeta *)m;

+ (void)setUserDefault:(id)object forKey:(NSString *)key;
+ (id)userDefaultForKey:(NSString *)key;
+ (void)removeUserDefaultForKey:(NSString *)key;

- (void)checkInternetReachability;
- (BOOL)isInternetConnectionAvailable;

- (void)addImportedEntity:(ScCachedEntity *)entity;
- (void)addImportedEntityRefs:(NSDictionary *)entityRefs forEntity:(ScCachedEntity *)entity;
- (ScCachedEntity *)importedEntityWithId:(NSString *)entityId;
- (NSDictionary *)importedEntityRefsForEntity:(ScCachedEntity *)entity;

@end
