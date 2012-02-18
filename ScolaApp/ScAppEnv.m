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
#import "ScLogging.h"
#import "ScScolaMember.h"

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
    
    NSSet *entitiesInsertedSinceLastTime = [saveInfo objectForKey:NSInsertedObjectsKey];
    NSSet *entitiesUpdatedSinceLastTime = [saveInfo objectForKey:NSUpdatedObjectsKey];
    NSSet *entitiesDeletedSinceLastTime = [saveInfo objectForKey:NSDeletedObjectsKey];
    
    [entitiesToPersistToServer unionSet:entitiesInsertedSinceLastTime];
    [entitiesToPersistToServer unionSet:entitiesUpdatedSinceLastTime];
    [entitiesToDeleteFromServer unionSet:entitiesDeletedSinceLastTime];
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
        entitiesScheduledForPersistence = [[NSMutableSet alloc] init];
        entitiesScheduledForDeletion = [[NSMutableSet alloc] init];
        
        NSNotificationCenter *notificationCentre = [NSNotificationCenter defaultCenter];
        [notificationCentre addObserver:self selector:@selector(contextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
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


- (BOOL)isModelPersisted
{
    return (entitiesToPersistToServer.count + entitiesToDeleteFromServer.count == 0);
}


#pragma mark - Interface implementations

- (NSString *)deviceUUID
{
    NSUserDefaults *userDefaults;
    
    if (!deviceUUID) {
        userDefaults = [NSUserDefaults standardUserDefaults];
        deviceUUID = [userDefaults objectForKey:@"scola.device.uuid"];
    }
    
    if (!deviceUUID) {
        CFUUIDRef newUUID = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef newUUIDAsCFString = CFUUIDCreateString(kCFAllocatorDefault, newUUID);
        deviceUUID = [[NSString stringWithString:(__bridge NSString *)newUUIDAsCFString] lowercaseString];
        
        CFRelease(newUUID);
        CFRelease(newUUIDAsCFString);
        
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


- (BOOL)isInternetConnectionAvailable
{
    return (isInternetConnectionWiFi || isInternetConnectionWWAN);
}


- (BOOL)isServerAvailable
{
    return (serverAvailability == ScServerAvailabilityAvailable);
}


- (NSArray *)entitiesToPersistToServer
{
    NSArray *entitiesToReturn = nil;
    
    if (entitiesToPersistToServer.count > 0) {
        entitiesToReturn = [entitiesToPersistToServer allObjects];
    }
    
    return entitiesToReturn;
}


- (NSArray *)entitiesToDeleteFromServer
{
    NSArray *entitiesToReturn = nil;

    if (entitiesToDeleteFromServer.count > 0) {
        entitiesToReturn = [entitiesToDeleteFromServer allObjects];
    }
    
    return entitiesToReturn;
}


- (BOOL)canScheduleEntityForPersistence:(ScCachedEntity *)entity
{
    BOOL isScheduled = ([entitiesScheduledForPersistence member:entity] != nil);
    
    if (!isScheduled) {
        if ([entitiesToPersistToServer member:entity]) {
            [entitiesScheduledForPersistence addObject:entity];
        }
    }
    
    return !isScheduled;
}


- (BOOL)canScheduleEntityForDeletion:(ScCachedEntity *)entity
{
    BOOL isScheduled = ([entitiesScheduledForDeletion member:entity] != nil);
    
    if (!isScheduled) {
        if ([entitiesToDeleteFromServer member:entity]) {
            [entitiesScheduledForDeletion addObject:entity];
        }
    }
    
    return !isScheduled;
}


- (void)entitiesWerePersistedToServer
{
    [entitiesToPersistToServer minusSet:entitiesScheduledForPersistence];
    [entitiesScheduledForPersistence removeAllObjects];
}


- (void)entitiesWereDeletedFromServer
{
    [entitiesToDeleteFromServer minusSet:entitiesScheduledForDeletion];
    [entitiesScheduledForDeletion removeAllObjects];
}

@end
