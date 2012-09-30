//
//  ScMeta.h
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Reachability.h"

#import "ScServerConnectionDelegate.h"

extern NSString * const kBundleId;
extern NSString * const kDarkLinenImageFile;
extern NSString * const kLanguageHungarian;

extern NSString * const kAuthViewControllerId;
extern NSString * const kMainViewControllerId;
extern NSString * const kMemberViewControllerId;
extern NSString * const kMembershipViewControllerId;
extern NSString * const kScolaViewControllerId;

extern NSString * const kPropertyEntityId;
extern NSString * const kPropertyEntityClass;
extern NSString * const kPropertyScolaId;
extern NSString * const kPropertyName;
extern NSString * const kPropertyDateOfBirth;
extern NSString * const kPropertyMobilePhone;
extern NSString * const kPropertyGender;
extern NSString * const kPropertyDidRegister;

extern NSString * const kGenderFemale;
extern NSString * const kGenderMale;

extern NSString * const kScolaTypeMemberRoot;
extern NSString * const kScolaTypeResidence;
extern NSString * const kScolaTypeSchoolClass;
extern NSString * const kScolaTypePreschoolClass;
extern NSString * const kScolaTypeSportsTeam;
extern NSString * const kScolaTypeOther;

extern NSString * const kGuardianRoleParent;
extern NSString * const kGuardianRoleMother;
extern NSString * const kGuardianRoleFather;
extern NSString * const kGuardianRoleOther;

extern NSString * const kContactRoleResidenceElder;


@class ScCachedEntity, ScMember;
@class ScState;

@interface ScMeta : NSObject <ScServerConnectionDelegate> {
@private
    Reachability *_internetReachability;

    NSString *_userId;
    NSDate *_authTokenExpiryDate;
    
    NSMutableSet *_scheduledEntities;
    NSMutableDictionary *_importedEntities;
    NSMutableDictionary *_importedEntityRefs;
}

@property (weak, nonatomic, readonly) NSManagedObjectContext *context;
@property (weak, nonatomic) ScMember *user;

@property (strong, nonatomic, readonly) NSString *deviceId;
@property (strong, nonatomic, readonly) NSString *authToken;
@property (strong, nonatomic, readonly) NSString *appVersion;
@property (strong, nonatomic, readonly) NSString *displayLanguage;
@property (strong, nonatomic) NSString *lastFetchDate;

@property (nonatomic, readonly) BOOL is_iPadDevice;
@property (nonatomic, readonly) BOOL is_iPodDevice;
@property (nonatomic, readonly) BOOL is_iPhoneDevice;
@property (nonatomic, readonly) BOOL isSimulatorDevice;
@property (nonatomic, readonly) BOOL isInternetConnectionWiFi;
@property (nonatomic, readonly) BOOL isInternetConnectionWWAN;

@property (nonatomic) BOOL isUserLoggedIn;

+ (ScMeta *)m;

+ (void)setUserDefault:(id)object forKey:(NSString *)key;
+ (id)userDefaultForKey:(NSString *)key;
+ (void)removeUserDefaultForKey:(NSString *)key;

+ (BOOL)isEmailValid:(UITextField *)emailField;
+ (BOOL)isPasswordValid:(UITextField *)passwordField;
+ (BOOL)isNameValid:(UITextField *)nameField;
+ (BOOL)isMobileNumberValid:(UITextField *)mobileNumberField;
+ (BOOL)isDateOfBirthValid:(UITextField *)dateField;
+ (BOOL)isAddressValidWithLine1:(UITextField *)line1Field line2:(UITextField *)line2Field;

- (void)checkInternetReachability;
- (BOOL)isInternetConnectionAvailable;

- (NSSet *)entitiesScheduledForPersistence;

- (void)addImportedEntity:(ScCachedEntity *)entity;
- (void)addImportedEntityRefs:(NSDictionary *)entityRefs forEntity:(ScCachedEntity *)entity;
- (ScCachedEntity *)importedEntityWithId:(NSString *)entityId;
- (NSDictionary *)importedEntityRefsForEntity:(ScCachedEntity *)entity;

@end
