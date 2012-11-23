//
//  OAppDelegate.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OAppDelegate.h"

#import <CoreData/CoreData.h>

#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"

#import "Reachability.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OServerConnection.h"
#import "OState.h"
#import "OStrings.h"

#import "OMember.h"

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
    [[OMeta m] removeAllEntityObservers];
    
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
        NSURL *applicationDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *storeURL = [applicationDocumentsDirectory URLByAppendingPathComponent: [NSString stringWithFormat:kPersistentStoreFormat, [OMeta m].userId]];
        
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        
        if(![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            OLogError(@"Error initiating Core Data: %@", [error localizedDescription]);
        }
    }
    
    return _persistentStoreCoordinator;
}


#pragma mark - Lifecycle methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    
    OLogDebug(@"Device is %@.", [UIDevice currentDevice].model);
    OLogDebug(@"Device name is %@.", [UIDevice currentDevice].name);
    OLogDebug(@"System name is %@.", [UIDevice currentDevice].systemName);
    OLogDebug(@"System version is %@.", [UIDevice currentDevice].systemVersion);
    OLogDebug(@"System language is '%@'.", [[OMeta m] displayLanguage]);
    
    [OStrings conditionallyRefresh];
    
    return YES;
}
							

- (void)applicationWillResignActive:(UIApplication *)application
{
    // TODO: Delete if not implemented.
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self.managedObjectContext saveReplicationState];
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // TODO: Delete if not implemented.
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if ([[OMeta m] userIsSignedIn]) {
        [[OMeta m].context replicateIfNeeded];
    }
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.managedObjectContext saveReplicationState];
}

@end
