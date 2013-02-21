//
//  OMeta.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMeta.h"

#import "NSManagedObjectContext+OrigoExtensions.h"
#import "NSString+OrigoExtensions.h"
#import "UIDatePicker+OrigoExtensions.h"

#import "OAppDelegate.h"
#import "OState.h"
#import "OLogging.h"
#import "OServerConnection.h"
#import "OStrings.h"
#import "OUUIDGenerator.h"

#import "OMember+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"

#import "OOrigoListViewController.h"
#import "OTabBarController.h"

NSString * const kGenderFemale = @"F";
NSString * const kGenderMale = @"M";

NSUInteger const kToddlerThreshold = 2;
NSUInteger const kCertainSchoolAge = 7;
NSUInteger const kTeenThreshold = 13;
NSUInteger const kAgeOfMajority = 18;

NSString * const kBundleId = @"com.origoapp.ios.OrigoApp";
NSString * const kLanguageHungarian = @"hu";

NSString * const kAuthViewControllerId = @"idAuthViewController";
NSString * const kTabBarControllerId = @"idTabBarController";
NSString * const kOrigoListViewControllerId = @"idOrigoListViewController";
NSString * const kOrigoViewControllerId = @"idOrigoViewController";
NSString * const kMemberViewControllerId = @"idMemberViewController";
NSString * const kMemberListViewControllerId = @"idMemberListViewController";

NSString * const kIconFileOrigo = @"10-arrows-in_black.png";
NSString * const kIconFileHousehold = @"glyphicons_020_home.png";
NSString * const kIconFileMan = @"glyphicons_003_user.png";
NSString * const kIconFileWoman = @"glyphicons_035_woman.png";
NSString * const kIconFileBoy = @"glyphicons_004_girl-as_boy.png";
NSString * const kIconFileGirl = @"glyphicons_004_girl.png";
NSString * const kIconFileInfant = @"76-baby_black.png";

NSString * const kPrefixDateProperty = @"date";
NSString * const kPrefixOrigoType = @"origoType";

NSString * const kOrigoTypeMemberRoot = @"origoTypeMemberRoot";
NSString * const kOrigoTypeResidence = @"origoTypeResidence";
NSString * const kOrigoTypeOrganisation = @"origoTypeOrganisation";
NSString * const kOrigoTypeSchoolClass = @"origoTypeSchoolClass";
NSString * const kOrigoTypePreschoolClass = @"origoTypePreschoolClass";
NSString * const kOrigoTypeSportsTeam = @"origoTypeSportsTeam";
NSString * const kOrigoTypeOther = @"origoTypeDefault";

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
NSString * const kPropertyKeyDateOfBirth = @"dateOfBirth";
NSString * const kPropertyKeyEmail = @"email";
NSString * const kPropertyKeyEntityId = @"entityId";
NSString * const kPropertyKeyIsGhost = @"isGhost";
NSString * const kPropertyKeyMobilePhone = @"mobilePhone";
NSString * const kPropertyKeyName = @"name";
NSString * const kPropertyKeyOrigo = @"origo";
NSString * const kPropertyKeyOrigoId = @"origoId";
NSString * const kPropertyKeyTelephone = @"telephone";

NSString * const kDefaultsKeyAuthInfo = @"origo.auth.info";
NSString * const kDefaultsKeyDirtyEntities = @"origo.dirtyEntities";
NSString * const kDefaultsKeyStringDate = @"origo.date.strings";

static NSString * const kDefaultsKeyUserEmail = @"origo.user.email";
static NSString * const kDefaultsKeyFormatAuthExpiryDate = @"origo.date.authExpiry.%@";
static NSString * const kDefaultsKeyFormatDeviceId = @"origo.id.device.%@";
static NSString * const kDefaultsKeyFormatLastReplicationDate = @"origo.date.lastReplication.%@";
static NSString * const kDefaultsKeyFormatUserId = @"origo.id.user.%@";

static NSTimeInterval const kTimeInterval30Days = 2592000;
//static NSTimeInterval const kTimeInterval30Days = 30;

static OMeta *m = nil;


@interface OMeta ()

@property (strong, nonatomic) NSString *authToken;

@end


@implementation OMeta

