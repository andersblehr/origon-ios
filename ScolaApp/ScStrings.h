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
extern NSString * const strPhoneDeterminate;
extern NSString * const str_iPodDeterminate;
extern NSString * const str_iPadDeterminate;
extern NSString * const strPhonePossessive;
extern NSString * const str_iPodPossessive;
extern NSString * const str_iPadPossessive;
extern NSString * const strThisPhone;
extern NSString * const strThis_iPod;
extern NSString * const strThis_iPad;

// Alert messages
extern NSString * const strInternalServerError;
extern NSString * const strInvalidNameAlert;
extern NSString * const strInvalidEmailAlert;
extern NSString * const strInvalidPasswordAlert;
extern NSString * const strInvalidScolaShortnameAlert;
extern NSString * const strPasswordsDoNotMatchAlert;
extern NSString * const strRegistrationCodesDoNotMatchAlert;
extern NSString * const strScolaInvitationNotFoundAlert;
extern NSString * const strUserExistsAlertTitle;
extern NSString * const strUserExistsButNotLoggedInAlert;
extern NSString * const strUserExistsAndLoggedInAlert;
extern NSString * const strNotLoggedInAlert;
extern NSString * const strNoAddressAlert;
extern NSString * const strNoDeviceNameAlert;
extern NSString * const strNotBornAlert;
extern NSString * const strUnrealisticAgeAlert;

// Button titles
extern NSString * const strOK;
extern NSString * const strCancel;
extern NSString * const strHaveAccess;
extern NSString * const strHaveCode;
extern NSString * const strLater;
extern NSString * const strTryAgain;
extern NSString * const strGoBack;
extern NSString * const strContinue;
extern NSString * const strSkipThis;
extern NSString * const strDone;
extern NSString * const strNext;
extern NSString * const strUseConfigured;
extern NSString * const strUseNew;

// Auth view
extern NSString * const strMembershipPrompt;
extern NSString * const strIsMember;
extern NSString * const strIsInvited;
extern NSString * const strIsNew;
extern NSString * const strUserHelpNew;
extern NSString * const strUserHelpInvited;
extern NSString * const strUserHelpMember;
extern NSString * const strNamePrompt;
extern NSString * const strNameAsReceivedPrompt;
extern NSString * const strEmailPrompt;
extern NSString * const strScolaShortnamePrompt;
extern NSString * const strNewPasswordPrompt;
extern NSString * const strPasswordPrompt;
extern NSString * const strPleaseWait;
extern NSString * const strUserHelpCompleteRegistration;
extern NSString * const strEmailSentPopUpTitle;
extern NSString * const strEmailSentPopUpMessage;
extern NSString * const strSeeYouLaterPopUpTitle;
extern NSString * const strSeeYouLaterPopUpMessage;
extern NSString * const strWelcomeBackPopUpTitle;
extern NSString * const strWelcomeBackPopUpMessage;
extern NSString * const strRegistrationCodePrompt;
extern NSString * const strRepeatPasswordPrompt;
extern NSString * const strScolaDescription;

// Address view
extern NSString * const strProvideAddressUserHelp;
extern NSString * const strVerifyAddressUserHelp;
extern NSString * const strAddressLine1Prompt;
extern NSString * const strAddressLine2Prompt;
extern NSString * const strPostCodeAndCityPrompt;

// Date of birth view
extern NSString * const strDeviceNameUserHelp;
extern NSString * const strDeviceNamePrompt;
extern NSString * const strGenderUserHelp;
extern NSString * const strFemale;
extern NSString * const strMale;
extern NSString * const strNeutral;
extern NSString * const strDateOfBirthUserHelp;
extern NSString * const strDateOfBirthPrompt;
extern NSString * const strDateOfBirthClickHerePrompt;

+ (BOOL)areStringsAvailable;
+ (NSString *)stringForKey:(NSString *)key;

@end
