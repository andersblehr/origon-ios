//
//  OAppDelegate.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

static NSString * const kTimeZoneNameUTC = @"UTC";
static NSString * const kPersistentStoreURLFormat = @"Origon^%@.sqlite";


@interface OAppDelegate () {
@private
    NSManagedObjectModel *_managedObjectModel;
    NSManagedObjectContext *_managedObjectContext;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
    
    BOOL _didJustLaunch;
    BOOL _didEnterBackground;
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
    if ([[OMeta m] userIsLoggedIn]) {
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
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
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
    OLogDebug(@"Localisation: %@", [[NSBundle mainBundle] preferredLocalizations][0]);
    //OLogDebug(@"Persistent store: %@", [self persistentStoreURL]);

    _didJustLaunch = YES;
    
    return YES;
}
							

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    OLogDebug(@"Application did enter background");
    
    [self saveApplicationState];
    
    _didEnterBackground = YES;
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (_didJustLaunch) {
        OLogDebug(@"Application did become active");
        
        if ([[OMeta m] userIsAllSet]) {
            [[OMeta m].replicator replicate];
        }
        
        _didJustLaunch = NO;
    } else if (_didEnterBackground) {
        OLogDebug(@"Application did resume from background");
        
        if ([[OState s].viewController respondsToSelector:@selector(didResumeFromBackground)]) {
            [[OState s].viewController didResumeFromBackground];
        }
        
        _didEnterBackground = NO;
    }
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    OLogDebug(@"Application will terminate");
    
    if (!_didEnterBackground) {
        [self saveApplicationState];
    }
}

@end
