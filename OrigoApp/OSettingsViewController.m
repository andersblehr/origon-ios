//
//  OSettingsViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OSettingsViewController.h"

#import "UIBarButtonItem+OrigoExtensions.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"

#import "OTabBarController.h"


@implementation OSettingsViewController

#pragma mark - Selector implementations

- (void)signOut
{
    [[OMeta m] userDidSignOut];
    
    UINavigationController *origoTabNavigationController = self.tabBarController.viewControllers[kTabBarOrigo];
    [origoTabNavigationController setViewControllers:[NSArray arrayWithObject:[self.storyboard instantiateViewControllerWithIdentifier:kOrigoListViewControllerId]]];
    
    [self presentModalViewControllerWithIdentifier:kAuthViewControllerId data:nil dismisser:origoTabNavigationController.viewControllers[0]];
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


#pragma mark - OTableViewControllerInstance conformance

- (void)initialise
{
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
