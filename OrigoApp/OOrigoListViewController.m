//
//  OOrigoListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OOrigoListViewController.h"

static NSString * const kSegueToMemberView = @"segueFromOrigoListToMemberView";
static NSString * const kSegueToMemberListView = @"segueFromOrigoListToMemberListView";

static NSInteger const kCountrySheetTag = 0;
static NSInteger const kCountrySheetButtonCountryLocatedOrInferred = 0;

static NSInteger const kOrigoTypeSheetTag = 1;

static NSInteger const kCountryAlertTag = 0;
static NSInteger const kCountryAlertButtonCancel = 0;

static NSInteger const kSectionKeyUser = 0;
static NSInteger const kSectionKeyOrigos = 1;
static NSInteger const kSectionKeyWards = 2;

static NSInteger const kUserRow = 0;


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
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[OStrings stringForKey:strSheetTitleCountry] delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

    NSString *inferredCountry = [OUtil localisedCountryNameFromCountryCode:[[OMeta m] inferredCountryCode]];
    NSString *locatedCountry = nil;
    
    if ([[OMeta m].locator didLocate]) {
        locatedCountry = [OUtil localisedCountryNameFromCountryCode:[OMeta m].locator.countryCode];
        [sheet addButtonWithTitle:locatedCountry];
    }
    
    if (!locatedCountry || ![locatedCountry isEqualToString:inferredCountry]) {
        [sheet addButtonWithTitle:inferredCountry];
    }
    
    if (!locatedCountry && [[OMeta m].locator canLocate]) {
        [sheet addButtonWithTitle:[OStrings stringForKey:strButtonCountryLocate]];
    }
    
    [sheet addButtonWithTitle:[OStrings stringForKey:strButtonCountryOther]];
    [sheet addButtonWithTitle:[OStrings stringForKey:strButtonCancel]];
    sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
    sheet.tag = kCountrySheetTag;
    
    [sheet showInView:self.actionSheetView];
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
    
    [OAlert showAlertWithTitle:country text:[NSString stringWithFormat:alertFormat, country] tag:kCountryAlertTag];
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
    [self presentModalViewControllerWithIdentifier:kVCIdentifierSettingList data:nil];
}


- (void)performAddAction
{
    NSString *question = [OStrings stringForKey:strSheetTitleOrigoType];
    
    if ([self targetIs:kTargetUser]) {
        question = [question stringByAppendingString:@"?"];
    } else if ([self targetIs:kTargetWard]) {
        NSString *forWardName = [NSString stringWithFormat:[OStrings stringForKey:strTermForName], [_member givenName]];
        question = [NSString stringWithFormat:@"%@ %@?", question, forWardName];
    }
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:question delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    for (NSString *origoType in _origoTypes) {
        [sheet addButtonWithTitle:[OStrings titleForOrigoType:origoType]];
    }
    
    [sheet addButtonWithTitle:[OStrings stringForKey:strButtonCancel]];
    sheet.cancelButtonIndex = [_origoTypes count];
    sheet.tag = kOrigoTypeSheetTag;
    
    [sheet showInView:self.actionSheetView];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Origo";
    
    if ([[OMeta m] userIsAllSet] && ![_member isUser]) {
        self.navigationItem.title = [self.title stringByAppendingString:[_member givenName] separator:kSeparatorInterpunct];
        self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:[_member givenName]];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([[OMeta m] userIsAllSet]) {
        if ([_member isUser]) {
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem settingsButtonWithTarget:self];
        }
        
        if ([[OMeta m].user isTeenOrOlder]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem addButtonWithTarget:self];
        }
        
        if (![self numberOfSectionsInTableView:self.tableView]) {
            [self.tableView addEmptyTableFooterViewWithText:[self footerText]];
        }
    }
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
        
        [self presentModalViewControllerWithIdentifier:kVCIdentifierMember data:[[OMeta m].user initialResidency]];
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
    
    if ([self targetIs:kTargetWard]) {
        if (![_member isOlderThan:kAgeThresholdInSchool]) {
            [_origoTypes addObject:kOrigoTypePreschoolClass];
        }
        
        [_origoTypes addObject:kOrigoTypeSchoolClass];
    } else {
        [_origoTypes addObject:kOrigoTypeOrganisation];
        [_origoTypes addObject:kOrigoTypeAssociation];
    }
    
    [_origoTypes addObject:kOrigoTypeSportsTeam];
    [_origoTypes addObject:kOrigoTypeOther];
}


