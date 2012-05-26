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


// Maintained in-app
NSString * const istrNoInternet                      = @"strNoInternet";
NSString * const istrServerDown                      = @"strServerDown";

// Grammer snippets
NSString * const strPhoneDefinite                    = @"strPhoneDefinite";
NSString * const str_iPodDefinite                    = @"str_iPodDefinite";
NSString * const str_iPadDefinite                    = @"str_iPadDefinite";
NSString * const strPhonePossessive                  = @"strPhonePossessive";
NSString * const str_iPodPossessive                  = @"str_iPodPossessive";
NSString * const str_iPadPossessive                  = @"str_iPadPossessive";
NSString * const strThisPhone                        = @"strThisPhone";
NSString * const strThis_iPod                        = @"strThis_iPod";
NSString * const strThis_iPad                        = @"strThis_iPad";

// Error & alert messages
NSString * const strNoInternetError                  = @"strNoInternetError";
NSString * const strServerErrorAlert                 = @"strServerErrorAlert";
NSString * const strInvalidNameAlert                 = @"strInvalidNameAlert";
NSString * const strInvalidEmailAlert                = @"strInvalidEmailAlert";
NSString * const strInvalidPasswordAlert             = @"strInvalidPasswordAlert";
NSString * const strEmailSentAlertTitle              = @"strEmailSentAlertTitle";
NSString * const strEmailSentAlert                   = @"strEmailSentAlert";
NSString * const strEmailSentToInviteeAlertTitle     = @"strEmailSentToInviteeAlertTitle";
NSString * const strEmailSentToInviteeAlert          = @"strEmailSentToInviteeAlert";
NSString * const strPasswordsDoNotMatchAlert         = @"strPasswordsDoNotMatchAlert";
NSString * const strRegistrationCodesDoNotMatchAlert = @"strRegistrationCodesDoNotMatchAlert";
NSString * const strUserExistsMustLogInAlert         = @"strUserExistsMustLogInAlert";
NSString * const strNotLoggedInAlert                 = @"strNotLoggedInAlert";
NSString * const strNoAddressAlert                   = @"strNoAddressAlert";
NSString * const strInvalidDateOfBirthAlert          = @"strInvalidDateOfBirthAlert";
NSString * const strNoPhoneNumberAlert               = @"strNoPhoneNumberAlert";

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
NSString * const strAddressUserHelp                  = @"strAddressUserHelp";
NSString * const strAddressListedUserHelp            = @"strAddressListedUserHelp";
NSString * const strAddressLine1Prompt               = @"strAddressLine1Prompt";
NSString * const strAddressLine2Prompt               = @"strAddressLine2Prompt";
NSString * const strPostCodeAndCityPrompt            = @"strPostCodeAndCityPrompt";
NSString * const strDateOfBirthUserHelp              = @"strDateOfBirthUserHelp";
NSString * const strDateOfBirthListedUserHelp        = @"strDateOfBirthListedUserHelp";
NSString * const strDateOfBirthPrompt                = @"strDateOfBirthPrompt";
NSString * const strDateOfBirthClickHerePrompt       = @"strDateOfBirthClickHerePrompt";

// Registration view 2
NSString * const strFemale                           = @"strFemale";
NSString * const strFemaleMinor                      = @"strFemaleMinor";
NSString * const strMale                             = @"strMale";
NSString * const strMaleMinor                        = @"strMaleMinor";
NSString * const strGenderUserHelp                   = @"strGenderUserHelp";
NSString * const strMobilePhoneUserHelp              = @"strMobilePhoneUserHelp";
NSString * const strMobilePhoneListedUserHelp        = @"strMobilePhoneListedUserHelp";
NSString * const strMobilePhonePrompt                = @"strMobilePhonePrompt";
NSString * const strLandlineUserHelp                 = @"strLandlineUserHelp";
NSString * const strLandlineListedUserHelp           = @"strLandlineListedUserHelp";
NSString * const strLandlinePrompt                   = @"strLandlinePrompt";

// Main view
NSString * const strMyPlace                          = @"strMyPlace";
NSString * const strOurPlace                         = @"strOurPlace";
NSString * const strMyMessageBoard                   = @"strMyMessageBoard";
NSString * const strOurMessageBoard                  = @"strOurMessageBoard";


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

+ (void)didReceiveResponse:(NSHTTPURLResponse *)response
{
    ScLogDebug(@"Received response. HTTP status code: %d", response.statusCode);
}


+ (void)finishedReceivingData:(NSDictionary *)data
{
    strings = data;
    
    [strings writeToFile:[self fullPathToStringsPlist] atomically:YES];
}


+ (void)didFailWithError:(NSError *)error
{
    [ScServerConnection showAlertForError:error];
}

@end
