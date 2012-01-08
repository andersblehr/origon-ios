//
//  ScStrings.h
//  ScolaApp
//
//  Created by Anders Blehr on 26.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScStrings : NSObject

// Grammer snippets
extern NSString * const strYourPhone;
extern NSString * const strYour_iPod;
extern NSString * const strYour_iPad;

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

// Button titles
extern NSString * const strOK;
extern NSString * const strCancel;
extern NSString * const strHaveAccess;
extern NSString * const strHaveCode;
extern NSString * const strLater;
extern NSString * const strTryAgain;
extern NSString * const strGoBack;
extern NSString * const strContinue;

// Auth view
extern NSString * const istrNoInternet;  // Maintained in-app
extern NSString * const istrServerDown;  // Maintained in-app
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

// Household view
extern NSString * const strDeviceNameUserHelp;
extern NSString * const strDeviceNamePrompt;
extern NSString * const strAddressUserHelp;
extern NSString * const strStreetAddressPrompt;
extern NSString * const strPostCodeAndCityPrompt;
extern NSString * const strDateOfBirthUserHelp;

+ (BOOL)areStringsAvailable;
+ (NSString *)stringForKey:(NSString *)key;

@end
