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

#import "OMember.h"

static NSString * const kPersistentStoreFormat = @"OrigoApp$%@.sqlite";


@interface OAppDelegate ()

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end


@implementation OAppDelegate

static void uncaughtExceptionHandler(NSException *exception)
{
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
}


#pragma mark - Persistent store release

- (void)releasePersistentStore
{
    _managedObjectModel = nil;
    _managedObjectContext= nil;
    _persistentStoreCoordinator = nil;
}


#pragma mark - Core Data accessors

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
    
    OLogState;
    OLogDebug(@"Device is %@.", [UIDevice currentDevice].model);
    OLogDebug(@"Device name is %@.", [UIDevice currentDevice].name);
    OLogDebug(@"System name is %@.", [UIDevice currentDevice].systemName);
    OLogDebug(@"System version is %@.", [UIDevice currentDevice].systemVersion);
    OLogDebug(@"System language is '%@'.", [[OMeta m] displayLanguage]);
    
    return YES;
}
							

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if ([OMeta m].isUserLoggedIn) {
        [[OMeta m].context synchroniseCacheWithServer];
    }
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // TODO: Delete if not implemented.
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // TODO: Delete if not implemented.
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // TODO: Delete if not implemented.
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // TODO: Delete if not implemented.
}

@end
