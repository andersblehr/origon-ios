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
extern NSString * const strButtonNext;
extern NSString * const strButtonDone;
extern NSString * const strButtonContinue;
extern NSString * const strButtonCancel;
extern NSString * const strButtonSignOut;
extern NSString * const strAlertTextNoInternet;
extern NSString * const strAlertTextServerError;
extern NSString * const strTermAddress;

// OAuthView strings
extern NSString * const strLabelSignIn;
extern NSString * const strLabelActivation;
extern NSString * const strFooterSignInOrRegister;
extern NSString * const strFooterActivate;
extern NSString * const strFooterActivateEmail;
extern NSString * const strPlaceholderAuthEmail;
extern NSString * const strPlaceholderPassword;
extern NSString * const strPlaceholderActivationCode;
extern NSString * const strPlaceholderRepeatPassword;
extern NSString * const strPlaceholderPleaseWait;
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

// OOrigoListView strings
extern NSString * const strTabBarTitleOrigo;
extern NSString * const strViewTitleWardOrigoList;
extern NSString * const strHeaderWardsOrigos;
extern NSString * const strHeaderMyOrigos;
extern NSString * const strFooterOrigoCreationFirst;
extern NSString * const strFooterOrigoCreation;
extern NSString * const strFooterOrigoCreationWards;
extern NSString * const strSheetTitleOrigoType;
extern NSString * const strTermMe;
extern NSString * const strTermYourChild;
extern NSString * const strTermHim;
extern NSString * const strTermHer;
extern NSString * const strTermHimOrHer;
extern NSString * const strTermForName;

// OMemberListView strings
extern NSString * const strViewTitleMembers;
extern NSString * const strViewTitleHousehold;
extern NSString * const strHeaderContacts;
extern NSString * const strHeaderHouseholdMembers;
extern NSString * const strHeaderOrigoMembers;
extern NSString * const strFooterResidence;
extern NSString * const strFooterSchoolClass;
extern NSString * const strFooterPreschoolClass;
extern NSString * const strFooterSportsTeam;
extern NSString * const strFooterOtherOrigo;
extern NSString * const strButtonNewHousemate;
extern NSString * const strButtonDeleteMember;

// OOrigoView strings
extern NSString * const strViewTitleNewOrigo;
extern NSString * const strLabelAddress;
extern NSString * const strLabelTelephone;
extern NSString * const strHeaderAddresses;
extern NSString * const strPlaceholderAddress;
extern NSString * const strPlaceholderTelephone;

// OMemberView strings
extern NSString * const strViewTitleAboutMe;
extern NSString * const strViewTitleNewMember;
extern NSString * const strViewTitleNewHouseholdMember;
extern NSString * const strLabelEmail;
extern NSString * const strLabelMobilePhone;
extern NSString * const strLabelDateOfBirth;
extern NSString * const strLabelAbbreviatedEmail;
extern NSString * const strLabelAbbreviatedMobilePhone;
extern NSString * const strLabelAbbreviatedDateOfBirth;
extern NSString * const strLabelAbbreviatedTelephone;
extern NSString * const strPlaceholderPhoto;
extern NSString * const strPlaceholderName;
extern NSString * const strPlaceholderEmail;
extern NSString * const strPlaceholderDateOfBirth;
extern NSString * const strPlaceholderMobilePhone;
extern NSString * const strFooterMember;
extern NSString * const strButtonNewAddress;
extern NSString * const strButtonInviteToHousehold;
extern NSString * const strButtonMergeHouseholds;
extern NSString * const strAlertTitleMemberExists;
extern NSString * const strAlertTextMemberExists;
extern NSString * const strAlertTitleUserEmailChange;
extern NSString * const strAlertTextUserEmailChange;
extern NSString * const strAlertTitleEmailChangeFailed;
extern NSString * const strAlertTextEmailChangeFailed;
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

// Meta strings
extern NSString * const origoTypeMemberRoot;
extern NSString * const origoTypeResidence;
extern NSString * const origoTypeSchoolClass;
extern NSString * const origoTypePreschoolClass;
extern NSString * const origoTypeSportsTeam;
extern NSString * const origoTypeDefault;

extern NSString * const xstrContactRolesSchoolClass;
extern NSString * const xstrContactRolesPreschoolClass;
extern NSString * const xstrContactRolesSportsTeam;


@interface OStrings : NSObject

+ (BOOL)hasStrings;
+ (void)fetchStrings:(id)delegate;
+ (void)conditionallyRefresh;

+ (NSString *)stringForKey:(NSString *)key;
+ (NSString *)labelForKey:(NSString *)key;
+ (NSString *)placeholderForKey:(NSString *)key;

@end
