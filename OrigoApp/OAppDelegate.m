//
//  OAppDelegate.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OAppDelegate.h"

static NSString * const kTimeZoneNameUTC = @"UTC";
static NSString * const kPersistentStoreURLFormat = @"OrigoApp^%@.sqlite";


@interface OAppDelegate () {
@private
    NSManagedObjectModel *_managedObjectModel;
    NSManagedObjectContext *_managedObjectContext;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
    
    BOOL _isRunningInBackground;
}

@end


@implementation OAppDelegate

#pragma mark - Custom exception handler

static void uncaughtExceptionHandler(NSException *exception)
{
    OLogError(@"CRASH: %@", exception);
    OLogError(@"Stack Trace: %@", [exception callStackSymbols]);
}


#pragma mark - Auxiliary methods

- (NSURL *)persistentStoreURL
{
    NSURL *documentDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    
    return [documentDirectory URLByAppendingPathComponent:[NSString stringWithFormat:kPersistentStoreURLFormat, [OMeta m].userId]];
}


- (void)saveApplicationState
{
    if ([[OMeta m] userIsSignedIn]) {
        [[OMeta m].replicator saveUserReplicationState];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - Persistent store handling

- (BOOL)hasPersistentStore
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[[self persistentStoreURL] path]];
}


- (void)releasePersistentStore
{
    _managedObjectModel = nil;
    _managedObjectContext = nil;
    _persistentStoreCoordinator = nil;
}


#pragma mark - Core Data property accessors

- (NSManagedObjectModel *)managedObjectModel
{
    if (!_managedObjectModel) {
        _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    
    return _managedObjectModel;
}


- (NSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        
        if (coordinator) {
            _managedObjectContext = [[NSManagedObjectContext alloc] init];
            _managedObjectContext.persistentStoreCoordinator = coordinator;
        }
    }
    
    return _managedObjectContext;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (!_persistentStoreCoordinator) {
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        
        if(![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[self persistentStoreURL] options:nil error:&error]) {
            OLogError(@"Error initialising Core Data: %@", [error localizedDescription]);
        }
    }
    
    return _persistentStoreCoordinator;
}


#pragma mark - Lifecycle methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    OLogDebug(@"Application did finish launching");
    
    //NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    //[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneWithName:kTimeZoneNameUTC]];
    
    _window.tintColor = [UIColor globalTintColour];
    
    OLogDebug(@"Device ID: %@", [OMeta m].deviceId);
    OLogDebug(@"System language: %@", [OMeta m].language);
    //OLogDebug(@"Persistent store: %@", [self persistentStoreURL]);

    return YES;
}
							

- (void)applicationWillResignActive:(UIApplication *)application
{
    // TODO: Delete if not implemented.
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    OLogDebug(@"Application did enter background");
    
    [self saveApplicationState];
    
    _isRunningInBackground = YES;
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // TODO: Delete if not implemented.
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    OLogDebug(@"Application did become active");
    
    if (_isRunningInBackground) {
        if ([[OState s].viewController respondsToSelector:@selector(didResumeFromBackground)]) {
            [[OState s].viewController didResumeFromBackground];
        }
        
        _isRunningInBackground = NO;
        
        if ([[OMeta m] userIsAllSet]) {
            [[OMeta m].replicator replicateIfNeeded];
        }
    } else {
        if ([[OMeta m] userIsAllSet]) {
            [OMeta touchDeviceIfNeeded];
            [[OMeta m].replicator replicate];
        }
    }
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    OLogDebug(@"Application will terminate");
    
    if (!_isRunningInBackground) {
        [self saveApplicationState];
    }
}

@end
