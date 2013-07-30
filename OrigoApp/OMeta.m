//
//  OMeta.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMeta.h"

NSString * const kBundleId = @"com.origoapp.ios.OrigoApp";

NSString * const kGenderFemale = @"F";
NSString * const kGenderMale = @"M";

NSInteger const kAgeThresholdToddler = 1;
NSInteger const kAgeThresholdInSchool = 6;
NSInteger const kAgeThresholdTeen = 13;
NSInteger const kAgeOfConsent = 16;
NSInteger const kAgeOfMajority = 18;

NSString * const kLanguageHungarian = @"hu";

NSString * const kIconFileOrigo = @"10-arrows-in_black.png";
NSString * const kIconFileHousehold = @"glyphicons_020_home.png";
NSString * const kIconFileMan = @"glyphicons_003_user.png";
NSString * const kIconFileWoman = @"glyphicons_035_woman.png";
NSString * const kIconFileBoy = @"glyphicons_004_girl-as_boy.png";
NSString * const kIconFileGirl = @"glyphicons_004_girl.png";
NSString * const kIconFileInfant = @"76-baby_black.png";
NSString * const kIconFileLocationArrow = @"193-location-arrow.png";

NSString * const kInputKeyActivate = @"activate";
NSString * const kInputKeyActivationCode = @"activationCode";
NSString * const kInputKeyAuthEmail = @"authEmail";
NSString * const kInputKeyPassword = @"password";
NSString * const kInputKeyRepeatPassword = @"repeatPassword";
NSString * const kInputKeySignIn = @"signIn";

NSString * const kJSONKeyActivationCode = @"activationCode";
NSString * const kJSONKeyDeviceId = @"deviceId";
NSString * const kJSONKeyEmail = @"email";
NSString * const kJSONKeyEntityClass = @"entityClass";
NSString * const kJSONKeyIsListed = @"isListed";
NSString * const kJSONKeyPasswordHash = @"passwordHash";

NSString * const kPropertyKeyAddress = @"address";
NSString * const kPropertyKeyCountry = @"country";
NSString * const kPropertyKeyDateOfBirth = @"dateOfBirth";
NSString * const kPropertyKeyDescriptionText = @"descriptionText";
NSString * const kPropertyKeyEmail = @"email";
NSString * const kPropertyKeyEntityId = @"entityId";
NSString * const kPropertyKeyFatherId = @"fatherId";
NSString * const kPropertyKeyGender = @"gender";
NSString * const kPropertyKeyHashCode = @"hashCode";
NSString * const kPropertyKeyIsExpired = @"isExpired";
NSString * const kPropertyKeyIsAwaitingDeletion = @"isAwaitingDeletion";
NSString * const kPropertyKeyMobilePhone = @"mobilePhone";
NSString * const kPropertyKeyMotherId = @"motherId";
NSString * const kPropertyKeyName = @"name";
NSString * const kPropertyKeyOrigoId = @"origoId";
NSString * const kPropertyKeyPasswordHash = @"passwordHash";
NSString * const kPropertyKeyTelephone = @"telephone";

NSString * const kRelationshipKeyMember = @"member";
NSString * const kRelationshipKeyOrigo = @"origo";

NSString * const kDefaultsKeyAuthInfo = @"origo.auth.info";
NSString * const kDefaultsKeyDirtyEntities = @"origo.state.dirtyEntities";
NSString * const kDefaultsKeyStringDate = @"origo.date.strings";

static NSTimeInterval const kTimeInterval30Days = 2592000;
//static NSTimeInterval const kTimeInterval30Days = 30;

static OMeta *m = nil;


@interface OMeta ()

@property (strong, nonatomic) NSString *authToken;

@property (strong, nonatomic) OMember *user;
@property (strong, nonatomic) OReplicator *replicator;
@property (strong, nonatomic) OLocator *locator;

@property (strong, nonatomic) UIDatePicker *sharedDatePicker;

@end


@implementation OMeta

#pragma mark - Auxiliary methods

- (void)checkReachability:(Reachability *)reachability
{
    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
    
    _internetConnectionIsWiFi = (internetStatus == ReachableViaWiFi);
    _internetConnectionIsWWAN = (internetStatus == ReachableViaWWAN);
    
    if (_internetConnectionIsWiFi) {
        OLogDebug(@"Connected to the internet via Wi-Fi.");
    } else if (_internetConnectionIsWWAN) {
        OLogDebug(@"Connected to the internet via mobile web (WWAN).");
    } else {
        OLogDebug(@"Not connected to the internet.");
    }
    
    _internetReachability = reachability;
}


- (void)reachabilityDidChange:(NSNotification *)notification
{
    [self checkReachability:(Reachability *)[notification object]];
}


