//
//  ScStrings.h
//  ScolaApp
//
//  Created by Anders Blehr on 26.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScStrings : NSObject {
@private
    NSDictionary *strings;
}

// Alert messages
extern NSString * const strInvalidNameAlert;
extern NSString * const strInvalidEmailAlert;
extern NSString * const strInvalidPasswordAlert;
extern NSString * const strInvalidInvitationCodeAlert;

// Generic strings
extern NSString * const strOK;
extern NSString * const strCancel;
extern NSString * const strContinue;
extern NSString * const strLater;
extern NSString * const strPleaseWait;
extern NSString * const strPleaseProvide;

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
extern NSString * const strInvitationCodePrompt;
extern NSString * const strPasswordPrompt;
extern NSString * const strNewPasswordPrompt;
extern NSString * const strEmailSentPopUp;
extern NSString * const strRegistrationCodePrompt;
extern NSString * const strRepeatPasswordPrompt;
extern NSString * const strScolaDescription;

// Confirm new user
extern NSString * const strUserWelcome;
extern NSString * const strEnterRegistrationCode;
extern NSString * const strRegistrationCode;
extern NSString * const strGenderFemale;
extern NSString * const strGenderMale;

+ (BOOL)areStringsAvailable;
+ (NSString *)stringForKey:(NSString *)key;

@end
