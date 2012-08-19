//
//  ScStrings.h
//  ScolaApp
//
//  Created by Anders Blehr on 26.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

// EULA
extern NSString * const strEULA;
extern NSString * const strAccept;
extern NSString * const strDecline;

// Generic strings
extern NSString * const strPleaseWait;
extern NSString * const strAbout;
extern NSString * const strToBe2ndPSg;
extern NSString * const strToBe3rdPSg;
extern NSString * const strYouNom;
extern NSString * const strYouAcc;
extern NSString * const strFemale;
extern NSString * const strFemaleMinor;
extern NSString * const strMale;
extern NSString * const strMaleMinor;
extern NSString * const strHousehold;
extern NSString * const strMyPlace;
extern NSString * const strOurPlace;
extern NSString * const strMyMessageBoard;
extern NSString * const strOurMessageBoard;

// Prompts
extern NSString * const strAuthEmailPrompt;
extern NSString * const strPasswordPrompt;
extern NSString * const strRegistrationCodePrompt;
extern NSString * const strRepeatPasswordPrompt;
extern NSString * const strPhotoPrompt;
extern NSString * const strNamePrompt;
extern NSString * const strEmailPrompt;
extern NSString * const strMobilePhonePrompt;
extern NSString * const strDateOfBirthPrompt;
extern NSString * const strUserWebsitePrompt;
extern NSString * const strAddressLine1Prompt;
extern NSString * const strAddressLine2Prompt;
extern NSString * const strHouseholdLandlinePrompt;
extern NSString * const strScolaLandlinePrompt;
extern NSString * const strScolaWebsitePrompt;

// Labels
extern NSString * const strSignInOrRegisterLabel;
extern NSString * const strConfirmRegistrationLabel;
extern NSString * const strSingleLetterEmailLabel;
extern NSString * const strSingleLetterMobilePhoneLabel;
extern NSString * const strSingleLetterDateOfBirthLabel;
extern NSString * const strSingleLetterAddressLabel;
extern NSString * const strSingleLetterLandlineLabel;
extern NSString * const strSingleLetterWebsiteLabel;
extern NSString * const strAddressLabel;
extern NSString * const strAddressesLabel;
extern NSString * const strLandlineLabel;

// Header & footer strings
extern NSString * const strSignInOrRegisterFooter;
extern NSString * const strConfirmRegistrationFooter;
extern NSString * const strHouseholdMemberListFooter;

// Button titles
extern NSString * const strOK;
extern NSString * const strCancel;
extern NSString * const strRetry;
extern NSString * const strStartOver;
extern NSString * const strHaveCode;

// Alerts & error messages
extern NSString * const strNoInternetError;
extern NSString * const strServerErrorAlert;
extern NSString * const strUserConfirmationFailedTitle;
extern NSString * const strUserConfirmationFailedAlert;
extern NSString * const strWelcomeBackTitle;
extern NSString * const strWelcomeBackAlert;
extern NSString * const strIncompleteRegistrationTitle;
extern NSString * const strIncompleteRegistrationAlert;

// ScMembershipView strings
extern NSString * const strMembershipViewTitleDefault;
extern NSString * const strMembershipViewTitleMyPlace;
extern NSString * const strMembershipViewTitleOurPlace;
extern NSString * const strHouseholdMembers;
extern NSString * const strDeleteConfirmation;

// ScMemberView strings
extern NSString * const strMemberViewTitleAboutYou;
extern NSString * const strMemberViewTitleNewMember;
extern NSString * const strMemberViewTitleNewHouseholdMember;
extern NSString * const strGenderActionSheetTitle;


@interface ScStrings : NSObject

+ (void)refreshStrings;

+ (NSString *)stringForKey:(NSString *)key;
+ (NSString *)lowercaseStringForKey:(NSString *)key;

@end
