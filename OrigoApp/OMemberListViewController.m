//
//  OMemberListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMemberListViewController.h"

#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"
#import "UIColor+OColorExtensions.h"
#import "UITableView+OTableViewExtensions.h"
#import "UIView+OViewExtensions.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"

#import "OMember.h"
#import "OMembership.h"
#import "OOrigo.h"
#import "OLinkedEntityRef.h"

#import "OMember+OMemberExtensions.h"
#import "OMembership+OMembershipExtensions.h"
#import "OOrigo+OOrigoExtensions.h"
#import "OReplicatedEntity+OReplicatedEntityExtensions.h"

#import "OMemberViewController.h"
#import "OOrigoViewController.h"

static NSString * const kSegueToMemberView = @"memberListToMemberView";
static NSString * const kSegueToOrigoView = @"memberListToOrigoView";

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
    
    if ([_contacts count] && [_members count]) {
        isContactSection = (section = kContactSection);
    } else {
        isContactSection = ((section == kOrigoSection + 1) && [_contacts count]);
    }
    
    return isContactSection;
}


- (BOOL)sectionIsMemberSection:(NSInteger)section
{
    BOOL isMemberSection = NO;
    
    if ([_contacts count] && [_members count]) {
        isMemberSection = (section == kMemberSection);
    } else {
        isMemberSection = ((section == kOrigoSection + 1) && [_members count]);
    }
    
    return isMemberSection;
}


#pragma mark - Selector implementations

- (void)addMember
{
    [OState s].actionIsRegister = YES;
    [OState s].aspectIsExternal = YES;
    
    OMemberViewController *memberViewController = [self.storyboard instantiateViewControllerWithIdentifier:kMemberViewControllerId];
    memberViewController.delegate = self;
    memberViewController.origo = _origo;
    
    UINavigationController *modalController = [[UINavigationController alloc] initWithRootViewController:memberViewController];
    modalController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self.navigationController presentViewController:modalController animated:YES completion:NULL];
}


