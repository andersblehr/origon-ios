//
//  ScStrings.h
//  ScolaApp
//
//  Created by Anders Blehr on 26.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

// Meta
extern NSString * const strScolaTypeSchoolClass;
extern NSString * const strScolaTypePreschoolClass;
extern NSString * const strScolaTypeSportsTeam;
extern NSString * const strScolaTypeOther;

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
extern NSString * const strAboutMember;
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
extern NSString * const strSingleLetterEmailLabel;
extern NSString * const strSingleLetterMobilePhoneLabel;
extern NSString * const strSingleLetterDateOfBirthLabel;
extern NSString * const strSingleLetterAddressLabel;
extern NSString * const strSingleLetterTelephoneLabel;
extern NSString * const strSingleLetterWebsiteLabel;
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

// ScMemberListView strings
extern NSString * const strMemberListViewTitleDefault;
extern NSString * const strMemberListViewTitleHousehold;
extern NSString * const strHouseholdMembers;
extern NSString * const strDeleteConfirmation;

// ScMemberView strings
extern NSString * const strMemberViewTitleAboutYou;
extern NSString * const strMemberViewTitleNewMember;
extern NSString * const strMemberViewTitleNewHouseholdMember;
extern NSString * const strGenderActionSheetTitleSelf;
extern NSString * const strGenderActionSheetTitleSelfMinor;
extern NSString * const strGenderActionSheetTitleMember;
extern NSString * const strGenderActionSheetTitleMemberMinor;


@interface ScStrings : NSObject

+ (void)refreshIfPossible;

+ (NSString *)stringForKey:(NSString *)key;
+ (NSString *)lowercaseStringForKey:(NSString *)key;

@end
