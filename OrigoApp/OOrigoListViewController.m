//
//  OOrigoListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "OOrigoListViewController.h"

#import "NSManagedObjectContext+OrigoExtensions.h"
#import "NSString+OrigoExtensions.h"
#import "UIBarButtonItem+OrigoExtensions.h"
#import "UITableView+OrigoExtensions.h"

#import "OAlert.h"
#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"

#import "OMember+OrigoExtensions.h"
#import "OMemberResidency.h"
#import "OMembership.h"
#import "OOrigo+OrigoExtensions.h"

#import "OAuthViewController.h"
#import "OMemberListViewController.h"
#import "OMemberViewController.h"
#import "OOrigoViewController.h"

static NSString * const kModalSegueToAuthView = @"modalFromOrigoListToAuthView";
static NSString * const kModalSegueToMemberView = @"modalFromOrigoListToMemberView";
static NSString * const kModalSegueToOrigoView = @"modalFromOrigoListToOrigoView";
static NSString * const kPushSegueToMemberListView = @"pushFromOrigoListToMemberListView";
static NSString * const kPushSegueToMemberView = @"pushFromOrigoListToMemberView";

static NSInteger const kSectionNone = -1;
static NSInteger const kSectionUser = 0;
static NSInteger const kSectionWard = 1;
static NSInteger const kUserRow = 0;


@implementation OOrigoListViewController

#pragma mark - Auxiliary methods

- (void)loadData
{
    _sortedOrigos = [[[_member origoMemberships] allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    if ([_member isUser]) {
        _sortedResidencies = [[_member.residencies allObjects] sortedArrayUsingSelector:@selector(compare:)];
        _sortedWards = [[[_member wards] allObjects] sortedArrayUsingSelector:@selector(compare:)];
    }
}


- (BOOL)sectionIsUserSection:(NSInteger)section
{
    return (self.state.aspectIsSelf && section == kSectionUser);
}


- (BOOL)sectionIsWardSection:(NSInteger)section
{
    return (self.state.aspectIsSelf && [_sortedWards count] && (section == kSectionWard));
}


- (BOOL)sectionIsOrigoSection:(NSInteger)section
{
    NSUInteger origoSection = self.state.aspectIsSelf ? ([_sortedWards count] ? 2 : 1) : 0;
    
    return ([_sortedOrigos count] && (section == origoSection));
}


#pragma mark - Selector implementations

- (void)addOrigo
{
    _origoTypes = [[NSMutableArray alloc] init];
    
    NSString *sheetTitle = [OStrings stringForKey:strSheetTitleOrigoType];
    
    if (self.state.aspectIsSelf) {
        sheetTitle = [sheetTitle stringByAppendingString:@"?"];
    } else if (self.state.aspectIsWard) {
        NSString *forWardName = [NSString stringWithFormat:[OStrings stringForKey:strTermForName], _member.givenName];
        sheetTitle = [NSString stringWithFormat:@"%@ %@?", sheetTitle, forWardName];
        
        if ([_member isOfPreschoolAge] && ![_member isMemberOfOrigoOfType:kOrigoTypeSchoolClass]) {
            [_origoTypes addObject:kOrigoTypePreschoolClass];
        }
        
        [_origoTypes addObject:kOrigoTypeSchoolClass];
    }
    
    [_origoTypes addObject:kOrigoTypeSportsTeam];
    [_origoTypes addObject:kOrigoTypeDefault];
    
    UIActionSheet *origoTypeSheet = [[UIActionSheet alloc] initWithTitle:sheetTitle delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    for (NSString *origoType in _origoTypes) {
        [origoTypeSheet addButtonWithTitle:[OStrings stringForKey:origoType]];
    }
    
    [origoTypeSheet addButtonWithTitle:[OStrings stringForKey:strButtonCancel]];
    origoTypeSheet.cancelButtonIndex = [_origoTypes count];
    
    [origoTypeSheet showInView:self.tabBarController.view];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setBackground];
    
    self.title = @"Origo";
    
    if ([[OMeta m] userIsAllSet]) {
        if (![_member isUser]) {
            self.navigationItem.title = [NSString stringWithFormat:[OStrings stringForKey:strViewTitleWardOrigoList], _member.givenName];
            self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:_member.givenName];
        }
        
        if ([[OMeta m].user isTeenOrOlder]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem addButtonWithTarget:self];
            self.navigationItem.rightBarButtonItem.action = @selector(addOrigo);
        }
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.state.aspectIsSelf && self.isPopped) {
        [self loadData];
        
        NSRange reloadRange = {0, 0};
        
        BOOL hasOrigoSection = ([_sortedOrigos count] > 0);
        BOOL hasWardSection = [self.tableView numberOfSections] == (hasOrigoSection ? 3 : 2);
        BOOL needsWardSection = ([_sortedWards count] > 0);
        BOOL userSectionNeedsReload = ([_sortedResidencies count] != [self.tableView numberOfRowsInSection:kSectionUser] - 1);
        BOOL wardSectionNeedsReload = (hasWardSection && ([_sortedWards count] != [self.tableView numberOfRowsInSection:kSectionWard]));

        if (userSectionNeedsReload || (needsWardSection && !hasWardSection && !hasOrigoSection)) {
            reloadRange.location = kSectionUser;
            reloadRange.length = 1;
        }
        
        if (wardSectionNeedsReload) {
            reloadRange.location = reloadRange.length ? reloadRange.location : kSectionWard;
            reloadRange.length++;
        } else if (needsWardSection && !hasWardSection) {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:kSectionWard] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else if (!needsWardSection && hasWardSection) {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:kSectionWard] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        if (reloadRange.length) {
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:reloadRange] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    OLogState;
    
    if (![[OMeta m] userIsSignedIn]) {
        [self performSegueWithIdentifier:kModalSegueToAuthView sender:self];
    } else if (![[OMeta m] userIsRegistered]) {
        [OAlert showAlertWithTitle:[OStrings stringForKey:strAlertTitleIncompleteRegistration] message:[OStrings stringForKey:strAlertTextIncompleteRegistration]];
        
        [self performSegueWithIdentifier:kModalSegueToMemberView sender:self];
    }
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kModalSegueToAuthView]) {
        OAuthViewController *authViewController = segue.destinationViewController;
        authViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:kModalSegueToMemberView]) {
        UINavigationController *navigationController = segue.destinationViewController;
        OMemberViewController *memberViewController = navigationController.viewControllers[0];
        memberViewController.membership = [[OMeta m].user.residencies anyObject]; // TODO: Fix!
        memberViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:kModalSegueToOrigoView]) {
        UINavigationController *navigationController = segue.destinationViewController;
        OOrigoViewController *origoViewController = navigationController.viewControllers[0];
        origoViewController.origo = [[OMeta m].context insertOrigoEntityOfType:_origoTypes[_indexOfSelectedOrigoType]];
        origoViewController.member = _member;
        origoViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:kPushSegueToMemberView]) {
        OMemberViewController *memberViewController = segue.destinationViewController;
        memberViewController.membership = [[OMeta m].user rootMembership];
        memberViewController.entityObservingDelegate = _selectedCell;
    } else if ([segue.identifier isEqualToString:kPushSegueToMemberListView]) {
        OMemberListViewController *memberListViewController = segue.destinationViewController;
        memberListViewController.origo = _selectedOrigo;
        memberListViewController.entityObservingDelegate = _selectedCell;
    }
}


