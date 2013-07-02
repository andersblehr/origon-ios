//
//  OStrings.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OStrings.h"

#import "NSDate+OrigoExtensions.h"

#import "OAlert.h"
#import "OConnection.h"
#import "ODefaults.h"
#import "OMeta.h"
#import "OLogging.h"
#import "OState.h"

#import "OOrigo+OrigoExtensions.h"

// Cross-view strings
NSString * const strButtonOK                         = @"strButtonOK";
NSString * const strButtonEdit                       = @"strButtonEdit";
NSString * const strButtonNext                       = @"strButtonNext";
NSString * const strButtonDone                       = @"strButtonDone";
NSString * const strButtonContinue                   = @"strButtonContinue";
NSString * const strButtonCancel                     = @"strButtonCancel";
NSString * const strButtonSignOut                    = @"strButtonSignOut";
NSString * const strAlertTextNoInternet              = @"strAlertTextNoInternet";
NSString * const strAlertTextServerError             = @"strAlertTextServerError";
NSString * const strAlertTextLocating                = @"strAlertTextLocating";
NSString * const strTermAddress                      = @"strTermAddress";
NSString * const strTermCountry                      = @"strTermCountry";

// OAuthView strings
NSString * const strLabelSignIn                      = @"strLabelSignIn";
NSString * const strLabelActivate                    = @"strLabelActivate";
NSString * const strFooterSignInOrRegister           = @"strFooterSignInOrRegister";
NSString * const strFooterActivateUser               = @"strFooterActivateUser";
NSString * const strFooterActivateEmail              = @"strFooterActivateEmail";
NSString * const strPlaceholderAuthEmail             = @"strPlaceholderAuthEmail";
NSString * const strPlaceholderPassword              = @"strPlaceholderPassword";
NSString * const strPlaceholderActivationCode        = @"strPlaceholderActivationCode";
NSString * const strPlaceholderRepeatPassword        = @"strPlaceholderRepeatPassword";
NSString * const strPlaceholderPleaseWait            = @"strPlaceholderPleaseWait";
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

// OOrigoListView strings
NSString * const strTabBarTitleOrigo                 = @"strTabBarTitleOrigo";
NSString * const strViewTitleWardOrigoList           = @"strViewTitleWardOrigoList";
NSString * const strHeaderWardsOrigos                = @"strHeaderWardsOrigos";
NSString * const strHeaderMyOrigos                   = @"strHeaderMyOrigos";
NSString * const strFooterOrigoCreationFirst         = @"strFooterOrigoCreationFirst";
NSString * const strFooterOrigoCreation              = @"strFooterOrigoCreation";
NSString * const strFooterOrigoCreationWards         = @"strFooterOrigoCreationWards";
NSString * const strButtonCountryLocate              = @"strButtonCountryLocate";
NSString * const strButtonCountryOther               = @"strButtonCountryOther";
NSString * const strAlertTitleCountryOther           = @"strAlertTitleCountryOther";
NSString * const strAlertTextCountryOther            = @"strAlertTextCountryOther";
NSString * const strAlertTextCountrySupported        = @"strAlertTextCountrySupported";
NSString * const strAlertTextCountryUnsupported      = @"strAlertTextCountryUnsupported";
NSString * const strSheetTitleCountry                = @"strSheetTitleCountry";
NSString * const strSheetTitleOrigoType              = @"strSheetTitleOrigoType";
NSString * const strTermMe                           = @"strTermMe";
NSString * const strTermYourChild                    = @"strTermYourChild";
NSString * const strTermHim                          = @"strTermHim";
NSString * const strTermHer                          = @"strTermHer";
NSString * const strTermHimOrHer                     = @"strTermHimOrHer";
NSString * const strTermForName                      = @"strTermForName";