#pragma mark - Auxiliary methods

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
        _userEmail = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsKeyUserEmail];
        _appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey];
        _displayLanguage = [NSLocale preferredLanguages][0];
        
        if (_userEmail) {
            _userId = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kDefaultsKeyFormatUserId, _userEmail]];
            _deviceId = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kDefaultsKeyFormatDeviceId, _userId]];
            _lastReplicationDate = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kDefaultsKeyFormatLastReplicationDate, _userId]];
        } else {
            _deviceId = [OUUIDGenerator generateUUID];
        }
        
        NSString *deviceModel = [UIDevice currentDevice].model;
        _deviceIs_iPad = [deviceModel hasPrefix:@"iPad"];
        _deviceIs_iPod = [deviceModel hasPrefix:@"iPod"];
        _deviceIs_iPhone = [deviceModel hasPrefix:@"iPhone"];
        _deviceIsSimulator = ([deviceModel rangeOfString:@"Simulator"].location != NSNotFound);
        
        _internetConnectionIsWiFi = NO;
        _internetConnectionIsWWAN = NO;
        
        _sharedDatePicker = [[UIDatePicker alloc] init];
        _sharedDatePicker.datePickerMode = UIDatePickerModeDate;
        [_sharedDatePicker setEarliestValidBirthDate];
        [_sharedDatePicker setLatestValidBirthDate];
        [_sharedDatePicker setToDefaultDate];
        
        _dirtyEntities = [[NSMutableSet alloc] init];
        _stagedEntities = [[NSMutableDictionary alloc] init];
        _stagedRelationshipRefs = [[NSMutableDictionary alloc] init];
        
        [self checkReachability:[Reachability reachabilityForInternetConnection]];
        
        if ([_internetReachability startNotifier]) {
            OLogInfo(@"Reachability notifier is running.");
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


#pragma mark - Connection status

- (BOOL)internetConnectionIsAvailable
{
    return (_internetConnectionIsWiFi || _internetConnectionIsWWAN);
}


#pragma mark - User sign in & sign out

- (void)userDidSignIn
{
    [[NSUserDefaults standardUserDefaults] setObject:_authTokenExpiryDate forKey:[NSString stringWithFormat:kDefaultsKeyFormatAuthExpiryDate, _userId]];
    
    _user = [self.context entityWithId:_userId];
    
    if (!_user) {
        _user = [self.context insertMemberEntityWithEmail:_userEmail];
    }
}


- (void)userDidSignOut
{
    [self.context saveReplicationState];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:kDefaultsKeyFormatAuthExpiryDate, _userId]];
    
    _user = nil;
    _userId = nil;
    _authToken = nil;
    _deviceId = nil;
    _lastReplicationDate = nil;
    
    [(OAppDelegate *)[UIApplication sharedApplication].delegate releasePersistentStore];
}


- (BOOL)userIsAllSet
{
    return ([self userIsSignedIn] && [self userIsRegistered]);
}


- (BOOL)userIsSignedIn
{
    if (!_user) {
        _authTokenExpiryDate = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kDefaultsKeyFormatAuthExpiryDate, _userId]];
        
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


#pragma mark - Replication housekeeping

- (NSSet *)dirtyEntitiesFromEarlierSessions
{
    NSMutableSet *dirtyEntities = [[NSMutableSet alloc] init];
    NSData *dirtyEntityURIArchive = [[NSUserDefaults standardUserDefaults] objectForKey:kDefaultsKeyDirtyEntities];
    
    if (dirtyEntityURIArchive) {
        NSSet *dirtyEntityURIs = [NSKeyedUnarchiver unarchiveObjectWithData:dirtyEntityURIArchive];
        
        for (NSURL *dirtyEntityURI in dirtyEntityURIs) {
            NSManagedObjectID *dirtyEntityID = [self.context.persistentStoreCoordinator managedObjectIDForURIRepresentation:dirtyEntityURI];
            
            [dirtyEntities addObject:[self.context objectWithID:dirtyEntityID]];
        }
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDefaultsKeyDirtyEntities];
    }
    
    return dirtyEntities;
}


- (NSSet *)dirtyEntities
{
    [_dirtyEntities unionSet:[self dirtyEntitiesFromEarlierSessions]];
    [_dirtyEntities unionSet:[self.context insertedObjects]];
    [_dirtyEntities unionSet:[self.context updatedObjects]];
    
    NSMutableSet *confirmedDirtyEntities = [[NSMutableSet alloc] init];
    
    for (OReplicatedEntity *entity in _dirtyEntities) {
        if ([entity isDirty]) {
            [confirmedDirtyEntities addObject:entity];
        }
    }
    
    _dirtyEntities = confirmedDirtyEntities;
    
    return _dirtyEntities;
}


