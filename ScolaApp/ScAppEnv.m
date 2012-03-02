//
//  ScAppEnv.m
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScAppEnv.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"

#import "ScAppDelegate.h"
#import "ScCachedEntity+ScCachedEntityExtensions.h"
#import "ScLogging.h"
#import "ScUUIDGenerator.h"

@implementation ScAppEnv

NSString * const kBundleID = @"com.scolaapp.ios.ScolaApp";

@synthesize deviceType;
@synthesize deviceName;
@synthesize deviceUUID;

@synthesize isInternetConnectionWiFi;
@synthesize isInternetConnectionWWAN;

@synthesize serverAvailability;
@synthesize managedObjectContext;

static ScAppEnv *env = nil;


#pragma mark - Auxiliary methods

- (void)initialiseManagedDocument
{
    ScLogDebug(@"Initialising Core Data...");
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
        entity.remotePersistenceState = ScRemotePersistenceStateDirtyNotScheduled;
    }
    
    for (ScCachedEntity *entity in entitiesUpdated) {
        entity.remotePersistenceState = ScRemotePersistenceStateDirtyNotScheduled;
    }
    
    for (ScCachedEntity *entity in entitiesDeleted) {
        entity.remotePersistenceState = ScRemotePersistenceStateDirtyNotScheduled;
    }
    
    [entitiesToPersistToServer unionSet:entitiesInserted];
    [entitiesToPersistToServer unionSet:entitiesUpdated];
    [entitiesToDeleteFromServer unionSet:entitiesDeleted];
}


#pragma mark - Singleton instance handling

+ (ScAppEnv *)env
{
    if (env == nil) {
        env = [[super allocWithZone:nil] init];
    }
    
    return env;
}


+ (id)allocWithZone:(NSZone *)zone
{
    return [self env];
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


- (id)init
{
    self = [super init];
    
    if (self) {
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


#pragma mark - Accessors

- (NSManagedObjectContext *)managedObjectContext
{
    if (!managedObjectContext) {
        ScLogBreakage(@"Attempt to access Core Data before it's available");
    }
    
    return managedObjectContext;
}


#pragma mark - Device information

- (NSString *)deviceUUID
{
    NSUserDefaults *userDefaults;
    
    if (!deviceUUID) {
        userDefaults = [NSUserDefaults standardUserDefaults];
        deviceUUID = [userDefaults objectForKey:@"scola.device.uuid"];
    }
    
    if (!deviceUUID) {
        deviceUUID = [ScUUIDGenerator generateUUID];
        [userDefaults setObject:deviceUUID forKey:@"scola.device.uuid"];
    }
    
    return deviceUUID;
}


- (NSString *)bundleVersion
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey];
}


- (NSString *)displayLanguage
{
    return [[NSLocale preferredLanguages] objectAtIndex:0];
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


- (BOOL)isServerAvailable
{
    return (serverAvailability == ScServerAvailabilityAvailable);
}


#pragma mark - Remote persistence

- (NSArray *)entitiesToPersistToServer
{
    NSArray *entitiesToPersist = nil;
    
    if (entitiesToPersistToServer.count > 0) {
        entitiesToPersist = [entitiesToPersistToServer allObjects];
    }
    
    return entitiesToPersist;
}


- (NSArray *)entitiesToDeleteFromServer
{
    NSArray *entitiesToDelete = nil;

    if (entitiesToDeleteFromServer.count > 0) {
        entitiesToDelete = [entitiesToDeleteFromServer allObjects];
    }
    
    return entitiesToDelete;
}


- (void)didPersistEntitiesToServer
{
    for (ScCachedEntity *entity in [entitiesToPersistToServer copy]) {
        if (entity.remotePersistenceState == ScRemotePersistenceStateDirtyScheduled) {
            entity.remotePersistenceState = ScRemotePersistenceStatePersisted;
            [entitiesToPersistToServer removeObject:entity];
        }
    }
}


- (void)didDeleteEntitiesFromServer
{
    for (ScCachedEntity *entity in [entitiesToDeleteFromServer copy]) {
        if (entity.remotePersistenceState == ScRemotePersistenceStateDirtyScheduled) {
            entity.remotePersistenceState = ScRemotePersistenceStateDeleted;
            [entitiesToDeleteFromServer removeObject:entity];
        }
    }
}

@end
