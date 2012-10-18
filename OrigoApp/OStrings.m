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
NSString * const strAboutYou                          = @"strAboutYou";
NSString * const strAboutMember                       = @"strAboutMember";
NSString * const strFemale                            = @"strFemale";
NSString * const strFemaleMinor                       = @"strFemaleMinor";
NSString * const strMale                              = @"strMale";
NSString * const strMaleMinor                         = @"strMaleMinor";
NSString * const strMyHousehold                       = @"strMyHousehold";
NSString * const strMyMessageBoard                    = @"strMyMessageBoard";
NSString * const strOurMessageBoard                   = @"strOurMessageBoard";

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
NSString * const strSingleLetterEmailLabel            = @"strSingleLetterEmailLabel";
NSString * const strSingleLetterMobilePhoneLabel      = @"strSingleLetterMobilePhoneLabel";
NSString * const strSingleLetterDateOfBirthLabel      = @"strSingleLetterDateOfBirthLabel";
NSString * const strSingleLetterAddressLabel          = @"strSingleLetterAddressLabel";
NSString * const strSingleLetterTelephoneLabel        = @"strSingleLetterTelephoneLabel";
NSString * const strSingleLetterWebsiteLabel          = @"strSingleLetterWebsiteLabel";
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

// ScMemberListView strings
NSString * const strMemberListViewTitleDefault        = @"strMemberListViewTitleDefault";
NSString * const strMemberListViewTitleHousehold      = @"strMemberListViewTitleHousehold";
NSString * const strHouseholdMembers                  = @"strHouseholdMembers";
NSString * const strDeleteConfirmation                = @"strDeleteConfirmation";

// ScMemberView strings
NSString * const strMemberViewTitleAboutYou           = @"strMemberViewTitleAboutYou";
NSString * const strMemberViewTitleNewMember          = @"strMemberViewTitleNewMember";
NSString * const strMemberViewTitleNewHouseholdMember = @"strMemberViewTitleNewHouseholdMember";
NSString * const strGenderActionSheetTitleSelf        = @"strGenderActionSheetTitleSelf";
NSString * const strGenderActionSheetTitleSelfMinor   = @"strGenderActionSheetTitleSelfMinor";
NSString * const strGenderActionSheetTitleMember      = @"strGenderActionSheetTitleMember";
NSString * const strGenderActionSheetTitleMemberMinor = @"strGenderActionSheetTitleMemberMinor";


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

+ (void)refreshIfPossible
{
    if ([OMeta m].isInternetConnectionAvailable) {
        if (!strings || [OMeta m].isInternetConnectionWiFi) { // TODO: Only if required
            [[[OServerConnection alloc] init] fetchStringsFromServer];
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


#pragma mark - ScServerConnectionDelegate implementation

+ (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    if (response.statusCode == kHTTPStatusCodeOK) {
        strings = data;
        [strings writeToFile:[self fullPathToStringsPlist] atomically:YES];
    }
}


+ (void)didFailWithError:(NSError *)error
{
    [OAlert showAlertForError:error];
}

@end
