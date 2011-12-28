//
//  ScStrings.m
//  ScolaApp
//
//  Created by Anders Blehr on 26.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScStrings.h"

#import "ScAppEnv.h"
#import "ScJSONUtil.h"
#import "ScLogging.h"
#import "ScServerConnection.h"

@implementation ScStrings

static ScStrings *stringsSingleton = nil;
static NSDictionary *strings = nil;

static NSString * const kStringsPlist = @"strings.plist";

// Alert messages
NSString * const strInvalidNameAlert           = @"strInvalidNameAlert";
NSString * const strInvalidEmailAlert          = @"strInvalidEmailAlert";
NSString * const strInvalidPasswordAlert       = @"strInvalidPasswordAlert";
NSString * const strInvalidInvitationCodeAlert = @"strInvalidInvitationCodeAlert";

// Root view (maintained in-app)
NSString * const istrNoInternet                = @"strNoInternet";
NSString * const istrServerDown                = @"strServerDown";

// Root view
NSString * const strMembershipPrompt           = @"strMembershipPrompt";
NSString * const strIsMember                   = @"strIsMember";
NSString * const strIsInvited                  = @"strIsInvited";
NSString * const strIsNew                      = @"strIsNew";
NSString * const strUserHelpNew                = @"strUserHelpNew";
NSString * const strUserHelpInvited            = @"strUserHelpInvited";
NSString * const strUserHelpMember             = @"strUserHelpMember";
NSString * const strNamePrompt                 = @"strNamePrompt";
NSString * const strEmailPrompt                = @"strEmailPrompt";
NSString * const strInvitationCodePrompt       = @"strInvitationCodePrompt";
NSString * const strPasswordPrompt             = @"strPasswordPrompt";
NSString * const strNewPasswordPrompt          = @"strNewPasswordPrompt";
NSString * const strScolaDescription           = @"strScolaDescription";

// Register user
NSString * const strFacebook                   = @"strFacebook";

// Confirm new user
NSString * const strUserWelcome                = @"strUserWelcome";
NSString * const strEnterRegistrationCode      = @"strEnterRegistrationCode";
NSString * const strRegistrationCode           = @"strRegistrationCode";
NSString * const strGenderFemale               = @"strFemale";
NSString * const strGenderMale                 = @"strMale";


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
        
        BOOL willGetStringsFromServer =
            [ScAppEnv env].isServerAvailable &&
            (!strings || [ScAppEnv env].isInternetConnectionWiFi);
        
        if (willGetStringsFromServer) {
            ScLogDebug(@"Getting strings from server...");
            strings = [[[ScServerConnection alloc] initForStrings] getStrings];
            
            ScLogDebug(@"Persisting strings to plist %@.", pathToPersistedStrings);
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