// OMemberListView strings
NSString * const strViewTitleMembers                 = @"strViewTitleMembers";
NSString * const strViewTitleHousehold               = @"strViewTitleHousehold";
NSString * const strHeaderContacts                   = @"strHeaderContacts";
NSString * const strHeaderHouseholdMembers           = @"strHeaderHouseholdMembers";
NSString * const strHeaderOrigoMembers               = @"strHeaderOrigoMembers";
NSString * const strFooterResidence                  = @"strFooterResidence";
NSString * const strFooterSchoolClass                = @"strFooterSchoolClass";
NSString * const strFooterPreschoolClass             = @"strFooterPreschoolClass";
NSString * const strFooterSportsTeam                 = @"strFooterSportsTeam";
NSString * const strFooterOtherOrigo                 = @"strFooterOtherOrigo";
NSString * const strButtonNewHousemate               = @"strButtonNewHousemate";
NSString * const strButtonDeleteMember               = @"strButtonDeleteMember";

// OOrigoView strings
NSString * const strDefaultResidenceName             = @"strDefaultResidenceName";
NSString * const strViewTitleNewOrigo                = @"strViewTitleNewOrigo";
NSString * const strLabelAddress                     = @"strLabelAddress";
NSString * const strLabelDescriptionText             = @"strLabelDescriptionText";
NSString * const strLabelTelephone                   = @"strLabelTelephone";
NSString * const strHeaderAddresses                  = @"strHeaderAddresses";
NSString * const strPlaceholderAddress               = @"strPlaceholderAddress";
NSString * const strPlaceholderDescriptionText       = @"strPlaceholderDescriptionText";
NSString * const strPlaceholderTelephone             = @"strPlaceholderTelephone";

// OMemberView strings
NSString * const strViewTitleAboutMe                 = @"strViewTitleAboutMe";
NSString * const strViewTitleNewMember               = @"strViewTitleNewMember";
NSString * const strViewTitleNewHouseholdMember      = @"strViewTitleNewHouseholdMember";
NSString * const strLabelEmail                       = @"strLabelEmail";
NSString * const strLabelMobilePhone                 = @"strLabelMobilePhone";
NSString * const strLabelDateOfBirth                 = @"strLabelDateOfBirth";
NSString * const strLabelAbbreviatedEmail            = @"strLabelAbbreviatedEmail";
NSString * const strLabelAbbreviatedMobilePhone      = @"strLabelAbbreviatedMobilePhone";
NSString * const strLabelAbbreviatedDateOfBirth      = @"strLabelAbbreviatedDateOfBirth";
NSString * const strLabelAbbreviatedTelephone        = @"strLabelAbbreviatedTelephone";
NSString * const strPlaceholderPhoto                 = @"strPlaceholderPhoto";
NSString * const strPlaceholderName                  = @"strPlaceholderName";
NSString * const strPlaceholderEmail                 = @"strPlaceholderEmail";
NSString * const strPlaceholderDateOfBirth           = @"strPlaceholderDateOfBirth";
NSString * const strPlaceholderMobilePhone           = @"strPlaceholderMobilePhone";
NSString * const strFooterMember                     = @"strFooterMember";
NSString * const strButtonNewAddress                 = @"strButtonNewAddress";
NSString * const strButtonInviteToHousehold          = @"strButtonInviteToHousehold";
NSString * const strButtonMergeHouseholds            = @"strButtonMergeHouseholds";
NSString * const strAlertTitleMemberExists           = @"strAlertTitleMemberExists";
NSString * const strAlertTextMemberExists            = @"strAlertTextMemberExists";
NSString * const strAlertTitleUserEmailChange        = @"strAlertTitleUserEmailChange";
NSString * const strAlertTextUserEmailChange         = @"strAlertTextUserEmailChange";
NSString * const strAlertTitleEmailChangeFailed      = @"strAlertTitleFailedEmailChange";
NSString * const strAlertTextEmailChangeFailed       = @"strAlertTextFailedEmailChange";
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

// OTaskListView strings
NSString * const strTabBarTitleTasks                 = @"strTabBarTitleTasks";

// OMessageListView strings
NSString * const strTabBarTitleMessages              = @"strTabBarTitleMessages";
NSString * const strDefaultMessageBoardName          = @"strDefaultMessageBoardName";

