//
//  ScMembershipViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 17.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMembershipViewController.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "UIColor+ScColorExtensions.h"
#import "UITableView+UITableViewExtensions.h"
#import "UIView+ScViewExtensions.h"

#import "ScLogging.h"
#import "ScMeta.h"
#import "ScState.h"
#import "ScStrings.h"
#import "ScTableViewCell.h"

#import "ScMember.h"
#import "ScMembership.h"
#import "ScScola.h"

#import "ScCachedEntity+ScCachedEntityExtensions.h"
#import "ScMember+ScMemberExtensions.h"
#import "ScMembership+ScMembershipExtensions.h"
#import "ScScola+ScScolaExtensions.h"

#import "ScMemberViewController.h"
#import "ScScolaViewController.h"

static NSString * const kSegueToMemberView = @"membershipToMemberView";
static NSString * const kSegueToScolaView = @"membershipToScolaView";

static NSInteger const kNumberOfSections = 3;
static NSInteger const kAddressSection = 0;
static NSInteger const kContactSection = 1;
static NSInteger const kMemberSection = 2;


@implementation ScMembershipViewController

#pragma mark - Selector implementations

- (void)addMember
{
    ScMemberViewController *memberViewController = [self.storyboard instantiateViewControllerWithIdentifier:kMemberViewControllerId];
    memberViewController.delegate = self;
    memberViewController.scola = _scola;
    
    [ScState s].action = ScStateActionRegister;
    [ScState s].target = ScStateTargetMember;
    
    UINavigationController *modalController = [[UINavigationController alloc] initWithRootViewController:memberViewController];
    modalController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self.navigationController presentViewController:modalController animated:YES completion:NULL];
    
    _isViewModallyHidden = YES;
}


