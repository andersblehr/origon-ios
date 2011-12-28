//
//  ScAppDelegate.m
//  ScolaApp
//
//  Created by Anders Blehr on 01.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "Reachability.h"

#import "ScAppDelegate.h"
#import "ScAppEnv.h"
#import "ScLogging.h"
#import "ScManagedObjectContext.h"
#import "ScServerConnection.h"

@implementation ScAppDelegate

@synthesize window;

@synthesize managedObjectModel;
@synthesize managedObjectContext;
@synthesize persistentStoreCoordinator;


#pragma mark - Core Data accessors

- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel == nil) {
        managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    
    return managedObjectModel;
}


- (ScManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext == nil) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        
        if (coordinator != nil) {
            managedObjectContext = [[ScManagedObjectContext alloc] init];
            managedObjectContext.persistentStoreCoordinator = coordinator;
        }
    }
    
    return managedObjectContext;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator == nil) {
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ScolaApp.sqlite"];
        
        NSError *error = nil;
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        
        if(![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                     configuration:nil
                                                               URL:storeURL
                                                           options:nil
                                                             error:&error]) {
            ScLogError(@"Unresolved error %@, %@.", error, [error userInfo]);
        }
    }
    
    return persistentStoreCoordinator;
}


- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


#pragma mark - Reachability

- (void)checkConnectivity:(Reachability *)reachability
{
    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
    
    if (internetStatus == ReachableViaWiFi) {
        ScLogInfo(@"Connected to the internet via Wi-Fi.");
        [ScAppEnv env].isInternetConnectionWiFi = YES;
    } else if (internetStatus == ReachableViaWWAN) {
        ScLogInfo(@"Connected to the internet via mobile web (WWAN).");
        [ScAppEnv env].isInternetConnectionWWAN = YES;
    } else {
        ScLogInfo(@"Not connected to the internet.");
    }
    
    if ([ScAppEnv env].isInternetConnectionAvailable && ![ScAppEnv env].isServerAvailable) {
        [ScAppEnv env].isServerAvailable = [ScServerConnection isServerAvailable];
    }
}


- (void)reachabilityChanged:(NSNotification *)notification
{
    [self checkConnectivity:(Reachability *)[notification object]];
}


#pragma mark - Lifecycle methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *device = [UIDevice currentDevice].model;

    if ([device hasPrefix:@"iPad"]) {
        [ScAppEnv env].is_iPadDevice = YES;
    } else if ([device hasPrefix:@"iPhone"]) {
        [ScAppEnv env].is_iPhoneDevice = YES;
    } else if ([device hasPrefix:@"iPod"]) {
        [ScAppEnv env].is_iPodTouchDevice = YES;
    } else {
        ScLogError(@"Unknown device: %@.", device);
    }

    NSString *systemLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    if (YES) { // TODO: Only do this if app supports system language
        [ScAppEnv env].displayLanguage = systemLanguage;
    }
    
    ScLogDebug(@"Device is %@.", device);
    ScLogDebug(@"System name is %@.", [UIDevice currentDevice].systemName);
    ScLogDebug(@"System version is %@.", [UIDevice currentDevice].systemVersion);
    ScLogDebug(@"System language is '%@'", [ScAppEnv env].displayLanguage);
    
    [self checkConnectivity:[Reachability reachabilityForInternetConnection]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    [ScAppEnv env].isDeviceRegistered = NO; // TODO: Need a mechanism here..
    
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
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    Reachability *internetReachability = [Reachability reachabilityForInternetConnection];
    [self checkConnectivity:internetReachability];

    [internetReachability startNotifier];
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
