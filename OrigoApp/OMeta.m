//
//  OMeta.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMeta.h"

#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"
#import "NSString+OStringExtensions.h"

#import "OAppDelegate.h"
#import "OState.h"
#import "OLogging.h"
#import "OServerConnection.h"
#import "OStrings.h"
#import "OUUIDGenerator.h"

#import "OMember.h"
#import "OReplicatedEntity.h"
#import "OReplicatedEntityGhost.h"

#import "OMember+OMemberExtensions.h"
#import "OReplicatedEntity+OReplicatedEntityExtensions.h"

#import "OOrigoListViewController.h"

NSUInteger const kCertainSchoolAge = 7;
NSUInteger const kAgeOfMajority = 18;

NSString * const kBundleId = @"com.origoapp.ios.OrigoApp";
NSString * const kLanguageHungarian = @"hu";

NSString * const kIconFileOrigo = @"10-arrows-in_black.png";
NSString * const kIconFileHousehold = @"glyphicons_020_home.png";
NSString * const kIconFileMan = @"glyphicons_003_user.png";
NSString * const kIconFileWoman = @"glyphicons_035_woman.png";
NSString * const kIconFileBoy = @"glyphicons_004_girl-as_boy.png";
NSString * const kIconFileGirl = @"glyphicons_004_girl.png";
NSString * const kIconFileInfant = @"76-baby_black.png";

NSString * const kOrigoTypeMemberRoot = @"origoTypeMemberRoot";
NSString * const kOrigoTypeResidence = @"origoTypeResidence";
NSString * const kOrigoTypeOrganisation = @"origoTypeOrganisation";
NSString * const kOrigoTypeSchoolClass = @"origoTypeSchoolClass";
NSString * const kOrigoTypePreschoolClass = @"origoTypePreschoolClass";
NSString * const kOrigoTypeSportsTeam = @"origoTypeSportsTeam";
NSString * const kOrigoTypeDefault = @"origoTypeDefault";

NSString * const kGenderFemale = @"F";
NSString * const kGenderMale = @"M";

NSString * const kAuthViewControllerId = @"idAuthViewController";
NSString * const kTabBarControllerId = @"idTabBarController";
NSString * const kOrigoListViewControllerId = @"idOrigoListViewController";
NSString * const kOrigoViewControllerId = @"idOrigoViewController";
NSString * const kMemberViewControllerId = @"idMemberViewController";
NSString * const kMemberListViewControllerId = @"idMemberListViewController";

NSString * const kKeyPathAuthInfo = @"origo.auth.info";
NSString * const kKeyPathDirtyEntities = @"origo.dirtyEntities";

NSString * const kKeyPathEntityClass = @"entityClass";
NSString * const kKeyPathEntityId = @"entityId";
NSString * const kKeyPathOrigoId = @"origoId";

static NSString * const kKeyPathUserId = @"origo.user.id";
static NSString * const kKeyPathFormatDeviceId = @"origo.device.id$%@";
static NSString * const kKeyPathFormatAuthExpiryDate = @"origo.auth.expires$%@";
static NSString * const kKeyPathFormatLastReplicationDate = @"origo.replication.date$%@";

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
    NSString *saltyDiff = [self.deviceId diff:expiryDateAsString];
    
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
        _userId = [[NSUserDefaults standardUserDefaults] objectForKey:kKeyPathUserId];
        _appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey];
        _displayLanguage = [NSLocale preferredLanguages][0];
        
        if (_userId) {
            _deviceId = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kKeyPathFormatDeviceId, _userId]];
            _lastReplicationDate = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kKeyPathFormatLastReplicationDate, _userId]];
        } else {
            _deviceId = [OUUIDGenerator generateUUID];
        }
        
        NSString *deviceModel = [UIDevice currentDevice].model;
        _is_iPadDevice = [deviceModel hasPrefix:@"iPad"];
        _is_iPodDevice = [deviceModel hasPrefix:@"iPod"];
        _is_iPhoneDevice = [deviceModel hasPrefix:@"iPhone"];
        _isSimulatorDevice = ([deviceModel rangeOfString:@"Simulator"].location != NSNotFound);
        
        _internetConnectionIsWiFi = NO;
        _internetConnectionIsWWAN = NO;
        
        _dirtyEntities = [[NSMutableSet alloc] init];
        _stagedServerEntities = [[NSMutableDictionary alloc] init];
        _stagedServerEntityRefs = [[NSMutableDictionary alloc] init];
        
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
    if (m == nil) {
        m = [[super allocWithZone:nil] init];
    }
    
    return m;
}


#pragma mark - Custom property accessors

