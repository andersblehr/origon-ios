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

#import "OMember+OrigoExtensions.h"
#import "OMembership.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"
#import "OSettings.h"

static NSString * const kSegueToMemberListView = @"segueFromOrigoListToMemberListView";

static NSInteger const kOrigoCountrySheetTag = 0;
static NSInteger const kOrigoCountrySheetButtonCountryProvided = 0;
static NSInteger const kOrigoCountrySheetButtonCountryOfLocation = 1;
static NSInteger const kOrigoCountrySheetButtonCountryOther = 2;

static NSInteger const kOrigoTypeSheetTag = 1;

static NSInteger const kOrigoCountryAlertTag = 0;

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
    
    if (self.state.aspectIsSelf && [self hasSectionWithKey:kWardSectionKey]) {
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
    } else if (self.state.aspectIsSelf) {
        footerText = [footerText stringByAppendingString:@"."];
    } else if (self.state.aspectIsWard) {
        NSString *forWardName = [NSString stringWithFormat:[OStrings stringForKey:strTermForName], _member.givenName];
        footerText = [NSString stringWithFormat:@"%@ %@.", footerText, forWardName];
    }
    
    return footerText;
}


- (BOOL)needsOrigoCountryForSelectedOrigoType
{
    BOOL needsOrigoCountry = NO;
    
    if (![OMeta m].settings.origoCountryCode) {
        needsOrigoCountry =
            ([_selectedOrigoType isEqualToString:kOrigoTypePreschoolClass] ||
             [_selectedOrigoType isEqualToString:kOrigoTypeSchoolClass]);
    }
    
    return needsOrigoCountry;
}


- (void)presentOrigoCountrySheet
{
    NSString *sheetTitleFormat = nil;
    NSString *buttonTitleCountryOfLocation = nil;
    
    if ([[OMeta m].locator canLocate]) {
        sheetTitleFormat = [OStrings stringForKey:strSheetTitleOrigoCountryLocate];
        buttonTitleCountryOfLocation = [OStrings stringForKey:strButtonCountryOfLocation];
    } else {
        sheetTitleFormat = [OStrings stringForKey:strSheetTitleOrigoCountryNoLocate];
    }
    
    UIActionSheet *origoCountrySheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:sheetTitleFormat, [OMeta m].locator.country] delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    [origoCountrySheet addButtonWithTitle:[OMeta m].locator.country];
    
    if ([[OMeta m].locator canLocate]) {
        [origoCountrySheet addButtonWithTitle:[OStrings stringForKey:strButtonCountryOfLocation]];
    }
    
    [origoCountrySheet addButtonWithTitle:[OStrings stringForKey:strButtonCountryOther]];
    [origoCountrySheet addButtonWithTitle:[OStrings stringForKey:strButtonCancel]];
    origoCountrySheet.cancelButtonIndex = origoCountrySheet.numberOfButtons - 1;
    origoCountrySheet.tag = kOrigoCountrySheetTag;
    
    [origoCountrySheet showInView:self.tabBarController.view];
}


- (void)displayOrigoCountryAlert
{
    [OMeta m].settings.origoCountryCode = [OMeta m].locator.countryCode;

    NSString *alertTitle = [NSString stringWithFormat:[OStrings stringForKey:strAlertTitleOrigoCountry], [OMeta m].locator.country];
    NSString *alertText = [NSString stringWithFormat:[OStrings stringForKey:strAlertTextOrigoCountry], [OMeta m].locator.country];
    
    [OAlert showAlertWithTitle:alertTitle message:alertText tag:kOrigoCountryAlertTag];
}


#pragma mark - Selector implementations

- (void)addOrigo
{
    NSString *sheetTitle = [OStrings stringForKey:strSheetTitleOrigoType];
    
    if (self.state.aspectIsSelf) {
        sheetTitle = [sheetTitle stringByAppendingString:@"?"];
    } else if (self.state.aspectIsWard) {
        NSString *forWardName = [NSString stringWithFormat:[OStrings stringForKey:strTermForName], _member.givenName];
        sheetTitle = [NSString stringWithFormat:@"%@ %@?", sheetTitle, forWardName];
    }
    
    UIActionSheet *origoTypeSheet = [[UIActionSheet alloc] initWithTitle:sheetTitle delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    for (NSString *origoType in _origoTypes) {
        [origoTypeSheet addButtonWithTitle:[OStrings stringForOrigoType:origoType]];
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
            [OAlert showAlertWithTitle:[OStrings stringForKey:strAlertTitleIncompleteRegistration] message:[OStrings stringForKey:strAlertTextIncompleteRegistration]];
            
            [[OMeta m] setUserDefault:nil forKey:kDefaultsKeyRegistrationAborted];
        }
        
        [self presentModalViewWithIdentifier:kMemberView data:[[OMeta m].user initialResidency]];
    }
}


