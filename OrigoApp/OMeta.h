//
//  OMeta.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Reachability.h"

#import "OServerConnectionDelegate.h"

extern NSString * const kBundleId;
extern NSString * const kLanguageHungarian;

extern NSString * const kAuthViewControllerId;
extern NSString * const kOrigoListViewControllerId;
extern NSString * const kOrigoViewControllerId;
extern NSString * const kMemberListViewControllerId;
extern NSString * const kMemberViewControllerId;

extern NSString * const kPropertyEntityId;
extern NSString * const kPropertyEntityClass;
extern NSString * const kPropertyOrigoId;
extern NSString * const kPropertyName;
extern NSString * const kPropertyDateOfBirth;
extern NSString * const kPropertyMobilePhone;
extern NSString * const kPropertyGender;
extern NSString * const kPropertyDidRegister;

extern NSString * const kGenderFemale;
extern NSString * const kGenderMale;

extern NSString * const kOrigoTypeMemberRoot;
extern NSString * const kOrigoTypeResidence;
extern NSString * const kOrigoTypeSchoolClass;
extern NSString * const kOrigoTypePreschoolClass;
extern NSString * const kOrigoTypeSportsTeam;
extern NSString * const kOrigoTypeOther;

extern NSString * const kGuardianRoleParent;
extern NSString * const kGuardianRoleMother;
extern NSString * const kGuardianRoleFather;
extern NSString * const kGuardianRoleOther;

extern NSString * const kContactRoleResidenceElder;


@class OCachedEntity, OMember;

@interface OMeta : NSObject <OServerConnectionDelegate> {
@private
    Reachability *_internetReachability;

    NSDate *_authTokenExpiryDate;
    NSMutableSet *_modifiedEntities;
    NSMutableDictionary *_stagedServerEntities;
    NSMutableDictionary *_stagedServerEntityRefs;
}

@property (nonatomic, readonly) BOOL isUserLoggedIn;
@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic, readonly) OMember *user;

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

@property (weak, nonatomic, readonly) NSManagedObjectContext *context;

+ (OMeta *)m;

+ (BOOL)isEmailValid:(UITextField *)emailField;
+ (BOOL)isPasswordValid:(UITextField *)passwordField;
+ (BOOL)isNameValid:(UITextField *)nameField;
+ (BOOL)isMobileNumberValid:(UITextField *)mobileNumberField;
+ (BOOL)isDateOfBirthValid:(UITextField *)dateField;
+ (BOOL)isAddressValidWithLine1:(UITextField *)line1Field line2:(UITextField *)line2Field;

- (void)checkInternetReachability;
- (BOOL)isInternetConnectionAvailable;

- (void)userDidLogIn;

- (NSSet *)modifiedEntities;
- (void)stageServerEntity:(OCachedEntity *)entity;
- (void)stageServerEntityRefs:(NSDictionary *)entityRefs forEntity:(OCachedEntity *)entity;
- (OCachedEntity *)stagedServerEntityWithId:(NSString *)entityId;
- (NSDictionary *)stagedServerEntityRefsForEntity:(OCachedEntity *)entity;

@end
