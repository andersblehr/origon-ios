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
extern NSString * const kPropertyKeyLastSeen;
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
extern NSString * const kMappedKeyStudyGroup;
extern NSString * const kMappedKeyTeam;
extern NSString * const kMappedKeyInstitution;

// Unbound keys
extern NSString * const kExternalKeyActivate;
extern NSString * const kExternalKeyActivationCode;
extern NSString * const kExternalKeyAuthEmail;
extern NSString * const kExternalKeyDeviceId;
extern NSString * const kExternalKeyEntityClass;
extern NSString * const kExternalKeyPassword;
extern NSString * const kExternalKeyRepeatPassword;
extern NSString * const kExternalKeySignIn;

// Button keys
extern NSString * const kButtonKeyDeleteRow;

// String key prefixes
extern NSString * const kStringPrefixDefault;
extern NSString * const kStringPrefixLabel;
extern NSString * const kStringPrefixAlternateLabel;
extern NSString * const kStringPrefixSettingLabel;
extern NSString * const kStringPrefixSettingListLabel;
extern NSString * const kStringPrefixPlaceholder;
extern NSString * const kStringPrefixOrigoTitle;
extern NSString * const kStringPrefixNewOrigoTitle;
extern NSString * const kStringPrefixFooter;
extern NSString * const kStringPrefixAddMemberButton;
extern NSString * const kStringPrefixAddOrganiserButton;
extern NSString * const kStringPrefixOrganiserTitle;
extern NSString * const kStringPrefixOrganisersTitle;
extern NSString * const kStringPrefixMembersTitle;
extern NSString * const kStringPrefixNewMemberTitle;
extern NSString * const kStringPrefixAllMembersTitle;
extern NSString * const kStringPrefixOrganiserRoleTitle;
extern NSString * const kStringPrefixAddOrganiserRoleButton;
extern NSString * const kStringPrefixEditOrganiserRoleButton;
extern NSString * const kStringPrefixMemberRoleTitle;
extern NSString * const kStringPrefixSettingTitle;

// Icon file names
extern NSString * const kIconFileOrigo;
extern NSString * const kIconFileSettings;
extern NSString * const kIconFile_iPad;
extern NSString * const kIconFile_iPhone;
extern NSString * const kIconFile_iPodTouch;
extern NSString * const kIconFileHousehold;
extern NSString * const kIconFileMan;
extern NSString * const kIconFileWoman;
extern NSString * const kIconFileBoy;
extern NSString * const kIconFileGirl;
extern NSString * const kIconFileEdit;
extern NSString * const kIconFileMap;
extern NSString * const kIconFileInfo;
extern NSString * const kIconFileLookup;
extern NSString * const kIconFileAcceptReject;
extern NSString * const kIconFilePlacePhoneCall;
extern NSString * const kIconFileSendText;
extern NSString * const kIconFileSendEmail;
extern NSString * const kIconFileRoleHolders;
extern NSString * const kIconFileMultiRoleOff;
extern NSString * const kIconFileMultiRoleOn;
extern NSString * const kIconFileGroups;

// Gender codes
extern NSString * const kGenderMale;
extern NSString * const kGenderFemale;

// Age thresholds
extern NSInteger const kAgeThresholdInSchool;
extern NSInteger const kAgeThresholdTeen;
extern NSInteger const kAgeOfConsent;
extern NSInteger const kAgeOfMajority;

// Geometry constants
extern CGFloat const kNavigationBarHeight;
extern CGFloat const kToolbarBarHeight;
extern CGFloat const kBorderWidth;
extern CGFloat const kContentInset;
extern CGFloat const kLineToHeaderHeightFactor;

// Misc constants
extern NSString * const kCustomData;
