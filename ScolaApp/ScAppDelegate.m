//
//  ScAppDelegate.m
//  ScolaApp
//
//  Created by Anders Blehr on 01.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "Facebook.h"
#import "Reachability.h"

#import "ScAppDelegate.h"
#import "ScAppEnv.h"
#import "ScLogging.h"

#define kFacebookAppId @"223875737682972"


@implementation ScAppDelegate

@synthesize window;

@synthesize facebook;

@synthesize managedObjectModel;
@synthesize managedObjectContext;
@synthesize persistentStoreCoordinator;


#pragma mark - Accessors

- (NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext == nil) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        
        if (coordinator != nil) {
            managedObjectContext = [[NSManagedObjectContext alloc] init];
            managedObjectContext.persistentStoreCoordinator = coordinator;
            
            [ScAppEnv env].managedObjectContext = managedObjectContext;
        }
    }
    
    return managedObjectContext;
}


- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel == nil) {
        managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    }
    
    return managedObjectModel;
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
        [ScAppEnv env].internetConnectionIsWiFi = YES;
    } else if (internetStatus == ReachableViaWWAN) {
        ScLogInfo(@"Connected to the internet via mobile web (WWAN).");
        [ScAppEnv env].internetConnectionIsWWAN = YES;
    } else {
        ScLogInfo(@"Not connected to the internet.");
    }
}


- (void)reachabilityChanged:(NSNotification *)notification
{
    [self checkConnectivity:(Reachability *)[notification object]];
}


#pragma mark - Methods for logging in and out

- (void)logInWithFacebook
{
    [facebook authorize:nil];
}


- (void)logInWithGoogle
{
    //TODO: Implement for Google
}


- (void)logOut
{
    if ([ScAppEnv env].isLoggedInWithFacebook) {
        [facebook logout:self];
    } else if ([ScAppEnv env].isLoggedInWithGoogle) {
        // TODO: Implement for Google
        
        [ScAppEnv env].isLoggedInWithGoogle = NO;
    } else {
        ScLogError(@"Attempt to log out when not logged in.");
    }
}


#pragma mark - FBSessionDelegate implementations

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [facebook handleOpenURL:url]; 
}


- (void)fbDidLogin
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:[facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
    
    [ScAppEnv env].isLoggedInWithFacebook = YES;
}


- (void)fbDidLogout
{
    // TODO
    
    [ScAppEnv env].isLoggedInWithFacebook = NO;
}


#pragma mark - Lifecycle methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *device = [UIDevice currentDevice].model;

    if ([device hasPrefix:@"iPad"]) {
        [ScAppEnv env].iPadDevice = YES;
    } else if ([device hasPrefix:@"iPhone"]) {
        [ScAppEnv env].iPhoneDevice = YES;
    } else if ([device hasPrefix:@"iPod"]) {
        [ScAppEnv env].iPodTouchDevice = YES;
    } else {
        ScLogError(@"Unknown device: %@.", device);
        return NO;
    }

    NSString *systemLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    if (YES) { // TODO: Only do this if app supports system language
        [ScAppEnv env].displayLanguage = systemLanguage;
    }
    
    ScLogDebug(@"Device is %@.", device);
    ScLogDebug(@"System name is %@.", [UIDevice currentDevice].systemName);
    ScLogDebug(@"System version is %@.", [UIDevice currentDevice].systemVersion);
    ScLogDebug(@"System language is '%@'", [ScAppEnv env].displayLanguage);
    
    // Monitor internet connectivity
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    // Check if valid Facebook access token exists
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    facebook = [[Facebook alloc] initWithAppId:kFacebookAppId andDelegate:self];
    
    if ([defaults objectForKey:@"FBAccessTokenKey"] && [defaults objectForKey:@"FBExpirationDateKey"]) {
        facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
    }
    
    [ScAppEnv env].isLoggedInWithFacebook = [facebook isSessionValid];
    
    // If no valid Facebook access token, check for valid Google access token
    if (![ScAppEnv env].isLoggedInWithFacebook) {
        [ScAppEnv env].isLoggedInWithGoogle = NO; // TODO: Implement for Google
    }
    
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
