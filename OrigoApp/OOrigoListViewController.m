//
//  OOrigoListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OOrigoListViewController.h"

#import "UIBarButtonItem+OrigoExtensions.h"
#import "UITableView+OrigoExtensions.h"

#import "OAlert.h"
#import "OEntityReplicator.h"
#import "OLocator.h"
#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OUtil.h"

#import "OMember+OrigoExtensions.h"
#import "OMembership.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"
#import "OSettings.h"

static NSString * const kSegueToMemberView = @"segueFromOrigoListToMemberView";
static NSString * const kSegueToMemberListView = @"segueFromOrigoListToMemberListView";

static NSInteger const kCountrySheetTag = 0;
static NSInteger const kCountrySheetButtonCountryLocatedOrInferred = 0;

static NSInteger const kOrigoTypeSheetTag = 1;

static NSInteger const kCountryAlertTag = 0;
static NSInteger const kCountryAlertButtonCancel = 0;

static NSInteger const kUserSectionKey = 0;
static NSInteger const kWardSectionKey = 1;
static NSInteger const kOrigoSectionKey = 2;

static NSInteger const kUserRow = 0;


@implementation OOrigoListViewController

#pragma mark - Auxiliary methods

- (NSString *)footerText
{
    NSString *footerText = nil;
    
    if ([self hasSectionWithKey:kOrigoSectionKey]) {
        footerText = [OStrings stringForKey:strFooterOrigoCreation];
    } else {
        footerText = [OStrings stringForKey:strFooterOrigoCreationFirst];
    }
    
    if ([self targetIs:kTargetUser] && [self hasSectionWithKey:kWardSectionKey]) {
        NSString *yourChild = nil;
        NSString *himOrHer = nil;
        
        BOOL allFemale = YES;
        BOOL allMale = YES;
        
        if ([self numberOfRowsInSectionWithKey:kWardSectionKey] == 1) {
            yourChild = ((OMember *)[self dataInSectionWithKey:kWardSectionKey][0]).givenName;
        } else {
            yourChild = [OStrings stringForKey:strTermYourChild];
        }
        
        for (OMember *ward in [self dataInSectionWithKey:kWardSectionKey]) {
            allFemale = allFemale && [ward isFemale];
            allMale = allMale && [ward isMale];
        }
        
        if (allFemale) {
            himOrHer = [OStrings stringForKey:strTermHer];
        } else if (allMale) {
            himOrHer = [OStrings stringForKey:strTermHim];
        } else {
            himOrHer = [OStrings stringForKey:strTermHimOrHer];
        }
        
        NSString *wardsAddendum = [NSString stringWithFormat:[OStrings stringForKey:strFooterOrigoCreationWards], yourChild, himOrHer];
        footerText = [NSString stringWithFormat:@"%@ %@", footerText, wardsAddendum];
    } else if ([self targetIs:kTargetUser]) {
        footerText = [footerText stringByAppendingString:@"."];
    } else if ([self targetIs:kTargetWard]) {
        NSString *forWardName = [NSString stringWithFormat:[OStrings stringForKey:strTermForName], _member.givenName];
        footerText = [NSString stringWithFormat:@"%@ %@.", footerText, forWardName];
    }
    
    return footerText;
}


- (void)presentCountrySheet
{
    UIActionSheet *countrySheet = [[UIActionSheet alloc] initWithTitle:[OStrings stringForKey:strSheetTitleCountry] delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];

    NSString *inferredCountry = [OUtil countryFromCountryCode:[OMeta m].inferredCountryCode];
    NSString *locatedCountry = nil;
    
    if ([[OMeta m].locator didLocate]) {
        locatedCountry = [OUtil countryFromCountryCode:[OMeta m].locator.countryCode];
        [countrySheet addButtonWithTitle:locatedCountry];
    }
    
    if (!locatedCountry || ![locatedCountry isEqualToString:inferredCountry]) {
        [countrySheet addButtonWithTitle:inferredCountry];
    }
    
    if (!locatedCountry && [[OMeta m].locator canLocate]) {
        [countrySheet addButtonWithTitle:[OStrings stringForKey:strButtonCountryLocate]];
    }
    
    [countrySheet addButtonWithTitle:[OStrings stringForKey:strButtonCountryOther]];
    [countrySheet addButtonWithTitle:[OStrings stringForKey:strButtonCancel]];
    countrySheet.cancelButtonIndex = countrySheet.numberOfButtons - 1;
    countrySheet.tag = kCountrySheetTag;
    
    [countrySheet showInView:self.tabBarController.view];
}


