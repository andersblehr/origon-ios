//
//  ScMeta.m
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScMeta.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"

#import "ScCachedEntity+ScCachedEntityExtensions.h"
#import "ScLogging.h"
#import "ScServerConnection.h"
#import "ScUUIDGenerator.h"

@implementation ScMeta

NSString * const kBundleID = @"com.scolaapp.ios.ScolaApp";

NSString * const kUserDefaultsKeyAuthId = @"scola.auth.id";
NSString * const kUserDefaultsKeyAuthToken = @"scola.auth.token";
NSString * const kUserDefaultsKeyAuthExpiryDate = @"scola.auth.expires";
NSString * const kUserDefaultsKeyAuthInfo = @"scola.auth.info";
NSString * const kUserDefaultsKeyDeviceId = @"scola.device.id"; // TODO: Add userId to key
NSString * const kUserDefaultsKeyLastFetchDate = @"scola.fetch.date";

NSString * const kKeyEntityId = @"entityId";
NSString * const kKeyEntityClass = @"entityClass";

@synthesize deviceId;

@synthesize is_iPadDevice;
@synthesize is_iPodDevice;
@synthesize is_iPhoneDevice;
@synthesize isSimulatorDevice;

@synthesize isInternetConnectionWiFi;
@synthesize isInternetConnectionWWAN;

@synthesize appVersion;
@synthesize displayLanguage;
@synthesize authToken;

@synthesize managedObjectContext = context;

static ScMeta *m = nil;


#pragma mark - Auxiliary methods

- (void)initialiseCoreData
{
    NSURL *applicationDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *docURL = [applicationDocumentsDirectory URLByAppendingPathComponent:@"ScolaApp"];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    managedDocument = [[UIManagedDocument alloc] initWithFileURL:docURL];
    managedDocument.persistentStoreOptions = options;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[docURL path]]) {
        [managedDocument openWithCompletionHandler:^(BOOL success){
            if (success) {
                ScLogDebug(@"Core Data initialised and ready (location: %@).", docURL);
                context = managedDocument.managedObjectContext;
            } else {
                ScLogError(@"Error initialising Core Data.");
            }
        }];
    } else {
        [managedDocument saveToURL:docURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success){
            if (success) {
                ScLogDebug(@"Core Data instantiated and ready (location: %@).", docURL);
                context = managedDocument.managedObjectContext;
            } else {
                ScLogError(@"Error instantiating Core Data.");
            }
        }];
    }
}


- (void)contextDidSave:(NSNotification *)notification
{
    NSDictionary *saveInfo = notification.userInfo;
    
    NSSet *entitiesInserted = [saveInfo objectForKey:NSInsertedObjectsKey];
    NSSet *entitiesUpdated = [saveInfo objectForKey:NSUpdatedObjectsKey];
    NSSet *entitiesDeleted = [saveInfo objectForKey:NSDeletedObjectsKey];
    
    for (ScCachedEntity *entity in entitiesInserted) {
        entity.persistenceState = ScRemotePersistenceStateDirtyNotScheduled;
    }
    
    for (ScCachedEntity *entity in entitiesUpdated) {
        entity.persistenceState = ScRemotePersistenceStateDirtyNotScheduled;
    }
    
    for (ScCachedEntity *entity in entitiesDeleted) {
        entity.persistenceState = ScRemotePersistenceStateDirtyNotScheduled;
    }
    
    [entitiesToPersistToServer unionSet:entitiesInserted];
    [entitiesToPersistToServer unionSet:entitiesUpdated];
    [entitiesToDeleteFromServer unionSet:entitiesDeleted];
}


- (void)checkReachability:(Reachability *)reachability
{
    if (reachability) {
        internetReachability = reachability;
    } else {
        internetReachability = [Reachability reachabilityForInternetConnection];
    }
    
    NetworkStatus internetStatus = [internetReachability currentReachabilityStatus];
    
    isInternetConnectionWiFi = (internetStatus == ReachableViaWiFi);
    isInternetConnectionWWAN = (internetStatus == ReachableViaWWAN);
    
    if (internetStatus == ReachableViaWiFi) {
        ScLogInfo(@"Connected to the internet via Wi-Fi.");
    } else if (internetStatus == ReachableViaWWAN) {
        ScLogInfo(@"Connected to the internet via mobile web (WWAN).");
    } else {
        ScLogInfo(@"Not connected to the internet.");
    }
}


