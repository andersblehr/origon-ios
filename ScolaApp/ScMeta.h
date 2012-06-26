//
//  ScMeta.h
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ScServerConnectionDelegate.h"

extern NSString * const kBundleId;
extern NSString * const kDarkLinenImageFile;

extern NSString * const kMemberViewControllerId;
extern NSString * const kMembershipViewControllerId;

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
extern NSString * const kGenderNoneGiven;

extern NSString * const kLanguageHungarian;

@class Reachability, ScCachedEntity, ScServerConnection;

@interface ScMeta : NSObject <ScServerConnectionDelegate> {
@private
    Reachability *internetReachability;
    
    NSDate *authTokenExpiryDate;
    
    NSMutableSet *scheduledEntities;
    NSMutableDictionary *importedEntities;
    NSMutableDictionary *importedEntityRefs;
}

@property (nonatomic) BOOL isUserLoggedIn;

@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSString *homeScolaId;
@property (strong, nonatomic) NSString *lastFetchDate;

@property (strong, readonly) NSString *deviceId;
@property (strong, readonly) NSString *authToken;
@property (strong, readonly) NSString *appVersion;
@property (strong, readonly) NSString *displayLanguage;

@property (nonatomic, readonly) BOOL is_iPadDevice;
@property (nonatomic, readonly) BOOL is_iPodDevice;
@property (nonatomic, readonly) BOOL is_iPhoneDevice;
@property (nonatomic, readonly) BOOL isSimulatorDevice;

@property (nonatomic, readonly) BOOL isInternetConnectionWiFi;
@property (nonatomic, readonly) BOOL isInternetConnectionWWAN;

@property (weak, readonly) NSManagedObjectContext *managedObjectContext;
@property (strong, readonly) NSSet *entitiesScheduledForPersistence;

+ (ScMeta *)m;

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message tag:(NSInteger)tag delegate:(id)delegate;

+ (void)setUserDefault:(id)object forKey:(NSString *)key;
+ (id)userDefaultForKey:(NSString *)key;
+ (void)removeUserDefaultForKey:(NSString *)key;

+ (BOOL)isEmailValid:(UITextField *)emailField;
+ (BOOL)isEmailValid:(UITextField *)emailField silent:(BOOL)silent;
+ (BOOL)isPasswordValid:(UITextField *)passwordField;
+ (BOOL)isNameValid:(UITextField *)nameField;
+ (BOOL)isMobileNumberValid:(UITextField *)mobileNumberField;
+ (BOOL)isDateOfBirthValid:(UITextField *)dateField;
+ (BOOL)isAddressValidWithLine1:(NSString *)line1 line2:(NSString *)line2 postCodeAndCity:(NSString *)postCodeAndCity;

- (void)checkInternetReachability;
- (BOOL)isInternetConnectionAvailable;

- (void)addImportedEntity:(ScCachedEntity *)entity;
- (void)addImportedEntityRefs:(NSDictionary *)entityRefs forEntity:(ScCachedEntity *)entity;
- (ScCachedEntity *)importedEntityWithId:(NSString *)entityId;
- (NSDictionary *)importedEntityRefsForEntity:(ScCachedEntity *)entity;

@end
