//
//  OStrings.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OStrings.h"

#import "OAlert.h"
#import "OMeta.h"
#import "OLogging.h"
#import "OServerConnection.h"

// Cross-view strings
NSString * const strNameMyHousehold                  = @"strNameMyHousehold";
NSString * const strNameOurHousehold                 = @"strNameOurHousehold";
NSString * const strNameMyMessageBoard               = @"strNameMyMessageBoard";
NSString * const strNameOurMessageBoard              = @"strNameOurMessageBoard";
NSString * const strButtonOK                         = @"strButtonOK";
NSString * const strButtonEdit                       = @"strButtonEdit";
NSString * const strButtonDone                       = @"strButtonDone";
NSString * const strButtonCancel                     = @"strButtonCancel";
NSString * const strAlertTextNoInternet              = @"strAlertTextNoInternet";
NSString * const strAlertTextServerError             = @"strAlertTextServerError";

// OAuthView strings
NSString * const strLabelSignInOrRegister            = @"strLabelSignInOrRegister";
NSString * const strLabelActivate                    = @"strLabelActivate";
NSString * const strFooterSignInOrRegister           = @"strFooterSignInOrRegister";
NSString * const strFooterActivate                   = @"strFooterActivate";
NSString * const strPromptAuthEmail                  = @"strPromptAuthEmail";
NSString * const strPromptPassword                   = @"strPromptPassword";
NSString * const strPromptActivationCode             = @"strPromptActivationCode";
NSString * const strPromptRepeatPassword             = @"strPromptRepeatPassword";
NSString * const strPromptPleaseWait                 = @"strPromptPleaseWait";
NSString * const strButtonHaveCode                   = @"strButtonHaveCode";
NSString * const strButtonStartOver                  = @"strButtonStartOver";
NSString * const strButtonAccept                     = @"strButtonAccept";
NSString * const strButtonDecline                    = @"strButtonDecline";
NSString * const strAlertTitleActivationFailed       = @"strAlertTitleActivationFailed";
NSString * const strAlertTextActivationFailed        = @"strAlertTextActivationFailed";
NSString * const strAlertTitleWelcomeBack            = @"strAlertTitleWelcomeBack";
NSString * const strAlertTextWelcomeBack             = @"strAlertTextWelcomeBack";
NSString * const strAlertTitleIncompleteRegistration = @"strAlertTitleIncompleteRegistration";
NSString * const strAlertTextIncompleteRegistration  = @"strAlertTextIncompleteRegistration";
NSString * const strSheetTitleEULA                   = @"strSheetTitleEULA";

// OOrigoListView strings
NSString * const strTabBarTitleOrigo                 = @"strTabBarTitleOrigo";
NSString * const strViewTitleOrigoList               = @"strViewTitleOrigoList";
NSString * const strHeaderWards                      = @"strHeaderWards";
NSString * const strHeaderMyOrigos                   = @"strHeaderMyOrigos";

// OMemberListView strings
NSString * const strViewTitleMembers                 = @"strViewTitleMembers";
NSString * const strViewTitleHousehold               = @"strViewTitleHousehold";
NSString * const strHeaderContacts                   = @"strHeaderContacts";
NSString * const strHeaderHouseholdMembers           = @"strHeaderHouseholdMembers";
NSString * const strHeaderOrigoMembers               = @"strHeaderOrigoMembers";
NSString * const strFooterHousehold                  = @"strFooterHousehold";
NSString * const strButtonDeleteMember               = @"strButtonDeleteMember";

// OOrigoView strings
NSString * const strLabelAddress                     = @"strLabelAddress";
NSString * const strLabelTelephone                   = @"strLabelTelephone";
NSString * const strHeaderAddress                    = @"strHeaderAddress";
NSString * const strHeaderAddresses                  = @"strHeaderAddresses";
NSString * const strPromptAddressLine1               = @"strPromptAddressLine1";
NSString * const strPromptAddressLine2               = @"strPromptAddressLine2";
NSString * const strPromptTelephone                  = @"strPromptTelephone";

