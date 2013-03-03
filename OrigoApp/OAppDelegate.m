//
//  OAppDelegate.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OAppDelegate.h"

#import <CoreData/CoreData.h>

#import "OEntityReplicator.h"
#import "OLogging.h"
#import "OMeta.h"
#import "OStrings.h"

static NSString * const kTimeZoneNameUTC = @"UTC";
static NSString * const kPersistentStoreFormat = @"OrigoApp^%@.sqlite";


@interface OAppDelegate ()

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end


@implementation OAppDelegate

static void uncaughtExceptionHandler(NSException *exception)
{
    OLogError(@"CRASH: %@", exception);
    OLogError(@"Stack Trace: %@", [exception callStackSymbols]);
}


#pragma mark - Persistent store release

- (void)releasePersistentStore
{
    _managedObjectModel = nil;
    _managedObjectContext = nil;
    _persistentStoreCoordinator = nil;
}


#pragma mark - Core Data properties

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel == nil) {
        _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    
    return _managedObjectModel;
}


- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext == nil) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        
        if (coordinator != nil) {
            _managedObjectContext = [[NSManagedObjectContext alloc] init];
            _managedObjectContext.persistentStoreCoordinator = coordinator;
        }
    }
    
    return _managedObjectContext;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator == nil) {
        NSURL *documentDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *persistentStoreURL = [documentDirectory URLByAppendingPathComponent: [NSString stringWithFormat:kPersistentStoreFormat, [OMeta m].userId]];
        
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        
        if(![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:persistentStoreURL options:nil error:&error]) {
            OLogError(@"Error initialising Core Data: %@", [error localizedDescription]);
        }
    }
    
    return _persistentStoreCoordinator;
}


#pragma mark - Lifecycle methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneWithName:kTimeZoneNameUTC]];
    
    OLogDebug(@"Device is %@.", [UIDevice currentDevice].model);
    OLogDebug(@"iOS version is %@.", [UIDevice currentDevice].systemVersion);
    OLogDebug(@"Device name is %@.", [UIDevice currentDevice].name);
    OLogDebug(@"System language is '%@'.", [[OMeta m] displayLanguage]);

    if ([OStrings hasStrings]) {
        [OStrings refreshIfNeeded];
    }
    
    //NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    //[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    return YES;
}
							

- (void)applicationWillResignActive:(UIApplication *)application
{
    // TODO: Delete if not implemented.
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    if ([[OMeta m] userIsSignedIn]) {
        [[OMeta m].replicator saveUserReplicationState];
        
        if (![[OMeta m] userIsRegistered]) {
            [[OMeta m] setUserDefault:@YES forKey:kDefaultsKeyRegistrationAborted];
        }
    }
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // TODO: Delete if not implemented.
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if ([[OMeta m] userIsSignedIn]) {
        [[OMeta m].replicator replicate];
    }
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    if ([[OMeta m] userIsSignedIn]) {
        [[OMeta m].replicator saveUserReplicationState];
    }
}

@end
