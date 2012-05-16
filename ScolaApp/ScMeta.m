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

#import "ScCachedEntity.h"

@implementation ScMeta

NSString * const kBundleId = @"com.scolaapp.ios.ScolaApp";
NSString * const kKeyEntityId = @"entityId";
NSString * const kKeyEntityClass = @"entityClass";
NSString * const kKeyScolaId = @"scolaId";

static NSString * const kUserDefaultsKeyUserId = @"scola.user.id";
static NSString * const kUserDefaultsKeyFormatHomeScolaId = @"scola.scola.id$%@";
static NSString * const kUserDefaultsKeyFormatDeviceId = @"scola.device.id$%@";
static NSString * const kUserDefaultsKeyFormatAuthToken = @"scola.auth.token$%@";
static NSString * const kUserDefaultsKeyFormatAuthExpiryDate = @"scola.auth.expires$%@";
static NSString * const kUserDefaultsKeyFormatLastFetchDate = @"scola.fetch.date$%@";

static ScMeta *m = nil;

@synthesize isUserLoggedIn;

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

@synthesize managedObjectContext;
@synthesize entitiesScheduledForPersistence;


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


- (void)reachabilityDidChange:(NSNotification *)notification
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
            lastFetchDate = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatLastFetchDate, userId]];
            deviceId = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatDeviceId, userId]];
            authToken = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthToken, userId]];
            authTokenExpiryDate = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthExpiryDate, userId]];
        } else {
            deviceId = [ScUUIDGenerator generateUUID];
        }
        
        appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey];
        displayLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
        
        scheduledEntities = [[NSMutableSet alloc] init];
        importedEntities = [[NSMutableDictionary alloc] init];
        importedEntityRefs = [[NSMutableDictionary alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
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

- (void)setIsUserLoggedIn:(BOOL)isLoggedIn
{
    [(ScAppDelegate *)[[UIApplication sharedApplication] delegate] releasePersistentStore];
    
    authToken = nil;
    
    if (isLoggedIn) {
        authTokenExpiryDate = [NSDate dateWithTimeIntervalSinceNow:30]; // TODO: Two weeks
        authToken = self.authToken;
    } else {
        authTokenExpiryDate = nil;
        
        [ScMeta removeUserDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthToken, userId]];
        [ScMeta removeUserDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthExpiryDate, userId]];
    }
}


- (void)setUserId:(NSString *)userIdentity
{
    userId = userIdentity;
    
    if (userId) {
        NSString *storedDeviceId = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatDeviceId, userId]];
        
        if (storedDeviceId) {
            deviceId = storedDeviceId;
        }
        
        [ScMeta setUserDefault:userId forKey:kUserDefaultsKeyUserId];    
        [ScMeta setUserDefault:deviceId forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatDeviceId, userId]];
    }
}


- (void)setHomeScolaId:(NSString *)scolaId
{
    homeScolaId = scolaId;
    
    [ScMeta setUserDefault:homeScolaId forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatHomeScolaId, userId]];
}


- (void)setLastFetchDate:(NSString *)fetchDate
{
    lastFetchDate = fetchDate;
    
    [ScMeta setUserDefault:fetchDate forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatLastFetchDate, userId]];
}


- (BOOL)isUserLoggedIn
{
    BOOL isAuthTokenValid = NO;
    
    if (authToken && authTokenExpiryDate) {
        NSDate *now = [NSDate date];
        
        if ([now compare:authTokenExpiryDate] == NSOrderedAscending) {
            NSString *expectedToken = [self generateAuthToken:authTokenExpiryDate];
            isAuthTokenValid = [authToken isEqualToString:expectedToken];
        }
    }
    
    return isAuthTokenValid;
}


- (NSString *)authToken
{
    if (!authToken && authTokenExpiryDate) {
        authToken = [self generateAuthToken:authTokenExpiryDate];
        
        [ScMeta setUserDefault:authToken forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthToken, userId]];
        [ScMeta setUserDefault:authTokenExpiryDate forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthExpiryDate, userId]];
    }
    
    return authToken;
}


- (NSManagedObjectContext *)managedObjectContext
{
    ScAppDelegate *delegate = (ScAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    return delegate.managedObjectContext;
}


- (NSSet *)entitiesScheduledForPersistence
{
    [scheduledEntities unionSet:[self.managedObjectContext insertedObjects]];
    [scheduledEntities unionSet:[self.managedObjectContext updatedObjects]];
    
    NSMutableSet *nonPersistedEntities = [[NSMutableSet alloc] init];
    
    for (ScCachedEntity *entity in scheduledEntities) {
        if (![entity isPersisted]) {
            [nonPersistedEntities addObject:entity];
        }
    }
    
    scheduledEntities = [NSMutableSet setWithSet:nonPersistedEntities];
    
    return scheduledEntities;
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


#pragma mark - Deserialisation housekeeping

- (void)addImportedEntity:(ScCachedEntity *)entity
{
    if ([importedEntityRefs count] == 0) {
        [importedEntities removeAllObjects];
    }
    
    [importedEntities setObject:entity forKey:entity.entityId];
}


- (void)addImportedEntityRefs:(NSDictionary *)entityRefs forEntity:(ScCachedEntity *)entity
{
    if ([importedEntityRefs count] == 0) {
        [importedEntities removeAllObjects];
    }
    
    [importedEntityRefs setObject:entityRefs forKey:entity.entityId];
}


- (ScCachedEntity *)importedEntityWithId:(NSString *)entityId
{
    return [importedEntities objectForKey:entityId];
}


- (NSDictionary *)importedEntityRefsForEntity:(ScCachedEntity *)entity
{
    NSDictionary *entityRefs = [importedEntityRefs objectForKey:entity.entityId];
    [importedEntityRefs removeObjectForKey:entity.entityId];
    
    return entityRefs;
}


#pragma mark - ScServerConnectionDelegate implementation

- (void)didReceiveResponse:(NSHTTPURLResponse *)response
{
    if (response.statusCode == kHTTPStatusCodeCreated) {
        ScLogDebug(@"Entities successfully persisted");
        
        NSDate *now = [NSDate date];
        
        for (ScCachedEntity *entity in scheduledEntities) {
            entity.dateModified = now;
            entity.hashCode = [NSNumber numberWithInteger:[entity computeHashCode]];
        }
        
        [self.managedObjectContext save];
        [scheduledEntities removeAllObjects];
    }
}


- (void)finishedReceivingData:(id)data
{
    [self.managedObjectContext saveWithDictionaries:data];
}


- (void)didFailWithError:(NSError *)error
{
    ScLogError(@"Error persisting entities (entities: %@)", scheduledEntities);
}

@end
