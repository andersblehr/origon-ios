//
//  OConstants.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

// View controller identifiers
extern NSString * const kIdentifierAuth;
extern NSString * const kIdentifierInfo;
extern NSString * const kIdentifierJoiner;
extern NSString * const kIdentifierMap;
extern NSString * const kIdentifierMember;
extern NSString * const kIdentifierOrigo;
extern NSString * const kIdentifierOrigoList;
extern NSString * const kIdentifierRecipientPicker;
extern NSString * const kIdentifierValueList;
extern NSString * const kIdentifierValuePicker;

// Reuse identifiers
extern NSString * const kReuseIdentifierUserLogin;
extern NSString * const kReuseIdentifierUserActivation;
extern NSString * const kReuseIdentifierPasswordChange;

// Language codes
extern NSString * const kLanguageCodeEnglish;

// NSUserDefaults keys
extern NSString * const kDefaultsKeyAuthInfo;
extern NSString * const kDefaultsKeyDirtyEntities;

// Entity property keys
extern NSString * const kPropertyKeyActiveSince;
extern NSString * const kPropertyKeyAddress;
extern NSString * const kPropertyKeyCreatedBy;
extern NSString * const kPropertyKeyCreatedIn;
extern NSString * const kPropertyKeyDateCreated;
extern NSString * const kPropertyKeyDateOfBirth;
extern NSString * const kPropertyKeyDateReplicated;
extern NSString * const kPropertyKeyDescriptionText;
extern NSString * const kPropertyKeyEmail;
extern NSString * const kPropertyKeyEntityId;
extern NSString * const kPropertyKeyFatherId;
extern NSString * const kPropertyKeyGender;
extern NSString * const kPropertyKeyHashCode;
extern NSString * const kPropertyKeyIsExpired;
extern NSString * const kPropertyKeyIsMinor;
extern NSString * const kPropertyKeyJoinCode;
extern NSString * const kPropertyKeyLocation;
extern NSString * const kPropertyKeyMobilePhone;
extern NSString * const kPropertyKeyModifiedBy;
extern NSString * const kPropertyKeyMotherId;
extern NSString * const kPropertyKeyName;
extern NSString * const kPropertyKeyOrigoId;
extern NSString * const kPropertyKeyPasswordHash;
extern NSString * const kPropertyKeyPermissions;
extern NSString * const kPropertyKeyPhoto;
extern NSString * const kPropertyKeyTelephone;
extern NSString * const kPropertyKeyType;

// Entity relationship keys
extern NSString * const kRelationshipKeyMember;
extern NSString * const kRelationshipKeyOrigo;

// Mapped keys
extern NSString * const kMappedKeyArena;
extern NSString * const kMappedKeyClub;
extern NSString * const kMappedKeyFullName;
extern NSString * const kMappedKeyListName;
extern NSString * const kMappedKeyPreschool;
extern NSString * const kMappedKeyPreschoolClass;
extern NSString * const kMappedKeyPrivateListName;
extern NSString * const kMappedKeyResidenceName;
extern NSString * const kMappedKeySchool;
extern NSString * const kMappedKeySchoolClass;

// Internal keys
extern NSString * const kInternalKeyDeviceId;
extern NSString * const kInternalKeyInlineCellContent;
extern NSString * const kInternalKeyEntityClass;

// Label keys
extern NSString * const kLabelKeyActivate;
extern NSString * const kLabelKeyAdmins;
extern NSString * const kLabelKeyRegisterOrLogIn;

// Input keys
extern NSString * const kInputKeyActivationCode;
extern NSString * const kInputKeyAuthEmail;
extern NSString * const kInputKeyNewPassword;
extern NSString * const kInputKeyOldPassword;
extern NSString * const kInputKeyPassword;
extern NSString * const kInputKeyRepeatNewPassword;
extern NSString * const kInputKeyRepeatPassword;

// Action keys
extern NSString * const kActionKeyActivate;
extern NSString * const kActionKeyCancel;
extern NSString * const kActionKeyChangePassword;
extern NSString * const kActionKeyJoinOrigo;
extern NSString * const kActionKeyLogin;
extern NSString * const kActionKeyLogout;
extern NSString * const kActionKeyPingServer;
extern NSString * const kActionKeyRegister;

// Placeholders
extern NSString * const kPlaceholderDefault;

// String prefixes
extern NSString * const kStringPrefixLabel;
extern NSString * const kStringPrefixAlternateLabel;
extern NSString * const kStringPrefixTitle;
extern NSString * const kStringPrefixSettingLabel;
extern NSString * const kStringPrefixPlaceholder;
extern NSString * const kStringPrefixOrigoTitle;
extern NSString * const kStringPrefixFooter;
extern NSString * const kStringPrefixAddMemberButton;
extern NSString * const kStringPrefixMemberTitle;
extern NSString * const kStringPrefixMembersTitle;
extern NSString * const kStringPrefixNewMemberTitle;
extern NSString * const kStringPrefixAllMembersTitle;
extern NSString * const kStringPrefixOrganiserRoleTitle;
extern NSString * const kStringPrefixAddOrganiserButton;
extern NSString * const kStringPrefixOrganiserTitle;
extern NSString * const kStringPrefixOrganisersTitle;
extern NSString * const kStringPrefixAddOrganiserRoleButton;
extern NSString * const kStringPrefixEditOrganiserRoleButton;
extern NSString * const kStringPrefixSettingTitle;

// Icon file names
extern NSString * const kIconFileLogo;
extern NSString * const kIconFileLogoSmall;
extern NSString * const kIconFileResidence;
extern NSString * const kIconFileList;
extern NSString * const kIconFileOrigo;
extern NSString * const kIconFileSettings;
extern NSString * const kIconFile_iPad;
extern NSString * const kIconFile_iPhone;
extern NSString * const kIconFile_iPodTouch;
extern NSString * const kIconFileMan;
extern NSString * const kIconFileWoman;
extern NSString * const kIconFileBoy;
extern NSString * const kIconFileGirl;
extern NSString * const kIconFileEdit;
extern NSString * const kIconFileLocation;
extern NSString * const kIconFileDirections;
extern NSString * const kIconFileNavigation;
extern NSString * const kIconFileGroups;
extern NSString * const kIconFileRecipientGroups;
extern NSString * const kIconFileInfo;
extern NSString * const kIconFileLookup;
extern NSString * const kIconFileAllContacts;
extern NSString * const kIconFileFavouriteNo;
extern NSString * const kIconFileFavouriteYes;
extern NSString * const kIconFileAcceptDecline;
extern NSString * const kIconFileJoin;
extern NSString * const kIconFileCall;
extern NSString * const kIconFileSendText;
extern NSString * const kIconFileSendEmail;
extern NSString * const kIconFileTwoHeads;

// Gender codes
extern NSString * const kGenderMale;
extern NSString * const kGenderFemale;

// Recipient types
extern NSInteger const kRecipientTypeText;
extern NSInteger const kRecipientTypeCall;
extern NSInteger const kRecipientTypeEmail;

// Age thresholds
extern NSInteger const kAgeThresholdInSchool;
extern NSInteger const kAgeThresholdTeen;
extern NSInteger const kAgeOfConsent;
extern NSInteger const kAgeOfMajority;

// Geometry constants
extern CGFloat const kNavigationBarHeight;
extern CGFloat const kNavigationBarTitleHeight;
extern CGFloat const kToolbarBarHeight;
extern CGFloat const kBorderWidth;
extern CGFloat const kContentInset;

// Misc constants
extern NSString * const kCustomData;
