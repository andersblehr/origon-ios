//
//  OMeta.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMeta.h"

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#import "NSManagedObjectContext+OrigoExtensions.h"
#import "NSString+OrigoExtensions.h"
#import "UIDatePicker+OrigoExtensions.h"

#import "OAppDelegate.h"
#import "OEntityReplicator.h"
#import "OLocator.h"
#import "OLogging.h"
#import "OState.h"
#import "OStrings.h"
#import "OUtil.h"
#import "OUUIDGenerator.h"

#import "OMember+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"
#import "OSettings.h"

NSString * const kBundleId = @"com.origoapp.ios.OrigoApp";

NSString * const kGenderFemale = @"F";
NSString * const kGenderMale = @"M";

NSUInteger const kAgeThresholdToddler = 2;
NSUInteger const kAgeThresholdInSchool = 7;
NSUInteger const kAgeThresholdTeen = 13;
NSUInteger const kAgeThresholdMajority = 18;

NSString * const kLanguageHungarian = @"hu";

NSString * const kIconFileOrigo = @"10-arrows-in_black.png";
NSString * const kIconFileHousehold = @"glyphicons_020_home.png";
NSString * const kIconFileMan = @"glyphicons_003_user.png";
NSString * const kIconFileWoman = @"glyphicons_035_woman.png";
NSString * const kIconFileBoy = @"glyphicons_004_girl-as_boy.png";
NSString * const kIconFileGirl = @"glyphicons_004_girl.png";
NSString * const kIconFileInfant = @"76-baby_black.png";
NSString * const kIconFileLocationArrow = @"193-location-arrow.png";

NSString * const kDatePropertyPrefix = @"date";

NSString * const kInputKeyActivate = @"activate";
NSString * const kInputKeyActivationCode = @"activationCode";
NSString * const kInputKeyAuthEmail = @"authEmail";
NSString * const kInputKeyPassword = @"password";
NSString * const kInputKeyRepeatPassword = @"repeatPassword";
NSString * const kInputKeySignIn = @"signIn";

NSString * const kJSONKeyEntityClass = @"entityClass";
NSString * const kJSONKeyIsListed = @"isListed";
NSString * const kJSONKeyPasswordHash = @"passwordHash";

NSString * const kPropertyKeyAddress = @"address";
NSString * const kPropertyKeyCountry = @"country";
NSString * const kPropertyKeyDateOfBirth = @"dateOfBirth";
NSString * const kPropertyKeyEmail = @"email";
NSString * const kPropertyKeyEntityId = @"entityId";
NSString * const kPropertyKeyHashCode = @"hashCode";
NSString * const kPropertyKeyIsExpired = @"isExpired";
NSString * const kPropertyKeyIsAwaitingDeletion = @"isAwaitingDeletion";
NSString * const kPropertyKeyMobilePhone = @"mobilePhone";
NSString * const kPropertyKeyName = @"name";
NSString * const kPropertyKeyOrigoId = @"origoId";
NSString * const kPropertyKeyTelephone = @"telephone";

NSString * const kRelationshipKeyMember = @"member";
NSString * const kRelationshipKeyOrigo = @"origo";

NSString * const kDefaultsKeyAuthInfo = @"origo.auth.info";
NSString * const kDefaultsKeyDirtyEntities = @"origo.state.dirtyEntities";
NSString * const kDefaultsKeyPasswordHash = @"origo.auth.passwordHash";
NSString * const kDefaultsKeyRegistrationAborted = @"origo.flags.registrationAborted";
NSString * const kDefaultsKeyStringDate = @"origo.date.strings";

static NSString * const kDefaultsKeyAuthExpiryDate = @"origo.date.authExpiry";
static NSString * const kDefaultsKeyDeviceId = @"origo.id.device";
static NSString * const kDefaultsKeyUserEmail = @"origo.user.email";
static NSString * const kDefaultsKeyLastReplicationDate = @"origo.date.lastReplication";
static NSString * const kDefaultsKeyUserId = @"origo.id.user";

static NSTimeInterval const kTimeInterval30Days = 2592000;
//static NSTimeInterval const kTimeInterval30Days = 30;

static OMeta *m = nil;


@interface OMeta ()

@property (strong, nonatomic) OMember *user;
@property (strong, nonatomic) OEntityReplicator *replicator;
@property (strong, nonatomic) OLocator *locator;

@property (nonatomic) BOOL userIsAllSet;
@property (nonatomic) BOOL userIsSignedIn;
@property (nonatomic) BOOL userIsRegistered;

@property (strong, nonatomic) NSString *authToken;

@end


@implementation OMeta

#pragma mark - Auxiliary methods