#pragma mark - OStateDelegate conformance

- (BOOL)shouldSetState
{
    return [[OMeta m] userIsAllSet];
}


- (void)setStatePrerequisites
{
    if (!_member || [_member isFault]) {
        _member = [OMeta m].user;
    }
    
    [self loadData];
}


- (void)setState
{
    self.state.actionIsList = YES;
    self.state.targetIsOrigo = YES;
    [self.state setAspectForMember:_member];
}


#pragma mark - UITableViewDataSource conformance

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numberOfSections = 0;

    if ([[OMeta m] userIsAllSet]) {
        numberOfSections++;
        
        if (self.state.aspectIsSelf) {
            if ([_sortedWards count]) {
                numberOfSections++;
            }
            
            if ([_sortedOrigos count]) {
                numberOfSections++;
            }
        }
    }
    
    return numberOfSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger numberOfRows = 0;
    
    if ([self sectionIsUserSection:section]) {
        numberOfRows = 1 + [_sortedResidencies count];
    } else if ([self sectionIsWardSection:section]) {
        numberOfRows = [_sortedWards count];
    } else if ([self sectionIsOrigoSection:section]) {
        numberOfRows = [_sortedOrigos count];
    }
    
    return numberOfRows;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultTableViewCellHeight;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTableViewCell *cell = nil;
    
    OMembership *membership = nil;
    OMember *member = nil;
    
    if ([self sectionIsUserSection:indexPath.section]) {
        if (indexPath.row == kUserRow) {
            member = [OMeta m].user;
        } else {
            membership = _sortedResidencies[indexPath.row - 1];
        }
    } else if ([self sectionIsWardSection:indexPath.section]) {
        member = _sortedWards[indexPath.row];
    } else if ([self sectionIsOrigoSection:indexPath.section]) {
        membership = _sortedOrigos[indexPath.row];
    }
    
    if (membership) {
        cell = [tableView listCellForEntity:membership.origo];
    } else if (member) {
        cell = [tableView listCellForEntity:member];
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate conformance

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = kDefaultPadding;
    
    if (section >= kSectionWard) {
        height = [tableView standardHeaderHeight];
    }
    
    return height;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = kDefaultPadding;
    
    if (section == [tableView numberOfSections] - 1) {
        height = [tableView standardFooterHeight];
    }
    
    return height;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = nil;
    
    if ([self sectionIsWardSection:section]) {
        headerView = [tableView headerViewWithText:[OStrings stringForKey:strHeaderWardsOrigos]];
    } else if ([self sectionIsOrigoSection:section]) {
        headerView = [tableView headerViewWithText:[OStrings stringForKey:strHeaderMyOrigos]];
    }
    
    return headerView;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = nil;
    
    if ((section == [tableView numberOfSections] - 1) && [[OMeta m].user isTeenOrOlder]) {
        NSString *footerText = nil;
        
        if ([_sortedOrigos count]) {
            footerText = [OStrings stringForKey:strFooterOrigoCreation];
        } else {
            footerText = [OStrings stringForKey:strFooterOrigoCreationFirst];
        }
        
        if (self.state.aspectIsSelf && [_sortedWards count]) {
            NSString *yourChild = nil;
            NSString *himOrHer = nil;
            
            BOOL allFemale = YES;
            BOOL allMale = YES;
            
            if ([_sortedWards count] == 1) {
                yourChild = ((OMember *)_sortedWards[0]).givenName;
            } else {
                yourChild = [OStrings stringForKey:strTermYourChild];
            }
            
            for (OMember *ward in _sortedWards) {
                allFemale = allFemale && [ward isFemale];
                allMale = allMale && [ward isMale];
            }
            
            if (allFemale) {
                himOrHer = [OStrings stringForKey:strTermHer];
            } else if (allMale) {
                himOrHer = [OStrings stringForKey:strTermHim];
            } else {
                himOrHer = [OStrings stringForKey:strTermHimOrHer];
            }
            
            NSString *wardsAddendum = [NSString stringWithFormat:[OStrings stringForKey:strFooterOrigoCreationWards], yourChild, himOrHer];
            footerText = [NSString stringWithFormat:@"%@ %@", footerText, wardsAddendum];
        } else if (self.state.aspectIsSelf) {
            footerText = [footerText stringByAppendingString:@"."];
        } else if (self.state.aspectIsWard) {
            NSString *forWardName = [NSString stringWithFormat:[OStrings stringForKey:strTermForName], _member.givenName];
            footerText = [NSString stringWithFormat:@"%@ %@.", footerText, forWardName];
        }
        
        footerView = [tableView footerViewWithText:footerText];
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
    _selectedOrigo = nil;
    _selectedMember = nil;
    
    if ([self sectionIsUserSection:indexPath.section]) {
        if (indexPath.row == kUserRow) {
            _selectedMember = [OMeta m].user;
        } else {
            _selectedOrigo = ((OMembership *)_sortedResidencies[indexPath.row - 1]).origo;
        }
    } else if ([self sectionIsWardSection:indexPath.section]) {
        _selectedMember = _sortedWards[indexPath.row];
    } else if ([self sectionIsOrigoSection:indexPath.section]) {
        _selectedOrigo = ((OMembership *)_sortedOrigos[indexPath.row]).origo;
    }
    
    if (_selectedOrigo) {
        [self performSegueWithIdentifier:kPushSegueToMemberListView sender:self];
    } else if (_selectedMember) {
        if ([_selectedMember isUser]) {
            [self performSegueWithIdentifier:kPushSegueToMemberView sender:self];
        } else {
            OOrigoListViewController *wardOrigosViewController = [self.storyboard instantiateViewControllerWithIdentifier:kOrigoListViewControllerId];
            wardOrigosViewController.member = _selectedMember;
            
            [self.navigationController pushViewController:wardOrigosViewController animated:YES];
        }
    }
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        _indexOfSelectedOrigoType = buttonIndex;
        
        [self performSegueWithIdentifier:kModalSegueToOrigoView sender:self];
    }
}


#pragma mark - OModalViewControllerDelegate conformance

- (void)dismissModalViewControllerWithIdentitifier:(NSString *)identitifier
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    if ([identitifier isEqualToString:kAuthViewControllerId] ||
        [identitifier isEqualToString:kMemberViewControllerId] ||
        [identitifier isEqualToString:kMemberListViewControllerId]) {
        if ([[OMeta m] userIsSignedIn]) {
            //[self configureViewAndDataSource];
            [self.tableView reloadData];
        }
    } else if ([identitifier isEqualToString:kOrigoViewControllerId]) {
        
    }
}


- (void)insertEntityInTableView:(OReplicatedEntity *)entity
{
    
}

@end
