//
//  OOrigoListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OOrigoListViewController.h"

static NSString * const kSegueToOrigoView = @"segueFromOrigoListToOrigoView";
static NSString * const kSegueToMemberView = @"segueFromOrigoListToMemberView";

static NSInteger const kActionSheetTagCountry = 0;
static NSInteger const kButtonTagLocated = 0;
static NSInteger const kButtonTagInferred = 1;
static NSInteger const kButtonTagLocate = 2;
static NSInteger const kButtonTagOther = 3;

static NSInteger const kActionSheetTagOrigoType = 1;

static NSInteger const kAlertTagCountry = 0;

static NSInteger const kSectionKeyMember = 0;
static NSInteger const kSectionKeyOrigos = 1;
static NSInteger const kSectionKeyWards = 2;


@implementation OOrigoListViewController

#pragma mark - Auxiliary methods

- (NSString *)footerText
{
    NSString *footerText = nil;
    
    if ([self hasSectionWithKey:kSectionKeyOrigos]) {
        footerText = [OStrings stringForKey:strFooterOrigoCreation];
    } else {
        footerText = [OStrings stringForKey:strFooterOrigoCreationFirst];
    }
    
    if ([self targetIs:kTargetUser] && [self hasSectionWithKey:kSectionKeyWards]) {
        NSString *yourChild = nil;
        NSString *himOrHer = nil;
        
        BOOL allMale = YES;
        BOOL allFemale = YES;
        
        if ([[_member wards] count] == 1) {
            yourChild = [[self dataInSectionWithKey:kSectionKeyWards][0] givenName];
        } else {
            yourChild = [OStrings stringForKey:strTermYourChild];
        }
        
        for (OMember *ward in [_member wards]) {
            allMale = allMale && [ward isMale];
            allFemale = allFemale && ![ward isMale];
        }
        
        if (allMale) {
            himOrHer = [OLanguage pronouns][_he_][accusative];
        } else if (allFemale) {
            himOrHer = [OLanguage pronouns][_she_][accusative];
        } else {
            himOrHer = [OStrings stringForKey:strTermHimOrHer];
        }
        
        NSString *wardsAddendum = [NSString stringWithFormat:[OStrings stringForKey:strFooterOrigoCreationWards], yourChild, himOrHer];
        footerText = [NSString stringWithFormat:@"%@ %@.", footerText, wardsAddendum];
    } else if ([self targetIs:kTargetUser]) {
        footerText = [footerText stringByAppendingString:@"."];
    } else if ([self targetIs:kTargetWard]) {
        NSString *forWardName = [NSString stringWithFormat:[OStrings stringForKey:strTermForName], [_member givenName]];
        footerText = [NSString stringWithFormat:@"%@ %@.", footerText, forWardName];
    }
    
    return footerText;
}


#pragma mark - Action sheets & alerts

- (void)presentCountrySheet
{
    NSString *inferredCountry = [OUtil localisedCountryNameFromCountryCode:[[OMeta m] inferredCountryCode]];
    NSString *locatedCountry = nil;
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:[OStrings stringForKey:strSheetTitleCountry] delegate:self tag:kActionSheetTagCountry];

    if ([[OMeta m].locator didLocate]) {
        locatedCountry = [OUtil localisedCountryNameFromCountryCode:[OMeta m].locator.countryCode];
        [actionSheet addButtonWithTitle:locatedCountry tag:kButtonTagLocated];
    }
    
    if (!locatedCountry || ![locatedCountry isEqualToString:inferredCountry]) {
        [actionSheet addButtonWithTitle:inferredCountry tag:kButtonTagInferred];
    }
    
    if (!locatedCountry && [[OMeta m].locator canLocate]) {
        [actionSheet addButtonWithTitle:[OStrings stringForKey:strButtonCountryLocate] tag:kButtonTagLocate];
    }
    
    [actionSheet addButtonWithTitle:[OStrings stringForKey:strButtonCountryOther] tag:kButtonTagOther];
    
    [actionSheet show];
}


- (void)presentCountryAlert
{
    NSString *country = [OUtil localisedCountryNameFromCountryCode:[OMeta m].settings.countryCode];
    NSString *alertFormat = nil;
    
    if ([OUtil isSupportedCountryCode:[OMeta m].settings.countryCode]) {
        alertFormat = [OStrings stringForKey:strAlertTextCountrySupported];
    } else {
        alertFormat = [OStrings stringForKey:strAlertTextCountryUnsupported];
    }
    
    [OAlert showAlertWithTitle:country text:[NSString stringWithFormat:alertFormat, country] tag:kAlertTagCountry];
}


