//
//  OOrigoListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "OOrigoListViewController.h"

#import "NSManagedObjectContext+OrigoExtensions.h"
#import "NSString+OrigoExtensions.h"
#import "UIBarButtonItem+OrigoExtensions.h"
#import "UITableView+OrigoExtensions.h"

#import "OAlert.h"
#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"

#import "OMember+OrigoExtensions.h"
#import "OMemberResidency.h"
#import "OMembership.h"
#import "OOrigo+OrigoExtensions.h"

#import "OAuthViewController.h"
#import "OMemberListViewController.h"
#import "OMemberViewController.h"
#import "OOrigoViewController.h"

static NSString * const kModalSegueToAuthView = @"modalFromOrigoListToAuthView";
static NSString * const kModalSegueToMemberView = @"modalFromOrigoListToMemberView";
static NSString * const kModalSegueToOrigoView = @"modalFromOrigoListToOrigoView";
static NSString * const kPushSegueToMemberListView = @"pushFromOrigoListToMemberListView";
static NSString * const kPushSegueToMemberView = @"pushFromOrigoListToMemberView";

static NSInteger const kUserSection = 0;
static NSInteger const kWardSection = 1;
static NSInteger const kOrigoSection = 2;

static NSInteger const kUserRow = 0;


@implementation OOrigoListViewController

#pragma mark - Auxiliary methods

- (NSString *)footerText
{
    NSString *footerText = nil;
    
    if ([self hasSectionWithKey:kOrigoSection]) {
        footerText = [OStrings stringForKey:strFooterOrigoCreation];
    } else {
        footerText = [OStrings stringForKey:strFooterOrigoCreationFirst];
    }
    
    if (self.state.aspectIsSelf && [self hasSectionWithKey:kWardSection]) {
        NSString *yourChild = nil;
        NSString *himOrHer = nil;
        
        BOOL allFemale = YES;
        BOOL allMale = YES;
        
        if ([self numberOfRowsInSectionWithKey:kWardSection] == 1) {
            yourChild = ((OMember *)[self entitiesInSectionWithKey:kWardSection][0]).givenName;
        } else {
            yourChild = [OStrings stringForKey:strTermYourChild];
        }
        
        for (OMember *ward in [self entitiesInSectionWithKey:kWardSection]) {
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


#pragma mark - Selector implementations

- (void)addOrigo
{
    _origoTypes = [[NSMutableArray alloc] init];
    
    NSString *sheetTitle = [OStrings stringForKey:strSheetTitleOrigoType];
    
    if (self.state.aspectIsSelf) {
        sheetTitle = [sheetTitle stringByAppendingString:@"?"];
    } else if (self.state.aspectIsWard) {
        NSString *forWardName = [NSString stringWithFormat:[OStrings stringForKey:strTermForName], _member.givenName];
        sheetTitle = [NSString stringWithFormat:@"%@ %@?", sheetTitle, forWardName];
        
        if ([_member isOfPreschoolAge] && ![_member isMemberOfOrigoOfType:kOrigoTypeSchoolClass]) {
            [_origoTypes addObject:kOrigoTypePreschoolClass];
        }
        
        [_origoTypes addObject:kOrigoTypeSchoolClass];
    }
    
    [_origoTypes addObject:kOrigoTypeSportsTeam];
    [_origoTypes addObject:kOrigoTypeDefault];
    
    UIActionSheet *origoTypeSheet = [[UIActionSheet alloc] initWithTitle:sheetTitle delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    for (NSString *origoType in _origoTypes) {
        [origoTypeSheet addButtonWithTitle:[OStrings stringForKey:origoType]];
    }
    
    [origoTypeSheet addButtonWithTitle:[OStrings stringForKey:strButtonCancel]];
    origoTypeSheet.cancelButtonIndex = [_origoTypes count];
    
    [origoTypeSheet showInView:self.tabBarController.view];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Origo";
    
    if ([self shouldInitialise]) {
        if (![_member isUser]) {
            self.navigationItem.title = [NSString stringWithFormat:[OStrings stringForKey:strViewTitleWardOrigoList], _member.givenName];
            self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:_member.givenName];
        }
        
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
    
    OLogState;
    
    if (![[OMeta m] userIsSignedIn]) {
        [self performSegueWithIdentifier:kModalSegueToAuthView sender:self];
    } else if (![[OMeta m] userIsRegistered]) {
        [OAlert showAlertWithTitle:[OStrings stringForKey:strAlertTitleIncompleteRegistration] message:[OStrings stringForKey:strAlertTextIncompleteRegistration]];
        
        [self performSegueWithIdentifier:kModalSegueToMemberView sender:self];
    }
}


#pragma mark - Overrides

- (BOOL)shouldInitialise
{
    return [[OMeta m] userIsAllSet];
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kModalSegueToAuthView]) {
        [self prepareForModalSegue:segue data:nil];
    } else if ([segue.identifier isEqualToString:kModalSegueToMemberView]) {
        [self prepareForModalSegue:segue data:[_member initialResidency]];
    } else if ([segue.identifier isEqualToString:kModalSegueToOrigoView]) {
        [self prepareForModalSegue:segue data:_member];
    } else {
        [self prepareForPushSegue:segue];
    }
}


#pragma mark - OTableViewControllerDelegate conformance

- (void)loadState
{
    _member = self.data ? self.data : [OMeta m].user;
    
    self.state.actionIsList = YES;
    self.state.targetIsOrigo = YES;
    [self.state setAspectForMember:_member];
}


- (void)loadData
{
    [self setData:[_member origoMemberships] forSectionWithKey:kOrigoSection];
    
    if ([_member isUser]) {
        [self setData:[_member rootMembership] forSectionWithKey:kUserSection];
        [self appendData:[_member residencies] toSectionWithKey:kUserSection];
        [self setData:[_member wards] forSectionWithKey:kWardSection];
    }
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return ([super hasFooterForSectionWithKey:sectionKey] && [[OMeta m].user isTeenOrOlder]);
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kWardSection) {
        text = [OStrings stringForKey:strHeaderWardsOrigos];
    } else if (sectionKey == kOrigoSection) {
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
    if (sectionKey == kWardSection) {
        OOrigoListViewController *origoListViewController = [self.storyboard instantiateViewControllerWithIdentifier:kOrigoListViewControllerId];
        origoListViewController.data = [self entityAtRow:row inSectionWithKey:sectionKey];
        
        [self.navigationController pushViewController:origoListViewController animated:YES];
    } else {
        [self performSegueWithIdentifier:kPushSegueToMemberListView sender:self];
    }
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        _indexOfSelectedOrigoType = buttonIndex;
        
        [self performSegueWithIdentifier:kModalSegueToOrigoView sender:self];
    }
}


#pragma mark - OModalViewControllerDelegate conformance

- (void)dismissModalViewControllerWithIdentitifier:(NSString *)identitifier
{
    [super dismissModalViewControllerWithIdentitifier:identitifier];
    
    if ([identitifier isEqualToString:kAuthViewControllerId] ||
        [identitifier isEqualToString:kMemberViewControllerId] ||
        [identitifier isEqualToString:kMemberListViewControllerId]) {
        if ([[OMeta m] userIsSignedIn]) {
            [self.tableView reloadData];
        }
    } else if ([identitifier isEqualToString:kOrigoViewControllerId]) {
        
    }
}

@end
