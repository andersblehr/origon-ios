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


// Tab bar titles
NSString * const strTabBarTitleOrigo                  = @"strTabBarTitleOrigo";
NSString * const strTabBarTitleCalendar               = @"strTabBarTitleCalendar";
NSString * const strTabBarTitleTasks                  = @"strTabBarTitleTasks";
NSString * const strTabBarTitleMessages               = @"strTabBarTitleMessages";
NSString * const strTabBarTitleSettings               = @"strTabBarTitleSettings";

// Meta
NSString * const strOrigoTypeSchoolClass              = @"strOrigoTypeSchoolClass";
NSString * const strOrigoTypePreschoolClass           = @"strOrigoTypePreschoolClass";
NSString * const strOrigoTypeSportsTeam               = @"strOrigoTypeSportsTeam";
NSString * const strOrigoTypeOther                    = @"strOrigoTypeOther";

NSString * const xstrContactRolesSchoolClass          = @"xstrContactRolesSchoolClass";
NSString * const xstrContactRolesPreschoolClass       = @"xstrContactRolesPreschoolClass";
NSString * const xstrContactRolesSportsTeam           = @"xstrContactRolesSportsTeam";

// EULA
NSString * const strEULA                              = @"strEULA";
NSString * const strAccept                            = @"strAccept";
NSString * const strDecline                           = @"strDecline";

// Generic strings
NSString * const strPleaseWait                        = @"strPleaseWait";
NSString * const strAboutMe                           = @"strAboutMe";
NSString * const strFemale                            = @"strFemale";
NSString * const strFemaleMinor                       = @"strFemaleMinor";
NSString * const strMale                              = @"strMale";
NSString * const strMaleMinor                         = @"strMaleMinor";
NSString * const strMyHousehold                       = @"strMyHousehold";
NSString * const strMyMessageBoard                    = @"strMyMessageBoard";
NSString * const strOurMessageBoard                   = @"strOurMessageBoard";
NSString * const strDeleteConfirmation                = @"strDeleteConfirmation";

// Prompts
NSString * const strAuthEmailPrompt                   = @"strAuthEmailPrompt";
NSString * const strPasswordPrompt                    = @"strPasswordPrompt";
NSString * const strActivationCodePrompt              = @"strActivationCodePrompt";
NSString * const strRepeatPasswordPrompt              = @"strRepeatPasswordPrompt";
NSString * const strPhotoPrompt                       = @"strPhotoPrompt";
NSString * const strNamePrompt                        = @"strNamePrompt";
NSString * const strEmailPrompt                       = @"strEmailPrompt";
NSString * const strMobilePhonePrompt                 = @"strMobilePhonePrompt";
NSString * const strDateOfBirthPrompt                 = @"strDateOfBirthPrompt";
NSString * const strUserWebsitePrompt                 = @"strUserWebsitePrompt";
NSString * const strAddressLine1Prompt                = @"strAddressLine1Prompt";
NSString * const strAddressLine2Prompt                = @"strAddressLine2Prompt";
NSString * const strTelephonePrompt                   = @"strTelephonePrompt";

// Labels
NSString * const strSignInOrRegisterLabel             = @"strSignInOrRegisterLabel";
NSString * const strActivateLabel                     = @"strActivateLabel";
NSString * const strAbbreviatedEmailLabel             = @"strAbbreviatedEmailLabel";
NSString * const strAbbreviatedMobilePhoneLabel       = @"strAbbreviatedMobilePhoneLabel";
NSString * const strAbbreviatedDateOfBirthLabel       = @"strAbbreviatedDateOfBirthLabel";
NSString * const strAbbreviatedTelephoneLabel         = @"strAbbreviatedTelephoneLabel";
NSString * const strAddressLabel                      = @"strAddressLabel";
NSString * const strAddressesLabel                    = @"strAddressesLabel";
NSString * const strTelephoneLabel                    = @"strTelephoneLabel";

// Header & footer strings
NSString * const strSignInOrRegisterFooter            = @"strSignInOrRegisterFooter";
NSString * const strActivateFooter                    = @"strActivateFooter";
NSString * const strHouseholdMemberListFooter         = @"strHouseholdMemberListFooter";

// Button titles
NSString * const strOK                                = @"strOK";
NSString * const strCancel                            = @"strCancel";
NSString * const strRetry                             = @"strRetry";
NSString * const strStartOver                         = @"strStartOver";
NSString * const strHaveCode                          = @"strHaveCode";
NSString * const strInviteToHousehold                 = @"strInviteToHousehold";
NSString * const strMergeHouseholds                   = @"strMergeHouseholds";

// Alerts & error messages
NSString * const strNoInternetError                   = @"strNoInternetError";
NSString * const strServerErrorAlert                  = @"strServerErrorAlert";
NSString * const strActivationFailedTitle             = @"strActivationFailedTitle";
NSString * const strActivationFailedAlert             = @"strActivationFailedAlert";
NSString * const strWelcomeBackTitle                  = @"strWelcomeBackTitle";
NSString * const strWelcomeBackAlert                  = @"strWelcomeBackAlert";
NSString * const strIncompleteRegistrationTitle       = @"strIncompleteRegistrationTitle";
NSString * const strIncompleteRegistrationAlert       = @"strIncompleteRegistrationAlert";
NSString * const strMemberExistsTitle                 = @"strMemberExistsTitle";
NSString * const strMemberExistsAlert                 = @"strMemberExistsAlert";
NSString * const strExistingResidenceAlert            = @"strExistingResidenceAlert";

// OOrigoListView strings
NSString * const strViewTitleWardOrigos               = @"strViewTitleWardOrigos";
NSString * const strSectionHeaderWards                = @"strSectionHeaderWards";
NSString * const strSectionHeaderOrigos               = @"strSectionHeaderOrigos";

// OMemberListView strings
NSString * const strViewTitleMembers                  = @"strViewTitleMembers";
NSString * const strViewTitleHousehold                = @"strViewTitleHousehold";
NSString * const strSectionHeaderContacts             = @"strSectionHeaderContacts";
NSString * const strSectionHeaderHouseholdMembers     = @"strSectionHeaderHouseholdMembers";
NSString * const strSectionHeaderOrigoMembers         = @"strSectionHeaderOrigoMembers";

// OMemberView strings
NSString * const strViewTitleNewMember                = @"strViewTitleNewMember";
NSString * const strViewTitleNewHouseholdMember       = @"strViewTitleNewHouseholdMember";
NSString * const strGenderSheetTitleSelf              = @"strGenderSheetTitleSelf";
NSString * const strGenderSheetTitleSelfMinor         = @"strGenderSheetTitleSelfMinor";
NSString * const strGenderSheetTitleMember            = @"strGenderSheetTitleMember";
NSString * const strGenderSheetTitleMemberMinor       = @"strGenderSheetTitleMemberMinor";


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
