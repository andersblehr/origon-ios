//
//  OMeta.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OMeta.h"

static NSString * const kLocalisedProject = @"lproj";
static NSTimeInterval const kTimeInterval30Days = 2592000;
//static NSTimeInterval const kTimeInterval30Days = 30;

static CGFloat _systemVersion = 0.f;
static CGFloat _screenScale = 0.f;


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
        _user = [OMember instanceWithId:_userId];
        _user.email = _userEmail;
    }
}


- (void)reset
{
    [ODefaults resetUser];
    
    _user = nil;
    _userId = nil;
    _locator = nil;
    _deviceId = nil;
    _authToken = nil;
    _authTokenExpiryDate = nil;
    _lastReplicationDate = nil;
    _userDidJustSignUp = NO;
    _isSignedIn = @NO;
    
    [(OAppDelegate *)[UIApplication sharedApplication].delegate releasePersistentStore];
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
        _systemVersion = [[UIDevice currentDevice].systemVersion floatValue];
        _appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        _appVersion = [[NSBundle mainBundle] infoDictionary][(id)kCFBundleVersionKey];
        _language = [NSLocale preferredLanguages][0];
        
        if ([ODefaults globalDefaultForKey:kDefaultsKeyUserEmail]) {
            self.userEmail = [ODefaults globalDefaultForKey:kDefaultsKeyUserEmail];
        }
        
        _internetConnectionIsWiFi = NO;
        _internetConnectionIsWWAN = NO;
        
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


#pragma mark - User sign in & registration status

- (void)userDidSignUp
{
    _userDidJustSignUp = YES;
}


- (void)userDidSignIn
{
    [ODefaults setUserDefault:_authTokenExpiryDate forKey:kDefaultsKeyAuthExpiryDate];
    
    [self loadUser];
    
    ODevice *device = [ODevice device];
    
    if ([device hasExpired]) {
        [device unexpire];
    }
    
    _isSignedIn = @YES;
}


- (void)userDidSignOut
{
    [self.replicator saveUserReplicationState];
    [self.replicator resetUserReplicationState];
    
    [ODefaults removeUserDefaultForKey:kDefaultsKeyAuthExpiryDate];
    
    [self reset];
}


- (BOOL)userIsAllSet
{
    return [self userIsSignedIn] && [self userIsRegistered];
}


- (BOOL)userIsSignedIn
{
    if (!_isSignedIn) {
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
            _isSignedIn = @YES;
        } else {
            [self reset];
        }
    }
    
    return [_isSignedIn boolValue];
}


- (BOOL)userIsRegistered
{
    return _user.dateOfBirth && [_user.mobilePhone hasValue] && [_user hasAddress];
}


#pragma mark - Convenience methods

- (BOOL)internetConnectionIsAvailable
{
    return (_internetConnectionIsWiFi || _internetConnectionIsWWAN);
}


+ (BOOL)usingEasternNameOrder
{
    return [[self m].language isEqualToString:kLanguageCodeHungarian];
}


+ (BOOL)deviceIsSimulator
{
    return [[UIDevice currentDevice].model containsString:@"Simulator"];
}


+ (BOOL)systemIs_iOS6x
{
    if (!_systemVersion) {
        _systemVersion = [[UIDevice currentDevice].systemVersion floatValue];
    }
    
    return (_systemVersion < 7.f);
}


+ (BOOL)screenIsRetina
{
    if (!_screenScale) {
        _screenScale = [UIScreen mainScreen].scale;
    }
    
    return (_screenScale >= 2.f);
}


#pragma mark - Localisation support

- (NSBundle *)localisedStringsBundle
{
    if (!_localisedStringsBundle) {
        _localisedStringsBundle = [NSBundle mainBundle];
        
        if (![_localisedStringsBundle pathForResource:[[self class] m].language ofType:kLocalisedProject]) {
            NSString *testString = [_localisedStringsBundle localizedStringForKey:@"String test" value:@"" table:nil];
            
            if ([testString isEqualToString:@"String test"] || [OSettings settings].useEnglish) {
                _localisedStringsBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:kLanguageCodeEnglish ofType:kLocalisedProject]];
            }
        }
    }
    
    return _localisedStringsBundle;
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


- (NSString *)authToken
{
    if (!_authToken) {
        _authTokenExpiryDate = [NSDate dateWithTimeIntervalSinceNow:kTimeInterval30Days];
        _authToken = [OCrypto authTokenWithExpiryDate:_authTokenExpiryDate];
    }
    
    return _authToken;
}


- (OLocator *)locator
{
    if (!_locator) {
        _locator = [[OLocator alloc] init];
    }
    
    return _locator;
}


- (OReplicator *)replicator
{
    if (!_replicator) {
        _replicator = [[OReplicator alloc] init];
    }
    
    return _replicator;
}


- (OSwitchboard *)switchboard
{
    if (!_switchboard) {
        _switchboard = [[OSwitchboard alloc] init];
    }
    
    return _switchboard;
}


- (NSManagedObjectContext *)context
{
    return ((OAppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
}

@end