- (void)presentListedUserAlert
{
    OMember *creator = [[OMeta m].context entityWithId:[OMeta m].user.createdBy];
    
    NSString *alertText = [NSString stringWithFormat:[OStrings stringForKey:strAlertTextListedUserRegistration], [creator givenName], [creator pronoun][nominative]];
    
    [OAlert showAlertWithTitle:[OStrings stringForKey:strAlertTitleListedUserRegistration] text:alertText];
}


#pragma mark - Selector implementations

- (void)openSettings
{
    [self presentModalViewControllerWithIdentifier:kIdentifierSettingList data:nil];
}


- (void)addItem
{
    NSString *prompt = [OStrings stringForKey:strSheetTitleOrigoType];
    
    if ([self targetIs:kTargetUser]) {
        prompt = [prompt stringByAppendingString:@"?"];
    } else if ([self targetIs:kTargetWard]) {
        NSString *forWardName = [NSString stringWithFormat:[OStrings stringForKey:strTermForName], [_member givenName]];
        prompt = [NSString stringWithFormat:@"%@ %@?", prompt, forWardName];
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagOrigoType];
    
    for (NSString *origoType in _origoTypes) {
        [actionSheet addButtonWithTitle:[OStrings labelForOrigoType:origoType labelType:kOrigoLabelTypeOrigo]];
    }
    
    [actionSheet show];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = [_member isWardOfUser] ? _member.givenName : @"Origo";
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([[OMeta m] userIsSignedIn] && ![[OMeta m] userIsRegistered]) {
        if (![[OMeta m].user.createdBy isEqualToString:[OMeta m].user.entityId]) {
            [self presentListedUserAlert];
        } else if (![OMeta m].userDidJustSignUp) {
            [OAlert showAlertWithTitle:[OStrings stringForKey:strAlertTitleIncompleteRegistration] text:[OStrings stringForKey:strAlertTextIncompleteRegistration]];
        }
        
        [self presentModalViewControllerWithIdentifier:kIdentifierMember data:[[OMeta m].user initialResidency]];
    }
}


#pragma mark - UIViewController overrides

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self prepareForPushSegue:segue];
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialiseState
{
    _member = self.data ? self.data : [OMeta m].user;
    _origoTypes = [[NSMutableArray alloc] init];
    
    self.state.target = _member;
    
    if ([_member isUser]) {
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem settingsButtonWithTarget:self];
    }
    
    if ([[OMeta m].user isTeenOrOlder]) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
        
        if ([self targetIs:kTargetUser]) {
            [_origoTypes addObject:kOrigoTypeFriends];
            [_origoTypes addObject:kOrigoTypeOrganisation];
            [_origoTypes addObject:kOrigoTypeTeam];
            [_origoTypes addObject:kOrigoTypeOther];
            [_origoTypes addObject:kOrigoTypeContactList];
        } else {
            if (![_member isOlderThan:kAgeThresholdInSchool]) {
                [_origoTypes addObject:kOrigoTypePreschoolClass];
            }
            
            [_origoTypes addObject:kOrigoTypeSchoolClass];
            [_origoTypes addObject:kOrigoTypePlaymates];
            [_origoTypes addObject:kOrigoTypeMinorTeam];
        }
    }
}


- (void)initialiseData
{
    if (_member) {
        [self setData:[_member participancies] forSectionWithKey:kSectionKeyOrigos];
        
        if ([_member isUser]) {
            [self setData:[_member residencies] forSectionWithKey:kSectionKeyMember];
            [self setData:[_member wards] forSectionWithKey:kSectionKeyWards];
        } else {
            [self setData:@[_member] forSectionWithKey:kSectionKeyMember];
        }
    }
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return ([self isLastSectionKey:sectionKey] && [[OMeta m].user isTeenOrOlder]);
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kSectionKeyWards) {
        text = [OStrings stringForKey:strHeaderWardsOrigos];
    } else if (sectionKey == kSectionKeyOrigos) {
        text = [[OLanguage possessiveClauseWithPossessor:_member noun:_origo_] stringByCapitalisingFirstLetter];
    }
    
    return text;
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    return [self footerText];
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if ((sectionKey == kSectionKeyMember) && ![_member isUser]) {
        [self performSegueWithIdentifier:kSegueToMemberView sender:self];
    } else if (sectionKey == kSectionKeyWards) {
        OOrigoListViewController *origoListViewController = [self.storyboard instantiateViewControllerWithIdentifier:kIdentifierOrigoList];
        origoListViewController.data = [self dataAtIndexPath:indexPath];
        
        [self.navigationController pushViewController:origoListViewController animated:YES];
    } else {
        [self performSegueWithIdentifier:kSegueToOrigoView sender:self];
    }
}