// OSettingListView strings
NSString * const strTabBarTitleSettings              = @"strTabBarTitleSettings";
NSString * const strSettingTitleCountry              = @"strSettingTitleCountry";
NSString * const strSettingTextCountry               = @"strSettingTextCountry";

// OSettingView strings
NSString * const strLabelCountrySettings             = @"strLabelCountrySettings";
NSString * const strLabelCountryLocation             = @"strLabelCountryLocation";
NSString * const strFooterCountryInfoParenthesis     = @"strFooterCountryInfoParenthesis";
NSString * const strFooterCountryInfoLocate          = @"strFooterCountryInfoLocate";

// Origo type strings
NSString * const strOrigoTypeResidence               = @"strOrigoTypeResidence";
NSString * const strOrigoTypeOrganisation            = @"strOrigoTypeOrganisation";
NSString * const strOrigoTypeAssociation             = @"strOrigoTypeAssociation";
NSString * const strOrigoTypeSchoolClass             = @"strOrigoTypeSchoolClass";
NSString * const strOrigoTypePreschoolClass          = @"strOrigoTypePreschoolClass";
NSString * const strOrigoTypeSportsTeam              = @"strOrigoTypeSportsTeam";
NSString * const strOrigoTypeOther                   = @"strOrigoTypeOther";
NSString * const strNewOrigoOfTypeResidence          = @"strNewOrigoOfTypeResidence";
NSString * const strNewOrigoOfTypeOrganisation       = @"strNewOrigoOfTypeOrganisation";
NSString * const strNewOrigoOfTypeAssociation        = @"strNewOrigoOfTypeAssociation";
NSString * const strNewOrigoOfTypeSchoolClass        = @"strNewOrigoOfTypeSchoolClass";
NSString * const strNewOrigoOfTypePreschoolClass     = @"strNewOrigoOfTypePreschoolClass";
NSString * const strNewOrigoOfTypeSportsTeam         = @"strNewOrigoOfTypeSportsTeam";
NSString * const strNewOrigoOfTypeOther              = @"strNewOrigoOfTypeOther";

// Meta strings
NSString * const metaSupportedCountryCodes           = @"metaSupportedCountryCodes";
NSString * const metaContactRolesSchoolClass         = @"metaContactRolesSchoolClass";
NSString * const metaContactRolesPreschoolClass      = @"metaContactRolesPreschoolClass";
NSString * const metaContactRolesAssociation         = @"metaContactRolesAssociation";
NSString * const metaContactRolesSportsTeam          = @"metaContactRolesSportsTeam";

static NSDictionary const *strings = nil;
static NSString * const kStringsPlist = @"strings.plist";
static NSInteger const kDaysBetweenStringFetches = 0; // TODO: Set to 14

static NSString * const kKeyPrefixLabel = @"strLabel";
static NSString * const kKeyPrefixPlaceholder = @"strPlaceholder";
static NSString * const kKeyPrefixContactRole = @"strContactRole";
static NSString * const kKeyPrefixSettingTitle = @"strSettingTitle";
static NSString * const kKeyPrefixSettingText = @"strSettingText";


@implementation OStrings

#pragma mark - Auxiliary methods

+ (NSString *)pathToStringsFile
{
    NSString *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString *relativePath = [kBundleId stringByAppendingPathComponent:kStringsPlist];
    
    return [cachesDirectory stringByAppendingPathComponent:relativePath];
}


+ (NSString *)stringKeyWithPrefix:(NSString *)prefix forKey:(NSString *)key
{
    return [prefix stringByAppendingString:[[[key substringWithRange:NSMakeRange(0, 1)] uppercaseString] stringByAppendingString:[key substringFromIndex:1]]];
}


#pragma mark - String fetching & refresh

+ (BOOL)hasStrings
{
    if (!strings) {
        strings = [NSDictionary dictionaryWithContentsOfFile:[self pathToStringsFile]];
    }
    
    return (strings != nil);
}


