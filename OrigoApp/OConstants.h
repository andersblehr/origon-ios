//
//  OConstants.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

// View controller identifiers
extern NSString * const kIdentifierAuth;
extern NSString * const kIdentifierCalendar;
extern NSString * const kIdentifierMember;
extern NSString * const kIdentifierMessageList;
extern NSString * const kIdentifierOrigo;
extern NSString * const kIdentifierOrigoList;
extern NSString * const kIdentifierTaskList;
extern NSString * const kIdentifierValueList;
extern NSString * const kIdentifierValuePicker;

// Reuse identifiers
extern NSString * const kReuseIdentifierUserSignIn;
extern NSString * const kReuseIdentifierUserActivation;

// Language codes
extern NSString * const kLanguageCodeEnglish;
extern NSString * const kLanguageCodeHungarian;

// NSUserDefaults keys
extern NSString * const kDefaultsKeyAuthInfo;
extern NSString * const kDefaultsKeyDirtyEntities;

// Entity property keys
extern NSString * const kPropertyKeyActiveSince;
extern NSString * const kPropertyKeyAddress;
extern NSString * const kPropertyKeyCountryCode;
extern NSString * const kPropertyKeyDateCreated;
extern NSString * const kPropertyKeyDateExpires;
extern NSString * const kPropertyKeyDateOfBirth;
extern NSString * const kPropertyKeyDateReplicated;
extern NSString * const kPropertyKeyDescriptionText;
extern NSString * const kPropertyKeyEmail;
extern NSString * const kPropertyKeyEntityId;
extern NSString * const kPropertyKeyFatherId;
extern NSString * const kPropertyKeyGender;
extern NSString * const kPropertyKeyHashCode;
extern NSString * const kPropertyKeyIsAwaitingDeletion;
extern NSString * const kPropertyKeyIsExpired;
extern NSString * const kPropertyKeyIsMinor;
extern NSString * const kPropertyKeyMobilePhone;
extern NSString * const kPropertyKeyMotherId;
extern NSString * const kPropertyKeyName;
extern NSString * const kPropertyKeyOrigoId;
extern NSString * const kPropertyKeyPasswordHash;
extern NSString * const kPropertyKeyPhoto;
extern NSString * const kPropertyKeyTelephone;
extern NSString * const kPropertyKeyType;

// Entity relationship keys
extern NSString * const kRelationshipKeyMember;
extern NSString * const kRelationshipKeyOrigo;

// Mapped keys
extern NSString * const kMappedKeyClub;
extern NSString * const kMappedKeyFullName;
extern NSString * const kMappedKeyGivenName;
extern NSString * const kMappedKeyOrganisation;
extern NSString * const kMappedKeyOrganisationDescription;
extern NSString * const kMappedKeyPreschool;
extern NSString * const kMappedKeyPreschoolClass;
extern NSString * const kMappedKeyResidenceName;
extern NSString * const kMappedKeySchool;
extern NSString * const kMappedKeySchoolClass;
extern NSString * const kMappedKeyStudentGroup;
extern NSString * const kMappedKeyTeam;
extern NSString * const kMappedKeyUniversity;

// Unbound keys
extern NSString * const kExternalKeyActivate;
extern NSString * const kExternalKeyActivationCode;
extern NSString * const kExternalKeyAuthEmail;
extern NSString * const kExternalKeyDeviceId;
extern NSString * const kExternalKeyEntityClass;
extern NSString * const kExternalKeyPassword;
extern NSString * const kExternalKeyRepeatPassword;
extern NSString * const kExternalKeySignIn;

// String key prefixes
extern NSString * const kStringPrefixDefault;
extern NSString * const kStringPrefixLabel;
extern NSString * const kStringPrefixAlternateLabel;
extern NSString * const kStringPrefixSettingLabel;
extern NSString * const kStringPrefixPlaceholder;
extern NSString * const kStringPrefixOrigoTitle;
extern NSString * const kStringPrefixNewOrigoTitle;
extern NSString * const kStringPrefixFooter;
extern NSString * const kStringPrefixAddMemberButton;
extern NSString * const kStringPrefixAddOrganiserButton;
extern NSString * const kStringPrefixEditMemberRolesButton;
extern NSString * const kStringPrefixOrganiserTitle;
extern NSString * const kStringPrefixMemberListTitle;
extern NSString * const kStringPrefixNewMemberTitle;
extern NSString * const kStringPrefixAllMembersTitle;
extern NSString * const kStringPrefixOrganiserRoleTitle;
extern NSString * const kStringPrefixMemberRoleTitle;
extern NSString * const kStringPrefixMemberRolesTitle;
extern NSString * const kStringPrefixSettingTitle;

// Icon file names
extern NSString * const kIconFileOrigo;
extern NSString * const kIconFileHousehold;
extern NSString * const kIconFileMan;
extern NSString * const kIconFileWoman;
extern NSString * const kIconFileBoy;
extern NSString * const kIconFileGirl;
extern NSString * const kIconFileInfant;
extern NSString * const kIconFileMultiRole;
extern NSString * const kIconFileMultiRoleSelected;
extern NSString * const kIconFileSettings;
extern NSString * const kIconFilePlus;
extern NSString * const kIconFileEdit;
extern NSString * const kIconFileMap;
extern NSString * const kIconFileInfo;
extern NSString * const kIconFileAction;
extern NSString * const kIconFileLookup;
extern NSString * const kIconFilePlacePhoneCall;
extern NSString * const kIconFilePlacePhoneCall_iOS6x;
extern NSString * const kIconFileSendText;
extern NSString * const kIconFileSendText_iOS6x;
extern NSString * const kIconFileSendEmail;
extern NSString * const kIconFileSendEmail_iOS6x;
extern NSString * const kIconFileLocationArrow;

// Gender codes
extern NSString * const kGenderMale;
extern NSString * const kGenderFemale;

// Age thresholds
extern NSInteger const kAgeThresholdInSchool;
extern NSInteger const kAgeThresholdTeen;
extern NSInteger const kAgeOfConsent;
extern NSInteger const kAgeOfMajority;

// Misc constants
extern NSString * const kCustomData;