- (NSString *)qualifiedUserDefaultKeyForKey:(NSString *)key
{
    NSString *qualifier = [key isEqualToString:kDefaultsKeyUserId] ? _userEmail : _userId;
    
    return [NSString stringWithFormat:@"%@$%@", key, qualifier];
}


- (void)checkReachability:(Reachability *)reachability
{
    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
    
    _internetConnectionIsWiFi = (internetStatus == ReachableViaWiFi);
    _internetConnectionIsWWAN = (internetStatus == ReachableViaWWAN);
    
    if (_internetConnectionIsWiFi) {
        OLogInfo(@"Connected to the internet via Wi-Fi.");
    } else if (_internetConnectionIsWWAN) {
        OLogInfo(@"Connected to the internet via mobile web (WWAN).");
    } else {
        OLogInfo(@"Not connected to the internet.");
    }
    
    _internetReachability = reachability;
}


- (void)reachabilityDidChange:(NSNotification *)notification
{
    [self checkReachability:(Reachability *)[notification object]];
}


- (NSString *)generateAuthToken:(NSDate *)expiryDate
{
    NSString *expiryDateAsString = expiryDate.description;
    NSString *rawToken = [self.deviceId seasonWith:expiryDateAsString];
    
    return [rawToken hashUsingSHA1];
}


- (void)loadUser
{
    _user = [self.context entityWithId:_userId];
    
    if (_user) {
        [self.replicator loadUserReplicationState];
    } else {
        _user = [self.context insertMemberEntity];
        _user.email = _userEmail;
    }
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
        _userEmail = [self globalDefaultForKey:kDefaultsKeyUserEmail];
        _appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey];
        _displayLanguage = [NSLocale preferredLanguages][0];
        
        if (_userEmail) {
            _userId = [self userDefaultForKey:kDefaultsKeyUserId];
            _deviceId = [self userDefaultForKey:kDefaultsKeyDeviceId];
            _lastReplicationDate = [self userDefaultForKey:kDefaultsKeyLastReplicationDate];
        } else {
            _deviceId = [OUUIDGenerator generateUUID];
        }
        
        _internetConnectionIsWiFi = NO;
        _internetConnectionIsWWAN = NO;
        _deviceIsSimulator = [[UIDevice currentDevice].model containsString:@"Simulator"];
        
        _sharedDatePicker = [[UIDatePicker alloc] init];
        _sharedDatePicker.datePickerMode = UIDatePickerModeDate;
        [_sharedDatePicker setEarliestValidBirthDate];
        [_sharedDatePicker setLatestValidBirthDate];
        [_sharedDatePicker setToDefaultDate];
        
        [self checkReachability:[Reachability reachabilityForInternetConnection]];
        
        if ([_internetReachability startNotifier]) {
            OLogDebug(@"Reachability notifier is running.");
        } else {
            OLogWarning(@"Could not start reachability notifier, checking internet connectivity only at startup.");
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    }
    
    return self;
}


+ (OMeta *)m
{
    if (!m) {
        m = [[super allocWithZone:nil] init];
    }
    
    return m;
}


#pragma mark - User sign in & sign out

- (void)userDidSignIn
{
    [self setUserDefault:_authTokenExpiryDate forKey:kDefaultsKeyAuthExpiryDate];
    [self loadUser];
    
    if (![self.context entityWithId:_deviceId]) {
        [self.context insertDeviceEntity];
    }
}


- (void)userDidSignOut
{
    [self.replicator saveUserReplicationState];
    [self.replicator resetUserReplicationState];
    
    [self setUserDefault:nil forKey:kDefaultsKeyAuthExpiryDate];
    
    _userId = nil;
    _user = nil;
    _locator = nil;
    _authToken = nil;
    _deviceId = nil;
    _lastReplicationDate = nil;
    
    [(OAppDelegate *)[UIApplication sharedApplication].delegate releasePersistentStore];
}


#pragma mark - User defaults convenience methods

- (void)setGlobalDefault:(id)globalDefault forKey:(NSString *)key
{
    if (globalDefault) {
        [[NSUserDefaults standardUserDefaults] setObject:globalDefault forKey:key];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}


- (void)setUserDefault:(id)userDefault forKey:(NSString *)key
{
    [self setGlobalDefault:userDefault forKey:[self qualifiedUserDefaultKeyForKey:key]];
}


- (id)globalDefaultForKey:(NSString *)key
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}


- (id)userDefaultForKey:(NSString *)key
{
    return [self globalDefaultForKey:[self qualifiedUserDefaultKeyForKey:key]];
}


#pragma mark - Custom accessors

