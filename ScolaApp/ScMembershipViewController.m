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
#import "ScScola+ScScolaExtensions.h"

#import "ScMemberViewController.h"
#import "ScScolaViewController.h"

static NSString * const kSegueToMemberView = @"membershipToMemberView";
static NSString * const kSegueToScolaView = @"membershipToScolaView";

static NSInteger const kNumberOfSections = 3;
static NSInteger const kAddressSection = 0;
static NSInteger const kAdultsSection = 1;
static NSInteger const kMinorsSection = 2;


@implementation ScMembershipViewController

#pragma mark - Selector implementations

- (void)addMembership
{
    ScMemberViewController *memberViewController = [self.storyboard instantiateViewControllerWithIdentifier:kMemberViewControllerId];
    memberViewController.delegate = self;
    memberViewController.scola = _scola;
    
    [ScMeta state].action = ScStateActionRegister;
    [ScMeta state].target = ScStateTargetMember;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:memberViewController];
    
    [self.navigationController presentViewController:navigationController animated:YES completion:NULL];
    
    _isViewModallyHidden = YES;
}


- (void)didFinishEditing
{
    if (_needsSynchronisation) {
        [[ScMeta m].managedObjectContext synchronise];
        
        _needsSynchronisation = NO;
    }
    
    if ([ScMeta state].actionIsRegister) {
        [_delegate shouldDismissViewControllerWithIdentitifier:kMembershipViewControllerId];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _localState = [[ScMeta state] copy];
    
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:kDarkLinenImageFile]];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    _adminIds = [[NSMutableSet alloc] init];
    _adults = [[NSMutableSet alloc] init];
    _minors = [[NSMutableSet alloc] init];
    
    for (ScMembership *membership in _scola.memberships) {
        if ([[membership isAdmin] boolValue]) {
            [_adminIds addObject:membership.member.entityId];
            
            if ([membership.member.entityId isEqualToString:[ScMeta m].userId]) {
                _isUserScolaAdmin = YES;
            }
        }
             
        if ([membership.member isMinor]) {
            [_minors addObject:membership];
        } else {
            [_adults addObject:membership];
        }
    }
    
    _sortedAdults = [[_adults allObjects] sortedArrayUsingSelector:@selector(compare:)];
    _sortedMinors = [[_minors allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    if ([ScMeta state].aspectIsHome) {
        if ([_scola hasMultipleResidents]) {
            _longTitle = [ScStrings stringForKey:strMembershipViewTitleOurPlace];
        } else {
            _longTitle = [ScStrings stringForKey:strMembershipViewTitleMyPlace];
        }
        
        if ([ScMeta state].actionIsRegister) {
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
    
    [[ScMeta state] setState:_localState];
    ScLogState;
    
    if ([ScMeta state].actionIsRegister) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didFinishEditing)];
        
        self.navigationItem.leftBarButtonItem = doneButton;
        self.navigationItem.rightBarButtonItem = _addButton;
    } else {
        BOOL isForHousehold = ([ScMeta state].aspectIsHome || [ScMeta state].aspectIsHousehold);
        
        self.tabBarController.title = isForHousehold ? _longTitle : self.title;
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
    [ScMeta state].action = ScStateActionDisplay;
    
    if ([segue.identifier isEqualToString:kSegueToScolaView]) {
        ScScolaViewController *scolaViewController = segue.destinationViewController;
        scolaViewController.scola = _scola;
        
        if ([ScMeta state].aspect == ScStateAspectScola) {
            [ScMeta state].target = ScStateTargetScola;
        } else {
            [ScMeta state].target = ScStateTargetHousehold;
        }
    } else if ([segue.identifier isEqualToString:kSegueToMemberView]) {
        ScMemberViewController *memberViewController = segue.destinationViewController;
        memberViewController.membership = _selectedMembership;
        
        [ScMeta state].target = ScStateTargetMember;
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
    } else if (section == kAdultsSection) {
        numberOfRows = [_sortedAdults count];
    } else if (section == kMinorsSection) {
        numberOfRows = [_sortedMinors count];
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
        NSArray *memberships = (indexPath.section == kAdultsSection) ? _sortedAdults : _sortedMinors;
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
            membershipToDelete = [_sortedAdults objectAtIndex:indexPath.row];
            
            [_adults removeObject:membershipToDelete];
            _sortedAdults = [[_adults allObjects] sortedArrayUsingSelector:@selector(compare:)];
        } else if (indexPath.section == kMinorsSection) {
            membershipToDelete = [_sortedMinors objectAtIndex:indexPath.row];
            
            [_minors removeObject:membershipToDelete];
            _sortedMinors = [[_minors allObjects] sortedArrayUsingSelector:@selector(compare:)];
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
    } else if ((section == kMinorsSection) && (![_sortedMinors count])) {
        height = kMinimumSectionHeaderHeight;
    }
    
    return height;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = kDefaultSectionFooterHeight;

    if (section == kAdultsSection) {
        if ([_sortedAdults count] && [_sortedMinors count]) {
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
        numberOfRowsInSection = [_sortedAdults count];
    } else if (indexPath.section == kMinorsSection) {
        numberOfRowsInSection = [_sortedMinors count];
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
            _selectedMembership = [_sortedAdults objectAtIndex:indexPath.row];
        } else if (indexPath.section == kMinorsSection) {
            _selectedMembership = [_sortedMinors objectAtIndex:indexPath.row];
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
        [ScMeta state].target = ScStateTargetMemberships;
        
        _isViewModallyHidden = NO;
    }
}


- (void)insertMembershipInTableView:(ScMembership *)membership
{
    NSInteger section;
    NSInteger row;
    
    if ([membership.member isMinor]) {
        [_minors addObject:membership];
        _sortedMinors = [[_minors allObjects] sortedArrayUsingSelector:@selector(compare:)];
        
        section = kMinorsSection;
        row = [_sortedMinors indexOfObject:membership];
    } else {
        [_adults addObject:membership];
        _sortedAdults = [[_adults allObjects] sortedArrayUsingSelector:@selector(compare:)];
        
        section = kAdultsSection;
        row = [_sortedAdults indexOfObject:membership];
    }
    
    [self.tableView insertCellForRow:row inSection:section];
    
    _needsSynchronisation = YES;
}

@end
