//
//  ScMeta.m
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScMeta.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "NSString+ScStringExtensions.h"

#import "ScAppDelegate.h"
#import "ScCachedEntity+ScCachedEntityExtensions.h"
#import "ScLogging.h"
#import "ScServerConnection.h"
#import "ScUUIDGenerator.h"

@implementation ScMeta

NSString * const kBundleID = @"com.scolaapp.ios.ScolaApp";
NSString * const kKeyEntityId = @"entityId";
NSString * const kKeyEntityClass = @"entityClass";

static NSString * const kUserDefaultsKeyUserId = @"scola.user.id";
static NSString * const kUserDefaultsKeyFormatHomeScolaId = @"scola.scola.id$%@";
static NSString * const kUserDefaultsKeyFormatDeviceId = @"scola.device.id$%@";
static NSString * const kUserDefaultsKeyFormatAuthToken = @"scola.auth.token$%@";
static NSString * const kUserDefaultsKeyFormatAuthExpiryDate = @"scola.auth.expires$%@";
static NSString * const kUserDefaultsKeyFormatLastFetchDate = @"scola.fetch.date$%@";

static ScMeta *m = nil;

@synthesize userId;
@synthesize homeScolaId;
@synthesize lastFetchDate;

@synthesize deviceId;
@synthesize authToken;
@synthesize appVersion;
@synthesize displayLanguage;

@synthesize is_iPadDevice;
@synthesize is_iPodDevice;
@synthesize is_iPhoneDevice;
@synthesize isSimulatorDevice;

@synthesize isInternetConnectionWiFi;
@synthesize isInternetConnectionWWAN;

@synthesize isUserLoggedIn;
@synthesize nonPersistedEntities;
@synthesize managedObjectContext;


#pragma mark - Auxiliary methods

- (void)checkReachability:(Reachability *)reachability
{
    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
    
    isInternetConnectionWiFi = (internetStatus == ReachableViaWiFi);
    isInternetConnectionWWAN = (internetStatus == ReachableViaWWAN);
    
    if (internetStatus == ReachableViaWiFi) {
        ScLogInfo(@"Connected to the internet via Wi-Fi.");
    } else if (internetStatus == ReachableViaWWAN) {
        ScLogInfo(@"Connected to the internet via mobile web (WWAN).");
    } else {
        ScLogInfo(@"Not connected to the internet.");
    }
    
    internetReachability = reachability;
}


- (void)reachabilityChanged:(NSNotification *)notification
{
    [self checkReachability:(Reachability *)[notification object]];
}


- (NSString *)generateAuthToken:(NSDate *)expiryDate
{
    NSString *expiryDateAsString = expiryDate.description;
    NSString *saltyDiff = [deviceId diff:expiryDateAsString];
    
    return [saltyDiff hashUsingSHA1];
}


#pragma mark - Singleton instantiation & initialisation

+ (id)allocWithZone:(NSZone *)zone
{
    return [self m];
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


- (id)init
{
    self = [super init];
    
    if (self) {
        NSString *deviceModel = [UIDevice currentDevice].model;
        
        is_iPadDevice = [deviceModel hasPrefix:@"iPad"];
        is_iPodDevice = [deviceModel hasPrefix:@"iPod"];
        is_iPhoneDevice = [deviceModel hasPrefix:@"iPhone"];
        isSimulatorDevice = ([deviceModel rangeOfString:@"Simulator"].location != NSNotFound);
        
        isInternetConnectionWiFi = NO;
        isInternetConnectionWWAN = NO;
        
        userId = [ScMeta userDefaultForKey:kUserDefaultsKeyUserId];
        
        if (userId) {
            homeScolaId = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatHomeScolaId, userId]];
            deviceId = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatDeviceId, userId]];
            authToken = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthToken, userId]];
            authTokenExpiryDate = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthExpiryDate, userId]];
            lastFetchDate = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatLastFetchDate, userId]];
        } else {
            deviceId = [ScUUIDGenerator generateUUID];
        }
        
        appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey];
        displayLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
        
        nonPersistedEntities = [[NSMutableSet alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    }
    
    return self;
}


+ (ScMeta *)m
{
    if (m == nil) {
        m = [[super allocWithZone:nil] init];
    }
    
    return m;
}


#pragma mark - NSUserDefaults convenience accessors

+ (void)setUserDefault:(id)object forKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
}


+ (id)userDefaultForKey:(NSString *)key
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}


+ (void)removeUserDefaultForKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
}


#pragma mark - Accessors

- (void)setUserId:(NSString *)userIdentity
{
    userId = userIdentity;
    deviceId = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatDeviceId, userId]];
    
    if (deviceId) {
        homeScolaId = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatHomeScolaId, userId]];
    } else {
        deviceId = [ScUUIDGenerator generateUUID];
        
        [ScMeta setUserDefault:userId forKey:kUserDefaultsKeyUserId];
        [ScMeta setUserDefault:homeScolaId forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatHomeScolaId, userId]];
        [ScMeta setUserDefault:deviceId forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatDeviceId, userId]];
    }
}


- (void)setLastFetchDate:(NSString *)fetchDate
{
    lastFetchDate = fetchDate;
    
    [ScMeta setUserDefault:fetchDate forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatLastFetchDate, userId]];
}


- (void)setIsUserLoggedIn:(BOOL)isLoggedIn
{
    [(ScAppDelegate *)[[UIApplication sharedApplication] delegate] releasePersistentStore];
    
    if (isLoggedIn) {
        authToken = self.authToken;
    } else {
        authTokenExpiryDate = nil;
        authToken = nil;
        
        [ScMeta removeUserDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthToken, userId]];
        [ScMeta removeUserDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthExpiryDate, userId]];
    }
    
    isUserLoggedIn = isLoggedIn;
}


- (NSString *)authToken
{
    if (!authToken) {
        authTokenExpiryDate = [NSDate dateWithTimeIntervalSinceNow:1]; // TODO: Two weeks
        authToken = [self generateAuthToken:authTokenExpiryDate];
        
        [ScMeta setUserDefault:authToken forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthToken, userId]];
        [ScMeta setUserDefault:authTokenExpiryDate forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthExpiryDate, userId]];
    }
    
    return authToken;
}


- (BOOL)isUserLoggedIn
{
    if (isUserLoggedIn) {
        BOOL isAuthTokenValid = NO;
        NSDate *now = [NSDate date];
        
        if ([now compare:authTokenExpiryDate] == NSOrderedAscending) {
            NSString *expectedToken = [self generateAuthToken:authTokenExpiryDate];
            isAuthTokenValid = [authToken isEqualToString:expectedToken];
        }
        
        if (!isAuthTokenValid) {
            self.isUserLoggedIn = NO;
        }
    }
    
    return isUserLoggedIn;
}


- (NSManagedObjectContext *)managedObjectContext
{
    ScAppDelegate *delegate = (ScAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    return delegate.managedObjectContext;
}


#pragma mark - Connection state

- (void)checkInternetReachability
{
    [self checkReachability:[Reachability reachabilityForInternetConnection]];
    
    if ([internetReachability startNotifier]) {
        ScLogInfo(@"Reachability notifier is running.");
    } else {
        ScLogWarning(@"Could not start reachability notifier, checking internet connectivity at app activation only.");
    }
}


- (BOOL)isInternetConnectionAvailable
{
    return (isInternetConnectionWiFi || isInternetConnectionWWAN);
}

@end
