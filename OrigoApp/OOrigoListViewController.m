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

#import "OMember+OMemberExtensions.h"
#import "OOrigo+OOrigoExtensions.h"

#import "OMemberListViewController.h"

static NSString * const kSegueToMemberListView = @"origoListToMemberListView";

static NSInteger const kMinimumNumberOfSections = 1;

static NSInteger const kUserSection = 0;
static NSInteger const kResidenceSection = 1;
static NSInteger const kWardSectionWithNoResidenceSection = 1;
static NSInteger const kWardSectionWithResidenceSection = 2;


@implementation OOrigoListViewController

#pragma mark - Auxiliary methods

- (BOOL)sectionIsUserSection:(NSInteger)section
{
    return (_tableViewHasResidenceSection && (section == kUserSection));
}


- (BOOL)sectionIsCombinedUserAndResidenceSection:(NSInteger)section
{
    return (!_tableViewHasResidenceSection && (section == kUserSection));
}


- (BOOL)sectionIsResidenceSection:(NSInteger)section
{
    return (_tableViewHasResidenceSection && (section == kResidenceSection));
}


- (BOOL)sectionIsWardSection:(NSInteger)section
{
    BOOL sectionIsWardSection = NO;
    
    if (_tableViewHasWardSection) {
        if (_tableViewHasResidenceSection) {
            sectionIsWardSection = (section == kWardSectionWithResidenceSection);
        } else {
            sectionIsWardSection = (section == kWardSectionWithNoResidenceSection);
        }
    }
    
    return sectionIsWardSection;
}


- (BOOL)sectionIsOrigoSection:(NSInteger)section
{
    return (_tableViewHasOrigoSection && (section == _numberOfSections - 1));
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
    
    self.title = @"Origo";
    self.navigationItem.title = @"Mine origo";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addOrigo)];
    
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
        if (![membership.origo isMemberRoot] && ![membership.origo isResidence]) {
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
    _tableViewHasResidenceSection = ([_sortedResidences count] > 1);
    _tableViewHasWardSection = ([_sortedWards count] > 0);
    _tableViewHasOrigoSection = ([_sortedOrigos count] > 0);
    
    _numberOfSections = kMinimumNumberOfSections;
    
    if (_tableViewHasResidenceSection) {
        _numberOfSections++;
    }
    
    if (_tableViewHasWardSection) {
        _numberOfSections++;
    }
    
    if (_tableViewHasOrigoSection) {
        _numberOfSections++;
    }
    
    return _numberOfSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    if ([self sectionIsUserSection:section]) {
        numberOfRows = 1;
    } else if ([self sectionIsCombinedUserAndResidenceSection:section]) {
        numberOfRows = 2;
    } else if ([self sectionIsResidenceSection:section]) {
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
    OOrigo *origo = nil;
    OMember *member = nil;
    
    if ([self sectionIsUserSection:indexPath.section]) {
        member = [OMeta m].user;
    } else if ([self sectionIsCombinedUserAndResidenceSection:indexPath.section]) {
        if (indexPath.row == 0) {
            member = [OMeta m].user;
        } else {
            origo = _sortedResidences[0];
        }
    } else if ([self sectionIsResidenceSection:indexPath.section]) {
        origo = _sortedResidences[indexPath.row];
    } else if ([self sectionIsWardSection:indexPath.section]) {
        member = _sortedWards[indexPath.row];
    } else if ([self sectionIsOrigoSection:indexPath.section]) {
        origo = _sortedOrigos[indexPath.row];
    }
    
    UITableViewCell *cell = [tableView cellWithReuseIdentifier:kReuseIdentifierDefault];
    cell.textLabel.text = origo ? origo.name : member.name;
    cell.detailTextLabel.text = origo ? origo.detail : member.detail;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0.f;
    
    if (section > kUserSection) {
        height = [tableView standardHeaderHeight];
    }
    
    return height;
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
    
    if ([self sectionIsUserSection:indexPath.section]) {
        isBottomCellInSection = YES;
    } else if ([self sectionIsCombinedUserAndResidenceSection:indexPath.section]) {
        isBottomCellInSection = (indexPath.row == 1);
    } else if ([self sectionIsResidenceSection:indexPath.section]) {
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
    _selectedMember = nil;
    
    if ([self sectionIsUserSection:indexPath.section]) {
        _selectedMember = [OMeta m].user;
    } else if ([self sectionIsCombinedUserAndResidenceSection:indexPath.section]) {
        if (indexPath.row == 0) {
            _selectedMember = [OMeta m].user;
        } else {
            _selectedOrigo = _sortedResidences[0];
        }
    } else if ([self sectionIsResidenceSection:indexPath.section]) {
        _selectedOrigo = _sortedResidences[indexPath.row];
    } else if ([self sectionIsWardSection:indexPath.section]) {
        _selectedMember = _sortedWards[indexPath.row];
        
        [OState s].aspectIsWard = YES;
    } else if ([self sectionIsOrigoSection:indexPath.section]) {
        _selectedOrigo = _sortedOrigos[indexPath.row];
    }
    
    [OState s].targetIsMember = YES;
    
    if (_selectedOrigo) {
        [self performSegueWithIdentifier:kSegueToMemberListView sender:self];
    } else if (_selectedMember) {
        // TODO: Segue to self..
    }
}

@end
