//
//  OOrigoListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "OOrigoListViewController.h"

#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"
#import "UITableView+OTableViewExtensions.h"
#import "UIView+OViewExtensions.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"

#import "OMemberGuardianship.h"
#import "OMember.h"
#import "OMemberResidency.h"
#import "OMembership.h"

#import "OOrigo+OOrigoExtensions.h"

#import "OMemberListViewController.h"

static NSString * const kSegueToMemberListView = @"origoListToMemberListView";

static NSInteger const kResidenceSection = 0;
static NSInteger const kWardSection = 1;
static NSInteger const kOrigoSection = 2;


@implementation OOrigoListViewController

#pragma mark - Selector implementations

- (void)addOrigo
{
    
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Origo";
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    self.navigationItem.title = @"Mine origo";
    //self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[ScMeta m].user.givenName style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addOrigo)];
    
    [self.tableView setBackground];
    
    NSMutableSet *residences = [[NSMutableSet alloc] init];
    NSMutableSet *wards = [[NSMutableSet alloc] init];
    _origos = [[NSMutableSet alloc] init];
    
    for (OMemberResidency *residency in [OMeta m].user.residencies) {
        [residences addObject:residency.residence];
    }
    
    for (OMemberGuardianship *wardship in [OMeta m].user.wardships) {
        [wards addObject:wardship.ward];
    }
    
    for (OMembership *membership in [OMeta m].user.memberships) {
        if (![[OMeta m].user.residencies containsObject:membership]) {
            [_origos addObject:membership.origo];
        }
    }
    
    _sortedResidences = [[residences allObjects] sortedArrayUsingSelector:@selector(compare:)];
    _sortedWards = [[wards allObjects] sortedArrayUsingSelector:@selector(compare:)];
    _sortedOrigos = [[_origos allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [OState s].actionIsList = YES;
    [OState s].targetIsOrigo = YES;
    [OState s].aspectIsSelf = YES;
    
    OLogState;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToMemberListView]) {
        OMemberListViewController *memberListViewController = segue.destinationViewController;
        
        memberListViewController.origo = _selectedOrigo;
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    OMember *user = [OMeta m].user;
    
    NSInteger numberOfRows = 0;
    
    if (section == kResidenceSection) {
        numberOfRows = [user.residencies count];
    } else if (section == kWardSection) {
        numberOfRows = [user.guardianships count];
    } else if (section == kOrigoSection) {
        numberOfRows = [user.memberships count] - [user.residencies count] - 1;
    }
    
    return numberOfRows;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [OTableViewCell defaultHeight];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    cell = [tableView cellWithReuseIdentifier:kReuseIdentifierDefault];
    
    if (indexPath.section == kResidenceSection) {
        OOrigo *residence = _sortedResidences[indexPath.row];
        
        cell.textLabel.text = [residence name];
        cell.detailTextLabel.text = [residence singleLineAddress];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0.f;
    
    if (section > kResidenceSection) {
        height = [tableView standardHeaderHeight];
    }
    
    return height;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = nil;
    
    if (section == kWardSection && [_sortedWards count]) {
        headerView = [tableView headerViewWithTitle:@"Mindreårige"];
    }
    
    return headerView;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isBottomCellInSection = NO;
    
    if (indexPath.section == kResidenceSection) {
        isBottomCellInSection = (indexPath.row == [_sortedResidences count] - 1);
    } else if (indexPath.section == kWardSection) {
        isBottomCellInSection = (indexPath.row == [_sortedWards count] - 1);
    } else if (indexPath.section == kOrigoSection) {
        isBottomCellInSection = (indexPath.row == [_sortedOrigos count] - 1);
    }
    
    if (isBottomCellInSection) {
        [cell.backgroundView addShadowForBottomTableViewCell];
    } else {
        [cell.backgroundView addShadowForContainedTableViewCell];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kWardSection) {
        _selectedWard = _sortedWards[indexPath.row];
    } else {
        [OState s].targetIsMember = YES;
        
        if (indexPath.section == kResidenceSection) {
            _selectedOrigo = _sortedResidences[indexPath.row];
        } else if (indexPath.section == kOrigoSection) {
            _selectedOrigo = _sortedOrigos[indexPath.row];
        }
        
        [self performSegueWithIdentifier:kSegueToMemberListView sender:self];
    }
}

@end
