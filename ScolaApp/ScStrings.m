//
//  ScStrings.m
//  ScolaApp
//
//  Created by Anders Blehr on 26.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScStrings.h"

#import "ScAlert.h"
#import "ScMeta.h"
#import "ScLogging.h"
#import "ScServerConnection.h"


// Meta
NSString * const strScolaTypeSchoolClass              = @"strScolaTypeSchoolClass";
NSString * const strScolaTypePreschoolClass           = @"strScolaTypePreschoolClass";
NSString * const strScolaTypeSportsTeam               = @"strScolaTypeSportsTeam";
NSString * const strScolaTypeOther                    = @"strScolaTypeOther";

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
NSString * const strHousehold                         = @"strHousehold";
NSString * const strMyPlace                           = @"strMyPlace";
NSString * const strOurPlace                          = @"strOurPlace";
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
NSString * const strHouseholdLandlinePrompt           = @"strHouseholdLandlinePrompt";
NSString * const strScolaLandlinePrompt               = @"strScolaLandlinePrompt";
NSString * const strScolaWebsitePrompt                = @"strScolaWebsitePrompt";

// Labels
NSString * const strSignInOrRegisterLabel             = @"strSignInOrRegisterLabel";
NSString * const strActivateLabel                     = @"strActivateLabel";
NSString * const strSingleLetterEmailLabel            = @"strSingleLetterEmailLabel";
NSString * const strSingleLetterMobilePhoneLabel      = @"strSingleLetterMobilePhoneLabel";
NSString * const strSingleLetterDateOfBirthLabel      = @"strSingleLetterDateOfBirthLabel";
NSString * const strSingleLetterAddressLabel          = @"strSingleLetterAddressLabel";
NSString * const strSingleLetterLandlineLabel         = @"strSingleLetterLandlineLabel";
NSString * const strSingleLetterWebsiteLabel          = @"strSingleLetterWebsiteLabel";
NSString * const strAddressLabel                      = @"strAddressLabel";
NSString * const strAddressesLabel                    = @"strAddressesLabel";
NSString * const strLandlineLabel                     = @"strLandlineLabel";

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

// ScMembershipView strings
NSString * const strMembershipViewTitleDefault        = @"strMembershipViewTitleDefault";
NSString * const strMembershipViewTitleMyPlace        = @"strMembershipViewTitleMyPlace";
NSString * const strMembershipViewTitleOurPlace       = @"strMembershipViewTitleOurPlace";
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


@implementation ScStrings

#pragma mark - Auxiliary methods

+ (NSString *)fullPathToStringsPlist
{
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *relativePath = [kBundleId stringByAppendingPathComponent:kStringsPlist];
    
    return [cachesDirectory stringByAppendingPathComponent:relativePath];
}


#pragma mark - Interface implementation

+ (void)refreshIfPossible
{
    if ([ScMeta m].isInternetConnectionAvailable) {
        if (!strings || [ScMeta m].isInternetConnectionWiFi) { // TODO: Only if required
            [[[ScServerConnection alloc] init] fetchStringsFromServer];
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
            ScLogBreakage(@"No string with key '%@'.", key);
        }
    } else {
        ScLogBreakage(@"Failed to instantiate strings from plist.");
    }
    
    return string;
}


+ (NSString *)lowercaseStringForKey:(NSString *)key
{
    return [[ScStrings stringForKey:key] lowercaseString];
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
    [ScAlert showAlertForError:error];
}

@end
