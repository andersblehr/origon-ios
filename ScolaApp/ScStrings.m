//
//  ScStrings.m
//  ScolaApp
//
//  Created by Anders Blehr on 26.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScStrings.h"

#import "ScAppEnv.h"
#import "ScLogging.h"
#import "ScServerConnection.h"

@implementation ScStrings

static ScStrings *stringsSingleton = nil;
static NSDictionary *strings = nil;

static NSString * const kStringsPlist = @"strings.plist";

// Alert messages
NSString * const strInternalServerError              = @"strInternalServerError";
NSString * const strInvalidNameAlert                 = @"strInvalidNameAlert";
NSString * const strInvalidEmailAlert                = @"strInvalidEmailAlert";
NSString * const strInvalidPasswordAlert             = @"strInvalidPasswordAlert";
NSString * const strInvalidScolaShortnameAlert       = @"strInvalidScolaShortnameAlert";
NSString * const strPasswordsDoNotMatchAlert         = @"strPasswordsDoNotMatchAlert";
NSString * const strRegistrationCodesDoNotMatchAlert = @"strRegistrationCodesDoNotMatchAlert";
NSString * const strScolaNotFoundAlert               = @"strScolaNotFoundAlert";
NSString * const strInvitationNotFoundAlert          = @"strInvitationNotFoundAlert";
NSString * const strUserExistsAlertTitle             = @"strUserExistsAlertTitle";
NSString * const strUserExistsButNotLoggedInAlert    = @"strUserExistsButNotLoggedInAlert";
NSString * const strUserExistsAndLoggedInAlert       = @"strUserExistsAndLoggedInAlert";

// Button titles
NSString * const strOK                               = @"strOK";
NSString * const strCancel                           = @"strCancel";
NSString * const strHaveAccess                       = @"strHaveAccess";
NSString * const strHaveCode                         = @"strHaveCode";
NSString * const strLater                            = @"strLater";
NSString * const strTryAgain                         = @"strTryAgain";
NSString * const strGoBack                           = @"strGoBack";
NSString * const strContinue                         = @"strContinue";

// Auth view
NSString * const istrNoInternet                      = @"strNoInternet";
NSString * const istrServerDown                      = @"strServerDown";
NSString * const strScolaDescription                 = @"strScolaDescription";
NSString * const strMembershipPrompt                 = @"strMembershipPrompt";
NSString * const strIsMember                         = @"strIsMember";
NSString * const strIsInvited                        = @"strIsInvited";
NSString * const strIsNew                            = @"strIsNew";
NSString * const strUserHelpNew                      = @"strUserHelpNew";
NSString * const strUserHelpInvited                  = @"strUserHelpInvited";
NSString * const strUserHelpMember                   = @"strUserHelpMember";
NSString * const strNamePrompt                       = @"strNamePrompt";
NSString * const strNameAsReceivedPrompt             = @"strNameAsReceivedPrompt";
NSString * const strEmailPrompt                      = @"strEmailPrompt";
NSString * const strScolaShortnamePrompt             = @"strScolaShortnamePrompt";
NSString * const strNewPasswordPrompt                = @"strNewPasswordPrompt";
NSString * const strPasswordPrompt                   = @"strPasswordPrompt";
NSString * const strPleaseWait                       = @"strPleaseWait";
NSString * const strUserHelpCompleteRegistration     = @"strUserHelpCompleteRegistration";
NSString * const strEmailSentPopUpTitle              = @"strEmailSentPopUpTitle";
NSString * const strEmailSentPopUpMessage            = @"strEmailSentPopUpMessage";
NSString * const strSeeYouLaterPopUpTitle            = @"strSeeYouLaterPopUpTitle";
NSString * const strSeeYouLaterPopUpMessage          = @"strSeeYouLaterPopUpMessage";
NSString * const strWelcomeBackPopUpTitle            = @"strWelcomeBackPopUpTitle";
NSString * const strWelcomeBackPopUpMessage          = @"strWelcomeBackPopUpMessage";
NSString * const strRegistrationCodePrompt           = @"strRegistrationCodePrompt";
NSString * const strRepeatPasswordPrompt             = @"strRepeatPasswordPrompt";


#pragma mark - Private methods

+ (NSString *)fullPathToStringsPlist
{
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *relativePath = [kBundleID stringByAppendingPathComponent:kStringsPlist];
    
    return [cachesDirectory stringByAppendingPathComponent:relativePath];
}


#pragma mark - Singleton instance handling

+ (id)allocWithZone:(NSZone *)zone
{
    if (!stringsSingleton) {
        stringsSingleton = [[super allocWithZone:nil] init];
    }
    
    return stringsSingleton;
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


- (id)init
{
    return [super init];
}


#pragma mark - String lookup

+ (BOOL)areStringsAvailable
{
    if (!stringsSingleton) {
        stringsSingleton = [[super allocWithZone:nil] init];
        
        NSString *pathToPersistedStrings = [self fullPathToStringsPlist];
        strings = [NSDictionary dictionaryWithContentsOfFile:pathToPersistedStrings];
        
        BOOL shouldGetStringsFromServer =
            [ScAppEnv env].isServerAvailable &&
            (!strings || [ScAppEnv env].isInternetConnectionWiFi); // TODO: Only if req'd
        
        if (shouldGetStringsFromServer) {
            ScLogVerbose(@"Getting strings from server...");
            strings = [[[ScServerConnection alloc] initForStrings] getRemoteClass:@"ScStrings"];
            
            ScLogVerbose(@"Persisting strings to plist %@.", pathToPersistedStrings);
            [strings writeToFile:pathToPersistedStrings atomically:YES];
        }
    }
    
    return (strings != nil);
}


+ (NSString *)stringForKey:(NSString *)key
{
    NSString *string = nil;
    
    if ([self areStringsAvailable]) {
        string = [strings objectForKey:key];
        
        if (!string) {
            ScLogBreakage(@"No string with key '%@'.", key);
        }
    } else {
        ScLogBreakage(@"Attempt to retrieve string when no strings are available.");
    }
    
    return string;
}

@end
