//
//  OStrings.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

// Cross-view strings
extern NSString * const strNameMyHousehold;
extern NSString * const strNameOurHousehold;
extern NSString * const strNameMyMessageBoard;
extern NSString * const strNameOurMessageBoard;
extern NSString * const strButtonOK;
extern NSString * const strButtonEdit;
extern NSString * const strButtonDone;
extern NSString * const strButtonCancel;
extern NSString * const strAlertTextNoInternet;
extern NSString * const strAlertTextServerError;

// OAuthView strings
extern NSString * const strLabelSignInOrRegister;
extern NSString * const strLabelActivate;
extern NSString * const strFooterSignInOrRegister;
extern NSString * const strFooterActivate;
extern NSString * const strPromptAuthEmail;
extern NSString * const strPromptPassword;
extern NSString * const strPromptActivationCode;
extern NSString * const strPromptRepeatPassword;
extern NSString * const strPromptPleaseWait;
extern NSString * const strButtonHaveCode;
extern NSString * const strButtonStartOver;
extern NSString * const strButtonAccept;
extern NSString * const strButtonDecline;
extern NSString * const strAlertTitleActivationFailed;
extern NSString * const strAlertTextActivationFailed;
extern NSString * const strAlertTitleWelcomeBack;
extern NSString * const strAlertTextWelcomeBack;
extern NSString * const strAlertTitleIncompleteRegistration;
extern NSString * const strAlertTextIncompleteRegistration;
extern NSString * const strSheetTitleEULA;

// OOrigoListView strings
extern NSString * const strTabBarTitleOrigo;
extern NSString * const strViewTitleOrigoList;
extern NSString * const strHeaderWards;
extern NSString * const strHeaderMyOrigos;

// OMemberListView strings
extern NSString * const strViewTitleMembers;
extern NSString * const strViewTitleHousehold;
extern NSString * const strHeaderContacts;
extern NSString * const strHeaderHouseholdMembers;
extern NSString * const strHeaderOrigoMembers;
extern NSString * const strFooterHousehold;
extern NSString * const strButtonDeleteMember;

// OOrigoView strings
extern NSString * const strLabelAddress;
extern NSString * const strLabelTelephone;
extern NSString * const strHeaderAddress;
extern NSString * const strHeaderAddresses;
extern NSString * const strPromptAddressLine1;
extern NSString * const strPromptAddressLine2;
extern NSString * const strPromptTelephone;

// OMemberView strings
extern NSString * const strViewTitleAboutMe;
extern NSString * const strViewTitleNewMember;
extern NSString * const strViewTitleNewHouseholdMember;
extern NSString * const strLabelAbbreviatedEmail;
extern NSString * const strLabelAbbreviatedMobilePhone;
extern NSString * const strLabelAbbreviatedDateOfBirth;
extern NSString * const strLabelAbbreviatedTelephone;
extern NSString * const strPromptPhoto;
extern NSString * const strPromptName;
extern NSString * const strPromptEmail;
extern NSString * const strPromptDateOfBirth;
extern NSString * const strPromptMobilePhone;
extern NSString * const strButtonInviteToHousehold;
extern NSString * const strButtonMergeHouseholds;
extern NSString * const strAlertTitleMemberExists;
extern NSString * const strAlertTextMemberExists;
extern NSString * const strSheetTitleGenderSelf;
extern NSString * const strSheetTitleGenderSelfMinor;
extern NSString * const strSheetTitleGenderMember;
extern NSString * const strSheetTitleGenderMinor;
extern NSString * const strSheetTitleExistingResidence;
extern NSString * const strTermFemale;
extern NSString * const strTermFemaleMinor;
extern NSString * const strTermMale;
extern NSString * const strTermMaleMinor;

// OCalendarView strings
extern NSString * const strTabBarTitleCalendar;

// OTaskView strings
extern NSString * const strTabBarTitleTasks;

// OMessageBoardView strings
extern NSString * const strTabBarTitleMessages;

// OSettingsView strings
extern NSString * const strTabBarTitleSettings;
extern NSString * const strButtonSignOut;

// Meta strings
extern NSString * const strOrigoTypeSchoolClass;
extern NSString * const strOrigoTypePreschoolClass;
extern NSString * const strOrigoTypeSportsTeam;
extern NSString * const strOrigoTypeOther;

extern NSString * const xstrContactRolesSchoolClass;
extern NSString * const xstrContactRolesPreschoolClass;
extern NSString * const xstrContactRolesSportsTeam;


@interface OStrings : NSObject

+ (void)conditionallyRefresh;

+ (NSString *)stringForKey:(NSString *)key;
+ (NSString *)lowercaseStringForKey:(NSString *)key;

@end
