//
//  ScStrings.m
//  ScolaApp
//
//  Created by Anders Blehr on 26.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScStrings.h"

#import "ScMeta.h"
#import "ScLogging.h"
#import "ScServerConnection.h"


static NSDictionary *strings = nil;

static NSString * const kStringsPlist = @"strings.plist";


// Generic labels
NSString * const strName                             = @"strName";
NSString * const strNamePlaceholder                  = @"strNamePlaceholder";
NSString * const strEmail                            = @"strEmail";
NSString * const strEmailPlaceholder                 = @"strEmailPlaceholder";
NSString * const strAddress                          = @"strAddress";
NSString * const strLandline                         = @"strLandline";
NSString * const strLandlinePlaceholder              = @"strLandlinePlaceholder";
NSString * const strMobile                           = @"strMobile";
NSString * const strMobilePlaceholder                = @"strMobilePlaceholder";
NSString * const strBorn                             = @"strBorn";
NSString * const strBornPlaceholder                  = @"strBornPlaceholder";

// Generic Scola strings
NSString * const strHousehold                        = @"strHousehold";
NSString * const strMyPlace                          = @"strMyPlace";
NSString * const strOurPlace                         = @"strOurPlace";
NSString * const strMyMessageBoard                   = @"strMyMessageBoard";
NSString * const strOurMessageBoard                  = @"strOurMessageBoard";

// Auth view
NSString * const strUserIntentionLogin               = @"strUserIntentionLogin";
NSString * const strUserIntentionRegistration        = @"strUserIntentionRegistration";
NSString * const strUserHelpNew                      = @"strUserHelpNew";
NSString * const strUserHelpMember                   = @"strUserHelpMember";
NSString * const strNamePrompt                       = @"strNamePrompt";
NSString * const strEmailPrompt                      = @"strEmailPrompt";
NSString * const strNewPasswordPrompt                = @"strNewPasswordPrompt";
NSString * const strPasswordPrompt                   = @"strPasswordPrompt";
NSString * const strPleaseWait                       = @"strPleaseWait";
NSString * const strUserHelpCompleteRegistration     = @"strUserHelpCompleteRegistration";
NSString * const strSeeYouLaterPopUpTitle            = @"strSeeYouLaterPopUpTitle";
NSString * const strSeeYouLaterPopUpMessage          = @"strSeeYouLaterPopUpMessage";
NSString * const strWelcomeBackPopUpTitle            = @"strWelcomeBackPopUpTitle";
NSString * const strWelcomeBackPopUpMessage          = @"strWelcomeBackPopUpMessage";
NSString * const strRegistrationCodePrompt           = @"strRegistrationCodePrompt";
NSString * const strRepeatPasswordPrompt             = @"strRepeatPasswordPrompt";
NSString * const strScolaDescription                 = @"strScolaDescription";

// Registration view 1
NSString * const strRegistrationView1Title           = @"strRegistrationView1Title";
NSString * const strRegistrationView1BackButtonTitle = @"strRegistrationView1BackButtonTitle";
NSString * const strAddressUserHelp                  = @"strAddressUserHelp";
NSString * const strProvideAddressUserHelp           = @"strProvideAddressUserHelp";
NSString * const strVerifyAddressUserHelp            = @"strVerifyAddressUserHelp";
NSString * const strAddressLine1Prompt               = @"strAddressLine1Prompt";
NSString * const strAddressLine2Prompt               = @"strAddressLine2Prompt";
NSString * const strPostCodeAndCityPrompt            = @"strPostCodeAndCityPrompt";
NSString * const strDateOfBirthUserHelp              = @"strDateOfBirthUserHelp";
NSString * const strVerifyDateOfBirthUserHelp        = @"strVerifyDateOfBirthUserHelp";
NSString * const strDateOfBirthPrompt                = @"strDateOfBirthPrompt";
NSString * const strDateOfBirthClickHerePrompt       = @"strDateOfBirthClickHerePrompt";

// Registration view 2
NSString * const strRegistrationView2Title           = @"strRegistrationView2Title";
NSString * const strFemale                           = @"strFemale";
NSString * const strFemaleMinor                      = @"strFemaleMinor";
NSString * const strMale                             = @"strMale";
NSString * const strMaleMinor                        = @"strMaleMinor";
NSString * const strGenderUserHelp                   = @"strGenderUserHelp";
NSString * const strMobilePhoneUserHelp              = @"strMobilePhoneUserHelp";
NSString * const strVerifyMobilePhoneUserHelp        = @"strVerifyMobilePhoneUserHelp";
NSString * const strMobilePhonePrompt                = @"strMobilePhonePrompt";
NSString * const strLandlineUserHelp                 = @"strLandlineUserHelp";
NSString * const strProvideLandlineUserHelp          = @"strProvideLandlineUserHelp";
NSString * const strVerifyLandlineUserHelp           = @"strVerifyLandlineUserHelp";
NSString * const strLandlinePrompt                   = @"strLandlinePrompt";

