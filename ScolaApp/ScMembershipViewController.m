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
#import "ScStrings.h"
#import "ScTableViewCell.h"

#import "ScMember.h"
#import "ScMembership.h"
#import "ScScola.h"

#import "ScCachedEntity+ScCachedEntityExtensions.h"
#import "ScMember+ScMemberExtensions.h"
#import "ScScola+ScScolaExtensions.h"

#import "ScMemberViewController.h"
#import "ScScolaViewController.h"

static NSString * const kSegueToMemberView = @"membershipToMemberView";
static NSString * const kSegueToScolaView = @"membershipToScolaView";

static NSInteger const kAddressSection = 0;
static NSInteger const kAdultsSection = 1;
static NSInteger const kMinorsSection = 2;


@interface ScMembershipViewController () {
    NSString *_longTitle;
    UIBarButtonItem *_addButton;
    
    NSMutableSet *_adminIds;
    NSMutableSet *_unsortedAdults;
    NSMutableSet *_unsortedMinors;
    NSArray *_adults;
    NSArray *_minors;
    
    BOOL _isUserScolaAdmin;
    BOOL _isViewModallyHidden;
    BOOL _needsSynchronisation;
    
    ScMembership *_selectedMembership;
}

@end


@implementation ScMembershipViewController

#pragma mark - State shorthands

- (BOOL)isDisplaying
{
    ScAppState_ appState = [ScMeta appState_];
    
    BOOL isDisplaying = 
        (appState == ScAppStateDisplayUserHouseholdMemberships) ||
        (appState == ScAppStateDisplayScolaMemberships) ||
        (appState == ScAppStateDisplayScolaMemberHouseholdMemberships);
    
    return isDisplaying;
}


- (BOOL)isRegistering
{
    ScAppState_ appState = [ScMeta appState_];
    
    BOOL isRegistering =
        (appState == ScAppStateRegisterUserHouseholdMemberships) ||
        (appState == ScAppStateRegisterScolaMemberships) ||
        (appState == ScAppStateRegisterScolaMemberHouseholdMemberships);
    
    return  isRegistering;
}


- (BOOL)isForHousehold
{
    ScAppState_ appState = [ScMeta appState_];
    
    BOOL isForHousehold =
        (appState == ScAppStateRegisterUserHouseholdMemberships) ||
        (appState == ScAppStateRegisterScolaMemberHouseholdMemberships) ||
        (appState == ScAppStateDisplayUserHouseholdMemberships) ||
        (appState == ScAppStateDisplayScolaMemberHouseholdMemberships);
    
    return isForHousehold;
}


- (BOOL)isForUser
{
    ScAppState_ appState = [ScMeta appState_];
    
    BOOL isForUser =
        (appState == ScAppStateRegisterUserHouseholdMemberships) ||
        (appState == ScAppStateDisplayUserHouseholdMemberships);
    
    return isForUser;
}


#pragma mark - Selector implementations

- (void)addMembership
{
    ScMemberViewController *memberViewController = [self.storyboard instantiateViewControllerWithIdentifier:kMemberViewControllerId];
    memberViewController.delegate = self;
    memberViewController.scola = _scola;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:memberViewController];
    
    if ([self isForUser] && [self isForHousehold]) {
        [ScMeta pushAppState:ScAppStateRegisterUserHouseholdMember];
    } else if ([self isForHousehold]) {
        [ScMeta pushAppState:ScAppStateRegisterScolaMemberHouseholdMember];
    } else {
        [ScMeta pushAppState:ScAppStateRegisterScolaMember];
    }
    
    [self.navigationController presentViewController:navigationController animated:YES completion:NULL];
    
    _isViewModallyHidden = YES;
}


- (void)didFinishEditing
{
    if (_needsSynchronisation) {
        [[ScMeta m].managedObjectContext synchronise];
        
        _needsSynchronisation = NO;
    }
    
    if ([self isRegistering]) {
        [_delegate shouldDismissViewControllerWithIdentitifier:kMemberViewControllerId];
    }
}


