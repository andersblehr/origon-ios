//
//  ScMeta.m
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScMeta.h"

#import "Reachability.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "NSString+ScStringExtensions.h"

#import "ScAppDelegate.h"
#import "ScCachedEntity+ScCachedEntityExtensions.h"
#import "ScLogging.h"
#import "ScServerConnection.h"
#import "ScStrings.h"
#import "ScUUIDGenerator.h"

#import "ScCachedEntity.h"

NSString * const kBundleId = @"com.scolaapp.ios.ScolaApp";
NSString * const kDarkLinenImageFile = @"dark_linen-640x960.png";

NSString * const kMemberViewControllerId = @"vcMember";
NSString * const kMembershipViewControllerId = @"vcMembership";
NSString * const kScolaViewControllerId = @"vcScola";

NSString * const kPropertyEntityId = @"entityId";
NSString * const kPropertyEntityClass = @"entityClass";
NSString * const kPropertyScolaId = @"scolaId";
NSString * const kPropertyName = @"name";
NSString * const kPropertyDateOfBirth = @"dateOfBirth";
NSString * const kPropertyMobilePhone = @"mobilePhone";
NSString * const kPropertyGender = @"gender";
NSString * const kPropertyDidRegister = @"didRegister";

NSString * const kGenderFemale = @"F";
NSString * const kGenderMale = @"M";
NSString * const kGenderNoneGiven = @"N";

NSString * const kLanguageHungarian = @"hu";

static NSInteger const kMinimumPassordLength = 6;

static NSString * const kUserDefaultsKeyUserId = @"scola.user.id";
static NSString * const kUserDefaultsKeyFormatHomeScolaId = @"scola.scola.id$%@";
static NSString * const kUserDefaultsKeyFormatDeviceId = @"scola.device.id$%@";
static NSString * const kUserDefaultsKeyFormatAuthExpiryDate = @"scola.auth.expires$%@";
static NSString * const kUserDefaultsKeyFormatLastFetchDate = @"scola.fetch.date$%@";

//static NSTimeInterval const kTimeIntervalTwoWeeks = 1209600;
static NSTimeInterval const kTimeIntervalTwoWeeks = 30;

static ScMeta *m = nil;


@implementation ScMeta

@synthesize appState;
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
    
    if (isInternetConnectionWiFi) {
        ScLogInfo(@"Connected to the internet via Wi-Fi.");
    } else if (isInternetConnectionWWAN) {
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
            deviceId = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatDeviceId, userId]];
            authTokenExpiryDate = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthExpiryDate, userId]];
            lastFetchDate = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatLastFetchDate, userId]];
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


#pragma mark - Alerting shortcuts

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
{
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil] show];
}


+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message tag:(NSInteger)tag delegate:(id)delegate
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:delegate cancelButtonTitle:[ScStrings stringForKey:strOK] otherButtonTitles:nil];
    alert.tag = tag;
    
    [alert show];
}


#pragma mark - NSUserDefaults convenience accessors

+ (void)setUserDefault:(id)object forKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


+ (id)userDefaultForKey:(NSString *)key
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}


+ (void)removeUserDefaultForKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - Input validation

+ (BOOL)isEmailValid:(UITextField *)emailField
{
    return [ScMeta isEmailValid:emailField silent:NO];
}


+ (BOOL)isEmailValid:(UITextField *)emailField silent:(BOOL)silent
{
    NSString *email = [emailField.text removeLeadingAndTrailingSpaces];
    
    NSUInteger atLocation = [email rangeOfString:@"@"].location;
    NSUInteger dotLocation = [email rangeOfString:@"." options:NSBackwardsSearch].location;
    NSUInteger spaceLocation = [email rangeOfString:@" "].location;
    
    BOOL isValid = (atLocation != NSNotFound);
    
    isValid = isValid && (dotLocation != NSNotFound);
    isValid = isValid && (dotLocation > atLocation);
    isValid = isValid && (spaceLocation == NSNotFound);
    
    if (!isValid && !silent) {
        [emailField becomeFirstResponder];
        
        [ScMeta showAlertWithTitle:[ScStrings stringForKey:strInvalidEmailTitle] message:[ScStrings stringForKey:strInvalidEmailAlert]];
    }
    
    return isValid;
}


