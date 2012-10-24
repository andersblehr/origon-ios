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

#import "OMember.h"
#import "OMemberResidency.h"
#import "OMembership.h"

#import "OMember+OMemberExtensions.h"
#import "OOrigo+OOrigoExtensions.h"

#import "OMemberListViewController.h"

static NSString * const kSegueToMemberListView = @"origoListToMemberListView";
static NSString * const kSegueToMemberView = @"origoListToMemberView";

static NSInteger const kResidenceSection = 0;
static NSInteger const kWardSection = 1;


@implementation OOrigoListViewController

#pragma mark - Auxiliary methods

- (BOOL)sectionIsResidenceSection:(NSInteger)section
{
    return ([OState s].aspectIsSelf && section == kResidenceSection);
}


- (BOOL)sectionIsWardSection:(NSInteger)section
{
    return ([_sortedWards count] && (section == kWardSection));
}


- (BOOL)sectionIsOrigoSection:(NSInteger)section
{
    NSInteger origoSection = ([OState s].aspectIsSelf) ? ([_sortedWards count] ? 2 : 1) : 0;
    
    return ([_sortedOrigos count] && (section == origoSection));
}


#pragma mark - Selector implementations

- (void)addOrigo
{
    
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setBackground];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    self.title = [OStrings stringForKey:strTabBarTitleOrigo];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addOrigo)];

    NSSet *wards = [[OMeta m].user wards];
    NSMutableSet *residences = [[NSMutableSet alloc] init];
    NSMutableSet *origos = [[NSMutableSet alloc] init];
    
    for (OMemberResidency *residency in [OMeta m].user.residencies) {
        [residences addObject:residency.residence];
    }
    
    for (OMembership *membership in [OMeta m].user.memberships) {
        if (![membership.origo isMemberRoot] && ![membership.origo isResidence]) {
            [origos addObject:membership.origo];
        }
    }
    
    _sortedWards = [[wards allObjects] sortedArrayUsingSelector:@selector(compare:)];
    _sortedResidences = [[residences allObjects] sortedArrayUsingSelector:@selector(compare:)];
    _sortedOrigos = [[origos allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    _aspect = [OState s].aspect;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [OState s].targetIsOrigo = YES;
    [OState s].actionIsList = YES;
    [OState s].aspect = _aspect;
    
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
    } else if ([segue.identifier isEqualToString:kSegueToMemberView]) {
        
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numberOfSections = 1;

    if ([OState s].aspectIsSelf) {
        if ([_sortedWards count]) {
            numberOfSections++;
        }
        
        if ([_sortedOrigos count]) {
            numberOfSections++;
        }
    }
    
    return numberOfSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    if (section == kResidenceSection) {
        numberOfRows = [_sortedResidences count];
    } else if ([self sectionIsWardSection:section]) {
        numberOfRows = [_sortedWards count];
    } else if ([self sectionIsOrigoSection:section]) {
        numberOfRows = [_sortedOrigos count];
    }
    
    return numberOfRows;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [OTableViewCell defaultHeight];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OMember *member = nil;
    OOrigo *origo = nil;
    
    if (indexPath.section == kResidenceSection) {
        origo = _sortedResidences[indexPath.row];
    } else if ([self sectionIsWardSection:indexPath.section]) {
        member = _sortedWards[indexPath.row];
    } else if ([self sectionIsOrigoSection:indexPath.section]) {
        origo = _sortedOrigos[indexPath.row];
    }
    
    UITableViewCell *cell = [tableView cellWithReuseIdentifier:kReuseIdentifierDefault];;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (![self sectionIsWardSection:indexPath.section]) {
        cell.textLabel.text = origo ? origo.name : member.name;
        cell.detailTextLabel.text = origo ? origo.details : member.details;
    } else {
        cell.textLabel.text = member.givenName;
    }
    
    if (member) {
        cell.imageView.image = [UIImage imageNamed:kIconFileOrigo];
    } else if (origo && [origo isResidence]) {
        cell.imageView.image = [UIImage imageNamed:kIconFileHousehold];
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = kMinimumSectionHeaderHeight;
    
    if (section == 0) {
        height = kDefaultSectionHeaderHeight;
    } else if (section >= kWardSection) {
        height = [tableView standardHeaderHeight];
    }
    
    return height;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return kDefaultSectionFooterHeight;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = nil;
    
    if ([self sectionIsWardSection:section]) {
        headerView = [tableView headerViewWithTitle:@"Barnas origo"];
    } else if ([self sectionIsOrigoSection:section]) {
        headerView = [tableView headerViewWithTitle:@"Mine origo"];
    }
    
    return headerView;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isBottomCellInSection = NO;
    
    if (indexPath.section == kResidenceSection) {
        isBottomCellInSection = (indexPath.row == [_sortedResidences count] - 1);
    } else if ([self sectionIsWardSection:indexPath.section]) {
        isBottomCellInSection = (indexPath.row == [_sortedWards count] - 1);
    } else if ([self sectionIsOrigoSection:indexPath.section]) {
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
    _selectedOrigo = nil;
    _selectedWard = nil;
    
    if (indexPath.section == kResidenceSection) {
        _selectedOrigo = _sortedResidences[indexPath.row];
        
        [OState s].aspectIsSelf = YES;
    } else if ([self sectionIsWardSection:indexPath.section]) {
        _selectedWard = _sortedWards[indexPath.row];
        
        [OState s].aspectIsWard = YES;
    } else if ([self sectionIsOrigoSection:indexPath.section]) {
        _selectedOrigo = _sortedOrigos[indexPath.row];
        
        [OState s].aspectIsExternal = YES;
    }
    
    if (_selectedOrigo) {
        [self performSegueWithIdentifier:kSegueToMemberListView sender:self];
    } else if (_selectedWard) {
        if ([OState s].aspectIsSelf) {
            [self performSegueWithIdentifier:kSegueToMemberView sender:self];
        } else if ([OState s].aspectIsWard) {
            // TODO: Segue to self..
        }
    }
}

@end