- (void)stageEntity:(OReplicatedEntity *)entity
{
    if ([_stagedRelationshipRefs count] == 0) {
        [_stagedEntities removeAllObjects];
    }
    
    [_stagedEntities setObject:entity forKey:entity.entityId];
}


- (void)stageRelationshipRefs:(NSDictionary *)relationshipRefs forEntity:(OReplicatedEntity *)entity
{
    if ([_stagedRelationshipRefs count] == 0) {
        [_stagedEntities removeAllObjects];
    }
    
    [_stagedRelationshipRefs setObject:relationshipRefs forKey:entity.entityId];
}


- (OReplicatedEntity *)stagedEntityWithId:(NSString *)entityId
{
    return [_stagedEntities objectForKey:entityId];
}


- (NSDictionary *)stagedRelationshipRefsForEntity:(OReplicatedEntity *)entity
{
    NSDictionary *relationshipRefs = [_stagedRelationshipRefs objectForKey:entity.entityId];
    [_stagedRelationshipRefs removeObjectForKey:entity.entityId];
    
    return relationshipRefs;
}


#pragma mark - Accessors overrides

- (void)setUserId:(NSString *)userId
{
    _userId = userId;
    
    [[NSUserDefaults standardUserDefaults] setObject:_userId forKey:[NSString stringWithFormat:kDefaultsKeyFormatUserId, _userEmail]];
    
    NSString *deviceId = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kDefaultsKeyFormatDeviceId, _userId]];
    NSString *lastReplicationDate = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kDefaultsKeyFormatLastReplicationDate, _userId]];
    
    if (deviceId) {
        _deviceId = deviceId;
    } else if (_deviceId) {
        [[NSUserDefaults standardUserDefaults] setObject:_deviceId forKey:[NSString stringWithFormat:kDefaultsKeyFormatDeviceId, _userId]];
    }
    
    if (lastReplicationDate) {
        _lastReplicationDate = lastReplicationDate;
    } else if (_lastReplicationDate) {
        [[NSUserDefaults standardUserDefaults] setObject:_lastReplicationDate forKey:[NSString stringWithFormat:kDefaultsKeyFormatLastReplicationDate, _userId]];
    }
}


- (void)setUserEmail:(NSString *)userEmail
{
    _userEmail = userEmail;
    
    if (_userEmail) {
        [[NSUserDefaults standardUserDefaults] setObject:_userEmail forKey:[NSString stringWithFormat:kDefaultsKeyUserEmail]];
        
        NSString *userId = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kDefaultsKeyFormatUserId, _userEmail]];
        
        if (userId) {
            self.userId = userId;
        } else if (_userId) {
            [[NSUserDefaults standardUserDefaults] setObject:_userId forKey:[NSString stringWithFormat:kDefaultsKeyFormatUserId, _userEmail]];
        } else if (!_deviceId) {
            _deviceId = [OUUIDGenerator generateUUID];
        }
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDefaultsKeyUserEmail];
    }
}


- (NSString *)authToken
{
    if (!_authToken) {
        _authTokenExpiryDate = [NSDate dateWithTimeIntervalSinceNow:kTimeInterval30Days];
        _authToken = [self generateAuthToken:_authTokenExpiryDate];
    }
    
    return _authToken;
}


- (void)setLastReplicationDate:(NSString *)lastReplicationDate
{
    _lastReplicationDate = lastReplicationDate;
    
    [[NSUserDefaults standardUserDefaults] setObject:_lastReplicationDate forKey:[NSString stringWithFormat:kDefaultsKeyFormatLastReplicationDate, _userId]];
}


- (NSManagedObjectContext *)context
{
    return ((OAppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
}


#pragma mark - OServerConnectionDelegate conformance

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    if (data) {
        [self.context saveServerReplicas:data];
    }

    if ((response.statusCode == kHTTPStatusCreated) ||
        (response.statusCode == kHTTPStatusMultiStatus)) {
        OLogDebug(@"Entities successfully replicated to server.");
        
        NSDate *now = [NSDate date];
        
        for (OReplicatedEntity *entity in _dirtyEntities) {
            if ([entity.isGhost boolValue]) {
                [self.context deleteObject:entity];
            } else {
                entity.dateReplicated = now;
                entity.hashCode = [entity computeHashCode];
            }
        }
        
        [self.context save];
        [_dirtyEntities removeAllObjects];
    }
}


- (void)didFailWithError:(NSError *)error
{
    OLogError(@"Error replicating with server.");
}

@end