+ (void)refreshIfNeeded
{
    if ([[OMeta m] userIsSignedIn] && [[OMeta m] internetConnectionIsAvailable]) {
        NSDate *stringDate = [ODefaults globalDefaultForKey:kDefaultsKeyStringDate];
        
        if (stringDate && ([stringDate daysBeforeNow] >= kDaysBetweenStringFetches)) {
            [OConnection fetchStrings];
        }
    }
}


#pragma mark - Interface strings

+ (NSString *)stringForKey:(NSString *)key
{
    NSString *string = @"";
    
    if ([self hasStrings]) {
        string = strings[key];
        
        if (!string) {
            OLogBreakage(@"No string with key '%@'.", key);
        }
    } else {
        OLogError(@"Failed to read strings from file.");
    }
    
    return string;
}


+ (NSString *)labelForKey:(NSString *)key
{
    return [self stringForKey:[self stringKeyWithPrefix:kKeyPrefixLabel forKey:key]];
}


+ (NSString *)placeholderForKey:(NSString *)key
{
    return [self stringForKey:[self stringKeyWithPrefix:kKeyPrefixPlaceholder forKey:key]];
}


#pragma mark - Title & text strings

+ (NSString *)titleForOrigoType:(NSString *)origoType
{
    NSString *stringKey = nil;
    BOOL is3rdParty = [[OState s] actionIs:kActionRegister] && [[OMeta m] userIsRegistered];
    
    if ([origoType isEqualToString:kOrigoTypeResidence]) {
        stringKey = is3rdParty ? strNewOrigoOfTypeResidence : strOrigoTypeResidence;
    } else if ([origoType isEqualToString:kOrigoTypeOrganisation]) {
        stringKey = is3rdParty ? strNewOrigoOfTypeOrganisation : strOrigoTypeOrganisation;
    } else if ([origoType isEqualToString:kOrigoTypeAssociation]) {
        stringKey = is3rdParty ? strNewOrigoOfTypeAssociation : strOrigoTypeAssociation;
    } else if ([origoType isEqualToString:kOrigoTypeSchoolClass]) {
        stringKey = is3rdParty ? strNewOrigoOfTypeSchoolClass : strOrigoTypeSchoolClass;
    } else if ([origoType isEqualToString:kOrigoTypePreschoolClass]) {
        stringKey = is3rdParty ? strNewOrigoOfTypePreschoolClass : strOrigoTypePreschoolClass;
    } else if ([origoType isEqualToString:kOrigoTypeSportsTeam]) {
        stringKey = is3rdParty ? strNewOrigoOfTypeSportsTeam : strOrigoTypeSportsTeam;
    } else {
        stringKey = is3rdParty ? strNewOrigoOfTypeOther : strOrigoTypeOther;
    }
    
    return [self stringForKey:stringKey];
}


+ (NSString *)titleForContactRole:(NSString *)contactRole
{
    return [self stringForKey:[self stringKeyWithPrefix:kKeyPrefixContactRole forKey:contactRole]];
}


+ (NSString *)titleForSettingKey:(NSString *)settingKey
{
    return [self stringForKey:[self stringKeyWithPrefix:kKeyPrefixSettingTitle forKey:settingKey]];
}


+ (NSString *)labelForSettingKey:(NSString *)settingKey
{
    return [self stringForKey:[self stringKeyWithPrefix:kKeyPrefixSettingText forKey:settingKey]];
}


#pragma mark - OConnectionDelegate conformance

+ (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    if (response.statusCode == kHTTPStatusOK) {
        strings = data;
        
        if ([strings writeToFile:[self pathToStringsFile] atomically:YES]) {
            [ODefaults setGlobalDefault:[NSDate date] forKey:kDefaultsKeyStringDate];
            OLogDebug(@"Wrote latest strings to file.");
        } else {
            OLogError(@"Error writing latest strings to file.");
        }
    } else {
        OLogError(@"Error retrieving latest strings from server.");
    }
}


+ (void)didFailWithError:(NSError *)error
{
    [[OState s].viewController didFailWithError:error];
}

@end
