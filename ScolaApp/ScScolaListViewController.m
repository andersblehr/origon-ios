//
//  ScScolaListViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ScScolaListViewController.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "UITableView+UITableViewExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScLogging.h"
#import "ScMeta.h"
#import "ScState.h"
#import "ScStrings.h"
#import "ScTableViewCell.h"

#import "ScMemberGuardianship.h"
#import "ScMember.h"
#import "ScMemberResidency.h"
#import "ScMembership.h"

#import "ScScola+ScScolaExtensions.h"

#import "ScMemberListViewController.h"

static NSString * const kSegueToScolaListView = @"scolaListToScolaListView";
static NSString * const kSegueToMemberListView = @"scolaListToMemberListView";

static NSInteger const kResidenceSection = 0;
static NSInteger const kWardSection = 1;
static NSInteger const kScolaSection = 2;


@implementation ScScolaListViewController

#pragma mark - Selector implementations

- (void)addScola
{
    
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = [ScMeta m].user.givenName;
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    self.navigationItem.title = [ScMeta m].user.name;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[ScMeta m].user.givenName style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addScola)];
    
    [self.tableView setBackground];
    
    NSMutableSet *residences = [[NSMutableSet alloc] init];
    NSMutableSet *wards = [[NSMutableSet alloc] init];
    _scolas = [[NSMutableSet alloc] init];
    
    for (ScMemberResidency *residency in [ScMeta m].user.residencies) {
        [residences addObject:residency.residence];
    }
    
    for (ScMemberGuardianship *wardship in [ScMeta m].user.wardships) {
        [wards addObject:wardship.ward];
    }
    
    for (ScMembership *membership in [ScMeta m].user.memberships) {
        if (![[ScMeta m].user.residencies containsObject:membership]) {
            [_scolas addObject:membership.scola];
        }
    }
    
    _sortedResidences = [[residences allObjects] sortedArrayUsingSelector:@selector(compare:)];
    _sortedWards = [[wards allObjects] sortedArrayUsingSelector:@selector(compare:)];
    _sortedScolas = [[_scolas allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [ScState s].actionIsList = YES;
    [ScState s].targetIsScola = YES;
    [ScState s].aspectIsSelf = YES;
    
    ScLogState;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToMemberListView]) {
        ScMemberListViewController *memberListViewController = segue.destinationViewController;
        
        memberListViewController.scola = _selectedScola;
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    ScMember *user = [ScMeta m].user;
    
    NSInteger numberOfRows = 0;
    
    if (section == kResidenceSection) {
        numberOfRows = [user.residencies count];
    } else if (section == kWardSection) {
        numberOfRows = [user.guardianships count];
    } else if (section == kScolaSection) {
        numberOfRows = [user.memberships count] - [user.residencies count] - 1;
    }
    
    return numberOfRows;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [ScTableViewCell defaultHeight];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    cell = [tableView cellWithReuseIdentifier:kReuseIdentifierDefault];
    
    if (indexPath.section == kResidenceSection) {
        ScScola *residence = _sortedResidences[indexPath.row];
        
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
    } else if (indexPath.section == kScolaSection) {
        isBottomCellInSection = (indexPath.row == [_sortedScolas count] - 1);
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
        [ScState s].targetIsMember = YES;
        
        if (indexPath.section == kResidenceSection) {
            _selectedScola = _sortedResidences[indexPath.row];
        } else if (indexPath.section == kScolaSection) {
            _selectedScola = _sortedScolas[indexPath.row];
        }
        
        [self performSegueWithIdentifier:kSegueToMemberListView sender:self];
    }
}

@end
