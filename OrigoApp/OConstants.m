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
NSString * const kIdentifierInfo = @"info";
NSString * const kIdentifierMap = @"map";
NSString * const kIdentifierMember = @"member";
NSString * const kIdentifierOrigo = @"origo";
NSString * const kIdentifierOrigoList = @"origos";
NSString * const kIdentifierRecipientPicker = @"recipients";
NSString * const kIdentifierValueList = @"values";
NSString * const kIdentifierValuePicker = @"value";

// Reuse identifiers
NSString * const kReuseIdentifierUserSignIn = @"signIn";
NSString * const kReuseIdentifierUserActivation = @"activate";
NSString * const kReuseIdentifierPasswordChange = @"passwordChange";

// Language codes
NSString * const kLanguageCodeEnglish = @"en";

// NSUserDefaults keys
NSString * const kDefaultsKeyAuthInfo = @"origo.auth.info";
NSString * const kDefaultsKeyDirtyEntities = @"origo.state.dirtyEntities";

// Entity property keys
NSString * const kPropertyKeyActiveSince = @"activeSince";
NSString * const kPropertyKeyAddress = @"address";
NSString * const kPropertyKeyCountryCode = @"countryCode";
NSString * const kPropertyKeyCreatedBy = @"createdBy";
NSString * const kPropertyKeyCreatedIn = @"createdIn";
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
NSString * const kPropertyKeyModifiedBy = @"modifiedBy";
NSString * const kPropertyKeyMotherId = @"motherId";
NSString * const kPropertyKeyName = @"name";
NSString * const kPropertyKeyOrigoId = @"origoId";
NSString * const kPropertyKeyPasswordHash = @"passwordHash";
NSString * const kPropertyKeyPermissions = @"permissions";
NSString * const kPropertyKeyPhoto = @"photo";
NSString * const kPropertyKeyTelephone = @"telephone";
NSString * const kPropertyKeyType = @"type";

// Entity relationship keys
NSString * const kRelationshipKeyMember = @"member";
NSString * const kRelationshipKeyOrigo = @"origo";

// Mapped keys
NSString * const kMappedKeyClub = @"club";
NSString * const kMappedKeyFullName = @"fullName";
NSString * const kMappedKeyInstitution = @"institution";
NSString * const kMappedKeyListName = @"listName";
NSString * const kMappedKeyPreschool = @"preschool";
NSString * const kMappedKeyPreschoolClass = @"preschoolClass";
NSString * const kMappedKeyResidenceName = @"residenceName";
NSString * const kMappedKeySchool = @"school";
NSString * const kMappedKeySchoolClass = @"schoolClass";
NSString * const kMappedKeyStudyGroup = @"studyGroup";
NSString * const kMappedKeyTeam = @"team";

// Internal keys
NSString * const kInternalKeyDeviceId = @"deviceId";
NSString * const kInternalKeyEditableListCellContent = @"editableListCellContent";
NSString * const kInternalKeyEntityClass = @"entityClass";

// Label keys
NSString * const kLabelKeyActivate = @"activate";
NSString * const kLabelKeyAdmins = @"admins";
NSString * const kLabelKeyRegisterOrSignIn = @"registerOrSignIn";

// Input keys
NSString * const kInputKeyActivationCode = @"activationCode";
NSString * const kInputKeyAuthEmail = @"authEmail";
NSString * const kInputKeyNewPassword = @"newPassword";
NSString * const kInputKeyOldPassword = @"oldPassword";
NSString * const kInputKeyPassword = @"password";
NSString * const kInputKeyRepeatNewPassword = @"repeatNewPassword";
NSString * const kInputKeyRepeatPassword = @"repeatPassword";

// Action keys
NSString * const kActionKeyActivate = @"activate";
NSString * const kActionKeyCancel = @"cancel";
NSString * const kActionKeyChangePassword = @"changePassword";
NSString * const kActionKeySignIn = @"signIn";
NSString * const kActionKeySignOut = @"signOut";
NSString * const kActionKeySignUp = @"signUp";

// Placeholders
NSString * const kPlaceholderDefaultValue = @"defaultValue";