- (void)didFinishAdding
{
    if (_needsReplication) {
        [[OMeta m].context replicate];
        
        _needsReplication = NO;
    }
    
    if (_delegate) {
        [_delegate dismissViewControllerWithIdentitifier:kMemberListViewControllerId];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _aspect = [OState s].aspect;
    
    [self.tableView setBackground];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    if ([_origo isResidence]) {
        if ([OState s].aspectIsSelf) {
            self.title = [OStrings stringForKey:strMyHousehold];
        } else {
            self.title = [OStrings stringForKey:strViewTitleHousehold];
        }
    } else {
        self.title = [OStrings stringForKey:strViewTitleMembers];
    }
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMember)];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didFinishAdding)];
    
    if ([_origo userIsAdmin]) {
        self.navigationItem.rightBarButtonItem = addButton;
        
        if (_delegate) {
            self.navigationItem.leftBarButtonItem = doneButton;
        }
    }
    
    _contacts = [[NSMutableSet alloc] init];
    _members = [[NSMutableSet alloc] init];
    
    for (OMembership *membership in _origo.memberships) {
        if ([membership hasContactRole]) {
            [_contacts addObject:membership];
        } else {
            [_members addObject:membership];
        }
    }
    
    _sortedContacts = [[_contacts allObjects] sortedArrayUsingSelector:@selector(compare:)];
    _sortedMembers = [[_members allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [OState s].targetIsMember = YES;
    [OState s].actionIsList = YES;
    [OState s].aspect = _aspect;
    
    OLogState;
}


- (void)viewWillDisappear:(BOOL)animated
{
    if (_needsReplication && !self.navigationController.presentedViewController) {
        [self didFinishAdding];
    }
    
	[super viewWillDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToOrigoView]) {
        OOrigoViewController *origoViewController = segue.destinationViewController;
        origoViewController.origo = _origo;
    } else if ([segue.identifier isEqualToString:kSegueToMemberView]) {
        OMemberViewController *memberViewController = segue.destinationViewController;
        memberViewController.membership = _selectedMembership;
    }
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numberOfSections = kDefaultNumberOfSections;
    
    if (![_contacts count] || ![_members count]) {
        numberOfSections = kReducedNumberOfSections;
    }
    
	return numberOfSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger numberOfRows = 0;
    
    NSUInteger numberOfContacts = [_contacts count];
    NSUInteger numberOfMembers = [_members count];
    
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
    CGFloat height;
    
    if (indexPath.section == kOrigoSection) {
        height = [OTableViewCell heightForEntity:_origo];
    } else {
        height = [OTableViewCell defaultHeight];
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTableViewCell *cell = nil;
    
    if (indexPath.section == kOrigoSection) {
        cell = [tableView cellForEntity:_origo];
        
        if ([_origo userIsAdmin]) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else {
        NSArray *memberships = [self sectionIsContactSection:indexPath.section] ? _sortedContacts : _sortedMembers;
        OMembership *membership = memberships[indexPath.row];
        
        cell = [tableView cellWithReuseIdentifier:kReuseIdentifierDefault];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = membership.member.name_;
        cell.detailTextLabel.text = [membership.member details];
        cell.imageView.image = [membership.member image];
    }
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDeleteRow = NO;
    
    if (indexPath.section != kOrigoSection) {
        OMembership *membershipForRow = nil;
        
        if ([self sectionIsContactSection:indexPath.section]) {
            membershipForRow = _sortedContacts[indexPath.row];
        } else if ([self sectionIsMemberSection:indexPath.section]) {
            membershipForRow = _sortedMembers[indexPath.row];
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
            revokedMembership = _sortedContacts[indexPath.row];
            
            [_contacts removeObject:revokedMembership];
            _sortedContacts = [[_contacts allObjects] sortedArrayUsingSelector:@selector(compare:)];
        } else if ([self sectionIsMemberSection:indexPath.section]) {
            revokedMembership = _sortedMembers[indexPath.row];
            
            [_members removeObject:revokedMembership];
            _sortedMembers = [[_members allObjects] sortedArrayUsingSelector:@selector(compare:)];
        }
        
        [[OMeta m].context deleteEntity:revokedMembership];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        _needsReplication = YES;
    }   
}


#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = kMinimumSectionHeaderHeight;
    
    if (section == kOrigoSection) {
        height = kDefaultSectionHeaderHeight;
    } else {
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
    
    if ([self sectionIsContactSection:section]) {
        headerView = [tableView headerViewWithTitle:[OStrings stringForKey:strSectionHeaderContacts]];
    } else if ([self sectionIsMemberSection:section]) {
        if ([_origo isResidence]) {
            headerView = [tableView headerViewWithTitle:[OStrings stringForKey:strSectionHeaderHouseholdMembers]];
        } else {
            headerView = [tableView headerViewWithTitle:[OStrings stringForKey:strSectionHeaderOrigoMembers]];
        }
    }
    
    return headerView;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = nil;
    
    if ([self sectionIsMemberSection:section] && [_origo userIsAdmin]) {
        footerView = [tableView footerViewWithText:[OStrings stringForKey:strHouseholdMemberListFooter]];
    }
    
    return footerView;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{   
    NSUInteger numberOfRowsInSection = 1;
    
    if ([self sectionIsContactSection:indexPath.section]) {
        numberOfRowsInSection = [_contacts count];
    } else if ([self sectionIsMemberSection:indexPath.section]) {
        numberOfRowsInSection = [_members count];
    }
    
    BOOL isLastRowInSection = (indexPath.row == numberOfRowsInSection - 1);
    
    if (isLastRowInSection) {
        [cell.backgroundView addShadowForBottomTableViewCell];
    } else {
        [cell.backgroundView addShadowForContainedTableViewCell];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kOrigoSection) {
        [self performSegueWithIdentifier:kSegueToOrigoView sender:self];
    } else {
        if ([self sectionIsContactSection:indexPath.section]) {
            _selectedMembership = _sortedContacts[indexPath.row];
        } else if ([self sectionIsMemberSection:indexPath.section]) {
            _selectedMembership = _sortedMembers[indexPath.row];
        }
        
        if ([_selectedMembership.member isUser]) {
            [OState s].aspectIsSelf = YES;
        } else {
            [OState s].aspectIsExternal = YES;
        }
        
        [self performSegueWithIdentifier:kSegueToMemberView sender:self];
    }
}


- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [OStrings stringForKey:strDeleteConfirmation];
}


#pragma mark - OModalInputViewControllerDelegate methods

- (void)dismissViewControllerWithIdentitifier:(NSString *)identitifier
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
        [_contacts addObject:membership];
        _sortedContacts = [[_contacts allObjects] sortedArrayUsingSelector:@selector(compare:)];
        
        section = kContactSection;
        row = [_sortedContacts indexOfObject:membership];
        sectionIsNew = ![_sortedContacts count];
    } else {
        [_members addObject:membership];
        _sortedMembers = [[_members allObjects] sortedArrayUsingSelector:@selector(compare:)];
        
        section = [_contacts count] ? kMemberSection : kMemberSection - 1;
        row = [_sortedMembers indexOfObject:membership];
        sectionIsNew = ![_sortedMembers count];
    }

    if (sectionIsNew) {
        [self.tableView insertRowInNewSection:section];
    } else {
        [self.tableView insertRow:row inSection:section];
    }
    
    _needsReplication = YES;
}

@end