// OMemberView strings
NSString * const strViewTitleAboutMe                 = @"strViewTitleAboutMe";
NSString * const strViewTitleNewMember               = @"strViewTitleNewMember";
NSString * const strViewTitleNewHouseholdMember      = @"strViewTitleNewHouseholdMember";
NSString * const strLabelAbbreviatedEmail            = @"strLabelAbbreviatedEmail";
NSString * const strLabelAbbreviatedMobilePhone      = @"strLabelAbbreviatedMobilePhone";
NSString * const strLabelAbbreviatedDateOfBirth      = @"strLabelAbbreviatedDateOfBirth";
NSString * const strLabelAbbreviatedTelephone        = @"strLabelAbbreviatedTelephone";
NSString * const strPromptPhoto                      = @"strPromptPhoto";
NSString * const strPromptName                       = @"strPromptName";
NSString * const strPromptEmail                      = @"strPromptEmail";
NSString * const strPromptDateOfBirth                = @"strPromptDateOfBirth";
NSString * const strPromptMobilePhone                = @"strPromptMobilePhone";
NSString * const strButtonInviteToHousehold          = @"strButtonInviteToHousehold";
NSString * const strButtonMergeHouseholds            = @"strButtonMergeHouseholds";
NSString * const strAlertTitleMemberExists           = @"strAlertTitleMemberExists";
NSString * const strAlertTextMemberExists            = @"strAlertTextMemberExists";
NSString * const strSheetTitleGenderSelf             = @"strSheetTitleGenderSelf";
NSString * const strSheetTitleGenderSelfMinor        = @"strSheetTitleGenderSelfMinor";
NSString * const strSheetTitleGenderMember           = @"strSheetTitleGenderMember";
NSString * const strSheetTitleGenderMinor            = @"strSheetTitleGenderMinor";
NSString * const strSheetTitleExistingResidence      = @"strSheetTitleExistingResidence";
NSString * const strTermFemale                       = @"strTermFemale";
NSString * const strTermFemaleMinor                  = @"strTermFemaleMinor";
NSString * const strTermMale                         = @"strTermMale";
NSString * const strTermMaleMinor                    = @"strTermMaleMinor";

// OCalendarView strings
NSString * const strTabBarTitleCalendar              = @"strTabBarTitleCalendar";

// OTaskView strings
NSString * const strTabBarTitleTasks                 = @"strTabBarTitleTasks";

// OMessageBoardView strings
NSString * const strTabBarTitleMessages              = @"strTabBarTitleMessages";

// OSettingsView strings
NSString * const strTabBarTitleSettings              = @"strTabBarTitleSettings";
NSString * const strButtonSignOut                    = @"strButtonSignOut";

// Meta strings
NSString * const strOrigoTypeSchoolClass             = @"strOrigoTypeSchoolClass";
NSString * const strOrigoTypePreschoolClass          = @"strOrigoTypePreschoolClass";
NSString * const strOrigoTypeSportsTeam              = @"strOrigoTypeSportsTeam";
NSString * const strOrigoTypeOther                   = @"strOrigoTypeOther";

NSString * const xstrContactRolesSchoolClass         = @"xstrContactRolesSchoolClass";
NSString * const xstrContactRolesPreschoolClass      = @"xstrContactRolesPreschoolClass";
NSString * const xstrContactRolesSportsTeam          = @"xstrContactRolesSportsTeam";

static NSString * const kStringsPlist = @"strings.plist";
static NSDictionary *strings = nil;


@implementation OStrings

#pragma mark - Auxiliary methods

+ (NSString *)fullPathToStringsPlist
{
    NSString *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString *relativePath = [kBundleId stringByAppendingPathComponent:kStringsPlist];
    
    return [cachesDirectory stringByAppendingPathComponent:relativePath];
}


#pragma mark - Interface implementation

+ (void)conditionallyRefresh
{
    if ([[OMeta m] internetConnectionIsAvailable]) {
        if (!strings || [OMeta m].internetConnectionIsWiFi) { // TODO: Only if required
            [[[OServerConnection alloc] init] getStrings];
        }
    }
}


+ (NSString *)stringForKey:(NSString *)key
{
    NSString *string = @"";
    
    if (!strings) {
        strings = [NSDictionary dictionaryWithContentsOfFile:[self fullPathToStringsPlist]];
    }
    
    if (strings) {
        string = [strings objectForKey:key];
        
        if (!string) {
            OLogBreakage(@"No string with key '%@'.", key);
        }
    } else {
        OLogBreakage(@"Failed to instantiate strings from plist.");
    }
    
    return string;
}


+ (NSString *)lowercaseStringForKey:(NSString *)key
{
    return [[OStrings stringForKey:key] lowercaseString];
}


#pragma mark - OServerConnectionDelegate implementation

+ (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    if (response.statusCode == kHTTPStatusCodeOK) {
        strings = data;
        
        if (![strings writeToFile:[self fullPathToStringsPlist] atomically:YES]) {
            OLogError(@"Error writing strings from server to plist '%@'.", [self fullPathToStringsPlist]);
        }
    }
}


+ (void)didFailWithError:(NSError *)error
{
    [OAlert showAlertForError:error];
}

@end