#pragma mark - View lifecycle

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:kDarkLinenImageFile]];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    _adminIds = [[NSMutableSet alloc] init];
    _unsortedAdults = [[NSMutableSet alloc] init];
    _unsortedMinors = [[NSMutableSet alloc] init];
    
    for (ScMembership *membership in _scola.memberships) {
        if ([[membership isAdmin] boolValue]) {
            [_adminIds addObject:membership.member.entityId];
            
            if ([membership.member.entityId isEqualToString:[ScMeta m].userId]) {
                _isUserScolaAdmin = YES;
            }
        }
             
        if ([membership.member isMinor]) {
            [_unsortedMinors addObject:membership];
        } else {
            [_unsortedAdults addObject:membership];
        }
    }
    
    _adults = [[_unsortedAdults allObjects] sortedArrayUsingSelector:@selector(compare:)];
    _minors = [[_unsortedMinors allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    if ([self isForUser]) {
        if ([_scola hasMultipleResidents]) {
            _longTitle = [ScStrings stringForKey:strMembershipViewTitleOurPlace];
        } else {
            _longTitle = [ScStrings stringForKey:strMembershipViewTitleMyPlace];
        }
        
        if ([self isRegistering]) {
            self.title = _longTitle;
        } else {
            self.title = [ScStrings stringForKey:strHousehold];
        }
    } else {
        self.title = [ScStrings stringForKey:strMembershipViewTitleDefault];
    }
    
    if (_isUserScolaAdmin) {
        _addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMembership)];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self isRegistering]) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didFinishEditing)];
        
        self.navigationItem.leftBarButtonItem = doneButton;
        self.navigationItem.rightBarButtonItem = _addButton;
    } else {
        self.tabBarController.title = [self isForHousehold] ? _longTitle : self.title;
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
    if ([segue.identifier isEqualToString:kSegueToScolaView]) {
        ScScolaViewController *scolaViewController = segue.destinationViewController;
        scolaViewController.scola = _scola;
        
        if ([self isForUser] && [self isForHousehold]) {
            [ScMeta pushAppState:ScAppStateDisplayUserHousehold];
        } else if ([self isForHousehold]) {
            [ScMeta pushAppState:ScAppStateDisplayScolaMemberHousehold];
        } else {
            [ScMeta pushAppState:ScAppStateDisplayScola];
        }
    } else if ([segue.identifier isEqualToString:kSegueToMemberView]) {
        ScMemberViewController *memberViewController = segue.destinationViewController;
        memberViewController.membership = _selectedMembership;
        
        if ([self isForUser] && [self isForHousehold]) {
            [ScMeta pushAppState:ScAppStateDisplayUserHouseholdMember];
        } else if ([self isForHousehold]) {
            [ScMeta pushAppState:ScAppStateDisplayScolaMemberHouseholdMember];
        } else {
            [ScMeta pushAppState:ScAppStateDisplayScolaMember];
        }
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
    
    if (section == kAddressSection) {
        numberOfRows = 1;
    } else if (section == kAdultsSection) {
        numberOfRows = [_adults count];
    } else if (section == kMinorsSection) {
        numberOfRows = [_minors count];
    }
    
	return numberOfRows;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height;
    
    if (indexPath.section == kAddressSection) {
        height = [ScTableViewCell heightForEntity:_scola editing:NO];
    } else {
        height = 1.1f * self.tableView.rowHeight;
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
        NSArray *memberships = (indexPath.section == kAdultsSection) ? _adults : _minors;
        ScMembership *membership = [memberships objectAtIndex:indexPath.row];
        
        cell = [tableView cellWithReuseIdentifier:kReuseIdentifierDefault];
        cell.textLabel.text = membership.member.name;
        cell.detailTextLabel.text = membership.member.mobilePhone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        ScMembership *membershipToDelete = nil;
        
        if (indexPath.section == kAdultsSection) {
            membershipToDelete = [_adults objectAtIndex:indexPath.row];
            
            [_unsortedAdults removeObject:membershipToDelete];
            _adults = [[_unsortedAdults allObjects] sortedArrayUsingSelector:@selector(compare:)];
        } else if (indexPath.section == kMinorsSection) {
            membershipToDelete = [_minors objectAtIndex:indexPath.row];
            
            [_unsortedMinors removeObject:membershipToDelete];
            _minors = [[_unsortedMinors allObjects] sortedArrayUsingSelector:@selector(compare:)];
        }
        
        [[ScMeta m].managedObjectContext deleteEntity:membershipToDelete];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        _needsSynchronisation = YES;
    }   
}


#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = kDefaultSectionHeaderHeight;
    
    if (section == kAdultsSection) {
        height = [tableView standardHeaderHeight];
    } else if ((section == kMinorsSection) && (![_minors count])) {
        height = kMinimumSectionHeaderHeight;
    }
    
    return height;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = kDefaultSectionFooterHeight;

    if (section == kAdultsSection) {
        if ([_adults count] && [_minors count]) {
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
    
    if (section == kAdultsSection) {
        headerView = [tableView headerViewWithTitle:[ScStrings stringForKey:strHouseholdMembers]];
    }
    
    return headerView;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = nil;
    
    if ((section == kMinorsSection) && _isUserScolaAdmin) {
        footerView = [tableView footerViewWithText:[ScStrings stringForKey:strHouseholdMemberListFooter]];
    }
    
    return footerView;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{   
    NSInteger numberOfRowsInSection = 1;
    
    if (indexPath.section == kAdultsSection) {
        numberOfRowsInSection = [_adults count];
    } else if (indexPath.section == kMinorsSection) {
        numberOfRowsInSection = [_minors count];
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
        if (indexPath.section == kAdultsSection) {
            _selectedMembership = [_adults objectAtIndex:indexPath.row];
        } else if (indexPath.section == kMinorsSection) {
            _selectedMembership = [_minors objectAtIndex:indexPath.row];
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
    [self dismissViewControllerAnimated:YES completion:NULL];
    [ScMeta popAppState];
    
    _isViewModallyHidden = NO;
}


- (void)insertMembershipInTableView:(ScMembership *)membership
{
    NSInteger section;
    NSInteger row;
    
    if ([membership.member isMinor]) {
        [_unsortedMinors addObject:membership];
        _minors = [[_unsortedMinors allObjects] sortedArrayUsingSelector:@selector(compare:)];
        
        section = kMinorsSection;
        row = [_minors indexOfObject:membership];
    } else {
        [_unsortedAdults addObject:membership];
        _adults = [[_unsortedAdults allObjects] sortedArrayUsingSelector:@selector(compare:)];
        
        section = kAdultsSection;
        row = [_adults indexOfObject:membership];
    }
    
    [self.tableView insertCellForRow:row inSection:section];
    
    _needsSynchronisation = YES;
}

@end
