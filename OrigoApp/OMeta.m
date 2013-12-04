//
//  OMeta.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMeta.h"

NSInteger const kAgeThresholdToddler = 1;
NSInteger const kAgeThresholdInSchool = 6;
NSInteger const kAgeThresholdTeen = 13;
NSInteger const kAgeOfConsent = 16;
NSInteger const kAgeOfMajority = 18;

NSString * const kProtocolHTTP = @"http://";
NSString * const kProtocolHTTPS = @"https://";
NSString * const kProtocolTel = @"tel://";

NSString * const kIconFileOrigo = @"10-arrows-in_black.png";
NSString * const kIconFileHousehold = @"glyphicons_020_home.png";
NSString * const kIconFileMan = @"glyphicons_003_user.png";
NSString * const kIconFileWoman = @"glyphicons_035_woman.png";
NSString * const kIconFileBoy = @"glyphicons_004_girl-as_boy.png";
NSString * const kIconFileGirl = @"glyphicons_004_girl.png";
NSString * const kIconFileInfant = @"76-baby_black.png";
NSString * const kIconFileSettings = @"14-gear.png";
NSString * const kIconFilePlus = @"05-plus.png";
NSString * const kIconFileAction = @"212-action2_centred.png";
NSString * const kIconFileLookup = @"01-magnify.png";
NSString * const kIconFilePlacePhoneCall = @"735-phone.png";
NSString * const kIconFilePlacePhoneCall_iOS6x = @"735-phone_pizazz.png";
NSString * const kIconFileSendText = @"734-chat.png";
NSString * const kIconFileSendText_iOS6x = @"734-chat_pizazz.png";
NSString * const kIconFileSendEmail = @"730-envelope.png";
NSString * const kIconFileSendEmail_iOS6x = @"730-envelope_pizazz.png";
NSString * const kIconFileLocationArrow = @"193-location-arrow.png";

NSString * const kGenderMale = @"M";
NSString * const kGenderFemale = @"F";

NSString * const kDefaultsKeyAuthInfo = @"origo.auth.info";
NSString * const kDefaultsKeyDirtyEntities = @"origo.state.dirtyEntities";
NSString * const kDefaultsKeyStringDate = @"origo.strings.date";
NSString * const kDefaultsKeyStringLanguage = @"origo.strings.language";

NSString * const kJSONKeyActivationCode = @"activationCode";
NSString * const kJSONKeyDeviceId = @"deviceId";
NSString * const kJSONKeyEmail = @"email";
NSString * const kJSONKeyEntityClass = @"entityClass";
NSString * const kJSONKeyPasswordHash = @"passwordHash";

NSString * const kInterfaceKeyActivate = @"activate";
NSString * const kInterfaceKeyActivationCode = @"activationCode";
NSString * const kInterfaceKeyAge = @"age";
NSString * const kInterfaceKeyAuthEmail = @"authEmail";
NSString * const kInterfaceKeyPassword = @"password";
NSString * const kInterfaceKeyPurpose = @"purpose";
NSString * const kInterfaceKeyResidenceName = @"residenceName";
NSString * const kInterfaceKeyRepeatPassword = @"repeatPassword";
NSString * const kInterfaceKeySignIn = @"signIn";

NSString * const kPropertyKeyAddress = @"address";
NSString * const kPropertyKeyCountry = @"country";
NSString * const kPropertyKeyDateOfBirth = @"dateOfBirth";
NSString * const kPropertyKeyDescriptionText = @"descriptionText";
NSString * const kPropertyKeyEmail = @"email";
NSString * const kPropertyKeyEntityId = @"entityId";
NSString * const kPropertyKeyFatherId = @"fatherId";
NSString * const kPropertyKeyGender = @"gender";
NSString * const kPropertyKeyHashCode = @"hashCode";
NSString * const kPropertyKeyIsAwaitingDeletion = @"isAwaitingDeletion";
NSString * const kPropertyKeyIsExpired = @"isExpired";
NSString * const kPropertyKeyIsJuvenile = @"isJuvenile";
NSString * const kPropertyKeyMobilePhone = @"mobilePhone";
NSString * const kPropertyKeyMotherId = @"motherId";
NSString * const kPropertyKeyName = @"name";
NSString * const kPropertyKeyOrigoId = @"origoId";
NSString * const kPropertyKeyPasswordHash = @"passwordHash";
NSString * const kPropertyKeyTelephone = @"telephone";

NSString * const kRelationshipKeyMember = @"member";
NSString * const kRelationshipKeyOrigo = @"origo";

static NSString * const kLanguageHungarian = @"hu";

static NSTimeInterval const kTimeInterval30Days = 2592000;
//static NSTimeInterval const kTimeInterval30Days = 30;

static CGFloat _systemVersion = 0.f;
static CGFloat _screenScale = 0.f;

static OMeta *_m = nil;


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
    return [OMeta m];
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


- (id)init
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
    if (!_m) {
        _m = [[super allocWithZone:nil] init];
    }
    
    return _m;
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
    
    ODevice *device = [self.context entityWithId:_deviceId];
    
    if (!device) {
        [self.context insertDeviceEntity];
    } else if ([device hasExpired]) {
        [device unexpire];
    }
    
    _isSignedIn = @YES;
}


- (void)userDidSignOut
{
    [self.replicator saveUserReplicationState];
    [self.replicator resetUserReplicationState];
    
    [ODefaults setUserDefault:nil forKey:kDefaultsKeyAuthExpiryDate];
    
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
    BOOL userHasAddress = NO;
    
    for (OMembership *residency in [_user residencies]) {
        userHasAddress = userHasAddress || [residency.origo.address hasValue];
    }
    
    return _user.dateOfBirth && [_user.mobilePhone hasValue] && userHasAddress;
}


#pragma mark - Convenience methods

- (BOOL)internetConnectionIsAvailable
{
    return (_internetConnectionIsWiFi || _internetConnectionIsWWAN);
}


- (BOOL)shouldUseEasternNameOrder
{
    return [_language isEqualToString:kLanguageHungarian];
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


#pragma mark - Meta information

+ (NSArray *)supportedLanguages
{
    return [[OStrings stringForKey:metaSupportedLanguages] componentsSeparatedByString:kSeparatorList];
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


- (OPhoneNumberFormatter *)phoneNumberFormatter
{
    if (!_phoneNumberFormatter) {
        _phoneNumberFormatter = [[OPhoneNumberFormatter alloc] init];
    }
    
    return _phoneNumberFormatter;
}


- (NSManagedObjectContext *)context
{
    return ((OAppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
}

@end
