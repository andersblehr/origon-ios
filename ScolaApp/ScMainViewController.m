//
//  ScMainViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ScMainViewController.h"

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

#import "ScMembershipViewController.h"

static NSInteger const kResidenceSection = 0;
static NSInteger const kWardSection = 1;
static NSInteger const kScolaSection = 2;

static NSString * const kSegueToMembershipView = @"mainToMembershipView";


@implementation ScMainViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Scola";
    
    [self.tableView addBackground];
    
    NSMutableSet *residences = [[NSMutableSet alloc] init];
    NSMutableSet *wards = [[NSMutableSet alloc] init];
    _scolas = [[NSMutableSet alloc] init];
    
    for (ScMemberResidency *residency in _member.residencies) {
        [residences addObject:residency.residence];
    }
    
    for (ScMemberGuardianship *wardship in _member.wardships) {
        [wards addObject:wardship.ward];
    }
    
    for (ScMembership *membership in _member.memberships) {
        if (![_member.residencies containsObject:membership]) {
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
    
    [ScState s].action = ScStateActionDefault;
    [ScState s].target = ScStateTargetDefault;
    [ScState s].aspect = ScStateAspectDefault;
    
    ScLogState;
    
    [self navigationController].navigationBarHidden = YES;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToMembershipView]) {
        UITabBarController *tabBarController = segue.destinationViewController;
        ScMembershipViewController *nextViewController = [tabBarController.viewControllers objectAtIndex:0];
        
        nextViewController.scola = nil; // TODO: Figure this out!
    }
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    if (section == kResidenceSection) {
        numberOfRows = [_member.residencies count];
    } else if (section == kWardSection) {
        numberOfRows = [_member.guardianships count];
    } else if (section == kScolaSection) {
        numberOfRows = [_member.memberships count] - [_member.residencies count];
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
        // TODO
        
        cell.textLabel.text = @"TODO";
        cell.detailTextLabel.text = @"TODO";
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
    
    if (section == kWardSection) {
        headerView = [tableView headerViewWithTitle:@"TODO"];
    }
    
    return headerView;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isLastCellInSection = NO;
    
    if (indexPath.section == kResidenceSection) {
        isLastCellInSection = (indexPath.row == [_sortedResidences count] - 1);
    } else if (indexPath.section == kWardSection) {
        isLastCellInSection = (indexPath.row == [_sortedWards count] - 1);
    } else if (indexPath.section == kScolaSection) {
        isLastCellInSection = (indexPath.row == [_sortedScolas count] - 1);
    }
    
    if (isLastCellInSection) {
        [cell.backgroundView addShadowForBottomTableViewCell];
    } else {
        [cell.backgroundView addShadowForNonBottomTableViewCell];
    }
}

@end