- (void)loadUser
{
    _user = [self.context entityWithId:_userId];
    
    if (_user) {
        [self.replicator loadUserReplicationState];
    } else {
        _user = [self.context insertMemberEntityWithId:_userId];
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
        _appVersion = [[NSBundle mainBundle] infoDictionary][(id)kCFBundleVersionKey];
        _displayLanguage = [NSLocale preferredLanguages][0];
        
        NSString *userEmail = [ODefaults globalDefaultForKey:kDefaultsKeyUserEmail];
        
        if (userEmail) {
            self.userEmail = userEmail;
        }
        
        _internetConnectionIsWiFi = NO;
        _internetConnectionIsWWAN = NO;
        
        _sharedDatePicker = [[UIDatePicker alloc] init];
        _sharedDatePicker.datePickerMode = UIDatePickerModeDate;
        
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


#pragma mark - User sign in & registration status

- (void)userDidSignIn
{
    [ODefaults setUserDefault:_authTokenExpiryDate forKey:kDefaultsKeyAuthExpiryDate];
    
    [self loadUser];
    
    if (![self.context entityWithId:_deviceId]) {
        [self.context insertDeviceEntity];
    }
}


- (void)userDidSignOut
{
    [self.replicator saveUserReplicationState];
    [self.replicator resetUserReplicationState];
    
    [ODefaults setUserDefault:nil forKey:kDefaultsKeyAuthExpiryDate];
    [ODefaults resetUser];
    
    _user = nil;
    _userId = nil;
    _locator = nil;
    _deviceId = nil;
    _authToken = nil;
    _lastReplicationDate = nil;
    
    [(OAppDelegate *)[UIApplication sharedApplication].delegate releasePersistentStore];
}


- (BOOL)userIsAllSet
{
    return [self userIsSignedIn] && [self userIsRegistered];
}


- (BOOL)userIsSignedIn
{
    if (!_authTokenExpiryDate) {
        _authTokenExpiryDate = [ODefaults userDefaultForKey:kDefaultsKeyAuthExpiryDate];
        
        if (_authTokenExpiryDate) {
            NSDate *now = [NSDate date];
            
            if ([now compare:_authTokenExpiryDate] == NSOrderedAscending) {
                _authToken = [OCrypto authTokenWithExpiryDate:_authTokenExpiryDate];
                _user = [self.context entityWithId:_userId];
            }
        }
    }
    
    return (_user != nil);
}


- (BOOL)userIsRegistered
{
    BOOL userHasDateOfBirth = [_user hasValueForKey:kPropertyKeyDateOfBirth];
    BOOL userHasMobilePhone = [_user hasValueForKey:kPropertyKeyMobilePhone];
    BOOL userHasAddress = NO;
    
    for (OMembership *residency in [_user residencies]) {
        userHasAddress = userHasAddress || [residency.origo hasValueForKey:kPropertyKeyAddress];
    }
    
    return userHasDateOfBirth && userHasMobilePhone && userHasAddress;
}


#pragma mark - Convenience methods

- (BOOL)internetConnectionIsAvailable
{
    return (_internetConnectionIsWiFi || _internetConnectionIsWWAN);
}


- (BOOL)shouldUseEasternNameOrder
{
    return [_displayLanguage isEqualToString:kLanguageHungarian];
}


- (BOOL)deviceIsSimulator
{
    return [[UIDevice currentDevice].model containsString:@"Simulator"];
}


- (NSArray *)supportedCountryCodes
{
    return [[OStrings stringForKey:metaSupportedCountryCodes] componentsSeparatedByString:kListSeparator];
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


#pragma mark - Custom accessors

- (void)setUserId:(NSString *)userId
{
    _userId = userId;
    [ODefaults setUserDefault:_userId forKey:kDefaultsKeyUserId];
    
    NSString *deviceId = [ODefaults userDefaultForKey:kDefaultsKeyDeviceId];
    NSString *lastReplicationDate = [ODefaults userDefaultForKey:kDefaultsKeyLastReplicationDate];
    
    if (deviceId) {
        _deviceId = deviceId;
    } else if (_deviceId) {
        [ODefaults setUserDefault:_deviceId forKey:kDefaultsKeyDeviceId];
    }
    
    if (lastReplicationDate) {
        _lastReplicationDate = lastReplicationDate;
    } else if (_lastReplicationDate) {
        [ODefaults setUserDefault:_lastReplicationDate forKey:kDefaultsKeyLastReplicationDate];
    }
}


- (void)setUserEmail:(NSString *)userEmail
{
    if ([[OState s] actionIs:kActionActivate] && [[OState s] targetIs:kTargetEmail]) {
        _user.email = userEmail;
        
        [ODefaults setUserDefault:nil forKey:kDefaultsKeyUserId];
        [ODefaults resetUser];
    }
    
    _userEmail = userEmail;
    [ODefaults setGlobalDefault:_userEmail forKey:kDefaultsKeyUserEmail];
    
    NSString *userId = [ODefaults userDefaultForKey:kDefaultsKeyUserId];
    
    if (userId) {
        self.userId = userId;
    } else if (_userId) {
        [ODefaults setUserDefault:_userId forKey:kDefaultsKeyUserId];
    }
}


- (void)setLastReplicationDate:(NSString *)lastReplicationDate
{
    _lastReplicationDate = lastReplicationDate;
    
    [ODefaults setUserDefault:_lastReplicationDate forKey:kDefaultsKeyLastReplicationDate];
}


- (NSString *)deviceId
{
    if (!_deviceId) {
        _deviceId = [OCrypto generateUUID];
    }
    
    return _deviceId;
}


- (NSString *)authToken
{
    if (!_authToken) {
        _authTokenExpiryDate = [NSDate dateWithTimeIntervalSinceNow:kTimeInterval30Days];
        _authToken = [OCrypto authTokenWithExpiryDate:_authTokenExpiryDate];
    }
    
    return _authToken;
}


- (OSettings *)settings
{
    return self.user.settings;
}


- (OReplicator *)replicator
{
    if (!_replicator) {
        _replicator = [[OReplicator alloc] init];
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


- (UIDatePicker *)sharedDatePicker
{
    _sharedDatePicker.date = [NSDate defaultDate];
    
    return _sharedDatePicker;
}


- (NSManagedObjectContext *)context
{
    return ((OAppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
}

@end