#pragma mark - OTableViewListDelegate conformance

- (NSString *)sortKeyForSectionWithKey:(NSInteger)sectionKey
{
    NSString *relationshipKey = (sectionKey == kSectionKeyWards) ? nil : kRelationshipKeyOrigo;
    
    return [OUtil sortKeyWithPropertyKey:kPropertyKeyName relationshipKey:relationshipKey];
}


- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    OReplicatedEntity *entity = [self dataAtIndexPath:indexPath];
    
    if ((sectionKey == kSectionKeyMember) && ![_member isUser]) {
        OMember *member = [entity asMember];

        cell.textLabel.text = member.name;
        cell.detailTextLabel.text = [member shortDetails];
        cell.imageView.image = [member smallImage];
    } else if (sectionKey == kSectionKeyWards) {
        OMember *ward = [entity asMember];
        
        cell.textLabel.text = [ward givenName];
        cell.imageView.image = [ward smallImage];
    } else {
        OMembership *membership = [entity asMembership];
        
        cell.textLabel.text = membership.origo.name;
        cell.imageView.image = [membership.origo smallImage];
        
        if (sectionKey == kSectionKeyMember) {
            cell.detailTextLabel.text = [membership.origo singleLineAddress];
        }
    }
}


#pragma mark - OModalViewControllerDismisser conformance

- (void)didDismissModalViewController:(OTableViewController *)viewController
{
    if ([[OMeta m] userIsSignedIn]) {
        [self.tableView reloadData];
    }
}


#pragma mark - OLocatorDelegate conformance

- (void)locatorDidLocate
{
    if ([OMeta m].locator.blocking) {
        [self presentCountrySheet];
    } else {
        [OMeta m].settings.countryCode = [OMeta m].locator.countryCode;
        
        [self presentCountryAlert];
    }
}


- (void)locatorCannotLocate
{
    [self presentCountrySheet];
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
    
    switch (actionSheet.tag) {
        case kActionSheetTagCountry:
            if (buttonTag == kButtonTagLocated) {
                [OMeta m].settings.countryCode = [OMeta m].locator.countryCode;
            } else if (buttonTag == kButtonTagInferred) {
                [OMeta m].settings.countryCode = [[OMeta m] inferredCountryCode];
            } else if (buttonTag == kButtonTagLocate) {
                [[OMeta m].locator locateBlocking:YES];
            } else if (buttonTag == kButtonTagOther) {
                [OAlert showAlertWithTitle:[OStrings stringForKey:strAlertTitleCountryOther] text:[OStrings stringForKey:strAlertTextCountryOther]];
            }
            
            if ([OMeta m].settings.countryCode) {
                if ([OUtil isSupportedCountryCode:[OMeta m].settings.countryCode]) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierOrigo data:_member meta:_selectedOrigoType];
                } else {
                    [self presentCountryAlert];
                }
            }
            
            break;
            
        case kActionSheetTagOrigoType:
            if (buttonIndex < actionSheet.cancelButtonIndex) {
                _selectedOrigoType = _origoTypes[buttonIndex];
                
                if (![OMeta m].settings.countryCode) {
                    if ([[OMeta m].locator isAuthorised] && ![[OMeta m].locator didLocate]) {
                        [[OMeta m].locator locateBlocking:YES];
                    } else {
                        [self presentCountrySheet];
                    }
                } else {
                    [self presentModalViewControllerWithIdentifier:kIdentifierOrigo data:_member meta:_selectedOrigoType];
                }
            }
            
            break;
            
        default:
            break;
    }
}


#pragma mark - UIAlertViewDelegate conformance

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertTagCountry:
            [self presentModalViewControllerWithIdentifier:kIdentifierOrigo data:_member meta:_selectedOrigoType];

            break;
            
        default:
            break;
    }
}

@end
