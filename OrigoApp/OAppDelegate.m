//
//  OAppDelegate.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OAppDelegate.h"

#import <CoreData/CoreData.h>

#import "ODefaults.h"
#import "OLogging.h"
#import "OMeta.h"
#import "OReplicator.h"
#import "OState.h"
#import "OStrings.h"

static NSString * const kTimeZoneNameUTC = @"UTC";
static NSString * const kPersistentStoreURLFormat = @"OrigoApp^%@.sqlite";


@implementation OAppDelegate

#pragma mark - Custom exception handler

static void uncaughtExceptionHandler(NSException *exception)
{
    OLogError(@"CRASH: %@", exception);
    OLogError(@"Stack Trace: %@", [exception callStackSymbols]);
}


#pragma mark - Auxiliary methods

- (void)saveApplicationState
{
    if ([[OMeta m] userIsSignedIn]) {
        [[OMeta m].replicator saveUserReplicationState];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - Persistent store release

- (void)releasePersistentStore
{
    _managedObjectModel = nil;
    _managedObjectContext = nil;
    _persistentStoreCoordinator = nil;
}


#pragma mark - Core Data property accessors

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
        NSURL *persistentStoreURL = [documentDirectory URLByAppendingPathComponent: [NSString stringWithFormat:kPersistentStoreURLFormat, [OMeta m].userId]];
        
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
    [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneWithName:kTimeZoneNameUTC]];
    
    if ([OMeta systemIs_iOS6x]) {
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
    } else {
        _window.tintColor = [UIColor windowTintColor];
    }
    
    OLogDebug(@"Device is %@.", [UIDevice currentDevice].model);
    OLogDebug(@"iOS version is %@.", [UIDevice currentDevice].systemVersion);
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
    [self saveApplicationState];
    
    _didEnterBackground = YES;
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // TODO: Delete if not implemented.
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (_didEnterBackground) {
        if ([[OState s].viewController respondsToSelector:@selector(didResumeFromBackground)]) {
            [[OState s].viewController didResumeFromBackground];
        }
        
        _didEnterBackground = NO;
    } else {
        if ([[OMeta m] userIsAllSet]) {
            [[OMeta m].replicator replicate];
        }
    }
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    if (!_didEnterBackground) {
        [self saveApplicationState];
    }
}

@end
