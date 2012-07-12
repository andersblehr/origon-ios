//
//  ScMeta.h
//  ScolaApp
//
//  Created by Anders Blehr on 12.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ScServerConnectionDelegate.h"

typedef enum {
/*  0 */ ScAppStateNeutral,
/*  1 */ ScAppStateStartup,
/*  2 */ ScAppStateLoginUser,
/*  3 */ ScAppStateConfirmSignUp,
/*  4 */ ScAppStateRegisterUser,
/*  5 */ ScAppStateRegisterUserHousehold,
/*  6 */ ScAppStateRegisterUserHouseholdMemberships,
/*  7 */ ScAppStateRegisterUserHouseholdMember,
/*  8 */ ScAppStateRegisterScola,
/*  9 */ ScAppStateRegisterScolaMemberships,
/* 10 */ ScAppStateRegisterScolaMember,
/* 11 */ ScAppStateRegisterScolaMemberHousehold,
/* 12 */ ScAppStateRegisterScolaMemberHouseholdMemberships,
/* 13 */ ScAppStateRegisterScolaMemberHouseholdMember,
/* 14 */ ScAppStateDisplayUser,
/* 15 */ ScAppStateDisplayUserHousehold,
/* 16 */ ScAppStateDisplayUserHouseholdMemberships,
/* 17 */ ScAppStateDisplayUserHouseholdMember,
/* 18 */ ScAppStateDisplayScola,
/* 19 */ ScAppStateDisplayScolaMemberships,
/* 20 */ ScAppStateDisplayScolaMember,
/* 21 */ ScAppStateDisplayScolaMemberHousehold,
/* 22 */ ScAppStateDisplayScolaMemberHouseholdMemberships,
/* 23 */ ScAppStateDisplayScolaMemberHouseholdMember,
/* 24 */ ScAppStateEditUser,
/* 25 */ ScAppStateEditHousehold,
/* 26 */ ScAppStateEditHouseholdMember,
/* 27 */ ScAppStateEditScola,
/* 18 */ ScAppStateEditScolaMember,
} ScAppState;

extern NSString * const kBundleId;
extern NSString * const kDarkLinenImageFile;

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
extern NSString * const kGenderNoneGiven;

extern NSString * const kLanguageHungarian;

@class Reachability, ScCachedEntity, ScServerConnection;

@interface ScMeta : NSObject <ScServerConnectionDelegate> {
@private
    Reachability *internetReachability;

    NSDate *authTokenExpiryDate;
    NSMutableArray *appStateStack;
    
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

+ (ScAppState)appState;
+ (void)pushAppState:(ScAppState)appState;
+ (void)popAppState;

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;

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

- (void)addImportedEntity:(ScCachedEntity *)entity;
- (void)addImportedEntityRefs:(NSDictionary *)entityRefs forEntity:(ScCachedEntity *)entity;
- (ScCachedEntity *)importedEntityWithId:(NSString *)entityId;
- (NSDictionary *)importedEntityRefsForEntity:(ScCachedEntity *)entity;

@end
