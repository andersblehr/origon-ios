//
//  ScAppDelegate.m
//  ScolaApp
//
//  Created by Anders Blehr on 01.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScAppDelegate.h"

#import <CoreData/CoreData.h>

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"

#import "Reachability.h"

#import "ScMeta.h"
#import "ScLogging.h"
#import "ScServerConnection.h"
#import "ScState.h"

#import "ScMember.h"


static NSString * const kPersistentStoreFormat = @"ScolaApp$%@.sqlite";


@interface ScAppDelegate ()

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end


@implementation ScAppDelegate


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
        NSURL *storeURL = [applicationDocumentsDirectory URLByAppendingPathComponent: [NSString stringWithFormat:kPersistentStoreFormat, [ScMeta m].userId]];
        
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        
        if(![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            ScLogError(@"Error initiating Core Data: %@", [error localizedDescription]);
        }
    }
    
    return _persistentStoreCoordinator;
}


#pragma mark - Lifecycle methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    [NSTimeZone setDefaultTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    
    ScLogState;
    ScLogDebug(@"Device is %@.", [UIDevice currentDevice].model);
    ScLogDebug(@"Device name is %@.", [UIDevice currentDevice].name);
    ScLogDebug(@"System name is %@.", [UIDevice currentDevice].systemName);
    ScLogDebug(@"System version is %@.", [UIDevice currentDevice].systemVersion);
    ScLogDebug(@"System language is '%@'.", [[ScMeta m] displayLanguage]);
    
    [[ScMeta m] checkInternetReachability];
    
    return YES;
}
							

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if ([ScMeta m].isUserLoggedIn) {
        [[ScMeta m].context synchroniseCacheWithServer];
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
