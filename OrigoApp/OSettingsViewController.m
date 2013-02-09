//
//  OSettingsViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OSettingsViewController.h"

#import "UIBarButtonItem+OrigoExtensions.h"
#import "UITableView+OrigoExtensions.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"

#import "OAuthViewController.h"
#import "OOrigoListViewController.h"
#import "OTabBarController.h"

static NSString * const kModalSegueToAuthView = @"modalFromSettingsToAuthView";


@implementation OSettingsViewController

#pragma mark - Selector implementations

- (void)signOut
{
    [[OMeta m] userDidSignOut];
    
    UINavigationController *origoTabNavigationController = self.tabBarController.viewControllers[kTabBarOrigo];
    [origoTabNavigationController setViewControllers:[NSArray arrayWithObject:[self.storyboard instantiateViewControllerWithIdentifier:kOrigoListViewControllerId]]];
    
    [self performSegueWithIdentifier:kModalSegueToAuthView sender:self];
}


#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = [OStrings stringForKey:strTabBarTitleSettings];
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem signOutButtonWithTarget:self];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    OLogState;
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (![[OMeta m] userIsSignedIn]) {
        self.tabBarController.selectedIndex = kTabBarOrigo;
    }
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kModalSegueToAuthView]) {
        UINavigationController *origoNavigationController = self.tabBarController.viewControllers[kTabBarOrigo];
        
        [self prepareForModalSegue:segue data:nil];
        [segue.destinationViewController setDelegate:origoNavigationController.viewControllers[0]];
    }
}


#pragma mark - OTableViewControllerDelegate conformance

- (void)loadState
{
    self.state.actionIsList = YES;
    self.state.targetIsSetting = YES;
    self.state.aspectIsSelf = YES;
}


#pragma mark - UITableViewDataSource conformance

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    
    return cell;
}

@end