#pragma mark - UIViewController overrides

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self prepareForPushSegue:segue];
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialise
{
    _viewId = kOrigoListView;
    _member = self.data ? self.data : [OMeta m].user;
    _origoTypes = [[NSMutableArray alloc] init];
    
    self.aspectCarrier = _member;
    
    if (self.state.aspectIsWard) {
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


- (void)populateDataSource
{
    [self setData:[_member participancies] forSectionWithKey:kOrigoSectionKey];
    
    if ([_member isUser]) {
        [self setData:[_member rootMembership] forSectionWithKey:kUserSectionKey];
        [self appendData:[_member residencies] toSectionWithKey:kUserSectionKey];
        [self setData:[_member wards] forSectionWithKey:kWardSectionKey];
    }
}


- (id)aspectCarrier
{
    return _member;
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


- (void)didSelectRow:(NSInteger)row inSectionWithKey:(NSInteger)sectionKey
{
    if (sectionKey == kWardSectionKey) {
        OOrigoListViewController *origoListViewController = [self.storyboard instantiateViewControllerWithIdentifier:kOrigoListView];
        origoListViewController.data = [self dataAtRow:row inSectionWithKey:sectionKey];
        
        [self.navigationController pushViewController:origoListViewController animated:YES];
    } else {
        [self performSegueWithIdentifier:kSegueToMemberListView sender:self];
    }
}


#pragma mark - OLocatorDelegate conformance

- (void)locatorDidLocate
{
    [self displayOrigoCountryAlert];
}


- (void)locatorCannotLocate
{
    [self presentOrigoCountrySheet];
}


#pragma mark - OTableViewListCellDelegate conformance

- (NSString *)cellTextForIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellText = nil;
    NSInteger sectionKey = [self sectionKeyForSectionNumber:indexPath.section];
    OReplicatedEntity *entity = [self dataForIndexPath:indexPath];
    
    if (sectionKey == kUserSectionKey) {
        if (indexPath.row == kUserRow) {
            cellText = [OStrings stringForKey:strTermMe];
        } else {
            cellText = [entity asMembership].origo.name;
        }
    } else if (sectionKey == kWardSectionKey) {
        cellText = [entity asMember].givenName;
    } else if (sectionKey == kOrigoSectionKey) {
        cellText = [entity asMembership].origo.name;
    }
    
    return cellText;
}


- (NSString *)cellDetailTextForIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellDetails = nil;
    OReplicatedEntity *entity = [self dataForIndexPath:indexPath];
    
    if ([self sectionKeyForSectionNumber:indexPath.section] == kUserSectionKey) {
        if (indexPath.row == kUserRow) {
            cellDetails = [entity asMembership].member.name;
        } else {
            cellDetails = [[entity asMembership].origo displayAddress];
        }
    }
    
    return cellDetails;
}


- (UIImage *)cellImageForIndexPath:(NSIndexPath *)indexPath
{
    UIImage *cellImage = nil;
    NSInteger sectionKey = [self sectionKeyForSectionNumber:indexPath.section];
    OReplicatedEntity *entity = [self dataForIndexPath:indexPath];
    
    if (sectionKey == kUserSectionKey) {
        if (indexPath.row == kUserRow) {
            cellImage = [[entity asMembership].member displayImage];
        } else {
            cellImage = [[entity asMembership].origo displayImage];
        }
    } else if (sectionKey == kWardSectionKey) {
        cellImage = [UIImage imageNamed:kIconFileOrigo];
    } else if (sectionKey == kOrigoSectionKey) {
        cellImage = [[entity asMembership].origo displayImage];
    }
    
    return cellImage;
}


#pragma mark - OModalViewControllerDelegate conformance

- (void)dismissModalViewWithIdentitifier:(NSString *)identitifier
{
    [super dismissModalViewWithIdentitifier:identitifier];
    
    if ([OMeta m].userIsSignedIn) {
        [self.tableView reloadData];
    }
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case kOrigoCountrySheetTag:
            if (buttonIndex == kOrigoCountrySheetButtonCountryProvided) {
                [self displayOrigoCountryAlert];
            } else if (buttonIndex == kOrigoCountrySheetButtonCountryOfLocation) {
                [[OMeta m].locator locate];
            } else if (buttonIndex == kOrigoCountrySheetButtonCountryOther) {
                // TODO: Modally open Settings pane for Origo country
            }
            
            break;
            
        case kOrigoTypeSheetTag:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                _selectedOrigoType = _origoTypes[buttonIndex];
                
                if ([self needsOrigoCountryForSelectedOrigoType]) {
                    [self presentOrigoCountrySheet];
                } else {
                    [self presentModalViewWithIdentifier:kOrigoView data:_member meta:_selectedOrigoType];
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
        case kOrigoCountryAlertTag:
            [self presentModalViewWithIdentifier:kOrigoView data:_member meta:_selectedOrigoType];

            break;
            
        default:
            break;
    }
}

@end