// String prefixes
NSString * const kStringPrefixLabel = @"[label]";
NSString * const kStringPrefixAlternateLabel = @"[alternate label]";
NSString * const kStringPrefixTitle = @"[title]";
NSString * const kStringPrefixSettingTitle = @"[setting]";
NSString * const kStringPrefixSettingLabel = @"[setting label]";
NSString * const kStringPrefixPlaceholder = @"[placeholder]";
NSString * const kStringPrefixOrigoTitle = @"[title]";
NSString * const kStringPrefixFooter = @"[registration footer]";
NSString * const kStringPrefixAddMemberButton = @"[add member]";
NSString * const kStringPrefixMemberTitle = @"[member]";
NSString * const kStringPrefixMembersTitle = @"[members]";
NSString * const kStringPrefixNewMemberTitle = @"[new member]";
NSString * const kStringPrefixNewMembersTitle = @"[new members]";
NSString * const kStringPrefixAllMembersTitle = @"[all members]";
NSString * const kStringPrefixAddOrganiserButton = @"[add organiser]";
NSString * const kStringPrefixOrganiserTitle = @"[organiser]";
NSString * const kStringPrefixOrganisersTitle = @"[organisers]";
NSString * const kStringPrefixOrganiserRoleTitle = @"[organiser role]";
NSString * const kStringPrefixAddOrganiserRoleButton = @"[add organiser role]";
NSString * const kStringPrefixEditOrganiserRoleButton = @"[edit organiser role]";
NSString * const kStringPrefixMemberRoleTitle = @"[member role]";

// Icon file names
NSString * const kIconFileResidence = @"ro-750-home-toolbar-selected.png";
NSString * const kIconFileList = @"ro-854-list.png";
NSString * const kIconFileOrigo = @"10-contract.png";
NSString * const kIconFileSettings = @"740-gear-toolbar.png";
NSString * const kIconFile_iPad = @"693-ipad.png";
NSString * const kIconFile_iPhone = @"ro-692-iphone-5.png";
NSString * const kIconFile_iPodTouch = @"ro-ipod-touch-5.png";
NSString * const kIconFileMan = @"769-male-toolbar.png";
NSString * const kIconFileWoman = @"768-female-toolbar.png";
NSString * const kIconFileBoy = @"ro-593-boy.png";
NSString * const kIconFileGirl = @"ro-594-girl.png";
NSString * const kIconFileEdit = @"830-pencil-toolbar.png";
NSString * const kIconFileLocation = @"722-location-pin-toolbar.png";
NSString * const kIconFileDirections = @"852-map-toolbar.png";
NSString * const kIconFileNavigation = @"113-navigation.png";
NSString * const kIconFileInfo = @"724-info-toolbar.png";
NSString * const kIconFileLookup = @"01-magnify.png";
NSString * const kIconFileFavouriteNo = @"726-star-toolbar.png";
NSString * const kIconFileFavouriteYes = @"726-star-toolbar-selected.png";
NSString * const kIconFileAcceptDecline = @"739-question-selected.png";
NSString * const kIconFileCall = @"735-phone.png";
NSString * const kIconFileSendText = @"734-chat.png";
NSString * const kIconFileSendEmail = @"730-envelope.png";
NSString * const kIconFileRoleHolders = @"ro-role-holders.png";
NSString * const kIconFileMultiRoleOff = @"779-users-toolbar.png";
NSString * const kIconFileMultiRoleOn = @"779-users-toolbar-selected.png";
NSString * const kIconFileGroups = @"895-user-group-toolbar.png";

// Gender codes
NSString * const kGenderMale = @"M";
NSString * const kGenderFemale = @"F";

// Recipient types
NSInteger const kRecipientTypeText = 0;
NSInteger const kRecipientTypeCall = 1;
NSInteger const kRecipientTypeEmail = 2;

// Age thresholds
NSInteger const kAgeThresholdInSchool = 6;
NSInteger const kAgeThresholdTeen = 13;
NSInteger const kAgeOfConsent = 16;
NSInteger const kAgeOfMajority = 18;

// Geometry constant
CGFloat const kNavigationBarHeight = 64.f;
CGFloat const kToolbarBarHeight = 44.f;
CGFloat const kBorderWidth = 0.5f;
CGFloat const kContentInset = 14.f;


// Misc constants
NSString * const kCustomData = @"customData";