+ (BOOL)isPasswordValid:(UITextField *)passwordField
{
    NSString *password = [passwordField.text removeLeadingAndTrailingSpaces];
    
    BOOL isValid = (password.length >= kMinimumPassordLength);
    
    if (!isValid) {
        [passwordField becomeFirstResponder];
        
        [ScMeta showAlertWithTitle:[ScStrings stringForKey:strInvalidPasswordTitle] message:[NSString stringWithFormat:[ScStrings stringForKey:strInvalidPasswordAlert], kMinimumPassordLength]];
    }
    
    return isValid;
}


+ (BOOL)isNameValid:(UITextField *)nameField
{
    NSString *name = [nameField.text removeLeadingAndTrailingSpaces];
    
    BOOL isValid = (name.length > 0);
    
    if (isValid) {
        NSUInteger spaceLocation = [name rangeOfString:@" "].location;
        
        isValid = isValid && (spaceLocation > 0);
        isValid = isValid && (spaceLocation < name.length - 1);
    }
    
    if (!isValid) {
        [nameField becomeFirstResponder];
        
        [ScMeta showAlertWithTitle:[ScStrings stringForKey:strInvalidNameTitle] message:[ScStrings stringForKey:strInvalidNameAlert]];
    }
    
    return isValid;
}


+ (BOOL)isMobileNumberValid:(UITextField *)mobileNumberField
{
    NSString *mobileNumber = [mobileNumberField.text removeLeadingAndTrailingSpaces];
    
    BOOL isValid = (mobileNumber.length > 0);
    
    if (!isValid) {
        [mobileNumberField becomeFirstResponder];
        
        [ScMeta showAlertWithTitle:[ScStrings stringForKey:strNoMobileNumberTitle] message:[ScStrings stringForKey:strNoMobileNumberAlert]];
    }
    
    return isValid;
}


+ (BOOL)isDateOfBirthValid:(UITextField *)dateField
{
    BOOL isValid = (dateField.text.length > 0);
    
    if (!isValid) {
        [ScMeta showAlertWithTitle:[ScStrings stringForKey:strInvalidDateOfBirthTitle] message:[ScStrings stringForKey:strInvalidDateOfBirthAlert]];
    }
    
    return isValid;
}


#pragma mark - Accessors

- (void)setIsUserLoggedIn:(BOOL)isLoggedIn
{
    [(ScAppDelegate *)[[UIApplication sharedApplication] delegate] releasePersistentStore];
    
    if (isLoggedIn) {
        [ScMeta setUserDefault:authTokenExpiryDate forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthExpiryDate, userId]];
    } else {
        self.userId = nil;
    }
}


- (BOOL)isUserLoggedIn
{
    if (!authToken && authTokenExpiryDate) {
        NSDate *now = [NSDate date];
        
        if ([now compare:authTokenExpiryDate] == NSOrderedAscending) {
            authToken = [self generateAuthToken:authTokenExpiryDate];
        }
    }
    
    return (authToken != nil);
}


- (void)setUserId:(NSString *)userIdentity
{
    userId = userIdentity;
    
    if (userId) {
        [ScMeta setUserDefault:userId forKey:kUserDefaultsKeyUserId];

        NSString *persistedDeviceId = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatDeviceId, userId]];
        lastFetchDate = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatLastFetchDate, userId]];
        
        if (persistedDeviceId) {
            deviceId = persistedDeviceId;
        } else {
            [ScMeta setUserDefault:deviceId forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatDeviceId, userId]];
        }
    } else {
        [ScMeta removeUserDefaultForKey:kUserDefaultsKeyUserId];
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


- (NSString *)authToken
{
    if (!authToken && ![self isUserLoggedIn]) {
        authTokenExpiryDate = [NSDate dateWithTimeIntervalSinceNow:kTimeIntervalTwoWeeks];
        authToken = [self generateAuthToken:authTokenExpiryDate];
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
        ScLogWarning(@"Could not start reachability notifier, checking internet connectivity only at startup.");
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

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    
    if (data) {
        [context saveWithDictionaries:data];
    }

    if ((response.statusCode == kHTTPStatusCodeCreated) ||
        (response.statusCode == kHTTPStatusCodeMultiStatus)) {
        ScLogDebug(@"Entities successfully persisted");
        
        NSDate *now = [NSDate date];
        
        for (ScCachedEntity *entity in scheduledEntities) {
            entity.dateModified = now;
            entity.hashCode = [NSNumber numberWithInteger:[entity computeHashCode]];
        }
        
        [context save];
        [scheduledEntities removeAllObjects];
    }
}


- (void)didFailWithError:(NSError *)error
{
    ScLogError(@"Error synchronising entities.");
}

@end
