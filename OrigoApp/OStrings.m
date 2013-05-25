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
#import "OMeta.h"
#import "OLogging.h"
#import "OServerConnection.h"
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
NSString * const strTermAddress                      = @"strTermAddress";
NSString * const strTermCountry                      = @"strTermCountry";

// OAuthView strings
NSString * const strLabelSignIn                      = @"strLabelSignIn";
NSString * const strLabelActivate                    = @"strLabelActivate";
NSString * const strFooterSignInOrRegister           = @"strFooterSignInOrRegister";
NSString * const strFooterActivate                   = @"strFooterActivate";
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
NSString * const strButtonCountryOfLocation          = @"strButtonCountryOfLocation";
NSString * const strButtonCountryOther               = @"strButtonCountryOther";
NSString * const strAlertTitleCountry                = @"strAlertTitleCountry";
NSString * const strAlertTextCountry                 = @"strAlertTextCountry";
NSString * const strSheetTitleCountryLocate          = @"strSheetTitleCountryLocate";
NSString * const strSheetTitleCountryNoLocate        = @"strSheetTitleCountryNoLocate";
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
NSString * const strLabelTelephone                   = @"strLabelTelephone";
NSString * const strHeaderAddresses                  = @"strHeaderAddresses";
NSString * const strPlaceholderAddress               = @"strPlaceholderAddress";
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
NSString * const xstrContactRolesSchoolClass         = @"xstrContactRolesSchoolClass";
NSString * const xstrContactRolesPreschoolClass      = @"xstrContactRolesPreschoolClass";
NSString * const xstrContactRolesAssociation         = @"xstrContactRolesAssociation";
NSString * const xstrContactRolesSportsTeam          = @"xstrContactRolesSportsTeam";

static NSInteger const kDaysBetweenStringFetches = 0; // TODO: Set to 14
static NSString * const kStringsPlist = @"strings.plist";
static NSDictionary const *strings = nil;

static NSString * const kLabelKeyPrefix = @"strLabel";
static NSString * const kPlaceholderKeyPrefix = @"strPlaceholder";
static NSString * const kSettingTitleKeyPrefix = @"strSettingTitle";
static NSString * const kSettingTextKeyPrefix = @"strSettingText";


@implementation OStrings

#pragma mark - Auxiliary methods

+ (NSString *)fullPathToStringsPlist
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
        strings = [NSDictionary dictionaryWithContentsOfFile:[self fullPathToStringsPlist]];
    }
    
    return (strings != nil);
}


+ (void)refreshIfNeeded
{
    NSDate *stringDate = [[OMeta m] globalDefaultForKey:kDefaultsKeyStringDate];
    
    if (!stringDate || ([stringDate daysBeforeNow] >= kDaysBetweenStringFetches)) {
        if ([self hasStrings] && [[OMeta m] internetConnectionIsAvailable]) {
            [[[OServerConnection alloc] init] fetchStrings:self];
        }
    }
}


#pragma mark - String lookup

+ (NSString *)stringForKey:(NSString *)key
{
    NSString *string = @"";
    
    if ([self hasStrings]) {
        string = [strings objectForKey:key];
        
        if (!string) {
            OLogBreakage(@"No string with key '%@'.", key);
        }
    } else {
        OLogBreakage(@"Failed to instantiate strings from plist.");
    }
    
    return string;
}


+ (NSString *)stringForOrigoType:(NSString *)origoType
{
    NSString *key = nil;
    BOOL is3rdParty = ([[OState s] actionIs:kActionRegister] && [OMeta m].userIsRegistered);
    
    if ([origoType isEqualToString:kOrigoTypeResidence]) {
        key = is3rdParty ? strNewOrigoOfTypeResidence : strOrigoTypeResidence;
    } else if ([origoType isEqualToString:kOrigoTypeOrganisation]) {
        key = is3rdParty ? strNewOrigoOfTypeOrganisation : strOrigoTypeOrganisation;
    } else if ([origoType isEqualToString:kOrigoTypeAssociation]) {
        key = is3rdParty ? strNewOrigoOfTypeAssociation : strOrigoTypeAssociation;
    } else if ([origoType isEqualToString:kOrigoTypeSchoolClass]) {
        key = is3rdParty ? strNewOrigoOfTypeSchoolClass : strOrigoTypeSchoolClass;
    } else if ([origoType isEqualToString:kOrigoTypePreschoolClass]) {
        key = is3rdParty ? strNewOrigoOfTypePreschoolClass : strOrigoTypePreschoolClass;
    } else if ([origoType isEqualToString:kOrigoTypeSportsTeam]) {
        key = is3rdParty ? strNewOrigoOfTypeSportsTeam : strOrigoTypeSportsTeam;
    } else {
        key = is3rdParty ? strNewOrigoOfTypeOther : strOrigoTypeOther;
    }
    
    return [self stringForKey:key];
}


+ (NSString *)labelForKey:(NSString *)key
{
    return [self stringForKey:[self stringKeyWithPrefix:kLabelKeyPrefix forKey:key]];
}


+ (NSString *)placeholderForKey:(NSString *)key
{
    return [self stringForKey:[self stringKeyWithPrefix:kPlaceholderKeyPrefix forKey:key]];
}


+ (NSString *)settingTitleForKey:(NSString *)key
{
    return [self stringForKey:[self stringKeyWithPrefix:kSettingTitleKeyPrefix forKey:key]];
}


+ (NSString *)settingTextForKey:(NSString *)key
{
    return [self stringForKey:[self stringKeyWithPrefix:kSettingTextKeyPrefix forKey:key]];
}


#pragma mark - OServerConnectionDelegate conformance

+ (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    if (response.statusCode == kHTTPStatusOK) {
        strings = data;
        
        if (![strings writeToFile:[self fullPathToStringsPlist] atomically:YES]) {
            OLogError(@"Error writing strings from server to plist '%@'.", [self fullPathToStringsPlist]);
        }
    }
}


+ (void)didFailWithError:(NSError *)error
{
    [[OState s].viewController didFailWithError:error];
}

@end
