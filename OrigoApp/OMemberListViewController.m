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

#import "OCachedEntity+OCachedEntityExtensions.h"
#import "OMember+OMemberExtensions.h"
#import "OMembership+OMembershipExtensions.h"
#import "OOrigo+OOrigoExtensions.h"

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
    if (_needsSynchronisation) {
        [[OMeta m].context synchroniseCacheWithServer];
        
        _needsSynchronisation = NO;
    }
    
    if (_delegate) {
        [_delegate dismissViewControllerWithIdentitifier:kMemberListViewControllerId];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setBackground];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    if ([_origo isResidence]) {
        if ([OState s].aspectIsSelf) {
            self.title = [OStrings stringForKey:strMyHousehold];
        } else {
            self.title = [OStrings stringForKey:strMemberListViewTitleHousehold];
        }
    } else {
        self.title = [OStrings stringForKey:strMemberListViewTitleDefault];
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
    
    _aspect = [OState s].aspect;
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
    if (_needsSynchronisation && !self.navigationController.presentedViewController) {
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
    
    if (![_sortedContacts count] || ![_sortedMembers count]) {
        numberOfSections = kReducedNumberOfSections;
    }
    
	return numberOfSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    NSInteger numberOfContacts = [_contacts count];
    NSInteger numberOfMembers = [_members count];
    
    if (section == kOrigoSection) {
        numberOfRows = 1;
    } else if (section == kMemberSection) {
        numberOfRows = numberOfMembers;
    } else {
        if ([_sortedContacts count]) {
            numberOfRows = numberOfContacts;
        } else if ([_sortedMembers count]) {
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
        NSArray *memberships = (indexPath.section == kContactSection) ? _sortedContacts : _sortedMembers;
        OMembership *membership = memberships[indexPath.row];
        
        cell = [tableView cellWithReuseIdentifier:kReuseIdentifierDefault];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = membership.member.name_;
        cell.detailTextLabel.text = [membership.member details];
        cell.imageView.image = [membership.member image];
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        OMembership *membershipToDelete = nil;
        
        if (indexPath.section == kContactSection) {
            membershipToDelete = _sortedContacts[indexPath.row];
            
            [_contacts removeObject:membershipToDelete];
            _sortedContacts = [[_contacts allObjects] sortedArrayUsingSelector:@selector(compare:)];
        } else if (indexPath.section == kMemberSection) {
            membershipToDelete = _sortedMembers[indexPath.row];
            
            [_members removeObject:membershipToDelete];
            _sortedMembers = [[_members allObjects] sortedArrayUsingSelector:@selector(compare:)];
        }
        
        [[OMeta m].context deleteEntityFromCache:membershipToDelete];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        _needsSynchronisation = YES;
    }   
}


#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = kMinimumSectionHeaderHeight;
    
    if (section == kOrigoSection) {
        height = kDefaultSectionHeaderHeight;
    } else if (section == kContactSection) {
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
    
    if (section == kContactSection) {
        headerView = [tableView headerViewWithTitle:[OStrings stringForKey:strHouseholdMembers]];
    }
    
    return headerView;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = nil;
    
    BOOL lastSection = ([_sortedContacts count] && [_sortedMembers count]) ? 2 : 1;
    
    if ((section == lastSection) && [_origo userIsAdmin]) {
        BOOL hasFooter = (section == kMemberSection);
        hasFooter = hasFooter || (![_sortedContacts count] || ![_sortedMembers count]);
        
        if (hasFooter) {
            footerView = [tableView footerViewWithText:[OStrings stringForKey:strHouseholdMemberListFooter]];
        }
    }
    
    return footerView;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{   
    NSInteger numberOfRowsInSection = 1;
    
    if (indexPath.section == kContactSection) {
        numberOfRowsInSection = [_sortedContacts count];
    } else if (indexPath.section == kMemberSection) {
        numberOfRowsInSection = [_sortedMembers count];
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
        if (indexPath.section == kContactSection) {
            _selectedMembership = _sortedContacts[indexPath.row];
        } else if (indexPath.section == kMemberSection) {
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
    NSString *deleteConfirmationTitle = nil;
    
    if (indexPath.section != kOrigoSection) {
        deleteConfirmationTitle = [OStrings stringForKey:strDeleteConfirmation];
    }
    
    return deleteConfirmationTitle;
}


#pragma mark - OMemberViewControllerDelegate methods

- (void)dismissViewControllerWithIdentitifier:(NSString *)identitifier
{
    if ([identitifier isEqualToString:kMemberViewControllerId]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}


- (void)insertEntityInTableView:(OCachedEntity *)entity
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
        
        section = kMemberSection;
        row = [_sortedMembers indexOfObject:membership];
        sectionIsNew = ![_sortedMembers count];
    }

    if (sectionIsNew) {
        [self.tableView insertRowInNewSection:section];
    } else {
        [self.tableView insertRow:row inSection:section];
    }
    
    _needsSynchronisation = YES;
}

@end
