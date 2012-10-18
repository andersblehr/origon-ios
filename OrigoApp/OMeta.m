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

#import "OCachedEntity.h"
#import "OMember.h"

#import "OCachedEntity+OCachedEntityExtensions.h"

NSString * const kBundleId = @"com.origoapp.ios.OrigoApp";
NSString * const kLanguageHungarian = @"hu";

NSString * const kAuthViewControllerId = @"idAuth";
NSString * const kOrigoListViewControllerId = @"idMain";
NSString * const kOrigoViewControllerId = @"idOrigo";
NSString * const kMemberViewControllerId = @"idMember";
NSString * const kMemberListViewControllerId = @"idMembership";

NSString * const kPropertyEntityId = @"entityId";
NSString * const kPropertyEntityClass = @"entityClass";
NSString * const kPropertyOrigoId = @"origoId";
NSString * const kPropertyName = @"name";
NSString * const kPropertyDateOfBirth = @"dateOfBirth";
NSString * const kPropertyMobilePhone = @"mobilePhone";
NSString * const kPropertyGender = @"gender";
NSString * const kPropertyDidRegister = @"didRegister";

NSString * const kGenderFemale = @"F";
NSString * const kGenderMale = @"M";

NSString * const kOrigoTypeMemberRoot = @"R";
NSString * const kOrigoTypeResidence = @"E";
NSString * const kOrigoTypeSchoolClass = @"S";
NSString * const kOrigoTypePreschoolClass = @"P";
NSString * const kOrigoTypeSportsTeam = @"T";
NSString * const kOrigoTypeOther = @"O";

NSString * const kGuardianRoleParent = @"P";
NSString * const kGuardianRoleMother = @"M";
NSString * const kGuardianRoleFather = @"F";
NSString * const kGuardianRoleOther = @"O";

NSString * const kContactRoleResidenceElder = @"residenceElder";

static NSInteger const kMinimumPassordLength = 6;

static NSString * const kUserDefaultsKeyUserId = @"origo.user.id";
static NSString * const kUserDefaultsKeyFormatDeviceId = @"origo.device.id$%@";
static NSString * const kUserDefaultsKeyFormatAuthExpiryDate = @"origo.auth.expires$%@";
static NSString * const kUserDefaultsKeyFormatLastFetchDate = @"origo.fetch.date$%@";

//static NSTimeInterval const kTimeIntervalTwoWeeks = 1209600;
static NSTimeInterval const kTimeIntervalTwoWeeks = 30;

static OMeta *m = nil;


@interface OMeta ()

@property (strong, nonatomic) NSString *authToken;

@end


@implementation OMeta

#pragma mark - Auxiliary methods

- (void)checkReachability:(Reachability *)reachability
{
    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
    
    _isInternetConnectionWiFi = (internetStatus == ReachableViaWiFi);
    _isInternetConnectionWWAN = (internetStatus == ReachableViaWWAN);
    
    if (_isInternetConnectionWiFi) {
        OLogInfo(@"Connected to the internet via Wi-Fi.");
    } else if (_isInternetConnectionWWAN) {
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
        _userId = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsKeyUserId];
        _appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey];
        _displayLanguage = [NSLocale preferredLanguages][0];
        
        if (_userId) {
            _deviceId = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatDeviceId, _userId]];
            _lastFetchDate = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatLastFetchDate, _userId]];
        } else {
            _deviceId = [OUUIDGenerator generateUUID];
        }
        
        NSString *deviceModel = [UIDevice currentDevice].model;
        _is_iPadDevice = [deviceModel hasPrefix:@"iPad"];
        _is_iPodDevice = [deviceModel hasPrefix:@"iPod"];
        _is_iPhoneDevice = [deviceModel hasPrefix:@"iPhone"];
        _isSimulatorDevice = ([deviceModel rangeOfString:@"Simulator"].location != NSNotFound);
        
        _isInternetConnectionWiFi = NO;
        _isInternetConnectionWWAN = NO;
        
        _modifiedEntities = [[NSMutableSet alloc] init];
        _stagedServerEntities = [[NSMutableDictionary alloc] init];
        _stagedServerEntityRefs = [[NSMutableDictionary alloc] init];
        
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


#pragma mark - Input validation

+ (BOOL)isEmailValid:(UITextField *)emailField
{
    NSString *email = [emailField.text removeLeadingAndTrailingSpaces];
    
    BOOL isValid = [email isEmailAddress];
    
    if (!isValid) {
        [emailField becomeFirstResponder];
    }
    
    return isValid;
}


+ (BOOL)isPasswordValid:(UITextField *)passwordField
{
    NSString *password = [passwordField.text removeLeadingAndTrailingSpaces];
    
    BOOL isValid = (password.length >= kMinimumPassordLength);
    
    if (!isValid) {
        [passwordField becomeFirstResponder];
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
    }
    
    return isValid;
}


+ (BOOL)isMobileNumberValid:(UITextField *)mobileNumberField
{
    NSString *mobileNumber = [mobileNumberField.text removeLeadingAndTrailingSpaces];
    
    BOOL isValid = (mobileNumber.length > 0);
    
    if (!isValid) {
        [mobileNumberField becomeFirstResponder];
    }
    
    return isValid;
}


+ (BOOL)isDateOfBirthValid:(UITextField *)dateField
{
    BOOL isValid = (dateField.text.length > 0);
    
    if (!isValid) {
        [dateField becomeFirstResponder];
    }
    
    return isValid;
}


