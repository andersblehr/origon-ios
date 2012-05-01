//
//  ScStrings.h
//  ScolaApp
//
//  Created by Anders Blehr on 26.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ScStrings : NSObject

// Maintained in-app
extern NSString * const istrNoInternet;
extern NSString * const istrServerDown;

// Grammer snippets
extern NSString * const strPhoneDefinite;
extern NSString * const str_iPodDefinite;
extern NSString * const str_iPadDefinite;
extern NSString * const strPhonePossessive;
extern NSString * const str_iPodPossessive;
extern NSString * const str_iPadPossessive;
extern NSString * const strThisPhone;
extern NSString * const strThis_iPod;
extern NSString * const strThis_iPad;

// Error & alert messages
extern NSString * const strNoInternetError;
extern NSString * const strServerErrorAlert;
extern NSString * const strInvalidNameAlert;
extern NSString * const strInvalidEmailAlert;
extern NSString * const strInvalidPasswordAlert;
extern NSString * const strEmailAlreadyRegisteredAlert;
extern NSString * const strPasswordsDoNotMatchAlert;
extern NSString * const strRegistrationCodesDoNotMatchAlert;
extern NSString * const strUserExistsAlertTitle;
extern NSString * const strUserExistsButNotLoggedInAlert;
extern NSString * const strUserExistsAndLoggedInAlert;
extern NSString * const strNotLoggedInAlert;
extern NSString * const strNoAddressAlert;
extern NSString * const strNoDeviceNameAlert;
extern NSString * const strNotBornAlert;
extern NSString * const strUnrealisticAgeAlert;
extern NSString * const strNoMobilePhoneAlert;

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

// Auth view
extern NSString * const strUserIntentionPrompt;
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
extern NSString * const strEmailSentPopUpTitle;
extern NSString * const strEmailSentPopUpMessage;
extern NSString * const strEmailSentToInviteePopUpTitle;
extern NSString * const strEmailSentToInviteePopUpMessage;
extern NSString * const strSeeYouLaterPopUpTitle;
extern NSString * const strSeeYouLaterPopUpMessage;
extern NSString * const strWelcomeBackPopUpTitle;
extern NSString * const strWelcomeBackPopUpMessage;
extern NSString * const strRegistrationCodePrompt;
extern NSString * const strRepeatPasswordPrompt;
extern NSString * const strScolaDescription;

// Registration view 1
extern NSString * const strProvideAddressUserHelp;
extern NSString * const strVerifyAddressUserHelp;
extern NSString * const strAddressLine1Prompt;
extern NSString * const strAddressLine2Prompt;
extern NSString * const strPostCodeAndCityPrompt;
extern NSString * const strDateOfBirthUserHelp;
extern NSString * const strDateOfBirthPrompt;
extern NSString * const strDateOfBirthClickHerePrompt;

// Registration view 2
extern NSString * const strGenderUserHelp;
extern NSString * const strFemaleAdult;
extern NSString * const strFemaleMinor;
extern NSString * const strMaleAdult;
extern NSString * const strMaleMinor;
extern NSString * const strMobilePhoneUserHelp;
extern NSString * const strMobilePhonePrompt;
extern NSString * const strDeviceNameUserHelp;
extern NSString * const strDeviceNamePrompt;

// Generic Scola strings
extern NSString * const strMyPlace;
extern NSString * const strOurPlace;
extern NSString * const strMyMessageBoard;
extern NSString * const strOurMessageBoard;

+ (void)refreshStrings;
+ (NSString *)stringForKey:(NSString *)key;

@end
