//
//  OStrings.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

// Cross-view terms & strings
extern NSString * const strFooterTapToEdit;
extern NSString * const strFooterOrigoSignature;
extern NSString * const strButtonOK;
extern NSString * const strButtonEdit;
extern NSString * const strButtonNext;
extern NSString * const strButtonDone;
extern NSString * const strButtonContinue;
extern NSString * const strButtonCancel;
extern NSString * const strButtonSignOut;
extern NSString * const strAlertTextNoInternet;
extern NSString * const strAlertTextServerError;
extern NSString * const strAlertTextLocating;
extern NSString * const strTermYes;
extern NSString * const strTermNo;
extern NSString * const strTermMan;
extern NSString * const strTermBoy;
extern NSString * const strTermWoman;
extern NSString * const strTermGirl;
extern NSString * const strFormatAge;
extern NSString * const strSeparatorAnd;

// OAuthView strings
extern NSString * const strLabelSignIn;
extern NSString * const strLabelActivate;
extern NSString * const strFooterSignInOrRegister;
extern NSString * const strFooterActivateUser;
extern NSString * const strFooterActivateEmail;
extern NSString * const strPlaceholderAuthEmail;
extern NSString * const strPlaceholderPassword;
extern NSString * const strPlaceholderActivationCode;
extern NSString * const strPlaceholderRepeatPassword;
extern NSString * const strPlaceholderPleaseWait;
extern NSString * const strButtonHaveCode;
extern NSString * const strButtonStartOver;
extern NSString * const strAlertTitleActivationFailed;
extern NSString * const strAlertTextActivationFailed;
extern NSString * const strAlertTitleWelcomeBack;
extern NSString * const strAlertTextWelcomeBack;

// OOrigoListView strings
extern NSString * const strTabBarTitleOrigo;
extern NSString * const strHeaderWardsOrigos;
extern NSString * const strHeaderMyOrigos;
extern NSString * const strFooterOrigoCreationFirst;
extern NSString * const strFooterOrigoCreation;
extern NSString * const strFooterOrigoCreationWards;
extern NSString * const strButtonCountryLocate;
extern NSString * const strButtonCountryOther;
extern NSString * const strAlertTitleListedUserRegistration;
extern NSString * const strAlertTextListedUserRegistration;
extern NSString * const strAlertTitleIncompleteRegistration;
extern NSString * const strAlertTextIncompleteRegistration;
extern NSString * const strAlertTitleCountryOther;
extern NSString * const strAlertTextCountryOther;
extern NSString * const strAlertTextCountrySupported;
extern NSString * const strAlertTextCountryUnsupported;
extern NSString * const strSheetTitleCountry;
extern NSString * const strSheetTitleOrigoType;
extern NSString * const strTermYourChild;
extern NSString * const strTermHimOrHer;
extern NSString * const strTermForName;

// OMemberListView strings
extern NSString * const strFooterResidence;
extern NSString * const strFooterSchoolClass;
extern NSString * const strFooterPreschoolClass;
extern NSString * const strFooterSportsTeam;
extern NSString * const strFooterOtherOrigo;
extern NSString * const strButtonNewHousemate;
extern NSString * const strButtonOtherGuardian;
extern NSString * const strButtonDeleteMember;

// OOrigoView strings
extern NSString * const strDefaultResidenceName;
extern NSString * const strViewTitleNewOrigo;
extern NSString * const strLabelAddress;
extern NSString * const strLabelPurpose;
extern NSString * const strLabelDescriptionText;
extern NSString * const strLabelTelephone;
extern NSString * const strPlaceholderAddress;
extern NSString * const strPlaceholderDescriptionText;
extern NSString * const strPlaceholderTelephone;

// OMemberView strings
extern NSString * const strViewTitleAboutMe;
extern NSString * const strLabelDateOfBirth;
extern NSString * const strLabelMobilePhone;
extern NSString * const strLabelEmail;
extern NSString * const strPlaceholderName;
extern NSString * const strPlaceholderPhoto;
extern NSString * const strPlaceholderDateOfBirth;
extern NSString * const strPlaceholderMobilePhone;
extern NSString * const strPlaceholderEmail;
extern NSString * const strFooterOrigoInviteAlert;
extern NSString * const strFooterJuvenileOrigoGuardian;
extern NSString * const strButtonParentToSome;
extern NSString * const strButtonAddAddress;
extern NSString * const strButtonChangePassword;
extern NSString * const strButtonEditRelations;
extern NSString * const strButtonCorrectGender;
extern NSString * const strButtonNewAddress;
extern NSString * const strButtonAllContacts;
extern NSString * const strButtonInviteToHousehold;
extern NSString * const strButtonMergeHouseholds;
extern NSString * const strAlertTitleMemberExists;
extern NSString * const strAlertTextMemberExists;
extern NSString * const strAlertTitleUserEmailChange;
extern NSString * const strAlertTextUserEmailChange;
extern NSString * const strAlertTitleEmailChangeFailed;
extern NSString * const strAlertTextEmailChangeFailed;
extern NSString * const strSheetTitleEmailRecipient;
extern NSString * const strSheetTitleTextRecipient;
extern NSString * const strSheetTitlePhoneCallRecipient;
extern NSString * const strSheetTitleExistingResidence;
extern NSString * const strQuestionArgumentGender;
extern NSString * const strQuestionArgumentGenderMinor;
extern NSString * const strTermHisFather;
extern NSString * const strTermHerFather;
extern NSString * const strTermHisMother;
extern NSString * const strTermHerMother;

// OCalendarView strings
extern NSString * const strTabBarTitleCalendar;

// OTaskListView strings
extern NSString * const strTabBarTitleTasks;

// OMessageListView strings
extern NSString * const strTabBarTitleMessages;
extern NSString * const strDefaultMessageBoardName;

// OSettingListView strings
extern NSString * const strTabBarTitleSettings;
extern NSString * const strSettingTitleCountry;
extern NSString * const strSettingTextCountry;

// OSettingView strings
extern NSString * const strLabelCountrySettings;
extern NSString * const strLabelCountryLocation;
extern NSString * const strFooterCountryInfo;
extern NSString * const strFooterCountryInfoNote;
extern NSString * const strFooterCountryInfoLocate;

// Origo type strings
extern NSString * const kOrigoLabelTypeOrigo;
extern NSString * const kOrigoLabelTypeOrigoNew;
extern NSString * const kOrigoLabelTypeMemberList;
extern NSString * const kOrigoLabelTypeMemberNew;

// Meta strings
extern NSString * const metaSupportedCountryCodes;
extern NSString * const metaContactRolesSchoolClass;
extern NSString * const metaContactRolesPreschoolClass;
extern NSString * const metaContactRolesOrganisation;
extern NSString * const metaContactRolesSportsTeam;

@interface OStrings : NSObject

+ (BOOL)hasStrings;
+ (void)refreshIfNeeded;

+ (NSString *)stringForKey:(NSString *)key;
+ (NSString *)labelForKey:(NSString *)key;
+ (NSString *)placeholderForKey:(NSString *)key;

+ (NSString *)labelForOrigoType:(NSString *)origoType labelType:(NSString *)labelType;
+ (NSString *)footerForOrigoType:(NSString *)origoType;
+ (NSString *)titleForContactRole:(NSString *)contactRole;
+ (NSString *)titleForSettingKey:(NSString *)settingKey;
+ (NSString *)labelForSettingKey:(NSString *)settingKey;

@end
