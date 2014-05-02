//
//  OConstants.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OConstants.h"

// View controller identifiers
NSString * const kIdentifierAuth = @"auth";
NSString * const kIdentifierCalendar = @"calendar";
NSString * const kIdentifierMember = @"member";
NSString * const kIdentifierMessageList = @"messages";
NSString * const kIdentifierOldOrigo = @"old";
NSString * const kIdentifierOrigo = @"origo";
NSString * const kIdentifierOrigoList = @"origos";
NSString * const kIdentifierTaskList = @"tasks";
NSString * const kIdentifierValueList = @"values";
NSString * const kIdentifierValuePicker = @"value";

// Reuse identifiers
NSString * const kReuseIdentifierUserSignIn = @"signIn";
NSString * const kReuseIdentifierUserActivation = @"activate";

// Language codes
NSString * const kLanguageCodeEnglish = @"en";
NSString * const kLanguageCodeHungarian = @"hu";

// NSUserDefaults keys
NSString * const kDefaultsKeyAuthInfo = @"origo.auth.info";
NSString * const kDefaultsKeyDirtyEntities = @"origo.state.dirtyEntities";

// JSON keys
NSString * const kJSONKeyActivationCode = @"activationCode";
NSString * const kJSONKeyDeviceId = @"deviceId";
NSString * const kJSONKeyEmail = @"email";
NSString * const kJSONKeyEntityClass = @"entityClass";
NSString * const kJSONKeyPasswordHash = @"passwordHash";

// Autonomous interface keys
NSString * const kInterfaceKeyActivate = @"activate";
NSString * const kInterfaceKeyActivationCode = @"activationCode";
NSString * const kInterfaceKeyAuthEmail = @"authEmail";
NSString * const kInterfaceKeyPassword = @"password";
NSString * const kInterfaceKeyPurpose = @"purpose";
NSString * const kInterfaceKeyResidenceName = @"residenceName";
NSString * const kInterfaceKeyRepeatPassword = @"repeatPassword";
NSString * const kInterfaceKeySignIn = @"signIn";

// Entity property keys
NSString * const kPropertyKeyAddress = @"address";
NSString * const kPropertyKeyCountryCode = @"countryCode";
NSString * const kPropertyKeyDateOfBirth = @"dateOfBirth";
NSString * const kPropertyKeyDescriptionText = @"descriptionText";
NSString * const kPropertyKeyEmail = @"email";
NSString * const kPropertyKeyEntityId = @"entityId";
NSString * const kPropertyKeyFatherId = @"fatherId";
NSString * const kPropertyKeyGender = @"gender";
NSString * const kPropertyKeyHashCode = @"hashCode";
NSString * const kPropertyKeyIsAwaitingDeletion = @"isAwaitingDeletion";
NSString * const kPropertyKeyIsExpired = @"isExpired";
NSString * const kPropertyKeyIsMinor = @"isMinor";
NSString * const kPropertyKeyMobilePhone = @"mobilePhone";
NSString * const kPropertyKeyMotherId = @"motherId";
NSString * const kPropertyKeyName = @"name";
NSString * const kPropertyKeyOrigoId = @"origoId";
NSString * const kPropertyKeyPasswordHash = @"passwordHash";
NSString * const kPropertyKeyPhoto = @"photo";
NSString * const kPropertyKeyTelephone = @"telephone";
NSString * const kPropertyKeyType = @"type";

// Entity relationship keys
NSString * const kRelationshipKeyMember = @"member";
NSString * const kRelationshipKeyMemberships = @"memberships";
NSString * const kRelationshipKeyOrigo = @"origo";

// String key prefixes
NSString * const kStringPrefixDefault = @"[default]";
NSString * const kStringPrefixLabel = @"[label]";
NSString * const kStringPrefixAlternateLabel = @"[alternate label]";
NSString * const kStringPrefixPlaceholder = @"[placeholder]";
NSString * const kStringPrefixOrigoTitle = @"[title]";
NSString * const kStringPrefixNewOrigoTitle = @"[registration title]";
NSString * const kStringPrefixFooter = @"[registration footer]";
NSString * const kStringPrefixAddMemberButton = @"[add member]";
NSString * const kStringPrefixAddContactButton = @"[add contact]";
NSString * const kStringPrefixContactTitle = @"[contact title]";
NSString * const kStringPrefixMemberListTitle = @"[member list]";
NSString * const kStringPrefixNewMemberTitle = @"[member registration]";
NSString * const kStringPrefixAllMembersTitle = @"[all members]";
NSString * const kStringPrefixContactRole = @"[contact role]";
NSString * const kStringPrefixSettingTitle = @"[setting title]";
NSString * const kStringPrefixSettingLabel = @"[setting label]";

// Icon file names
NSString * const kIconFileOrigo = @"10-arrows-in_black.png";
NSString * const kIconFileHousehold = @"glyphicons_020_home.png";
NSString * const kIconFileMan = @"glyphicons_003_user.png";
NSString * const kIconFileWoman = @"glyphicons_035_woman.png";
NSString * const kIconFileBoy = @"glyphicons_004_girl-as_boy.png";
NSString * const kIconFileGirl = @"glyphicons_004_girl.png";
NSString * const kIconFileInfant = @"76-baby_black.png";
NSString * const kIconFileSettings = @"14-gear.png";
NSString * const kIconFilePlus = @"05-plus.png";
NSString * const kIconFileAction = @"212-action2_centred.png";
NSString * const kIconFileLookup = @"01-magnify.png";
NSString * const kIconFilePlacePhoneCall = @"735-phone.png";
NSString * const kIconFilePlacePhoneCall_iOS6x = @"735-phone_pizazz.png";
NSString * const kIconFileSendText = @"734-chat.png";
NSString * const kIconFileSendText_iOS6x = @"734-chat_pizazz.png";
NSString * const kIconFileSendEmail = @"730-envelope.png";
NSString * const kIconFileSendEmail_iOS6x = @"730-envelope_pizazz.png";
NSString * const kIconFileLocationArrow = @"193-location-arrow.png";

// Gender codes
NSString * const kGenderMale = @"M";
NSString * const kGenderFemale = @"F";

// Age thresholds
NSInteger const kAgeThresholdInSchool = 6;
NSInteger const kAgeThresholdTeen = 13;
NSInteger const kAgeOfConsent = 16;
NSInteger const kAgeOfMajority = 18;

// Misc constants
NSString * const kCustomData = @"customData";
