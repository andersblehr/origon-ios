//
//  OSettingsViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OSettingsViewController.h"

#import "UIBarButtonItem+OBarButtonItemExtensions.h"
#import "UITableView+OTableViewExtensions.h"

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
    
    UINavigationController *origoNavigationController = self.tabBarController.viewControllers[kTabBarOrigo];
    [origoNavigationController setViewControllers:[NSArray arrayWithObject:[self.storyboard instantiateViewControllerWithIdentifier:kOrigoListViewControllerId]]];
    
    [self performSegueWithIdentifier:kModalSegueToAuthView sender:self];
}


#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView setBackground];
    
    self.title = [OStrings stringForKey:strTabBarTitleSettings];
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem signOutButtonWithTarget:self];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [OState s].actionIsList = YES;
    [OState s].targetIsSetting = YES;
    [OState s].aspectIsNone = YES;
    
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
        OAuthViewController *authViewController = segue.destinationViewController;
        authViewController.delegate = (OOrigoListViewController *)origoNavigationController.viewControllers[0];
    }
}


#pragma mark - UITableViewDataSource conformance

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    
    return cell;
}


#pragma mark - UITableViewDelegate conformance

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
