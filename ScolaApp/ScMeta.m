//
//  ScMeta.m
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScMeta.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "NSString+ScStringExtensions.h"

#import "ScAppDelegate.h"
#import "ScState.h"
#import "ScLogging.h"
#import "ScServerConnection.h"
#import "ScStrings.h"
#import "ScUUIDGenerator.h"

#import "ScCachedEntity.h"
#import "ScMember.h"

#import "ScCachedEntity+ScCachedEntityExtensions.h"

NSString * const kBundleId = @"com.scolaapp.ios.ScolaApp";
NSString * const kDarkLinenImageFile = @"dark_linen-640x960.png";
NSString * const kLanguageHungarian = @"hu";

NSString * const kAuthViewControllerId = @"idAuth";
NSString * const kMainViewControllerId = @"idMain";
NSString * const kMemberViewControllerId = @"idMember";
NSString * const kMembershipViewControllerId = @"idMembership";
NSString * const kScolaViewControllerId = @"idScola";

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

NSString * const kScolaTypeMemberRoot = @"R";
NSString * const kScolaTypeResidence = @"E";
NSString * const kScolaTypeSchoolClass = @"S";
NSString * const kScolaTypePreschoolClass = @"P";
NSString * const kScolaTypeSportsTeam = @"T";
NSString * const kScolaTypeOther = @"O";

NSString * const kGuardianRoleParent = @"P";
NSString * const kGuardianRoleMother = @"M";
NSString * const kGuardianRoleFather = @"F";
NSString * const kGuardianRoleOther = @"O";

NSString * const kContactRoleResidenceElder = @"residenceElder";

static NSInteger const kMinimumPassordLength = 6;

static NSString * const kUserDefaultsKeyUserId = @"scola.user.id";
static NSString * const kUserDefaultsKeyFormatDeviceId = @"scola.device.id$%@";
static NSString * const kUserDefaultsKeyFormatAuthExpiryDate = @"scola.auth.expires$%@";
static NSString * const kUserDefaultsKeyFormatLastFetchDate = @"scola.fetch.date$%@";

//static NSTimeInterval const kTimeIntervalTwoWeeks = 1209600;
static NSTimeInterval const kTimeIntervalTwoWeeks = 30;

static ScMeta *m = nil;


@interface ScMeta ()

@property (strong, nonatomic) NSString *authToken;

@end


@implementation ScMeta

#pragma mark - Auxiliary methods

- (void)checkReachability:(Reachability *)reachability
{
    NetworkStatus internetStatus = [reachability currentReachabilityStatus];
    
    _isInternetConnectionWiFi = (internetStatus == ReachableViaWiFi);
    _isInternetConnectionWWAN = (internetStatus == ReachableViaWWAN);
    
    if (_isInternetConnectionWiFi) {
        ScLogInfo(@"Connected to the internet via Wi-Fi.");
    } else if (_isInternetConnectionWWAN) {
        ScLogInfo(@"Connected to the internet via mobile web (WWAN).");
    } else {
        ScLogInfo(@"Not connected to the internet.");
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
        NSString *deviceModel = [UIDevice currentDevice].model;
        _is_iPadDevice = [deviceModel hasPrefix:@"iPad"];
        _is_iPodDevice = [deviceModel hasPrefix:@"iPod"];
        _is_iPhoneDevice = [deviceModel hasPrefix:@"iPhone"];
        _isSimulatorDevice = ([deviceModel rangeOfString:@"Simulator"].location != NSNotFound);
        
        _isInternetConnectionWiFi = NO;
        _isInternetConnectionWWAN = NO;
        
        _userId = [ScMeta userDefaultForKey:kUserDefaultsKeyUserId];
        
        if (_userId) {
            _deviceId = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatDeviceId, _userId]];
            _authTokenExpiryDate = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthExpiryDate, _userId]];
            _lastFetchDate = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatLastFetchDate, _userId]];
        } else {
            _deviceId = [ScUUIDGenerator generateUUID];
        }
        
        _appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey];
        _displayLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
        
        _scheduledEntities = [[NSMutableSet alloc] init];
        _importedEntities = [[NSMutableDictionary alloc] init];
        _importedEntityRefs = [[NSMutableDictionary alloc] init];
        
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

- (NSManagedObjectContext *)context
{
    ScAppDelegate *appDelegate = (ScAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    return appDelegate.managedObjectContext;
}


- (void)setUser:(ScMember *)user
{
    _user = user;
    _userId = user.entityId;
    
    if (user) {
        [ScMeta setUserDefault:_userId forKey:kUserDefaultsKeyUserId];
        
        _lastFetchDate = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatLastFetchDate, _userId]];
        
        NSString *persistedDeviceId = [ScMeta userDefaultForKey:[NSString stringWithFormat:kUserDefaultsKeyFormatDeviceId, _userId]];
        
        if (persistedDeviceId) {
            _deviceId = persistedDeviceId;
        } else {
            [ScMeta setUserDefault:_deviceId forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatDeviceId, _userId]];
        }
    } else {
        [ScMeta removeUserDefaultForKey:kUserDefaultsKeyUserId];
    }
}