- (void)reachabilityChanged:(NSNotification *)notification
{
    [self checkReachability:(Reachability *)[notification object]];
}


#pragma mark - Singleton instantiation & initialisation

+ (id)allocWithZone:(NSZone *)zone
{
    return [self m];
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


- (id)init
{
    self = [super init];
    
    if (self) {
        NSString *deviceModel = [UIDevice currentDevice].model;
        
        is_iPadDevice = [deviceModel hasPrefix:@"iPad"];
        is_iPodDevice = [deviceModel hasPrefix:@"iPod"];
        is_iPhoneDevice = [deviceModel hasPrefix:@"iPhone"];
        isSimulatorDevice = ([deviceModel rangeOfString:@"Simulator"].location != NSNotFound);
        
        isInternetConnectionWiFi = NO;
        isInternetConnectionWWAN = NO;
        
        deviceId = [ScMeta userDefaultForKey:kUserDefaultsKeyDeviceId];
        
        if (!deviceId) {
            deviceId = [ScUUIDGenerator generateUUID];
            [ScMeta setUserDefault:deviceId forKey:kUserDefaultsKeyDeviceId];
        }
        
        appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey];
        displayLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
        
        [self initialiseCoreData];
        
        entitiesToPersistToServer = [[NSMutableSet alloc] init];
        entitiesToDeleteFromServer = [[NSMutableSet alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    }
    
    return self;
}


+ (ScMeta *)m
{
    if (m == nil) {
        m = [[super allocWithZone:nil] init];
    }
    
    return m;
}


#pragma mark - NSUserDefaults convenience accessors

+ (void)setUserDefault:(id)object forKey:(NSString *)key
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setObject:object forKey:key];
}


+ (id)userDefaultForKey:(NSString *)key
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    return [userDefaults objectForKey:key];
}


+ (void)removeUserDefaultForKey:(NSString *)key
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults removeObjectForKey:key];
}


#pragma mark - Accessors

- (NSString *)authToken
{
    return [ScMeta userDefaultForKey:kUserDefaultsKeyAuthToken];
}


- (NSManagedObjectContext *)managedObjectContext
{
    if (!context) {
        ScLogBreakage(@"Attempt to access Core Data before it's available");
    }
    
    return context;
}


#pragma mark - Connection state

- (void)checkInternetReachability
{
    internetReachability = [Reachability reachabilityForInternetConnection];
    [self checkReachability:internetReachability];
    
    if ([internetReachability startNotifier]) {
        ScLogInfo(@"Reachability notifier is running.");
    } else {
        ScLogWarning(@"Could not start reachability notifier, checking internet connectivity at app activation only.");
    }
}


- (BOOL)isInternetConnectionAvailable
{
    return (isInternetConnectionWiFi || isInternetConnectionWWAN);
}


#pragma mark - Remote entity persistence

- (NSArray *)entitiesToPersistToServer
{
    return [entitiesToPersistToServer allObjects];
}


- (NSArray *)entitiesToDeleteFromServer
{
    return [entitiesToDeleteFromServer allObjects];
}


- (void)didPersistEntitiesToServer
{
    for (ScCachedEntity *entity in [entitiesToPersistToServer copy]) {
        if (entity.persistenceState == ScRemotePersistenceStateDirtyScheduled) {
            entity.persistenceState = ScRemotePersistenceStatePersisted;
            [entitiesToPersistToServer removeObject:entity];
        }
    }
}


- (void)didDeleteEntitiesFromServer
{
    for (ScCachedEntity *entity in [entitiesToDeleteFromServer copy]) {
        if (entity.persistenceState == ScRemotePersistenceStateDirtyScheduled) {
            entity.persistenceState = ScRemotePersistenceStateDeleted;
            [entitiesToDeleteFromServer removeObject:entity];
        }
    }
}

@end