- (void)setUserId:(NSString *)userId
{
    _userId = userId;
    
    [self setUserDefault:_userId forKey:kDefaultsKeyUserId];
    
    NSString *deviceId = [self userDefaultForKey:kDefaultsKeyDeviceId];
    NSString *lastReplicationDate = [self userDefaultForKey:kDefaultsKeyLastReplicationDate];
    
    if (deviceId) {
        _deviceId = deviceId;
    } else if (_deviceId) {
        [self setUserDefault:_deviceId forKey:kDefaultsKeyDeviceId];
    }
    
    if (lastReplicationDate) {
        _lastReplicationDate = lastReplicationDate;
    } else if (_lastReplicationDate) {
        [self setUserDefault:_lastReplicationDate forKey:kDefaultsKeyLastReplicationDate];
    }
}


- (void)setLastReplicationDate:(NSString *)lastReplicationDate
{
    _lastReplicationDate = lastReplicationDate;
    
    [self setUserDefault:_lastReplicationDate forKey:kDefaultsKeyLastReplicationDate];
}


- (void)setUserEmail:(NSString *)userEmail
{
    _userEmail = userEmail;
    
    if (_userEmail) {
        [self setGlobalDefault:_userEmail forKey:kDefaultsKeyUserEmail];

        NSString *userId = [self userDefaultForKey:kDefaultsKeyUserId];
        
        if (userId) {
            self.userId = userId;
        } else if (_userId) {
            [self setUserDefault:_userId forKey:kDefaultsKeyUserId];
        } else if (!_deviceId) {
            _deviceId = [OUUIDGenerator generateUUID];
        }
    } else {
        [self setGlobalDefault:nil forKey:kDefaultsKeyUserEmail];
    }
}


- (OEntityReplicator *)replicator
{
    if (!_replicator) {
        _replicator = [[OEntityReplicator alloc] init];
    }
    
    return _replicator;
}


- (OLocator *)locator
{
    if (!_locator) {
        _locator = [[OLocator alloc] init];
    }
    
    return _locator;
}


- (OSettings *)settings
{
    return self.user.settings;
}


- (NSString *)authToken
{
    if (!_authToken) {
        _authTokenExpiryDate = [NSDate dateWithTimeIntervalSinceNow:kTimeInterval30Days];
        _authToken = [self generateAuthToken:_authTokenExpiryDate];
    }
    
    return _authToken;
}


- (NSString *)inferredCountryCode
{
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    NSString *inferredCountryCode = [networkInfo subscriberCellularProvider].isoCountryCode;
    
    if (!inferredCountryCode) {
        inferredCountryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    }
    
    return inferredCountryCode;
}


- (BOOL)userIsAllSet
{
    return (self.userIsSignedIn && self.userIsRegistered);
}


- (BOOL)userIsSignedIn
{
    if (!_user) {
        _authTokenExpiryDate = [self userDefaultForKey:kDefaultsKeyAuthExpiryDate];
        
        if (_authTokenExpiryDate) {
            NSDate *now = [NSDate date];
            
            if ([now compare:_authTokenExpiryDate] == NSOrderedAscending) {
                _authToken = [self generateAuthToken:_authTokenExpiryDate];
                _user = [self.context entityWithId:_userId];
            }
        }
    }
    
    return (_user != nil);
}


- (BOOL)userIsRegistered
{
    return ([_user hasValueForKey:kPropertyKeyMobilePhone] && [_user hasAddress]);
}


- (BOOL)internetConnectionIsAvailable
{
    return (_internetConnectionIsWiFi || _internetConnectionIsWWAN);
}


- (BOOL)shouldUseEasternNameOrder
{
    return [_displayLanguage isEqualToString:kLanguageHungarian];
}


- (NSArray *)supportedCountryCodes
{
    NSMutableDictionary *codesByCountry = [[NSMutableDictionary alloc] init];
    NSArray *countryCodes = [[OStrings stringForKey:metaSupportedCountryCodes] componentsSeparatedByString:kListSeparator];
    
    for (NSString *countryCode in countryCodes) {
        [codesByCountry setObject:countryCode forKey:[OUtil countryFromCountryCode:countryCode]];
    }
    
    NSMutableArray *supportedCountryCodesSortedByCountry = [[NSMutableArray alloc] init];
    NSArray *sortedCountries = [codesByCountry keysSortedByValueUsingSelector:@selector(localizedCompare:)];
    
    for (NSString *country in sortedCountries) {
        [supportedCountryCodesSortedByCountry addObject:[codesByCountry objectForKey:country]];
    }
    
    return supportedCountryCodesSortedByCountry;
}


- (NSManagedObjectContext *)context
{
    return ((OAppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
}

@end
