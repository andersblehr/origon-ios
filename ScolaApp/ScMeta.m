//
//  ScAppEnv.m
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
NSString * const kUserDefaultsKeyDeviceId = @"scola.device.id";
NSString * const kUserDefaultsKeyLastFetchDate = @"scola.fetch.date";

NSString * const kKeyEntityId = @"entityId";
NSString * const kKeyEntityClass = @"entityClass";

@synthesize deviceId;
@synthesize deviceType;
@synthesize deviceName;

@synthesize isInternetConnectionWiFi;
@synthesize isInternetConnectionWWAN;

@synthesize managedObjectContext;

static ScMeta *env = nil;


#pragma mark - Auxiliary methods

- (void)initialiseManagedDocument
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
                ScLogDebug(@"Core Data initialised and ready.");
                managedObjectContext = managedDocument.managedObjectContext;
            } else {
                ScLogError(@"Error initialising Core Data.");
            }
        }];
    } else {
        [managedDocument saveToURL:docURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success){
            if (success) {
                ScLogDebug(@"Core Data instantiated and ready.");
                managedObjectContext = managedDocument.managedObjectContext;
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


#pragma mark - Singleton initialisation

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
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        deviceId = [userDefaults objectForKey:kUserDefaultsKeyDeviceId];
        
        if (!deviceId) {
            deviceId = [ScUUIDGenerator generateUUID];
            [userDefaults setObject:deviceId forKey:kUserDefaultsKeyDeviceId];
        }
        
        deviceType = [UIDevice currentDevice].model;
        deviceName = [UIDevice currentDevice].name;
        
        isInternetConnectionWiFi = NO;
        isInternetConnectionWWAN = NO;
        
        [self initialiseManagedDocument];
        
        entitiesToPersistToServer = [[NSMutableSet alloc] init];
        entitiesToDeleteFromServer = [[NSMutableSet alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
    
    return self;
}


#pragma mark - Singleton instantiation

+ (ScMeta *)m
{
    if (env == nil) {
        env = [[super allocWithZone:nil] init];
    }
    
    return env;
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

- (NSManagedObjectContext *)managedObjectContext
{
    if (!managedObjectContext) {
        ScLogBreakage(@"Attempt to access Core Data before it's available");
    }
    
    return managedObjectContext;
}


#pragma mark - Meta information

- (NSString *)bundleVersion
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey];
}


- (NSString *)displayLanguage
{
    return [[NSLocale preferredLanguages] objectAtIndex:0];
}


- (NSString *)authToken
{
    NSString *authToken = [ScMeta userDefaultForKey:kUserDefaultsKeyAuthToken];
    
    if (!authToken) {
        authToken = @"<null>";
    }
    
    return authToken;
}


- (BOOL)is_iPadDevice
{
    return [deviceType hasPrefix:@"iPad"];
}


- (BOOL)is_iPhoneDevice
{
    return [deviceType hasPrefix:@"iPhone"];
}


- (BOOL)is_iPodTouchDevice
{
    return [deviceType hasPrefix:@"iPod"];
}


- (BOOL)isSimulatorDevice
{
    return ([deviceType rangeOfString:@"Simulator"].location != NSNotFound);
}


#pragma mark - Connection state

- (BOOL)isInternetConnectionAvailable
{
    return (isInternetConnectionWiFi || isInternetConnectionWWAN);
}


#pragma mark - Remote persistence

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
