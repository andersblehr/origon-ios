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

static NSInteger const kDefaultNumberOfSections = 3;
static NSInteger const kReducedNumberOfSections = 2;

static NSInteger const kOrigoSection = 0;
static NSInteger const kContactSection = 1;
static NSInteger const kMemberSection = 2;


@implementation OMemberListViewController

#pragma mark - Auxiliary methods

- (BOOL)sectionIsContactSection:(NSInteger)section
{
    BOOL isContactSection = NO;
    
    if ([_contactMemberships count] && [_regularMemberships count]) {
        isContactSection = (section = kContactSection);
    } else {
        isContactSection = ((section == kOrigoSection + 1) && [_contactMemberships count]);
    }
    
    return isContactSection;
}


- (BOOL)sectionIsMemberSection:(NSInteger)section
{
    BOOL isMemberSection = NO;
    
    if ([_contactMemberships count] && [_regularMemberships count]) {
        isMemberSection = (section == kMemberSection);
    } else {
        isMemberSection = ((section == kOrigoSection + 1) && [_regularMemberships count]);
    }
    
    return isMemberSection;
}


#pragma mark - State handling

- (void)setState
{
    [OState s].actionIsList = YES;
    [OState s].targetIsMember = YES;
    [[OState s] setAspectForOrigo:_origo];
}


- (void)restoreStateIfNeeded
{
    if (![self isBeingPresented] && ![self isMovingToParentViewController]) {
        [self setState];
    }
}


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
    
    [self setState];
    
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
    
    _contactMemberships = [[NSMutableSet alloc] init];
    _regularMemberships = [[NSMutableSet alloc] init];
    
    for (OMembership *membership in _origo.memberships) {
        if ([membership hasContactRole]) {
            [_contactMemberships addObject:membership];
        } else {
            [_regularMemberships addObject:membership];
        }
    }
    
    _sortedContactMemberships = [[_contactMemberships allObjects] sortedArrayUsingSelector:@selector(compare:)];
    _sortedRegularMemberships = [[_regularMemberships allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self restoreStateIfNeeded];
    
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
        [OState s].actionIsRegister = YES;
        
        UINavigationController *navigationController = segue.destinationViewController;
        OMemberViewController *memberViewController = navigationController.viewControllers[0];
        memberViewController.delegate = self;
        memberViewController.origo = _origo;
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


#pragma mark - UITableViewDataSource conformance

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numberOfSections = kDefaultNumberOfSections;
    
    if (![_contactMemberships count] || ![_regularMemberships count]) {
        numberOfSections = kReducedNumberOfSections;
    }
    
	return numberOfSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger numberOfRows = 0;
    
    NSUInteger numberOfContacts = [_contactMemberships count];
    NSUInteger numberOfMembers = [_regularMemberships count];
    
    if (section == kOrigoSection) {
        numberOfRows = 1;
    } else if (section == kMemberSection) {
        numberOfRows = numberOfMembers;
    } else {
        if (numberOfContacts) {
            numberOfRows = numberOfContacts;
        } else if (numberOfMembers) {
            numberOfRows = numberOfMembers;
        }
    }
    
	return numberOfRows;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0;
    
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
        OMembership *membership = nil;
        
        if ([self sectionIsContactSection:indexPath.section]) {
            membership = _sortedContactMemberships[indexPath.row];
        } else {
            membership = _sortedRegularMemberships[indexPath.row];
        }
        
        cell = [tableView listCellForEntity:membership.member];
    }
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDeleteRow = NO;
    
    if (indexPath.section != kOrigoSection) {
        OMembership *membershipForRow = nil;
        
        if ([self sectionIsContactSection:indexPath.section]) {
            membershipForRow = _sortedContactMemberships[indexPath.row];
        } else if ([self sectionIsMemberSection:indexPath.section]) {
            membershipForRow = _sortedRegularMemberships[indexPath.row];
        }
        
        canDeleteRow = ([_origo userIsAdmin] && ![membershipForRow.member isUser]);
    }
    
    return canDeleteRow;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        OMembership *revokedMembership = nil;
        
        if ([self sectionIsContactSection:indexPath.section]) {
            revokedMembership = _sortedContactMemberships[indexPath.row];
            
            [_contactMemberships removeObject:revokedMembership];
            _sortedContactMemberships = [[_contactMemberships allObjects] sortedArrayUsingSelector:@selector(compare:)];
        } else if ([self sectionIsMemberSection:indexPath.section]) {
            revokedMembership = _sortedRegularMemberships[indexPath.row];
            
            [_regularMemberships removeObject:revokedMembership];
            _sortedRegularMemberships = [[_regularMemberships allObjects] sortedArrayUsingSelector:@selector(compare:)];
        }
        
        [[OMeta m].context deleteEntity:revokedMembership];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


#pragma mark - UITableViewDelegate conformance

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = kDefaultPadding;
    
    if (section > kOrigoSection) {
        height = [tableView standardHeaderHeight];
    }
    
    return height;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = kDefaultPadding;
    
    if ([self sectionIsMemberSection:section] && [_origo userIsAdmin]) {
        height = [tableView standardFooterHeight];
    }
    
    return height;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = nil;
    
    if ([self sectionIsContactSection:section]) {
        headerView = [tableView headerViewWithText:[OStrings stringForKey:strHeaderContacts]];
    } else if ([self sectionIsMemberSection:section]) {
        if ([_origo isResidence]) {
            headerView = [tableView headerViewWithText:[OStrings stringForKey:strHeaderHouseholdMembers]];
        } else {
            headerView = [tableView headerViewWithText:[OStrings stringForKey:strHeaderOrigoMembers]];
        }
    }
    
    return headerView;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = nil;
    
    if ([self sectionIsMemberSection:section] && [_origo userIsAdmin]) {
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
        if ([self sectionIsContactSection:indexPath.section]) {
            _selectedMembership = _sortedContactMemberships[indexPath.row];
        } else if ([self sectionIsMemberSection:indexPath.section]) {
            _selectedMembership = _sortedRegularMemberships[indexPath.row];
        }
        
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
    if ([identitifier isEqualToString:kMemberViewControllerId]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}


- (void)insertEntityInTableView:(OReplicatedEntity *)entity
{
    NSInteger section;
    NSInteger row;
    BOOL sectionIsNew = NO;
    
    OMembership *membership = (OMembership *)entity;
    
    if ([membership hasContactRole]) {
        [_contactMemberships addObject:membership];
        _sortedContactMemberships = [[_contactMemberships allObjects] sortedArrayUsingSelector:@selector(compare:)];
        
        section = kContactSection;
        row = [_sortedContactMemberships indexOfObject:membership];
        sectionIsNew = ![_sortedContactMemberships count];
    } else {
        [_regularMemberships addObject:membership];
        _sortedRegularMemberships = [[_regularMemberships allObjects] sortedArrayUsingSelector:@selector(compare:)];
        
        section = [_contactMemberships count] ? kMemberSection : kMemberSection - 1;
        row = [_sortedRegularMemberships indexOfObject:membership];
        sectionIsNew = ![_sortedRegularMemberships count];
    }

    if (sectionIsNew) {
        [self.tableView insertRowInNewSection:section];
    } else {
        [self.tableView insertRow:row inSection:section];
    }
}

@end
