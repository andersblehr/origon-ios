//
//  OMemberListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMemberListViewController.h"

#import "NSManagedObjectContext+OrigoExtensions.h"
#import "UIBarButtonItem+OrigoExtensions.h"
#import "UITableView+OrigoExtensions.h"

#import "OEntityObservingDelegate.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextView.h"

#import "OMember+OrigoExtensions.h"
#import "OMembership+OrigoExtensions.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"

#import "OMemberViewController.h"
#import "OOrigoViewController.h"

static NSString * const kModalSegueToMemberView = @"modalFromMemberListToMemberView";
static NSString * const kPushSegueToMemberView = @"pushFromMemberListToMemberView";
static NSString * const kPushSegueToOrigoView = @"pushFromMemberListToOrigoView";

static NSInteger const kOrigoSection = 0;
static NSInteger const kContactSection = 1;
static NSInteger const kMemberSection = 2;


@implementation OMemberListViewController

#pragma mark - Selector implementations

- (void)addMember
{
    [self performSegueWithIdentifier:kModalSegueToMemberView sender:self];
}


- (void)didFinishEditing
{
    [_delegate dismissModalViewControllerWithIdentitifier:kMemberListViewControllerId];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setBackground];
    
    if ([_origo isResidence]) {
        if ([_origo userIsMember]) {
            self.title = _origo.name;
        } else {
            self.title = [OStrings stringForKey:strViewTitleHousehold];
        }
    } else {
        self.title = [OStrings stringForKey:strViewTitleMembers];
    }
    
    if ([_origo userIsAdmin]) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem addButtonWithTarget:self];
        self.navigationItem.rightBarButtonItem.action = @selector(addMember);
        
        if (_delegate) {
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    OLogState;
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    if (!self.presentedViewController) {
        [[OMeta m].context replicateIfNeeded];
    }
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kModalSegueToMemberView]) {
        UINavigationController *navigationController = segue.destinationViewController;
        OMemberViewController *memberViewController = navigationController.viewControllers[0];
        memberViewController.origo = _origo;
        memberViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:kPushSegueToOrigoView]) {
        OOrigoViewController *origoViewController = segue.destinationViewController;
        origoViewController.membership = [_origo userMembership];
        origoViewController.entityObservingDelegate = _selectedCell;
    } else if ([segue.identifier isEqualToString:kPushSegueToMemberView]) {
        OMemberViewController *memberViewController = segue.destinationViewController;
        memberViewController.membership = _selectedMembership;
        memberViewController.entityObservingDelegate = _selectedCell;
    }
}


#pragma mark - OTableViewControllerDelegate conformance

- (void)setState
{
    self.state.actionIsList = YES;
    self.state.targetIsMember = YES;
    [self.state setAspectForOrigo:_origo];
}


- (void)loadData
{
    NSMutableSet *contactMemberships = [[NSMutableSet alloc] init];
    NSMutableSet *regularMemberships = [[NSMutableSet alloc] init];
    
    for (OMembership *membership in _origo.memberships) {
        if ([membership hasContactRole]) {
            [contactMemberships addObject:membership];
        } else {
            [regularMemberships addObject:membership];
        }
    }
    
    [self setData:_origo forSection:kOrigoSection];
    [self setData:contactMemberships forSection:kContactSection];
    [self setData:regularMemberships forSection:kMemberSection];
}


#pragma mark - UITableViewDataSource conformance

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.f;
    
    if (indexPath.section == kOrigoSection) {
        height = [_origo cellHeight];
    } else {
        height = kDefaultTableViewCellHeight;
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTableViewCell *cell = nil;
    
    if (indexPath.section == kOrigoSection) {
        _origoCell = [tableView cellForEntity:_origo];
        _origoCell.entityObservingDelegate = _entityObservingDelegate;
        
        if ([_origo userIsAdmin]) {
            _origoCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        cell = _origoCell;
    } else {
        cell = [tableView listCellForEntity:[[self entityForIndexPath:indexPath] member]];
    }
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDeleteRow = NO;
    
    if (indexPath.section != kOrigoSection) {
        OMembership *membershipForRow = [self entityForIndexPath:indexPath];
        canDeleteRow = ([_origo userIsAdmin] && ![membershipForRow.member isUser]);
    }
    
    return canDeleteRow;
}


#pragma mark - UITableViewDelegate conformance

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = kMinimumPadding;
    
    if (section == kOrigoSection) {
        height = kDefaultPadding;
    } else if (![self sectionIsEmpty:section]) {
        height = [tableView standardHeaderHeight];
    }
    
    return height;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = kMinimumPadding;
    
    if (section == kOrigoSection) {
        height = kDefaultPadding;
    } else if ((section == kMemberSection) && [_origo userIsAdmin]) {
        height = [tableView standardFooterHeight];
    }
    
    return height;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = nil;
    
    if ((section != kOrigoSection) && ![self sectionIsEmpty:section]) {
        if (section == kContactSection) {
            headerView = [tableView headerViewWithText:[OStrings stringForKey:strHeaderContacts]];
        } else if (section == kMemberSection) {
            if ([_origo isResidence]) {
                headerView = [tableView headerViewWithText:[OStrings stringForKey:strHeaderHouseholdMembers]];
            } else {
                headerView = [tableView headerViewWithText:[OStrings stringForKey:strHeaderOrigoMembers]];
            }
        }
    }
    
    return headerView;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = nil;
    
    if ((section == kMemberSection) && [_origo userIsAdmin]) {
        footerView = [tableView footerViewWithText:[OStrings stringForKey:strFooterHousehold]];
    }
    
    return footerView;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(OTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1) {
        [cell willAppearTrailing:YES];
    } else {
        [cell willAppearTrailing:NO];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedCell = (OTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == kOrigoSection) {
        [self performSegueWithIdentifier:kPushSegueToOrigoView sender:self];
    } else {
        _selectedMembership = [self entityForIndexPath:indexPath];
        
        [self performSegueWithIdentifier:kPushSegueToMemberView sender:self];
    }
}


- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [OStrings stringForKey:strButtonDeleteMember];
}


#pragma mark - OModalViewControllerDelegate conformance

- (void)dismissModalViewControllerWithIdentitifier:(NSString *)identitifier
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
