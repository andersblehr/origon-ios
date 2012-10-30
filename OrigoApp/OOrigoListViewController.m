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
    return ([OState s].aspectIsSelf && [_sortedWards count] && (section == kWardSection));
}


- (BOOL)sectionIsOrigoSection:(NSInteger)section
{
    NSUInteger origoSection = [OState s].aspectIsSelf ? ([_sortedWards count] ? 2 : 1) : 0;
    
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
    
    _aspect = [OState s].aspect;
    
    [self.tableView setBackground];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addOrigo)];

    if ([OState s].aspectIsSelf) {
        self.title = [OStrings stringForKey:strTabBarTitleOrigo];
        self.member = [OMeta m].user;
        
        NSMutableSet *residences = [[NSMutableSet alloc] init];
        NSSet *wards = [_member wards];
        
        for (OMemberResidency *residency in _member.residencies) {
            [residences addObject:residency.residence];
        }
        
        _sortedResidences = [[residences allObjects] sortedArrayUsingSelector:@selector(compare:)];
        _sortedWards = [[wards allObjects] sortedArrayUsingSelector:@selector(compare:)];
    } else {
        self.title = [NSString stringWithFormat:[OStrings stringForKey:strViewTitleWardOrigos], _member.givenName];
    }
    
    NSMutableSet *origos = [[NSMutableSet alloc] init];
    
    for (OMembership *membership in _member.memberships) {
        if (![membership.origo isMemberRoot] && ![membership.origo isResidence]) {
            [origos addObject:membership.origo];
        }
    }
    
    _sortedOrigos = [[origos allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [OState s].targetIsOrigo = YES;
    [OState s].actionIsList = YES;
    [OState s].aspect = _aspect;
    
    OLogState;

    if ([OState s].aspectIsSelf) {
        NSRange reloadRange = {0, 0};
        
        if ([_member.residencies count] != [_sortedResidences count]) {
            NSMutableSet *residences = [[NSMutableSet alloc] init];
            
            for (OMemberResidency *residency in _member.residencies) {
                [residences addObject:residency.residence];
            }
            
            _sortedResidences = [[residences allObjects] sortedArrayUsingSelector:@selector(compare:)];
            
            reloadRange.location = kResidenceSection;
            reloadRange.length = 1;
        }
        
        NSSet *wards = [_member wards];
        
        if ([wards count] != [_sortedWards count]) {
            BOOL wardsSectionDoesExist = ([_sortedWards count] > 0);
            _sortedWards = [[wards allObjects] sortedArrayUsingSelector:@selector(compare:)];
            
            if ([wards count]) {
                if (!wardsSectionDoesExist) {
                    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:kWardSection] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
                
                if (reloadRange.length) {
                    reloadRange.length++;
                } else {
                    reloadRange.location = kWardSection;
                    reloadRange.length = 1;
                }
            } else {
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:kWardSection] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
        
        if (reloadRange.length) {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:reloadRange] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
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
    NSUInteger numberOfRows = 0;
    
    if ([self sectionIsResidenceSection:section]) {
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
    OMember *ward = nil;
    
    if ([self sectionIsResidenceSection:indexPath.section]) {
        origo = _sortedResidences[indexPath.row];
    } else if ([self sectionIsWardSection:indexPath.section]) {
        ward = _sortedWards[indexPath.row];
    } else if ([self sectionIsOrigoSection:indexPath.section]) {
        origo = _sortedOrigos[indexPath.row];
    }
    
    UITableViewCell *cell = [tableView cellWithReuseIdentifier:kReuseIdentifierDefault];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (origo) {
        cell.textLabel.text = origo.name;
        cell.detailTextLabel.text = origo.details;
        
        if ([origo isResidence]) {
            cell.imageView.image = [UIImage imageNamed:kIconFileHousehold];
        } else {
            // TODO: What icon to use for general origos?
        }
    } else if (ward) {
        cell.textLabel.text = ward.givenName;
        cell.imageView.image = [UIImage imageNamed:kIconFileOrigo];
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = kDefaultPadding;
    
    if (section >= kWardSection) {
        height = [tableView standardHeaderHeight];
    }
    
    return height;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = nil;
    
    if ([self sectionIsWardSection:section]) {
        headerView = [tableView headerViewWithTitle:[OStrings stringForKey:strSectionHeaderWards]];
    } else if ([self sectionIsOrigoSection:section]) {
        headerView = [tableView headerViewWithTitle:[OStrings stringForKey:strSectionHeaderOrigos]];
    }
    
    return headerView;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isBottomCellInSection = NO;
    
    if ([self sectionIsResidenceSection:indexPath.section]) {
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
    
    if ([self sectionIsResidenceSection:indexPath.section]) {
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
        OOrigoListViewController *wardOrigoListViewController = [self.storyboard instantiateViewControllerWithIdentifier:kOrigoListViewControllerId];
        wardOrigoListViewController.member = _selectedWard;
        
        [self.navigationController pushViewController:wardOrigoListViewController animated:YES];
    }
}


#pragma mark - OModalInputViewControllerDelegate methods

- (void)dismissViewControllerWithIdentitifier:(NSString *)identitifier
{
    if ([identitifier isEqualToString:@"Identifier string"]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}


- (void)insertEntityInTableView:(OReplicatedEntity *)entity
{
    
}

@end