- (void)displayCountryAlert
{
    NSString *country = [OUtil countryFromCountryCode:[OMeta m].settings.countryCode];
    NSString *alertFormat = nil;
    
    if ([OUtil isSupportedCountryCode:[OMeta m].settings.countryCode]) {
        alertFormat = [OStrings stringForKey:strAlertTextCountrySupported];
    } else {
        alertFormat = [OStrings stringForKey:strAlertTextCountryUnsupported];
    }
    
    [OAlert showAlertWithTitle:country text:[NSString stringWithFormat:alertFormat, country] tag:kCountryAlertTag];
}


#pragma mark - Selector implementations

- (void)addOrigo
{
    NSString *sheetTitle = [OStrings stringForKey:strSheetTitleOrigoType];
    
    if ([self targetIs:kTargetUser]) {
        sheetTitle = [sheetTitle stringByAppendingString:@"?"];
    } else if ([self targetIs:kTargetWard]) {
        NSString *forWardName = [NSString stringWithFormat:[OStrings stringForKey:strTermForName], _member.givenName];
        sheetTitle = [NSString stringWithFormat:@"%@ %@?", sheetTitle, forWardName];
    }
    
    UIActionSheet *origoTypeSheet = [[UIActionSheet alloc] initWithTitle:sheetTitle delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    for (NSString *origoType in _origoTypes) {
        [origoTypeSheet addButtonWithTitle:[OStrings titleForOrigoType:origoType]];
    }
    
    [origoTypeSheet addButtonWithTitle:[OStrings stringForKey:strButtonCancel]];
    origoTypeSheet.cancelButtonIndex = [_origoTypes count];
    origoTypeSheet.tag = kOrigoTypeSheetTag;
    
    [origoTypeSheet showInView:self.tabBarController.view];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Origo";
    
    if ([OMeta m].userIsAllSet && ![_member isUser]) {
        self.navigationItem.title = [NSString stringWithFormat:[OStrings stringForKey:strViewTitleWardOrigoList], _member.givenName];
        self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:_member.givenName];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([OMeta m].userIsAllSet) {
        if ([[OMeta m].user isTeenOrOlder]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem addButtonWithTarget:self];
            self.navigationItem.rightBarButtonItem.action = @selector(addOrigo);
        }
        
        if (![self numberOfSectionsInTableView:self.tableView]) {
            [self.tableView addEmptyTableFooterViewWithText:[self footerText]];
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([OMeta m].userIsSignedIn && ![OMeta m].userIsRegistered) {
        if ([[OMeta m] userDefaultForKey:kDefaultsKeyRegistrationAborted]) {
            [OAlert showAlertWithTitle:[OStrings stringForKey:strAlertTitleIncompleteRegistration] text:[OStrings stringForKey:strAlertTextIncompleteRegistration]];
            
            [[OMeta m] setUserDefault:nil forKey:kDefaultsKeyRegistrationAborted];
        }
        
        [self presentModalViewWithIdentifier:kViewIdMember data:[[OMeta m].user initialResidency]];
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
    
    self.target = _member;
    
    if ([self targetIs:kTargetWard]) {
        if ([_member isOfPreschoolAge]) {
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
    [self setData:[_member participancies] forSectionWithKey:kOrigoSectionKey];
    
    if ([_member isUser]) {
        [self setData:[_member rootMembership] forSectionWithKey:kUserSectionKey];
        [self appendData:[_member residencies] toSectionWithKey:kUserSectionKey];
        [self setData:[_member wards] forSectionWithKey:kWardSectionKey];
    }
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return ([super hasFooterForSectionWithKey:sectionKey] && [[OMeta m].user isTeenOrOlder]);
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kWardSectionKey) {
        text = [OStrings stringForKey:strHeaderWardsOrigos];
    } else if (sectionKey == kOrigoSectionKey) {
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
    if ([self sectionKeyForIndexPath:indexPath] == kWardSectionKey) {
        OOrigoListViewController *origoListViewController = [self.storyboard instantiateViewControllerWithIdentifier:kViewIdOrigoList];
        origoListViewController.data = [self dataAtIndexPath:indexPath];
        
        [self.navigationController pushViewController:origoListViewController animated:YES];
    } else {
        if (indexPath.row == kUserRow) {
            [self performSegueWithIdentifier:kSegueToMemberView sender:self];
        } else {
            [self performSegueWithIdentifier:kSegueToMemberListView sender:self];
        }
    }
}


#pragma mark - OLocatorDelegate conformance

- (void)locatorDidLocate
{
    if (_isObtainingCountryList) {
        _isObtainingCountryList = NO;
        
        [self presentCountrySheet];
    } else {
        [OMeta m].settings.countryCode = [OMeta m].locator.countryCode;
        
        [self displayCountryAlert];
    }
}


- (void)locatorCannotLocate
{
    [self presentCountrySheet];
}


#pragma mark - OTableViewListCellDelegate conformance

- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    OReplicatedEntity *entity = [self dataAtIndexPath:indexPath];
    OMembership *membership = [entity asMembership];
    
    if (sectionKey == kUserSectionKey) {
        if (indexPath.row == kUserRow) {
            cell.textLabel.text = [OStrings stringForKey:strTermMe];
            cell.detailTextLabel.text = membership.member.name;
            cell.imageView.image = [membership.member displayImage];
        } else {
            cell.textLabel.text = membership.origo.name;
            cell.detailTextLabel.text = [membership.origo displayAddress];
            cell.imageView.image = [membership.origo displayImage];
        }
    } else if (sectionKey == kWardSectionKey) {
        cell.textLabel.text = [entity asMember].givenName;
        cell.imageView.image = [[entity asMember] displayImage]; //[UIImage imageNamed:kIconFileOrigo];
    } else if (sectionKey == kOrigoSectionKey) {
        cell.textLabel.text = membership.origo.name;
        cell.imageView.image = [membership.origo displayImage];
    }
}


#pragma mark - OModalViewControllerDelegate conformance

- (void)dismissModalViewControllerWithIdentifier:(NSString *)identifier
{
    [super dismissModalViewControllerWithIdentifier:identifier];
    
    if ([OMeta m].userIsSignedIn) {
        [self.tableView reloadData];
    }
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
                        [OMeta m].settings.countryCode = [OMeta m].inferredCountryCode;
                    }
                } else {
                    if ([[OMeta m].locator didLocate]) {
                        [OMeta m].settings.countryCode = [OMeta m].inferredCountryCode;
                    } else {
                        [[OMeta m].locator locateBlocking:YES];
                    }
                }
                
                if ([OMeta m].settings.countryCode) {
                    if ([OUtil isSupportedCountryCode:[OMeta m].settings.countryCode]) {
                        [self presentModalViewWithIdentifier:kViewIdOrigo data:_member meta:_selectedOrigoType];
                    } else {
                        [self displayCountryAlert];
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
                        _isObtainingCountryList = YES;
                        
                        [[OMeta m].locator locateBlocking:YES];
                    } else {
                        [self presentCountrySheet];
                    }
                } else {
                    [self presentModalViewWithIdentifier:kViewIdOrigo data:_member meta:_selectedOrigoType];
                }
            }
            
            break;
            
        default:
            break;
    }
}


#pragma mark - UIAlertViewDelegate conformance

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kCountryAlertTag:
            [self presentModalViewWithIdentifier:kViewIdOrigo data:_member meta:_selectedOrigoType];

            break;
            
        default:
            break;
    }
}

@end
