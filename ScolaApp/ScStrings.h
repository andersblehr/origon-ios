//
//  ScStrings.h
//  ScolaApp
//
//  Created by Anders Blehr on 26.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScStrings : NSObject

// Alert messages
extern NSString * const strInvalidNameAlert;
extern NSString * const strInvalidEmailAlert;
extern NSString * const strInvalidPasswordAlert;
extern NSString * const strInvalidScolaShortnameAlert;
extern NSString * const strPasswordsDoNotMatchAlert;
extern NSString * const strRegistrationCodesDoNotMatchAlert;
extern NSString * const strNoScolaWithShortnameAlert;
extern NSString * const strScolaHasNoListingForNameAlert;


// Generic strings
extern NSString * const strOK;
extern NSString * const strCancel;
extern NSString * const strTryAgain;
extern NSString * const strGoBack;
extern NSString * const strPleaseWait;

// Root view (maintained in-app)
extern NSString * const istrNoInternet;
extern NSString * const istrServerDown;

// Root view
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
extern NSString * const strUserHelpCompleteRegistration;
extern NSString * const strEmailSentPopUpTitle;
extern NSString * const strEmailSentPopUpMessage;
extern NSString * const strContinue;
extern NSString * const strLater;
extern NSString * const strSeeYouLaterPopUpTitle;
extern NSString * const strSeeYouLaterPopUpMessage;
extern NSString * const strWelcomeBackPopUpTitle;
extern NSString * const strWelcomeBackPopUpMessage;
extern NSString * const strRegistrationCodePrompt;
extern NSString * const strRepeatPasswordPrompt;
extern NSString * const strScolaDescription;

+ (BOOL)areStringsAvailable;
+ (NSString *)stringForKey:(NSString *)key;

@end
