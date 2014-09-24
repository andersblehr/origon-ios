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
NSString * const kPropertyKeyLastSeen = @"lastSeen";
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

// Button keys
NSString * const kButtonKeyDeleteRow = @"deleteRow";

// String key prefixes
NSString * const kStringPrefixDefault = @"[default]";
NSString * const kStringPrefixLabel = @"[label]";
NSString * const kStringPrefixAlternateLabel = @"[alternate label]";
NSString * const kStringPrefixSettingLabel = @"[setting label]";
NSString * const kStringPrefixSettingListLabel = @"[setting list label]";
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
NSString * const kStringPrefixEditOrganiserRoleButton = @"[edit organiser role]";
NSString * const kStringPrefixMemberRoleTitle = @"[member role]";
NSString * const kStringPrefixSettingTitle = @"[setting title]";

// Icon file names
NSString * const kIconFileOrigo = @"10-contract.png";
NSString * const kIconFileSettings = @"740-gear-toolbar.png";
NSString * const kIconFile_iPad = @"693-ipad.png";
NSString * const kIconFile_iPhone = @"692-iphone-5.png";
NSString * const kIconFile_iPodTouch = @"ro-ipod-touch-5.png";
NSString * const kIconFileHousehold = @"750-home-toolbar-selected.png";
NSString * const kIconFileMan = @"769-male-toolbar.png";
NSString * const kIconFileWoman = @"768-female-toolbar.png";
NSString * const kIconFileBoy = @"593-boy_shrunk.png";
NSString * const kIconFileGirl = @"594-girl_shrunk.png";
NSString * const kIconFileEdit = @"830-pencil-toolbar.png";
NSString * const kIconFileMap = @"852-map-toolbar.png";
NSString * const kIconFileInfo = @"724-info-toolbar.png";
NSString * const kIconFileLookup = @"01-magnify.png";
NSString * const kIconFileAcceptReject = @"739-question-selected.png";
NSString * const kIconFilePlacePhoneCall = @"735-phone.png";
NSString * const kIconFileSendText = @"734-chat.png";
NSString * const kIconFileSendEmail = @"730-envelope.png";
NSString * const kIconFileRoleHolders = @"ro-role-holders.png";
NSString * const kIconFileMultiRoleOff = @"779-users-toolbar.png";
NSString * const kIconFileMultiRoleOn = @"779-users-toolbar-selected.png";
NSString * const kIconFileGroups = @"895-user-group-toolbar.png";

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
CGFloat const kToolbarBarHeight = 44.f;
CGFloat const kContentInset = 14.f;
CGFloat const kLineToHeaderHeightFactor = 1.5f;


// Misc constants
NSString * const kCustomData = @"customData";
