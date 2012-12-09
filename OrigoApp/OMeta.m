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
#import "OTabBarController.h"

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

NSString * const kOrigoTypeMemberRoot = @"origoTypeMemberRoot";
NSString * const kOrigoTypeResidence = @"origoTypeResidence";
NSString * const kOrigoTypeOrganisation = @"origoTypeOrganisation";
NSString * const kOrigoTypeSchoolClass = @"origoTypeSchoolClass";
NSString * const kOrigoTypePreschoolClass = @"origoTypePreschoolClass";
NSString * const kOrigoTypeSportsTeam = @"origoTypeSportsTeam";
NSString * const kOrigoTypeDefault = @"origoTypeDefault";

NSString * const kKeyPathAuthInfo = @"origo.auth.info";
NSString * const kKeyPathDirtyEntities = @"origo.dirtyEntities";
NSString * const kKeyPathEntityClass = @"entityClass";
NSString * const kKeyPathEntityId = @"entityId";
NSString * const kKeyPathOrigo = @"origo";
NSString * const kKeyPathOrigoId = @"origoId";
NSString * const kKeyPathSignIn = @"signIn";
NSString * const kKeyPathAuthEmail = @"authEmail";
NSString * const kKeyPathPassword = @"password";
NSString * const kKeyPathActivation = @"activation";
NSString * const kKeyPathActivationCode = @"activationCode";
NSString * const kKeyPathRepeatPassword = @"repeatPassword";
NSString * const kKeyPathPasswordHash = @"passwordHash";
NSString * const kKeyPathIsListed = @"isListed";
NSString * const kKeyPathName = @"name";
NSString * const kKeyPathMobilePhone = @"mobilePhone";
NSString * const kKeyPathEmail = @"email";
NSString * const kKeyPathDateOfBirth = @"dateOfBirth";
NSString * const kKeyPathAddress = @"address";
NSString * const kKeyPathTelephone = @"telephone";

NSString * const kGenderFemale = @"F";
NSString * const kGenderMale = @"M";

NSUInteger const kCertainSchoolAge = 7;
NSUInteger const kAgeOfMajority = 18;

static NSString * const kKeyPathUserEmail = @"origo.user.email";
static NSString * const kKeyPathFormatDeviceId = @"origo.id.device.%@";
static NSString * const kKeyPathFormatAuthExpiryDate = @"origo.date.authExpiry.%@";
static NSString * const kKeyPathFormatLastReplicationDate = @"origo.date.lastReplication.%@";

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
        _userEmail = [[NSUserDefaults standardUserDefaults] objectForKey:kKeyPathUserEmail];
        _appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey];
        _displayLanguage = [NSLocale preferredLanguages][0];
        
        if (_userEmail) {
            _deviceId = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kKeyPathFormatDeviceId, _userEmail]];
            _lastReplicationDate = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kKeyPathFormatLastReplicationDate, _userEmail]];
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
        
        _contextObservers = [[NSMutableDictionary alloc] init];
        
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
    if (m == nil) {
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
    [[NSUserDefaults standardUserDefaults] setObject:_authTokenExpiryDate forKey:[NSString stringWithFormat:kKeyPathFormatAuthExpiryDate, _userEmail]];
    
    _user = [self.context memberEntityWithEmail:_userEmail];
    
    if (!_user) {
        _user = [self.context insertMemberEntityWithEmail:_userEmail];
    }
}


- (void)userDidSignOut
{
    _user = nil;
    _authToken = nil;
    _deviceId = nil;
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:kKeyPathFormatAuthExpiryDate, _userEmail]];
    
    [(OAppDelegate *)[UIApplication sharedApplication].delegate releasePersistentStore];
}


- (BOOL)userIsAllSet
{
    return ([self userIsSignedIn] && [self userIsRegistered]);
}


- (BOOL)userIsSignedIn
{
    if (!_user) {
        _authTokenExpiryDate = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kKeyPathFormatAuthExpiryDate, _userEmail]];
        
        if (_authTokenExpiryDate) {
            NSDate *now = [NSDate date];
            
            if ([now compare:_authTokenExpiryDate] == NSOrderedAscending) {
                _authToken = [self generateAuthToken:_authTokenExpiryDate];
                _user = [self.context memberEntityWithEmail:_userEmail];
            }
        }
    }
    
    return (_user != nil);
}


- (BOOL)userIsRegistered
{
    return ([_user hasMobilePhone] && [_user hasAddress]);
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

- (void)setUserEmail:(NSString *)userEmail
{
    _userEmail = userEmail;
    
    if (_userEmail) {
        [[NSUserDefaults standardUserDefaults] setObject:_userEmail forKey:kKeyPathUserEmail];
        
        NSString *deviceId = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kKeyPathFormatDeviceId, _userEmail]];
        
        if (deviceId) {
            _deviceId = deviceId;
        } else {
            if (!_deviceId) {
                _deviceId = [OUUIDGenerator generateUUID];
            }
            
            [[NSUserDefaults standardUserDefaults] setObject:_deviceId forKey:[NSString stringWithFormat:kKeyPathFormatDeviceId, _userEmail]];
        }
        
        _lastReplicationDate = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kKeyPathFormatLastReplicationDate, _userEmail]];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kKeyPathUserEmail];
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
    
    [[NSUserDefaults standardUserDefaults] setObject:replicationDate forKey:[NSString stringWithFormat:kKeyPathFormatLastReplicationDate, _userEmail]];
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