- (void)didFinishEditing
{
    if (_needsSynchronisation) {
        [[ScMeta m].context synchroniseCacheWithServer];
        
        _needsSynchronisation = NO;
    }
    
    if ([ScState s].actionIsRegister) {
        [_delegate shouldDismissViewControllerWithIdentitifier:kMembershipViewControllerId];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[ScState s] saveCurrentStateForViewController:kMembershipViewControllerId];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    [self.tableView addBackground];
    
    _contacts = [[NSMutableSet alloc] init];
    _members = [[NSMutableSet alloc] init];
    
    for (ScMembership *membership in _scola.memberships) {
        if ([membership.member isUser] && ([membership.isAdmin boolValue])) {
            _isUserScolaAdmin = YES;
        }
             
        if ([membership hasContactRole]) {
            [_contacts addObject:membership];
        } else {
            [_members addObject:membership];
        }
    }
    
    _sortedContacts = [[_contacts allObjects] sortedArrayUsingSelector:@selector(compare:)];
    _sortedMembers = [[_members allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    if ([_scola isResidence] && [ScState s].aspectIsSelf) {
        if ([_scola.residencies count] > 1) {
            _longTitle = [ScStrings stringForKey:strMembershipViewTitleOurPlace];
        } else {
            _longTitle = [ScStrings stringForKey:strMembershipViewTitleMyPlace];
        }
        
        if ([ScState s].actionIsRegister) {
            self.title = _longTitle;
        } else {
            self.title = [ScStrings stringForKey:strHousehold];
        }
    } else {
        self.title = [ScStrings stringForKey:strMembershipViewTitleDefault];
    }
    
    if (_isUserScolaAdmin) {
        _addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMember)];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[ScState s] revertToSavedStateForViewController:kMembershipViewControllerId];
    ScLogState;
    
    if ([ScState s].actionIsRegister) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didFinishEditing)];
        
        self.navigationItem.leftBarButtonItem = doneButton;
        self.navigationItem.rightBarButtonItem = _addButton;
    } else {
        self.tabBarController.title = [_scola isResidence] ? _longTitle : self.title;
        self.tabBarController.navigationItem.rightBarButtonItem = _addButton;
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    if (_needsSynchronisation && !_isViewModallyHidden) {
        [self didFinishEditing];
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
    [ScState s].action = ScStateActionDisplay;
    
    if ([segue.identifier isEqualToString:kSegueToScolaView]) {
        ScScolaViewController *scolaViewController = segue.destinationViewController;
        scolaViewController.scola = _scola;
        
        if ([_scola isResidence]) {
            [ScState s].target = ScStateTargetResidence;
        } else {
            [ScState s].target = ScStateTargetScola;
        }
    } else if ([segue.identifier isEqualToString:kSegueToMemberView]) {
        ScMemberViewController *memberViewController = segue.destinationViewController;
        memberViewController.membership = _selectedMembership;
        
        [ScState s].target = ScStateTargetMember;
    }
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return kNumberOfSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    if (section == kAddressSection) {
        numberOfRows = 1;
    } else if (section == kContactSection) {
        numberOfRows = [_sortedContacts count];
    } else if (section == kMemberSection) {
        numberOfRows = [_sortedMembers count];
    }
    
	return numberOfRows;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height;
    
    if (indexPath.section == kAddressSection) {
        height = [ScTableViewCell heightForEntity:_scola];
    } else {
        height = [ScTableViewCell defaultHeight];
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ScTableViewCell *cell = nil;
    
    if (indexPath.section == kAddressSection) {
        cell = [tableView cellForEntity:_scola];
        
        if (_isUserScolaAdmin) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else {
        NSArray *memberships = (indexPath.section == kContactSection) ? _sortedContacts : _sortedMembers;
        ScMembership *membership = [memberships objectAtIndex:indexPath.row];
        
        cell = [tableView cellWithReuseIdentifier:kReuseIdentifierDefault];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = membership.member.name;
        cell.detailTextLabel.text = [membership.member details];
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        ScMembership *membershipToDelete = nil;
        
        if (indexPath.section == kContactSection) {
            membershipToDelete = [_sortedContacts objectAtIndex:indexPath.row];
            
            [_contacts removeObject:membershipToDelete];
            _sortedContacts = [[_contacts allObjects] sortedArrayUsingSelector:@selector(compare:)];
        } else if (indexPath.section == kMemberSection) {
            membershipToDelete = [_sortedMembers objectAtIndex:indexPath.row];
            
            [_members removeObject:membershipToDelete];
            _sortedMembers = [[_members allObjects] sortedArrayUsingSelector:@selector(compare:)];
        }
        
        [[ScMeta m].context deleteEntityFromCache:membershipToDelete];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        _needsSynchronisation = YES;
    }   
}


#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = kDefaultSectionHeaderHeight;
    
    if (section == kContactSection) {
        height = [tableView standardHeaderHeight];
    } else if ((section == kMemberSection) && (![_sortedMembers count])) {
        height = kMinimumSectionHeaderHeight;
    }
    
    return height;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = kDefaultSectionFooterHeight;

    if (section == kContactSection) {
        if ([_sortedContacts count] && [_sortedMembers count]) {
            height = kSectionSpacing;
        } else {
            height = kMinimumSectionFooterHeight;
        }
    }
    
    return height;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = nil;
    
    if (section == kContactSection) {
        headerView = [tableView headerViewWithTitle:[ScStrings stringForKey:strHouseholdMembers]];
    }
    
    return headerView;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = nil;
    
    if ((section == kMemberSection) && _isUserScolaAdmin) {
        footerView = [tableView footerViewWithText:[ScStrings stringForKey:strHouseholdMemberListFooter]];
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
        [cell.backgroundView addShadowForNonBottomTableViewCell];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kAddressSection) {
        [self performSegueWithIdentifier:kSegueToScolaView sender:self];
    } else {
        if (indexPath.section == kContactSection) {
            _selectedMembership = [_sortedContacts objectAtIndex:indexPath.row];
        } else if (indexPath.section == kMemberSection) {
            _selectedMembership = [_sortedMembers objectAtIndex:indexPath.row];
        }
        
        [self performSegueWithIdentifier:kSegueToMemberView sender:self];
    }
}


- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *deleteConfirmationTitle = nil;
    
    if (indexPath.section != kAddressSection) {
        deleteConfirmationTitle = [ScStrings stringForKey:strDeleteConfirmation];
    }
    
    return deleteConfirmationTitle;
}


#pragma mark - ScMemberViewControllerDelegate methods

- (void)shouldDismissViewControllerWithIdentitifier:(NSString *)identitifier
{
    if ([identitifier isEqualToString:kMemberViewControllerId]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
        [ScState s].target = ScStateTargetMemberships;
        
        _isViewModallyHidden = NO;
    }
}


- (void)insertMembershipInTableView:(ScMembership *)membership
{
    NSInteger section;
    NSInteger row;
    
    if ([membership hasContactRole]) {
        [_contacts addObject:membership];
        _sortedContacts = [[_contacts allObjects] sortedArrayUsingSelector:@selector(compare:)];
        
        section = kContactSection;
        row = [_sortedContacts indexOfObject:membership];
    } else {
        [_members addObject:membership];
        _sortedMembers = [[_members allObjects] sortedArrayUsingSelector:@selector(compare:)];
        
        section = kMemberSection;
        row = [_sortedMembers indexOfObject:membership];
    }
    
    [self.tableView insertCellForRow:row inSection:section];
    
    _needsSynchronisation = YES;
}

@end