// Membership view
NSString * const strMembershipViewHomeScolaTitle1    = @"strMembershipViewHomeScolaTitle1";
NSString * const strMembershipViewHomeScolaTitle2    = @"strMembershipViewHomeScolaTitle2";
NSString * const strMembershipViewDefaultTitle       = @"strMembershipViewDefaultTitle";
NSString * const strHouseholdMembers                 = @"strHouseholdMembers";
NSString * const strHouseholdMemberListFooter        = @"strHouseholdMemberListFooter";
NSString * const strDeleteConfirmation               = @"strDeleteConfirmation";

// Member view
NSString * const strNewMemberViewTitle               = @"strNewMemberViewTitle";
NSString * const strUnderOurRoofViewTitle            = @"strUnderOurRoofViewTitle";

// Error & alert messages
NSString * const strNoInternetError                  = @"strNoInternetError";
NSString * const strServerErrorAlert                 = @"strServerErrorAlert";
NSString * const strInvalidNameTitle                 = @"strInvalidNameTitle";
NSString * const strInvalidNameAlert                 = @"strInvalidNameAlert";
NSString * const strInvalidEmailTitle                = @"strInvalidEmailTitle";
NSString * const strInvalidEmailAlert                = @"strInvalidEmailAlert";
NSString * const strInvalidPasswordTitle             = @"strInvalidPasswordTitle";
NSString * const strInvalidPasswordAlert             = @"strInvalidPasswordAlert";
NSString * const strInvalidDateOfBirthTitle          = @"strInvalidDateOfBirthTitle";
NSString * const strInvalidDateOfBirthAlert          = @"strInvalidDateOfBirthAlert";
NSString * const strInvalidGenderTitle               = @"strInvalidGenderTitle";
NSString * const strInvalidGenderAlert               = @"strInvalidGenderAlert";
NSString * const strEmailSentAlertTitle              = @"strEmailSentAlertTitle";
NSString * const strEmailSentAlert                   = @"strEmailSentAlert";
NSString * const strEmailSentToInviteeTitle          = @"strEmailSentToInviteeTitle";
NSString * const strEmailSentToInviteeAlert          = @"strEmailSentToInviteeAlert";
NSString * const strPasswordsDoNotMatchTitle         = @"strPasswordsDoNotMatchTitle";
NSString * const strPasswordsDoNotMatchAlert         = @"strPasswordsDoNotMatchAlert";
NSString * const strInvalidRegistrationCodeTitle     = @"strInvalidRegistrationCodeTitle";
NSString * const strInvalidRegistrationCodeAlert     = @"strInvalidRegistrationCodeAlert";
NSString * const strUserExistsMustLogInAlert         = @"strUserExistsMustLogInAlert";
NSString * const strNotLoggedInAlert                 = @"strNotLoggedInAlert";
NSString * const strNoAddressTitle                   = @"strNoAddressTitle";
NSString * const strNoAddressAlert                   = @"strNoAddressAlert";
NSString * const strNoMobileNumberTitle              = @"strNoMobileNumberTitle";
NSString * const strNoMobileNumberAlert              = @"strNoMobileNumberAlert";
NSString * const strNoPhoneNumberTitle               = @"strNoPhoneNumberTitle";
NSString * const strNoPhoneNumberAlert               = @"strNoPhoneNumberAlert";
NSString * const strIncompleteRegistrationTitle      = @"strIncompleteRegistrationTitle";
NSString * const strIncompleteRegistrationAlert      = @"strIncompleteRegistrationAlert";

// Button titles
NSString * const strOK                               = @"strOK";
NSString * const strCancel                           = @"strCancel";
NSString * const strLogIn                            = @"strLogIn";
NSString * const strNewUser                          = @"strNewUser";
NSString * const strHaveAccess                       = @"strHaveAccess";
NSString * const strHaveCode                         = @"strHaveCode";
NSString * const strLater                            = @"strLater";
NSString * const strTryAgain                         = @"strTryAgain";
NSString * const strGoBack                           = @"strGoBack";
NSString * const strContinue                         = @"strContinue";
NSString * const strSkipThis                         = @"strSkipThis";
NSString * const strDone                             = @"strDone";
NSString * const strNext                             = @"strNext";
NSString * const strUseConfigured                    = @"strUseConfigured";
NSString * const strUseNew                           = @"strUseNew";


@implementation ScStrings

#pragma mark - Auxiliary methods methods

+ (NSString *)fullPathToStringsPlist
{
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *relativePath = [kBundleId stringByAppendingPathComponent:kStringsPlist];
    
    return [cachesDirectory stringByAppendingPathComponent:relativePath];
}


#pragma mark - Interface implementation

+ (void)refreshStrings
{
    if ([ScMeta m].isInternetConnectionAvailable) {
        if (!strings || [ScMeta m].isInternetConnectionWiFi) { // TODO: Only if req'd
            [[[ScServerConnection alloc] init] fetchStringsUsingDelegate:self];
        }
    } else {
        ScLogBreakage(@"Attempt to refresh strings when server is not available.");
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
    [ScServerConnection showAlertForError:error];
}

@end