- (NSString *)authToken
{
    if (!_authToken && !self.isUserLoggedIn) {
        _authTokenExpiryDate = [NSDate dateWithTimeIntervalSinceNow:kTimeIntervalTwoWeeks];
        _authToken = [self generateAuthToken:_authTokenExpiryDate];
    }
    
    return _authToken;
}


- (void)setLastFetchDate:(NSString *)fetchDate
{
    _lastFetchDate = fetchDate;
    
    [ScMeta setUserDefault:fetchDate forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatLastFetchDate, _userId]];
}


- (void)setIsUserLoggedIn:(BOOL)isLoggedIn
{
    [(ScAppDelegate *)[[UIApplication sharedApplication] delegate] releasePersistentStore];
    
    if (isLoggedIn) {
        [ScMeta setUserDefault:_authTokenExpiryDate forKey:[NSString stringWithFormat:kUserDefaultsKeyFormatAuthExpiryDate, _userId]];
    } else {
        _user = nil;
        _userId = nil;
    }
}


- (BOOL)isUserLoggedIn
{
    if (!_authToken && _authTokenExpiryDate) {
        NSDate *now = [NSDate date];
        
        if ([now compare:_authTokenExpiryDate] == NSOrderedAscending) {
            _authToken = [self generateAuthToken:_authTokenExpiryDate];
        }
    }
    
    return (_authToken != nil);
}


#pragma mark - Connection state

- (void)checkInternetReachability
{
    [self checkReachability:[Reachability reachabilityForInternetConnection]];
    
    if ([_internetReachability startNotifier]) {
        ScLogInfo(@"Reachability notifier is running.");
    } else {
        ScLogWarning(@"Could not start reachability notifier, checking internet connectivity only at startup.");
    }
}


- (BOOL)isInternetConnectionAvailable
{
    return (_isInternetConnectionWiFi || _isInternetConnectionWWAN);
}


#pragma mark - Persistence scheduling

- (NSSet *)entitiesScheduledForPersistence
{
    [_scheduledEntities unionSet:[self.context insertedObjects]];
    [_scheduledEntities unionSet:[self.context updatedObjects]];
    
    NSMutableSet *nonPersistedEntities = [[NSMutableSet alloc] init];
    
    for (ScCachedEntity *entity in _scheduledEntities) {
        if ([entity didChange]) {
            [nonPersistedEntities addObject:entity];
        }
    }
    
    _scheduledEntities = [NSMutableSet setWithSet:nonPersistedEntities];
    
    return _scheduledEntities;
}


#pragma mark - JSON deserialisation housekeeping

- (void)addImportedEntity:(ScCachedEntity *)entity
{
    if ([_importedEntityRefs count] == 0) {
        [_importedEntities removeAllObjects];
    }
    
    [_importedEntities setObject:entity forKey:entity.entityId];
}


- (void)addImportedEntityRefs:(NSDictionary *)entityRefs forEntity:(ScCachedEntity *)entity
{
    if ([_importedEntityRefs count] == 0) {
        [_importedEntities removeAllObjects];
    }
    
    [_importedEntityRefs setObject:entityRefs forKey:entity.entityId];
}


- (ScCachedEntity *)importedEntityWithId:(NSString *)entityId
{
    return [_importedEntities objectForKey:entityId];
}


- (NSDictionary *)importedEntityRefsForEntity:(ScCachedEntity *)entity
{
    NSDictionary *entityRefs = [_importedEntityRefs objectForKey:entity.entityId];
    [_importedEntityRefs removeObjectForKey:entity.entityId];
    
    return entityRefs;
}


#pragma mark - ScServerConnectionDelegate implementation

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    if (data) {
        [self.context saveWithDictionaries:data];
    }

    if ((response.statusCode == kHTTPStatusCodeCreated) ||
        (response.statusCode == kHTTPStatusCodeMultiStatus)) {
        ScLogDebug(@"Entities successfully persisted");
        
        NSDate *now = [NSDate date];
        
        for (ScCachedEntity *entity in _scheduledEntities) {
            entity.dateModified = now;
            entity.hashCode = [NSNumber numberWithInteger:[entity computeHashCode]];
        }
        
        [self.context save];
        [_scheduledEntities removeAllObjects];
    }
}


- (void)didFailWithError:(NSError *)error
{
    ScLogError(@"Error synchronising entities.");
}

@end
