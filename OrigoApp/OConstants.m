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

// Entity property keys
NSString * const kPropertyKeyActiveSince = @"activeSince";
NSString * const kPropertyKeyAddress = @"address";
NSString * const kPropertyKeyCountryCode = @"countryCode";
NSString * const kPropertyKeyDateCreated = @"dateCreated";
NSString * const kPropertyKeyDateExpires = @"dateExpires";
NSString * const kPropertyKeyDateOfBirth = @"dateOfBirth";
NSString * const kPropertyKeyDateReplicated = @"dateReplicated";
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
NSString * const kRelationshipKeyOrigo = @"origo";

// Mapped keys
NSString * const kMappedKeyClub = @"club";
NSString * const kMappedKeyFullName = @"fullName";
NSString * const kMappedKeyGivenName = @"givenName";
NSString * const kMappedKeyOrganisation = @"organisation";
NSString * const kMappedKeyOrganisationDescription = @"organisationDescription";
NSString * const kMappedKeyPreschool = @"preschool";
NSString * const kMappedKeyPreschoolClass = @"preschoolClass";
NSString * const kMappedKeyResidenceName = @"residenceName";
NSString * const kMappedKeySchool = @"school";
NSString * const kMappedKeySchoolClass = @"schoolClass";
NSString * const kMappedKeyStudyGroup = @"studyGroup";
NSString * const kMappedKeyTeam = @"team";
NSString * const kMappedKeyInstitution = @"institution";

// Unbound keys
NSString * const kExternalKeyActivate = @"activate";
NSString * const kExternalKeyActivationCode = @"activationCode";
NSString * const kExternalKeyAuthEmail = @"authEmail";
NSString * const kExternalKeyDeviceId = @"deviceId";
NSString * const kExternalKeyEntityClass = @"entityClass";
NSString * const kExternalKeyPassword = @"password";
NSString * const kExternalKeyRepeatPassword = @"repeatPassword";
NSString * const kExternalKeySignIn = @"signIn";

// String key prefixes
NSString * const kStringPrefixDefault = @"[default]";
NSString * const kStringPrefixLabel = @"[label]";
NSString * const kStringPrefixAlternateLabel = @"[alternate label]";
NSString * const kStringPrefixSettingLabel = @"[setting label]";
NSString * const kStringPrefixPlaceholder = @"[placeholder]";
NSString * const kStringPrefixOrigoTitle = @"[title]";
NSString * const kStringPrefixNewOrigoTitle = @"[registration title]";
NSString * const kStringPrefixFooter = @"[registration footer]";
NSString * const kStringPrefixAddMemberButton = @"[add member]";
NSString * const kStringPrefixAddOrganiserButton = @"[add organiser]";
NSString * const kStringPrefixOrganiserTitle = @"[organiser]";
NSString * const kStringPrefixOrganisersTitle = @"[organisers]";
NSString * const kStringPrefixMembersTitle = @"[members]";
NSString * const kStringPrefixNewMemberTitle = @"[member registration]";
NSString * const kStringPrefixAllMembersTitle = @"[all members]";
NSString * const kStringPrefixOrganiserRoleTitle = @"[organiser role]";
NSString * const kStringPrefixAddOrganiserRoleButton = @"[add organiser role]";
NSString * const kStringPrefixMemberRoleTitle = @"[member role]";
NSString * const kStringPrefixMemberRolesTitle = @"[member roles]";
NSString * const kStringPrefixSettingTitle = @"[setting title]";

// Icon file names
NSString * const kIconFileOrigo = @"10-arrows-in_black.png";
NSString * const kIconFileHousehold = @"glyphicons_020_home.png";
NSString * const kIconFileMan = @"glyphicons_003_user.png";
NSString * const kIconFileWoman = @"glyphicons_035_woman.png";
NSString * const kIconFileBoy = @"glyphicons_004_girl-as_boy.png";
NSString * const kIconFileGirl = @"glyphicons_004_girl.png";
NSString * const kIconFileInfant = @"76-baby_black.png";
NSString * const kIconFileMultiRole = @"779-users";
NSString * const kIconFileMultiRoleSelected = @"779-users-selected";
NSString * const kIconFileSettings = @"14-gear.png";
NSString * const kIconFilePlus = @"05-plus.png";
NSString * const kIconFileEdit = @"830-pencil.png";
NSString * const kIconFileMap = @"852-map.png";
NSString * const kIconFileInfo = @"724-info.png";
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

// Geometry constant
CGFloat const kBorderWidth = 0.5f;
CGFloat const kBorderWidthNonRetina = 1.f;
CGFloat const kToolbarBarHeight = 44.f;
CGFloat const kContentInset = 14.f;
CGFloat const kLineToHeaderHeightFactor = 1.5f;


// Misc constants
NSString * const kCustomData = @"customData";
