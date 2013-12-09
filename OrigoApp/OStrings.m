//
//  OStrings.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OStrings.h"

// String key prefixes
NSString * const kKeyPrefixDefault                    = @"strDefault";
NSString * const kKeyPrefixLabel                      = @"strLabel";
NSString * const kKeyPrefixAlternateLabel             = @"strAlternateLabel";
NSString * const kKeyPrefixPlaceholder                = @"strPlaceholder";
NSString * const kKeyPrefixFooter                     = @"strFooter";
NSString * const kKeyPrefixAddMemberButton            = @"strButtonAddMember";
NSString * const kKeyPrefixAddContactButton           = @"strButtonAddContact";
NSString * const kKeyPrefixContactRole                = @"strContactRole";
NSString * const kKeyPrefixSettingTitle               = @"strSettingTitle";
NSString * const kKeyPrefixSettingLabel               = @"strSettingLabel";
NSString * const kKeyPrefixOrigoTitle                 = @"strOrigoTitle";
NSString * const kKeyPrefixNewOrigoTitle              = @"strNewOrigoTitle";
NSString * const kKeyPrefixMemberListTitle            = @"strMemberListTitle";
NSString * const kKeyPrefixNewMemberTitle             = @"strNewMemberTitle";
NSString * const kKeyPrefixAllMembersTitle            = @"strAllMembersTitle";

// Cross-view terms & strings
NSString * const strFooterTapToEdit                   = @"strFooterTapToEdit";
NSString * const strFooterOrigoSignature              = @"strFooterOrigoSignature";
NSString * const strButtonOK                          = @"strButtonOK";
NSString * const strButtonEdit                        = @"strButtonEdit";
NSString * const strButtonNext                        = @"strButtonNext";
NSString * const strButtonDone                        = @"strButtonDone";
NSString * const strButtonContinue                    = @"strButtonContinue";
NSString * const strButtonCancel                      = @"strButtonCancel";
NSString * const strButtonSignOut                     = @"strButtonSignOut";
NSString * const strAlertTextNoInternet               = @"strAlertTextNoInternet";
NSString * const strAlertTextServerError              = @"strAlertTextServerError";
NSString * const strAlertTextLocating                 = @"strAlertTextLocating";
NSString * const strTermYes                           = @"strTermYes";
NSString * const strTermNo                            = @"strTermNo";
NSString * const strTermMan                           = @"strTermMan";
NSString * const strTermBoy                           = @"strTermBoy";
NSString * const strTermWoman                         = @"strTermWoman";
NSString * const strTermGirl                          = @"strTermGirl";
NSString * const strFormatAge                         = @"strFormatAge";
NSString * const strSeparatorAnd                      = @"strSeparatorAnd";

// OAuthView strings
NSString * const strLabelSignIn                       = @"strLabelSignIn";
NSString * const strLabelActivate                     = @"strLabelActivate";
NSString * const strFooterSignInOrRegister            = @"strFooterSignInOrRegister";
NSString * const strFooterActivateUser                = @"strFooterActivateUser";
NSString * const strFooterActivateEmail               = @"strFooterActivateEmail";
NSString * const strPlaceholderAuthEmail              = @"strPlaceholderAuthEmail";
NSString * const strPlaceholderPassword               = @"strPlaceholderPassword";
NSString * const strPlaceholderActivationCode         = @"strPlaceholderActivationCode";
NSString * const strPlaceholderRepeatPassword         = @"strPlaceholderRepeatPassword";
NSString * const strButtonHaveCode                    = @"strButtonHaveCode";
NSString * const strButtonStartOver                   = @"strButtonStartOver";
NSString * const strAlertTitleActivationFailed        = @"strAlertTitleActivationFailed";
NSString * const strAlertTextActivationFailed         = @"strAlertTextActivationFailed";
NSString * const strAlertTitleWelcomeBack             = @"strAlertTitleWelcomeBack";
NSString * const strAlertTextWelcomeBack              = @"strAlertTextWelcomeBack";

// OOrigoListView strings
NSString * const strViewTitleOrigo                    = @"strViewTitleOrigo";
NSString * const strHeaderWardsOrigos                 = @"strHeaderWardsOrigos";
NSString * const strHeaderMyOrigos                    = @"strHeaderMyOrigos";
NSString * const strFooterOrigoCreationFirst          = @"strFooterOrigoCreationFirst";
NSString * const strFooterOrigoCreation               = @"strFooterOrigoCreation";
NSString * const strFooterOrigoCreationWards          = @"strFooterOrigoCreationWards";
NSString * const strAlertTitleListedUserRegistration  = @"strAlertTitleListedUserRegistration";
NSString * const strAlertTextListedUserRegistration   = @"strAlertTextListedUserRegistration";
NSString * const strAlertTitleIncompleteRegistration  = @"strAlertTitleIncompleteRegistration";
NSString * const strAlertTextIncompleteRegistration   = @"strAlertTextIncompleteRegistration";
NSString * const strSheetPromptOrigoType              = @"strSheetPromptOrigoType";
NSString * const strTextNoOrigos                      = @"strTextNoOrigos";
NSString * const strTermYourChild                     = @"strTermYourChild";
NSString * const strTermHimOrHer                      = @"strTermHimOrHer";
NSString * const strTermForName                       = @"strTermForName";

