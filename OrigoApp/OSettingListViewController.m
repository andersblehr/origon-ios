//
//  OSettingListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OSettingListViewController.h"

#import "UIBarButtonItem+OrigoExtensions.h"
#import "UITableView+OrigoExtensions.h"

#import "OLocator.h"
#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"

#import "OSettings+OrigoExtensions.h"

#import "OTabBarController.h"

static NSString * const kSegueToSettingView = @"sequeFromSettingListToSettingView";

static NSInteger const kSettingsSectionKey = 0;


@implementation OSettingListViewController

#pragma mark - Selector implementations

- (void)signOut
{
    [[OMeta m] userDidSignOut];
    
    UINavigationController *origoTabNavigationController = self.tabBarController.viewControllers[kTabBarOrigo];
    [origoTabNavigationController setViewControllers:[NSArray arrayWithObject:[self.storyboard instantiateViewControllerWithIdentifier:kViewIdOrigoList]]];
    
    [self presentModalViewWithIdentifier:kViewIdAuth data:nil dismisser:origoTabNavigationController.viewControllers[0]];
}


#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = [OStrings stringForKey:strTabBarTitleSettings];
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem signOutButtonWithTarget:self];
    
    if (![OMeta m].settings.countryCode) {
        [OMeta m].settings.countryCode = [OMeta m].locator.countryCode;
    }
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (![OMeta m].userIsSignedIn) {
        self.tabBarController.selectedIndex = kTabBarOrigo;
    }
}


#pragma mark - UIViewController overrides

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToSettingView]) {
        [self prepareForPushSegue:segue];
    }
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialise
{
    self.target = kTargetUser;
}


- (void)populateDataSource
{
    [self setData:[[OMeta m].settings settingKeys] forSectionWithKey:kSettingsSectionKey];
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return NO;
}


- (void)didSelectRow:(NSInteger)row inSectionWithKey:(NSInteger)sectionKey
{
    [self performSegueWithIdentifier:kSegueToSettingView sender:self];
}


#pragma mark - OTableViewListCellDelegate conformance

- (NSString *)cellTextForIndexPath:(NSIndexPath *)indexPath
{
    return [OStrings settingTextForKey:[self dataForIndexPath:indexPath]];
}


- (NSString *)cellDetailTextForIndexPath:(NSIndexPath *)indexPath
{
    return [[OMeta m].settings valueForSettingKey:[self dataForIndexPath:indexPath]];
}


#pragma mark - UITableViewDataSource conformance

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView settingCellForIndexPath:indexPath delegate:self];
}

@end
