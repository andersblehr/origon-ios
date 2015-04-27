//
//  OMeta.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OMeta.h"

static NSString * const kLocalisationTest = @"Localisation test";

static NSTimeInterval const kTimeInterval30Days = 2592000;
//static NSTimeInterval const kTimeInterval30Days = 30;


@interface OMeta () {
@private
    NSBundle *_localisedStringsBundle;
    
    OReplicator *_replicator;
    OActivityIndicator *_activityIndicator;
    
    NSNumber *_isLoggedIn;
    NSString *_authToken;
    NSDate *_authTokenExpiryDate;
}

@end


@implementation OMeta

#pragma mark - Auxiliary methods

- (void)checkReachability:(Reachability *)reachability
{
    NetworkStatus reachabilityStatus = [reachability currentReachabilityStatus];
    
    BOOL internetConnectionIsWiFi = reachabilityStatus == ReachableViaWiFi;
    BOOL internetConnectionIsWWAN = reachabilityStatus == ReachableViaWWAN;
    
    if (internetConnectionIsWiFi) {
        OLogDebug(@"Connected to the internet via Wi-Fi.");
    } else if (internetConnectionIsWWAN) {
        OLogDebug(@"Connected to the internet via mobile web (WWAN).");
    } else {
        OLogDebug(@"Not connected to the internet.");
    }
    
    _internetReachability = reachability;
    _hasInternetConnection = internetConnectionIsWiFi || internetConnectionIsWWAN;
}


- (void)loadUser
{
    _user = [self.context entityWithId:_userId];
    
    if (_user) {
        [self.replicator loadUserReplicationState];
    } else {
        _user = [OMember instanceWithId:_userId];
        _user.email = _userEmail;
    }
    
    if ([self userIsRegistered] && ![_user isActive]) {
        [_user makeActive];
    }
}


- (void)reset
{
    [ODefaults resetUser];
    
    _user = nil;
    _userId = nil;
    _deviceId = nil;
    _authToken = nil;
    _authTokenExpiryDate = nil;
    _lastReplicationDate = nil;
    _userDidJustRegister = NO;
    _isLoggedIn = @NO;
    
    [self.appDelegate releasePersistentStore];
    [OEntityProxy clearCachedProxies];
    [OMember clearCachedPeers];
}


#pragma mark - Selector implementations

- (void)reachabilityDidChange:(NSNotification *)notification
{
    [self checkReachability:[notification object]];
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


- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        _appVersion = [[NSBundle mainBundle] infoDictionary][(id)kCFBundleVersionKey];
        _language = [NSLocale preferredLanguages][0];
        _carrier = [[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider];
        _hasInternetConnection = NO;
        
        if ([ODefaults globalDefaultForKey:kDefaultsKeyUserEmail]) {
            self.userEmail = [ODefaults globalDefaultForKey:kDefaultsKeyUserEmail];
        }
        
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
    static OMeta *meta = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        meta = [[super allocWithZone:nil] init];
    });
    
    return meta;
}


#pragma mark - User login & registration status

- (void)userDidRegister
{
    _userDidJustRegister = YES;
}


- (void)userDidLogin
{
    [ODefaults setUserDefault:_authTokenExpiryDate forKey:kDefaultsKeyAuthExpiryDate];
    
    [self loadUser];
    
    _isLoggedIn = @YES;
}


- (void)logout
{
    [self.replicator saveUserReplicationState];
    [self.replicator resetUserReplicationState];
    
    [ODefaults removeUserDefaultForKey:kDefaultsKeyAuthExpiryDate];
    
    [self reset];
    
    if ([[OState s].viewController respondsToSelector:@selector(didLogout)]) {
        [[OState s].viewController didLogout];
    }
}


- (BOOL)userIsAllSet
{
    return [self userIsLoggedIn] && [self userIsRegistered];
}


- (BOOL)userIsLoggedIn
{
    if (!_isLoggedIn) {
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

        if (_user) {
            _isLoggedIn = @YES;
        } else {
            [self reset];
        }
    }
    
    return [_isLoggedIn boolValue];
}


- (BOOL)userIsRegistered
{
    return _user.dateOfBirth && [_user.mobilePhone hasValue] && [_user hasAddress];
}


#pragma mark - Convenience methods

+ (BOOL)deviceIsSimulator
{
    return [[UIDevice currentDevice].model containsString:@"Simulator"];
}


+ (BOOL)iOSVersionIs:(NSString *)majorVersionNumber
{
    return [[UIDevice currentDevice].systemVersion hasPrefix:majorVersionNumber];
}


+ (CGSize)screenSize
{
    return [UIScreen mainScreen].applicationFrame.size;
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
        
        [ODefaults removeUserDefaultForKey:kDefaultsKeyUserId];
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


- (void)setSettings:(NSString *)settings
{
    _user.settings = settings;
}


- (NSString *)settings
{
    return _user.settings;
}


- (NSString *)authToken
{
    if (!_authToken) {
        _authTokenExpiryDate = [NSDate dateWithTimeIntervalSinceNow:kTimeInterval30Days];
        _authToken = [OCrypto authTokenWithExpiryDate:_authTokenExpiryDate];
    }
    
    return _authToken;
}


- (NSBundle *)localisedStringsBundle
{
    if (!_localisedStringsBundle) {
        _localisedStringsBundle = [NSBundle mainBundle];
        
        if (![_localisedStringsBundle pathForResource:_language ofType:@"lproj"]) {
            NSString *testString = [_localisedStringsBundle localizedStringForKey:kLocalisationTest value:@"" table:nil];
            
            if ([testString isEqualToString:kLocalisationTest]) {
                _localisedStringsBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:kLanguageCodeEnglish ofType:@"lproj"]];
            }
        }
    }
    
    return _localisedStringsBundle;
}


- (OReplicator *)replicator
{
    if (!_replicator) {
        _replicator = [[OReplicator alloc] init];
    }
    
    return _replicator;
}


- (OActivityIndicator *)activityIndicator
{
    if (!_activityIndicator) {
        _activityIndicator = [[OActivityIndicator alloc] init];
    }
    
    return _activityIndicator;
}


- (OAppDelegate *)appDelegate
{
    return (OAppDelegate *)[UIApplication sharedApplication].delegate;
}


- (NSManagedObjectContext *)context
{
    return self.appDelegate.managedObjectContext;
}

@end