// OOrigoView strings
NSString * const strLabelAddress                      = @"strLabelAddress";
NSString * const strLabelPurpose                      = @"strLabelPurpose";
NSString * const strLabelDescriptionText              = @"strLabelDescriptionText";
NSString * const strLabelTelephone                    = @"strLabelTelephone";
NSString * const strPlaceholderAddress                = @"strPlaceholderAddress";
NSString * const strPlaceholderDescriptionText        = @"strPlaceholderDescriptionText";
NSString * const strPlaceholderTelephone              = @"strPlaceholderTelephone";
NSString * const strButtonAddParentContact            = @"strButtonAddParentContact";
NSString * const strButtonAbout                       = @"strButtonAbout";
NSString * const strButtonShowInMap                   = @"strButtonShowInMap";
NSString * const strButtonNewHousemate                = @"strButtonNewHousemate";
NSString * const strButtonOtherGuardian               = @"strButtonOtherGuardian";
NSString * const strButtonDeleteMember                = @"strButtonDeleteMember";

// OMemberView strings
NSString * const strViewTitleAboutMe                  = @"strViewTitleAboutMe";
NSString * const strLabelDateOfBirth                  = @"strLabelDateOfBirth";
NSString * const strLabelMobilePhone                  = @"strLabelMobilePhone";
NSString * const strLabelEmail                        = @"strLabelEmail";
NSString * const strPlaceholderPhoto                  = @"strPlaceholderPhoto";
NSString * const strPlaceholderName                   = @"strPlaceholderName";
NSString * const strPlaceholderDateOfBirth            = @"strPlaceholderDateOfBirth";
NSString * const strPlaceholderMobilePhone            = @"strPlaceholderMobilePhone";
NSString * const strPlaceholderEmail                  = @"strPlaceholderEmail";
NSString * const strFooterOrigoInviteAlert            = @"strFooterOrigoInviteAlert";
NSString * const strFooterJuvenileOrigoGuardian       = @"strFooterJuvenileOrigoGuardian";
NSString * const strButtonParentToSome                = @"strButtonParentToSome";
NSString * const strButtonAddAddress                  = @"strButtonAddAddress";
NSString * const strButtonChangePassword              = @"strButtonChangePassword";
NSString * const strButtonEditRelations               = @"strButtonEditRelations";
NSString * const strButtonCorrectGender               = @"strButtonCorrectGender";
NSString * const strButtonNewAddress                  = @"strButtonNewAddress";
NSString * const strButtonAllContacts                 = @"strButtonAllContacts";
NSString * const strButtonAllGuardians                = @"strButtonAllGuardians";
NSString * const strButtonLookUpInContacts            = @"strButtonLookUpInContacts";
NSString * const strButtonLookUpInOrigo               = @"strButtonLookUpInOrigo";
NSString * const strButtonDifferentNumber             = @"strButtonDifferentNumber";
NSString * const strButtonDifferentEmail              = @"strButtonDifferentEmail";
NSString * const strButtonInviteToHousehold           = @"strButtonInviteToHousehold";
NSString * const strButtonMergeHouseholds             = @"strButtonMergeHouseholds";
NSString * const strAlertTitleMemberExists            = @"strAlertTitleMemberExists";
NSString * const strAlertTextMemberExists             = @"strAlertTextMemberExists";
NSString * const strAlertTitleUserEmailChange         = @"strAlertTitleUserEmailChange";
NSString * const strAlertTextUserEmailChange          = @"strAlertTextUserEmailChange";
NSString * const strAlertTitleEmailChangeFailed       = @"strAlertTitleFailedEmailChange";
NSString * const strAlertTextEmailChangeFailed        = @"strAlertTextFailedEmailChange";
NSString * const strSheetPromptEmailRecipient         = @"strSheetPromptEmailRecipient";
NSString * const strSheetPromptTextRecipient          = @"strSheetPromptTextRecipient";
NSString * const strSheetPromptCallRecipient          = @"strSheetPromptCallRecipient";
NSString * const strSheetPromptMultiValuePhone        = @"strSheetPromptMultiValuePhone";
NSString * const strSheetPromptMultiValueEmail        = @"strSheetPromptMultiValueEmail";
NSString * const strSheetPromptExistingResidence      = @"strSheetPromptExistingResidence";
NSString * const strQuestionArgumentGender            = @"strQuestionArgumentGender";
NSString * const strQuestionArgumentGenderMinor       = @"strQuestionArgumentGenderMinor";
NSString * const strTermHisFather                     = @"strTermHisFather";
NSString * const strTermHerFather                     = @"strTermHerFather";
NSString * const strTermHisMother                     = @"strTermHisMother";
NSString * const strTermHerMother                     = @"strTermHerMother";