+ (BOOL)isAddressValidWithLine1:(UITextField *)line1Field line2:(UITextField *)line2Field
{
    NSString *addressLine1 = [line1Field.text removeLeadingAndTrailingSpaces];
    NSString *addressLine2 = [line2Field.text removeLeadingAndTrailingSpaces];
    
    BOOL isValid = ((addressLine1.length > 0) || (addressLine2.length > 0));
    
    if (!isValid) {
        [line1Field becomeFirstResponder];
    }
    
    return isValid;
}


#pragma mark - Custom property accessors

- (BOOL)isUserLoggedIn
{
    if (!_user) {
        _authTokenExpiryDate = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthExpiryDate, _userId]];
        
        if (_authTokenExpiryDate) {
            NSDate *now = [NSDate date];
            
            if ([now compare:_authTokenExpiryDate] == NSOrderedAscending) {
                _authToken = [self generateAuthToken:_authTokenExpiryDate];
                _user = [self.context fetchEntityFromCache:_userId];
            }
        }
    }
    
    return (_user != nil);
}


- (void)setUserId:(NSString *)userId
{
    [(OAppDelegate *)[[UIApplication sharedApplication] delegate] releasePersistentStore];
    
    _userId = userId;
    
    if (_userId) {
        [[NSUserDefaults standardUserDefaults] setObject:_userId forKey:kUserDefaultsKeyUserId];
        
        NSString *deviceId = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatDeviceId, _userId]];
        NSString *lastFetchDate = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatLastFetchDate, _userId]];
        
        if (deviceId) {
            _deviceId = deviceId;
        } else if (_deviceId) {
            [[NSUserDefaults standardUserDefaults] setObject:_deviceId forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatDeviceId, _userId]];
        }
        
        if (lastFetchDate) {
            _lastFetchDate = lastFetchDate;
        } else if (_lastFetchDate) {
            [[NSUserDefaults standardUserDefaults] setObject:_lastFetchDate forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatLastFetchDate, _userId]];
        }
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserDefaultsKeyUserId];
    }
}


- (NSString *)authToken
{
    if (!_authToken) {
        _authTokenExpiryDate = [NSDate dateWithTimeIntervalSinceNow:kTimeIntervalTwoWeeks];
        _authToken = [self generateAuthToken:_authTokenExpiryDate];
    }
    
    return _authToken;
}


- (void)setLastFetchDate:(NSString *)fetchDate
{
    _lastFetchDate = fetchDate;
    
    [[NSUserDefaults standardUserDefaults] setObject:fetchDate forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatLastFetchDate, _userId]];
}


- (NSManagedObjectContext *)context
{
    return ((OAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext;
}


#pragma mark - Connection state

- (void)checkInternetReachability
{
    [self checkReachability:[Reachability reachabilityForInternetConnection]];
    
    if ([_internetReachability startNotifier]) {
        OLogInfo(@"Reachability notifier is running.");
    } else {
        OLogWarning(@"Could not start reachability notifier, checking internet connectivity only at startup.");
    }
}


- (BOOL)isInternetConnectionAvailable
{
    return (_isInternetConnectionWiFi || _isInternetConnectionWWAN);
}


#pragma mark - User login

- (void)userDidLogIn
{
    [[NSUserDefaults standardUserDefaults] setObject:_authTokenExpiryDate forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthExpiryDate, _userId]];
    
    _user = [self.context fetchEntityFromCache:_userId];
    
    if (!_user) {
        _user = [self.context entityForMemberWithId:_userId];
    }
}


#pragma mark - Cache & persistence housekeeping

- (NSSet *)modifiedEntities
{
    [_modifiedEntities unionSet:[self.context insertedObjects]];
    [_modifiedEntities unionSet:[self.context updatedObjects]];
    
    NSMutableSet *dirtyEntities = [[NSMutableSet alloc] init];
    
    for (OCachedEntity *entity in _modifiedEntities) {
        if ([entity isDirty]) {
            [dirtyEntities addObject:entity];
        }
    }
    
    _modifiedEntities = dirtyEntities;
    
    return _modifiedEntities;
}


- (void)stageServerEntity:(OCachedEntity *)entity
{
    if ([_stagedServerEntityRefs count] == 0) {
        [_stagedServerEntities removeAllObjects];
    }
    
    [_stagedServerEntities setObject:entity forKey:entity.entityId];
}


- (void)stageServerEntityRefs:(NSDictionary *)entityRefs forEntity:(OCachedEntity *)entity
{
    if ([_stagedServerEntityRefs count] == 0) {
        [_stagedServerEntities removeAllObjects];
    }
    
    [_stagedServerEntityRefs setObject:entityRefs forKey:entity.entityId];
}


- (OCachedEntity *)stagedServerEntityWithId:(NSString *)entityId
{
    return [_stagedServerEntities objectForKey:entityId];
}


- (NSDictionary *)stagedServerEntityRefsForEntity:(OCachedEntity *)entity
{
    NSDictionary *entityRefs = [_stagedServerEntityRefs objectForKey:entity.entityId];
    [_stagedServerEntityRefs removeObjectForKey:entity.entityId];
    
    return entityRefs;
}


#pragma mark - OServerConnectionDelegate implementation

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    if (data) {
        [self.context saveServerEntitiesToCache:data];
    }

    if ((response.statusCode == kHTTPStatusCodeCreated) ||
        (response.statusCode == kHTTPStatusCodeMultiStatus)) {
        OLogDebug(@"Entities successfully persisted");
        
        NSDate *now = [NSDate date];
        
        for (OCachedEntity *entity in _modifiedEntities) {
            entity.dateModified = now;
            entity.hashCode = [NSNumber numberWithInteger:[entity computeHashCode]];
        }
        
        [self.context saveToCache];
        [_modifiedEntities removeAllObjects];
    }
}


- (void)didFailWithError:(NSError *)error
{
    OLogError(@"Error synchronising cache with server.");
}

@end
