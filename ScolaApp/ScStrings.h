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
extern NSString * const strYouSubject;
extern NSString * const strYouObject;
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
extern NSString * const strDateOfBirthPrompt;
extern NSString * const strMobilePhonePrompt;
extern NSString * const strAddressLine1Prompt;
extern NSString * const strAddressLine2Prompt;
extern NSString * const strPostCodeAndCityPrompt;
extern NSString * const strLandlinePrompt;

// Labels
extern NSString * const strSignInOrRegisterLabel;
extern NSString * const strConfirmRegistrationLabel;
extern NSString * const strAddressLabel;
extern NSString * const strLandlineLabel;

// Header & footer strings
extern NSString * const strSignInOrRegisterFooter;
extern NSString * const strConfirmRegistrationFooter;
extern NSString * const strHouseholdMemberListFooter;

// Button titles
extern NSString * const strOK;
extern NSString * const strCancel;
extern NSString * const strRetry;
extern NSString * const strHaveCode;
extern NSString * const strGoBack;

// Alerts & error messages
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
extern NSString * const strInvalidRegistrationCodeTitle;
extern NSString * const strInvalidRegistrationCodeAlert;
extern NSString * const strPasswordsDoNotMatchTitle;
extern NSString * const strPasswordsDoNotMatchAlert;
extern NSString * const strNoAddressTitle;
extern NSString * const strNoAddressAlert;
extern NSString * const strNoMobileNumberTitle;
extern NSString * const strNoMobileNumberAlert;
extern NSString * const strNoPhoneNumberTitle;
extern NSString * const strNoPhoneNumberAlert;
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