// OCalendarView strings
NSString * const strViewTitleCalendar                 = @"strViewTitleCalendar";

// OTaskListView strings
NSString * const strViewTitleTasks                    = @"strViewTitleTasks";

// OMessageListView strings
NSString * const strViewTitleMessages                 = @"strViewTitleMessages";
NSString * const strDefaultMessageBoardName           = @"strDefaultMessageBoardName";

// OSettingListView strings
NSString * const strViewTitleSettings                 = @"strViewTitleSettings";

// OSettingView strings
// ...

// Meta strings
NSString * const metaSupportedLanguages               = @"metaSupportedLanguages";
NSString * const metaMultiLingualCountryCodes         = @"metaMultiLingualCountryCodes";
NSString * const metaCountryCodesByCountryCallingCode = @"metaCountryCodesByCountryCallingCode";
NSString * const metaInternationalTemplate            = @"metaInternationalTemplate";
NSString * const metaPhoneNumberTemplatesByRegion     = @"metaPhoneNumberTemplatesByRegion";
NSString * const metaContactRolesSchoolClass          = @"metaContactRolesSchoolClass";
NSString * const metaContactRolesPreschoolClass       = @"metaContactRolesPreschoolClass";
NSString * const metaContactRolesOrganisation         = @"metaContactRolesAssociation";
NSString * const metaContactRolesSportsTeam           = @"metaContactRolesSportsTeam";

static NSString * const kStringsPlist = @"strings.plist";
static NSInteger const kDaysBetweenStringFetches = 0; // TODO: Set to 14

static NSDictionary const *_strings = nil;


@implementation OStrings

#pragma mark - Auxiliary methods

+ (NSString *)pathToStringsFile
{
    NSString *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString *relativePath = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingPathComponent:kStringsPlist];
    
    return [cachesDirectory stringByAppendingPathComponent:relativePath];
}


#pragma mark - String fetching & refresh

+ (BOOL)hasStrings
{
    if (!_strings) {
        NSString *persistedLanguage = [ODefaults globalDefaultForKey:kDefaultsKeyStringLanguage];
        
        if (persistedLanguage) {
            BOOL canLoadStrings = [persistedLanguage isEqualToString:[OMeta m].language];
            
            if (!canLoadStrings) {
                NSArray *supportedLanguages = [OMeta supportedLanguages];
                
                BOOL persistedIsSupported = [supportedLanguages containsObject:persistedLanguage];
                BOOL currentIsSupported = [supportedLanguages containsObject:[OMeta m].language];
                
                canLoadStrings = !persistedIsSupported && !currentIsSupported;
            }
            
            if (canLoadStrings) {
                _strings = [NSDictionary dictionaryWithContentsOfFile:[self pathToStringsFile]];
            }
        }
    }
    
    return (_strings != nil);
}


+ (void)refreshIfNeeded
{
    if ([[OMeta m] userIsSignedIn] && [[OMeta m] internetConnectionIsAvailable]) {
        NSDate *stringDate = [ODefaults globalDefaultForKey:kDefaultsKeyStringDate];
        
        if (!stringDate || ([stringDate daysBeforeNow] >= kDaysBetweenStringFetches)) {
            [OConnection fetchStrings];
        }
    }
}


#pragma mark - Display strings

+ (NSString *)stringForKey:(NSString *)key
{
    NSString *string = [NSString string];
    
    if ([self hasStrings]) {
        string = _strings[key];
        
        if (!string) {
            OLogBreakage(@"No string with key '%@'.", key);
        }
    } else {
        OLogError(@"Failed to read strings from file.");
    }
    
    return string;
}


+ (NSString *)stringForKey:(NSString *)key withKeyPrefix:(NSString *)prefix
{
    return [OStrings stringForKey:[prefix stringByAppendingCapitalisedString:key]];
}


#pragma mark - OConnectionDelegate conformance

+ (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    if (response.statusCode == kHTTPStatusOK) {
        _strings = data;
        
        if ([_strings writeToFile:[self pathToStringsFile] atomically:YES]) {
            [ODefaults setGlobalDefault:[NSDate date] forKey:kDefaultsKeyStringDate];
            [ODefaults setGlobalDefault:[OMeta m].language forKey:kDefaultsKeyStringLanguage];
            
            OLogDebug(@"Wrote latest strings to file (language: %@).", [OMeta m].language);
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
