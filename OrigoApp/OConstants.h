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
extern NSString * const kIdentifierOldOrigo;
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

// JSON keys
extern NSString * const kJSONKeyActivationCode;
extern NSString * const kJSONKeyDeviceId;
extern NSString * const kJSONKeyEmail;
extern NSString * const kJSONKeyEntityClass;
extern NSString * const kJSONKeyPasswordHash;

// Autonomous interface keys
extern NSString * const kInterfaceKeyActivate;
extern NSString * const kInterfaceKeyActivationCode;
extern NSString * const kInterfaceKeyAuthEmail;
extern NSString * const kInterfaceKeyPassword;
extern NSString * const kInterfaceKeyPurpose;
extern NSString * const kInterfaceKeyRepeatPassword;
extern NSString * const kInterfaceKeyResidenceName;
extern NSString * const kInterfaceKeySignIn;

// Entity property keys
extern NSString * const kPropertyKeyAddress;
extern NSString * const kPropertyKeyCountryCode;
extern NSString * const kPropertyKeyDateOfBirth;
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

// Icon file names
extern NSString * const kIconFileOrigo;
extern NSString * const kIconFileHousehold;
extern NSString * const kIconFileMan;
extern NSString * const kIconFileWoman;
extern NSString * const kIconFileBoy;
extern NSString * const kIconFileGirl;
extern NSString * const kIconFileInfant;
extern NSString * const kIconFileSettings;
extern NSString * const kIconFilePlus;
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

