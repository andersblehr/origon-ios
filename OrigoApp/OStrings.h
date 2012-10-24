//
//  OStrings.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

// Tab bar titles
extern NSString * const strTabBarTitleOrigo;
extern NSString * const strTabBarTitleCalendar;
extern NSString * const strTabBarTitleTasks;
extern NSString * const strTabBarTitleMessages;
extern NSString * const strTabBarTitleSettings;

// Meta
extern NSString * const strOrigoTypeSchoolClass;
extern NSString * const strOrigoTypePreschoolClass;
extern NSString * const strOrigoTypeSportsTeam;
extern NSString * const strOrigoTypeOther;

extern NSString * const xstrContactRolesSchoolClass;
extern NSString * const xstrContactRolesPreschoolClass;
extern NSString * const xstrContactRolesSportsTeam;

// EULA
extern NSString * const strEULA;
extern NSString * const strAccept;
extern NSString * const strDecline;

// Generic strings
extern NSString * const strPleaseWait;
extern NSString * const strAboutYou;
extern NSString * const strFemale;
extern NSString * const strFemaleMinor;
extern NSString * const strMale;
extern NSString * const strMaleMinor;
extern NSString * const strMyHousehold;
extern NSString * const strMyMessageBoard;
extern NSString * const strOurMessageBoard;

// Prompts
extern NSString * const strAuthEmailPrompt;
extern NSString * const strPasswordPrompt;
extern NSString * const strActivationCodePrompt;
extern NSString * const strRepeatPasswordPrompt;
extern NSString * const strPhotoPrompt;
extern NSString * const strNamePrompt;
extern NSString * const strEmailPrompt;
extern NSString * const strMobilePhonePrompt;
extern NSString * const strDateOfBirthPrompt;
extern NSString * const strUserWebsitePrompt;
extern NSString * const strAddressLine1Prompt;
extern NSString * const strAddressLine2Prompt;
extern NSString * const strTelephonePrompt;

// Labels
extern NSString * const strSignInOrRegisterLabel;
extern NSString * const strActivateLabel;
extern NSString * const strAbbreviatedEmailLabel;
extern NSString * const strAbbreviatedMobilePhoneLabel;
extern NSString * const strAbbreviatedDateOfBirthLabel;
extern NSString * const strAbbreviatedTelephoneLabel;
extern NSString * const strAddressLabel;
extern NSString * const strAddressesLabel;
extern NSString * const strTelephoneLabel;

// Header & footer strings
extern NSString * const strSignInOrRegisterFooter;
extern NSString * const strActivateFooter;
extern NSString * const strHouseholdMemberListFooter;

// Button titles
extern NSString * const strOK;
extern NSString * const strCancel;
extern NSString * const strRetry;
extern NSString * const strStartOver;
extern NSString * const strHaveCode;
extern NSString * const strInviteToHousehold;
extern NSString * const strMergeHouseholds;

// Alerts & error messages
extern NSString * const strNoInternetError;
extern NSString * const strServerErrorAlert;
extern NSString * const strActivationFailedTitle;
extern NSString * const strActivationFailedAlert;
extern NSString * const strWelcomeBackTitle;
extern NSString * const strWelcomeBackAlert;
extern NSString * const strIncompleteRegistrationTitle;
extern NSString * const strIncompleteRegistrationAlert;
extern NSString * const strMemberExistsTitle;
extern NSString * const strMemberExistsAlert;
extern NSString * const strExistingResidenceAlert;

// OMemberListView strings
extern NSString * const strMemberListViewTitleDefault;
extern NSString * const strMemberListViewTitleHousehold;
extern NSString * const strHouseholdMembers;
extern NSString * const strDeleteConfirmation;

// OMemberView strings
extern NSString * const strMemberViewTitleAboutYou;
extern NSString * const strMemberViewTitleNewMember;
extern NSString * const strMemberViewTitleNewHouseholdMember;
extern NSString * const strGenderActionSheetTitleSelf;
extern NSString * const strGenderActionSheetTitleSelfMinor;
extern NSString * const strGenderActionSheetTitleMember;
extern NSString * const strGenderActionSheetTitleMemberMinor;


@interface OStrings : NSObject

+ (void)refreshIfPossible;

+ (NSString *)stringForKey:(NSString *)key;
+ (NSString *)lowercaseStringForKey:(NSString *)key;

@end