- (void)initialiseDataSource
{
    [self setData:[_member participancies] forSectionWithKey:kSectionKeyOrigos];
    
    if ([_member isUser]) {
        [self setData:[_member rootMembership] forSectionWithKey:kSectionKeyUser];
        [self appendData:[_member residencies] toSectionWithKey:kSectionKeyUser];
        [self setData:[_member wards] forSectionWithKey:kSectionKeyWards];
    }
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return ([super hasFooterForSectionWithKey:sectionKey] && [[OMeta m].user isTeenOrOlder]);
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kSectionKeyWards) {
        text = [OStrings stringForKey:strHeaderWardsOrigos];
    } else if (sectionKey == kSectionKeyOrigos) {
        text = [OStrings stringForKey:strHeaderMyOrigos];
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
    
    if (sectionKey == kSectionKeyUser) {
        if (indexPath.row == kUserRow) {
            [self performSegueWithIdentifier:kSegueToMemberView sender:self];
        } else {
            [self performSegueWithIdentifier:kSegueToMemberListView sender:self];
        }
    } else if (sectionKey == kSectionKeyOrigos) {
        [self performSegueWithIdentifier:kSegueToMemberListView sender:self];
    } else if (sectionKey == kSectionKeyWards) {
        OOrigoListViewController *origoListViewController = [self.storyboard instantiateViewControllerWithIdentifier:kVCIdentifierOrigoList];
        origoListViewController.data = [self dataAtIndexPath:indexPath];
        
        [self.navigationController pushViewController:origoListViewController animated:YES];
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
    
    if ((sectionKey == kSectionKeyUser) || (sectionKey == kSectionKeyOrigos)) {
        OMembership *membership = [entity asMembership];
        
        if (sectionKey == kSectionKeyUser) {
            if (indexPath.row == kUserRow) {
                cell.textLabel.text = [[OLanguage pronouns][_I_][disjunctive] capitalizedString];
                cell.detailTextLabel.text = membership.member.name;
                cell.imageView.image = [membership.member smallImage];
            } else {
                cell.textLabel.text = membership.origo.name;
                cell.detailTextLabel.text = [membership.origo singleLineAddress];
                cell.imageView.image = [membership.origo listCellImage];
            }
        } else if (sectionKey == kSectionKeyOrigos) {
            cell.textLabel.text = membership.origo.name;
            cell.imageView.image = [membership.origo listCellImage];
        }
    } else if (sectionKey == kSectionKeyWards) {
        OMember *ward = [entity asMember];
        
        cell.textLabel.text = [ward givenName];
        cell.imageView.image = [ward smallImage];
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

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case kCountrySheetTag:
            if (buttonIndex < actionSheet.cancelButtonIndex - 1) {
                if (buttonIndex == kCountrySheetButtonCountryLocatedOrInferred) {
                    if ([[OMeta m].locator didLocate]) {
                        [OMeta m].settings.countryCode = [OMeta m].locator.countryCode;
                    } else {
                        [OMeta m].settings.countryCode = [[OMeta m] inferredCountryCode];
                    }
                } else {
                    if ([[OMeta m].locator didLocate]) {
                        [OMeta m].settings.countryCode = [[OMeta m] inferredCountryCode];
                    } else {
                        [[OMeta m].locator locateBlocking:YES];
                    }
                }
                
                if ([OMeta m].settings.countryCode) {
                    if ([OUtil isSupportedCountryCode:[OMeta m].settings.countryCode]) {
                        [self presentModalViewControllerWithIdentifier:kVCIdentifierOrigo data:_member meta:_selectedOrigoType];
                    } else {
                        [self presentCountryAlert];
                    }
                }
            } else if (buttonIndex == actionSheet.cancelButtonIndex - 1) {
                [OAlert showAlertWithTitle:[OStrings stringForKey:strAlertTitleCountryOther] text:[OStrings stringForKey:strAlertTextCountryOther]];
            }
            
            break;
            
        case kOrigoTypeSheetTag:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                _selectedOrigoType = _origoTypes[buttonIndex];
                
                if (![OMeta m].settings.countryCode) {
                    if ([[OMeta m].locator isAuthorised] && ![[OMeta m].locator didLocate]) {
                        [[OMeta m].locator locateBlocking:YES];
                    } else {
                        [self presentCountrySheet];
                    }
                } else {
                    [self presentModalViewControllerWithIdentifier:kVCIdentifierOrigo data:_member meta:_selectedOrigoType];
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
        case kCountryAlertTag:
            [self presentModalViewControllerWithIdentifier:kVCIdentifierOrigo data:_member meta:_selectedOrigoType];

            break;
            
        default:
            break;
    }
}

@end