- (void)setUserId:(NSString *)userId
{
    [(OAppDelegate *)[[UIApplication sharedApplication] delegate] releasePersistentStore];
    
    _userId = userId;
    
    if (_userId) {
        [[NSUserDefaults standardUserDefaults] setObject:_userId forKey:kKeyPathUserId];
        
        NSString *deviceId = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kKeyPathFormatDeviceId, _userId]];
        NSString *lastReplicationDate = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kKeyPathFormatLastReplicationDate, _userId]];
        
        if (deviceId) {
            _deviceId = deviceId;
        } else if (_deviceId) {
            [[NSUserDefaults standardUserDefaults] setObject:_deviceId forKey:[NSString stringWithFormat:kKeyPathFormatDeviceId, _userId]];
        }
        
        if (lastReplicationDate) {
            _lastReplicationDate = lastReplicationDate;
        } else if (_lastReplicationDate) {
            [[NSUserDefaults standardUserDefaults] setObject:_lastReplicationDate forKey:[NSString stringWithFormat:kKeyPathFormatLastReplicationDate, _userId]];
        }
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kKeyPathUserId];
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


- (void)setLastReplicationDate:(NSString *)replicationDate
{
    _lastReplicationDate = replicationDate;
    
    [[NSUserDefaults standardUserDefaults] setObject:replicationDate forKey:[NSString stringWithFormat:kKeyPathFormatLastReplicationDate, _userId]];
}


- (NSManagedObjectContext *)context
{
    return ((OAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
}


#pragma mark - Convenience methods

- (BOOL)internetConnectionIsAvailable
{
    return (_internetConnectionIsWiFi || _internetConnectionIsWWAN);
}


#pragma mark - User sign in & sign out

- (void)userDidSignIn
{
    [[NSUserDefaults standardUserDefaults] setObject:_authTokenExpiryDate forKey:[NSString stringWithFormat:kKeyPathFormatAuthExpiryDate, _userId]];
    
    _user = [self.context entityWithId:_userId];
    
    if (!_user) {
        _user = [self.context insertMemberEntityWithId:_userId];
    }
}


- (void)userDidSignOut
{
    _user = nil;
    _authToken = nil;
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:kKeyPathFormatAuthExpiryDate, _userId]];
}


- (BOOL)userIsSignedIn
{
    if (!_user) {
        _authTokenExpiryDate = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kKeyPathFormatAuthExpiryDate, _userId]];
        
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


- (BOOL)registrationIsComplete
{
    return ([_user hasPhone] && [_user hasAddress]);
}


#pragma mark - Replication housekeeping

- (NSSet *)dirtyEntitiesFromEarlierSessions
{
    NSMutableSet *dirtyEntities = [[NSMutableSet alloc] init];
    NSData *dirtyEntityURIArchive = [[NSUserDefaults standardUserDefaults] objectForKey:kKeyPathDirtyEntities];
    
    if (dirtyEntityURIArchive) {
        NSSet *dirtyEntityURIs = [NSKeyedUnarchiver unarchiveObjectWithData:dirtyEntityURIArchive];
        
        for (NSURL *dirtyEntityURI in dirtyEntityURIs) {
            NSManagedObjectID *dirtyEntityID = [self.context.persistentStoreCoordinator managedObjectIDForURIRepresentation:dirtyEntityURI];
            
            [dirtyEntities addObject:[self.context objectWithID:dirtyEntityID]];
        }
        
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kKeyPathDirtyEntities];
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


- (void)stageServerEntity:(OReplicatedEntity *)entity
{
    if ([_stagedServerEntityRefs count] == 0) {
        [_stagedServerEntities removeAllObjects];
    }
    
    [_stagedServerEntities setObject:entity forKey:entity.entityId];
}


- (void)stageServerEntityRefs:(NSDictionary *)entityRefs forEntity:(OReplicatedEntity *)entity
{
    if ([_stagedServerEntityRefs count] == 0) {
        [_stagedServerEntities removeAllObjects];
    }
    
    [_stagedServerEntityRefs setObject:entityRefs forKey:entity.entityId];
}


- (OReplicatedEntity *)stagedServerEntityWithId:(NSString *)entityId
{
    return [_stagedServerEntities objectForKey:entityId];
}


- (NSDictionary *)stagedServerEntityRefsForEntity:(OReplicatedEntity *)entity
{
    NSDictionary *entityRefs = [_stagedServerEntityRefs objectForKey:entity.entityId];
    [_stagedServerEntityRefs removeObjectForKey:entity.entityId];
    
    return entityRefs;
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
            if ([entity isKindOfClass:OReplicatedEntityGhost.class]) {
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
