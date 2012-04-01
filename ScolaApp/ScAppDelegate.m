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
#import "ScMeta.h"
#import "ScLogging.h"
#import "ScServerConnection.h"

@implementation ScAppDelegate

@synthesize window;


#pragma mark - Lifecycle methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    ScLogDebug(@"Device is %@.", [UIDevice currentDevice].model);
    ScLogDebug(@"Device name is %@.", [UIDevice currentDevice].name);
    ScLogDebug(@"System name is %@.", [UIDevice currentDevice].systemName);
    ScLogDebug(@"System version is %@.", [UIDevice currentDevice].systemVersion);
    ScLogDebug(@"System language is '%@'", [[ScMeta m] displayLanguage]);
    
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
    [[ScMeta m] checkInternetReachability];
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
