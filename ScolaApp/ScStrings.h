//
//  ScStrings.h
//  ScolaApp
//
//  Created by Anders Blehr on 26.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>


// Generic labels
extern NSString * const strName;
extern NSString * const strNamePlaceholder;
extern NSString * const strEmail;
extern NSString * const strEmailPlaceholder;
extern NSString * const strAddress;
extern NSString * const strLandline;
extern NSString * const strLandlinePlaceholder;
extern NSString * const strMobile;
extern NSString * const strMobilePlaceholder;
extern NSString * const strBorn;
extern NSString * const strBornPlaceholder;

// Generic Scola strings
extern NSString * const strHousehold;
extern NSString * const strMyPlace;
extern NSString * const strOurPlace;
extern NSString * const strMyMessageBoard;
extern NSString * const strOurMessageBoard;

// Auth view
extern NSString * const strUserIntentionLogin;
extern NSString * const strUserIntentionRegistration;
extern NSString * const strUserHelpNew;
extern NSString * const strUserHelpMember;
extern NSString * const strNamePrompt;
extern NSString * const strEmailPrompt;
extern NSString * const strNewPasswordPrompt;
extern NSString * const strPasswordPrompt;
extern NSString * const strPleaseWait;
extern NSString * const strUserHelpCompleteRegistration;
extern NSString * const strSeeYouLaterPopUpTitle;
extern NSString * const strSeeYouLaterPopUpMessage;
extern NSString * const strWelcomeBackPopUpTitle;
extern NSString * const strWelcomeBackPopUpMessage;
extern NSString * const strRegistrationCodePrompt;
extern NSString * const strRepeatPasswordPrompt;
extern NSString * const strScolaDescription;

// Registration view 1
extern NSString * const strRegistrationView1Title;
extern NSString * const strRegistrationView1BackButtonTitle;
extern NSString * const strAddressUserHelp;
extern NSString * const strProvideAddressUserHelp;
extern NSString * const strVerifyAddressUserHelp;
extern NSString * const strAddressLine1Prompt;
extern NSString * const strAddressLine2Prompt;
extern NSString * const strPostCodeAndCityPrompt;
extern NSString * const strDateOfBirthUserHelp;
extern NSString * const strVerifyDateOfBirthUserHelp;
extern NSString * const strDateOfBirthPrompt;
extern NSString * const strDateOfBirthClickHerePrompt;

// Registration view 2
extern NSString * const strRegistrationView2Title;
extern NSString * const strFemale;
extern NSString * const strFemaleMinor;
extern NSString * const strMale;
extern NSString * const strMaleMinor;
extern NSString * const strGenderUserHelp;
extern NSString * const strMobilePhoneUserHelp;
extern NSString * const strVerifyMobilePhoneUserHelp;
extern NSString * const strMobilePhonePrompt;
extern NSString * const strLandlineUserHelp;
extern NSString * const strProvideLandlineUserHelp;
extern NSString * const strVerifyLandlineUserHelp;
extern NSString * const strLandlinePrompt;

// Membership view
extern NSString * const strMembershipViewHomeScolaTitle1;
extern NSString * const strMembershipViewHomeScolaTitle2;
extern NSString * const strMembershipViewDefaultTitle;
extern NSString * const strHouseholdMembers;
extern NSString * const strHouseholdMemberListFooter;
extern NSString * const strDeleteConfirmation;

// Member view
extern NSString * const strNewMemberViewTitle;
extern NSString * const strUnderOurRoofViewTitle;
extern NSString * const strGenderActionSheetTitle;

// Error & alert messages
extern NSString * const strNoInternetError;
extern NSString * const strServerErrorAlert;
extern NSString * const strInvalidNameTitle;
extern NSString * const strInvalidNameAlert;
extern NSString * const strInvalidEmailTitle;
extern NSString * const strInvalidEmailAlert;
extern NSString * const strInvalidPasswordTitle;
extern NSString * const strInvalidPasswordAlert;
extern NSString * const strInvalidDateOfBirthTitle;
extern NSString * const strInvalidDateOfBirthAlert;
extern NSString * const strInvalidGenderTitle;
extern NSString * const strInvalidGenderAlert;
extern NSString * const strEmailSentAlertTitle;
extern NSString * const strEmailSentAlert;
extern NSString * const strEmailSentToInviteeTitle;
extern NSString * const strEmailSentToInviteeAlert;
extern NSString * const strPasswordsDoNotMatchTitle;
extern NSString * const strPasswordsDoNotMatchAlert;
extern NSString * const strInvalidRegistrationCodeTitle;
extern NSString * const strInvalidRegistrationCodeAlert;
extern NSString * const strUserExistsMustLogInAlert;
extern NSString * const strNotLoggedInAlert;
extern NSString * const strNoAddressTitle;
extern NSString * const strNoAddressAlert;
extern NSString * const strNoMobileNumberTitle;
extern NSString * const strNoMobileNumberAlert;
extern NSString * const strNoPhoneNumberTitle;
extern NSString * const strNoPhoneNumberAlert;
extern NSString * const strIncompleteRegistrationTitle;
extern NSString * const strIncompleteRegistrationAlert;

// Button titles
extern NSString * const strOK;
extern NSString * const strCancel;
extern NSString * const strLogIn;
extern NSString * const strNewUser;
extern NSString * const strHaveAccess;
extern NSString * const strHaveCode;
extern NSString * const strLater;
extern NSString * const strTryAgain;
extern NSString * const strGoBack;
extern NSString * const strContinue;
extern NSString * const strDone;
extern NSString * const strNext;
extern NSString * const strUseConfigured;
extern NSString * const strUseNew;

@interface ScStrings : NSObject

+ (void)refreshStrings;
+ (NSString *)stringForKey:(NSString *)key;

@end
