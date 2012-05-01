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

@implementation ScStrings

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
NSString * const strEmailAlreadyRegisteredAlert      = @"strEmailAlreadyRegisteredAlert";
NSString * const strPasswordsDoNotMatchAlert         = @"strPasswordsDoNotMatchAlert";
NSString * const strRegistrationCodesDoNotMatchAlert = @"strRegistrationCodesDoNotMatchAlert";
NSString * const strUserExistsAlertTitle             = @"strUserExistsAlertTitle";
NSString * const strUserExistsButNotLoggedInAlert    = @"strUserExistsButNotLoggedInAlert";
NSString * const strUserExistsAndLoggedInAlert       = @"strUserExistsAndLoggedInAlert";
NSString * const strNotLoggedInAlert                 = @"strNotLoggedInAlert";
NSString * const strNoAddressAlert                   = @"strNoAddressAlert";
NSString * const strNoDeviceNameAlert                = @"strNoDeviceNameAlert";
NSString * const strNotBornAlert                     = @"strNotBornAlert";
NSString * const strUnrealisticAgeAlert              = @"strUnrealisticAgeAlert";
NSString * const strNoMobilePhoneAlert               = @"strNoMobilePhoneAlert";

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
NSString * const strUserIntentionPrompt              = @"strUserIntentionPrompt";
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
NSString * const strEmailSentPopUpTitle              = @"strEmailSentPopUpTitle";
NSString * const strEmailSentPopUpMessage            = @"strEmailSentPopUpMessage";
NSString * const strEmailSentToInviteePopUpTitle     = @"strEmailSentToInviteePopUpTitle";
NSString * const strEmailSentToInviteePopUpMessage   = @"strEmailSentToInviteePopUpMessage";
NSString * const strSeeYouLaterPopUpTitle            = @"strSeeYouLaterPopUpTitle";
NSString * const strSeeYouLaterPopUpMessage          = @"strSeeYouLaterPopUpMessage";
NSString * const strWelcomeBackPopUpTitle            = @"strWelcomeBackPopUpTitle";
NSString * const strWelcomeBackPopUpMessage          = @"strWelcomeBackPopUpMessage";
NSString * const strRegistrationCodePrompt           = @"strRegistrationCodePrompt";
NSString * const strRepeatPasswordPrompt             = @"strRepeatPasswordPrompt";
NSString * const strScolaDescription                 = @"strScolaDescription";

// Registration view 1
NSString * const strProvideAddressUserHelp           = @"strProvideAddressUserHelp";
NSString * const strVerifyAddressUserHelp            = @"strVerifyAddressUserHelp";
NSString * const strAddressLine1Prompt               = @"strAddressLine1Prompt";
NSString * const strAddressLine2Prompt               = @"strAddressLine2Prompt";
NSString * const strPostCodeAndCityPrompt            = @"strPostCodeAndCityPrompt";
NSString * const strDateOfBirthUserHelp              = @"strDateOfBirthUserHelp";
NSString * const strDateOfBirthPrompt                = @"strDateOfBirthPrompt";
NSString * const strDateOfBirthClickHerePrompt       = @"strDateOfBirthClickHerePrompt";

// Registration view 2
NSString * const strGenderUserHelp                   = @"strGenderUserHelp";
NSString * const strFemaleAdult                      = @"strFemaleAdult";
NSString * const strFemaleMinor                      = @"strFemaleMinor";
NSString * const strMaleAdult                        = @"strMaleAdult";
NSString * const strMaleMinor                        = @"strMaleMinor";
NSString * const strMobilePhoneUserHelp              = @"strMobilePhoneUserHelp";
NSString * const strMobilePhonePrompt                = @"strMobilePhonePrompt";
NSString * const strDeviceNameUserHelp               = @"strDeviceNameUserHelp";
NSString * const strDeviceNamePrompt                 = @"strDeviceNamePrompt";

// Main view
NSString * const strMyPlace                          = @"strMyPlace";
NSString * const strOurPlace                         = @"strOurPlace";
NSString * const strMyMessageBoard                   = @"strMyMessageBoard";
NSString * const strOurMessageBoard                  = @"strOurMessageBoard";


#pragma mark - Auxiliary methods methods

+ (NSString *)fullPathToStringsPlist
{
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *relativePath = [kBundleID stringByAppendingPathComponent:kStringsPlist];
    
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
