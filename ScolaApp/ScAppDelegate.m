//
//  ScAppDelegate.m
//  ScolaApp
//
//  Created by Anders Blehr on 01.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "Reachability.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"

#import "ScAppDelegate.h"
#import "ScMeta.h"
#import "ScLogging.h"
#import "ScServerConnection.h"

@implementation ScAppDelegate

static NSString * const kPersistentStoreFormat = @"ScolaApp$%@.sqlite";

@synthesize window;

@synthesize managedObjectModel;
@synthesize managedObjectContext;
@synthesize persistentStoreCoordinator;


#pragma mark - Persistent store

- (void)releasePersistentStore
{
    managedObjectModel = nil;
    managedObjectContext= nil;
    persistentStoreCoordinator = nil;
}


#pragma mark - Core Data accessors

- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel == nil) {
        managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    
    return managedObjectModel;
}


- (NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext == nil) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        
        if (coordinator != nil) {
            managedObjectContext = [[NSManagedObjectContext alloc] init];
            managedObjectContext.persistentStoreCoordinator = coordinator;
        }
    }
    
    return managedObjectContext;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator == nil) {
        NSURL *applicationDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *storeURL = [applicationDocumentsDirectory URLByAppendingPathComponent: [NSString stringWithFormat:kPersistentStoreFormat, [ScMeta m].userId]];
        
        NSError *error = nil;
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        
        if(![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            ScLogError(@"Error initiating Core Data: %@", [error localizedDescription]);
        }
    }
    
    return persistentStoreCoordinator;
}


#pragma mark - Lifecycle methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[ScMeta m].managedObjectContext synchronise];
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
