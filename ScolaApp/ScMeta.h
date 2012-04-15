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
    Reachability *internetReachability;
    
    NSDate *authTokenExpiryDate;
}

extern NSString * const kBundleID;
extern NSString * const kKeyEntityId;
extern NSString * const kKeyEntityClass;

@property (strong, nonatomic) NSString *userId;
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

+ (ScMeta *)m;

+ (void)setUserDefault:(id)object forKey:(NSString *)key;
+ (id)userDefaultForKey:(NSString *)key;
+ (void)removeUserDefaultForKey:(NSString *)key;

- (void)checkInternetReachability;
- (BOOL)isInternetConnectionAvailable;

- (BOOL)isAuthTokenValid;
- (void)invalidateAuthToken;

@end
