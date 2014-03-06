//
//  OStrings.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

// String key prefixes
extern NSString * const kKeyPrefixDefault;
extern NSString * const kKeyPrefixLabel;
extern NSString * const kKeyPrefixAlternateLabel;
extern NSString * const kKeyPrefixPlaceholder;
extern NSString * const kKeyPrefixOrigoTitle;
extern NSString * const kKeyPrefixNewOrigoTitle;
extern NSString * const kKeyPrefixFooter;
extern NSString * const kKeyPrefixAddMemberButton;
extern NSString * const kKeyPrefixAddContactButton;
extern NSString * const kKeyPrefixContactTitle;
extern NSString * const kKeyPrefixMemberListTitle;
extern NSString * const kKeyPrefixNewMemberTitle;
extern NSString * const kKeyPrefixAllMembersTitle;
extern NSString * const kKeyPrefixContactRole;
extern NSString * const kKeyPrefixSettingTitle;
extern NSString * const kKeyPrefixSettingLabel;

// Cross-view strings
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
extern NSString * const strTermYes;
extern NSString * const strTermNo;
extern NSString * const strTermMan;
extern NSString * const strTermBoy;
extern NSString * const strTermWoman;
extern NSString * const strTermGirl;
extern NSString * const strTermParentContact;

extern NSString * const strFormatAge;
extern NSString * const strSeparatorAnd;

// OAuthViewController strings
extern NSString * const strLabelSignIn;
extern NSString * const strLabelActivate;
extern NSString * const strFooterSignInOrRegister;
extern NSString * const strFooterActivateUser;
extern NSString * const strFooterActivateEmail;
extern NSString * const strPlaceholderAuthEmail;
extern NSString * const strPlaceholderPassword;
extern NSString * const strPlaceholderActivationCode;
extern NSString * const strPlaceholderRepeatPassword;
extern NSString * const strButtonHaveCode;
extern NSString * const strButtonStartOver;
extern NSString * const strAlertTitleActivationFailed;
extern NSString * const strAlertTextActivationFailed;
extern NSString * const strAlertTitleWelcomeBack;
extern NSString * const strAlertTextWelcomeBack;

// OOrigoListViewController strings
extern NSString * const strViewTitleOrigo;
extern NSString * const strHeaderWardsOrigos;
extern NSString * const strHeaderMyOrigos;
extern NSString * const strFooterOrigoCreationFirst;
extern NSString * const strFooterOrigoCreation;
extern NSString * const strFooterOrigoCreationWards;
extern NSString * const strAlertTitleListedUserRegistration;
extern NSString * const strAlertTextListedUserRegistration;
extern NSString * const strAlertTitleIncompleteRegistration;
extern NSString * const strAlertTextIncompleteRegistration;
extern NSString * const strSheetPromptOrigoType;
extern NSString * const strTextNoOrigos;
extern NSString * const strTermYourChild;
extern NSString * const strTermHimOrHer;
extern NSString * const strTermForName;

// OOrigoViewController strings
extern NSString * const strLabelAddress;
extern NSString * const strLabelPurpose;
extern NSString * const strLabelDescriptionText;
extern NSString * const strLabelTelephone;
extern NSString * const strPlaceholderAddress;
extern NSString * const strPlaceholderDescriptionText;
extern NSString * const strPlaceholderTelephone;
extern NSString * const strButtonEditRoles;
extern NSString * const strButtonAddFromOrigo;
extern NSString * const strButtonAddParentContact;
extern NSString * const strButtonShowInMap;
extern NSString * const strButtonAbout;
extern NSString * const strButtonNewHousemate;
extern NSString * const strButtonOtherGuardian;
extern NSString * const strButtonDeleteMember;

// OMemberViewController strings
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
extern NSString * const strButtonAllGuardians;
extern NSString * const strButtonRetrieveFromContacts;
extern NSString * const strButtonRetrieveFromOrigo;
extern NSString * const strButtonDifferentNumber;
extern NSString * const strButtonDifferentEmail;
extern NSString * const strButtonInviteToHousehold;
extern NSString * const strButtonMergeHouseholds;
extern NSString * const strAlertTitleDataConflict;
extern NSString * const strAlertTextDataConflict;
extern NSString * const strAlertTitleMembershipExists;
extern NSString * const strAlertTextMembershipExists;
extern NSString * const strAlertTitleUserEmailChange;
extern NSString * const strAlertTextUserEmailChange;
extern NSString * const strAlertTitleEmailChangeFailed;
extern NSString * const strAlertTextEmailChangeFailed;
extern NSString * const strSheetPromptEmailRecipient;
extern NSString * const strSheetPromptTextRecipient;
extern NSString * const strSheetPromptCallRecipient;
extern NSString * const strSheetPromptMultiValuePhone;
extern NSString * const strSheetPromptMultiValueEmail;
extern NSString * const strSheetPromptExistingResidence;
extern NSString * const strQuestionArgumentGender;
extern NSString * const strQuestionArgumentGenderMinor;
extern NSString * const strTermHisFather;
extern NSString * const strTermHerFather;
extern NSString * const strTermHisMother;
extern NSString * const strTermHerMother;

// OCalendarViewController strings
extern NSString * const strViewTitleCalendar;

// OTaskListViewController strings
extern NSString * const strViewTitleTasks;

// OMessageListViewController strings
extern NSString * const strViewTitleMessages;

// OValueListViewController strings
extern NSString * const strViewTitleSettings;

// OValuePickerViewController strings
extern NSString * const strSegmentedTitleAdultsMinors;

// Meta strings
extern NSString * const metaSupportedLanguages;
extern NSString * const metaMultiLingualCountryCodes;
extern NSString * const metaCountryCodesByCountryCallingCode;
extern NSString * const metaInternationalTemplate;
extern NSString * const metaPhoneNumberTemplatesByRegion;
extern NSString * const metaContactRolesSchoolClass;
extern NSString * const metaContactRolesPreschoolClass;
extern NSString * const metaContactRolesOrganisation;
extern NSString * const metaContactRolesSportsTeam;

@interface OStrings : NSObject

+ (BOOL)hasStrings;
+ (void)refreshIfNeeded;

+ (NSString *)stringForKey:(NSString *)key;
+ (NSString *)stringForKey:(NSString *)key withKeyPrefix:(NSString *)prefix;

@end
