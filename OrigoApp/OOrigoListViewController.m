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

static NSInteger const kUserSection = 0;
static NSInteger const kWardSection = 1;
static NSInteger const kOrigoSection = 2;

static NSInteger const kUserRow = 0;


@implementation OOrigoListViewController

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
    
    if ([self shouldInitialise]) {
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


#pragma mark - OTableViewControllerDelegate conformance

- (BOOL)shouldInitialise
{
    return [[OMeta m] userIsAllSet];
}


- (void)setPrerequisites
{
    if (!_member || [_member isFault]) {
        _member = [OMeta m].user;
    }
}


- (void)setState
{
    self.state.actionIsList = YES;
    self.state.targetIsOrigo = YES;
    [self.state setAspectForMember:_member];
}


- (void)loadData
{
    [self setData:[_member origoMemberships] forSectionWithKey:kOrigoSection];
    
    if ([_member isUser]) {
        [self setData:_member forSectionWithKey:kUserSection];
        [self appendData:_member.residencies toSectionWithKey:kUserSection];
        [self setData:[_member wards] forSectionWithKey:kWardSection];
    }
}


#pragma mark - UITableViewDataSource conformance

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kDefaultTableViewCellHeight;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTableViewCell *cell = nil;
    
    OMembership *membership = nil;
    OMember *member = nil;
    
    if (indexPath.section == [self sectionNumberForSectionKey:kUserSection]) {
        if (indexPath.row == kUserRow) {
            member = [OMeta m].user;
        } else {
            membership = [self entityForIndexPath:indexPath];
        }
    } else if (indexPath.section == [self sectionNumberForSectionKey:kWardSection]) {
        member = [self entityForIndexPath:indexPath];
    } else if (indexPath.section == [self sectionNumberForSectionKey:kOrigoSection]) {
        membership = [self entityForIndexPath:indexPath];
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
    CGFloat height = kMinimumPadding;
    
    if (section == [self sectionNumberForSectionKey:kUserSection]) {
        height = kDefaultPadding;
    } else if ([self hasSectionWithKey:section]) {
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
    
    if (section == [self sectionNumberForSectionKey:kWardSection]) {
        headerView = [tableView headerViewWithText:[OStrings stringForKey:strHeaderWardsOrigos]];
    } else if (section == [self sectionNumberForSectionKey:kOrigoSection]) {
        headerView = [tableView headerViewWithText:[OStrings stringForKey:strHeaderMyOrigos]];
    }
    
    return headerView;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = nil;
    
    if ((section == [tableView numberOfSections] - 1) && [[OMeta m].user isTeenOrOlder]) {
        NSString *footerText = nil;
        
        if ([self hasSectionWithKey:kOrigoSection]) {
            footerText = [OStrings stringForKey:strFooterOrigoCreation];
        } else {
            footerText = [OStrings stringForKey:strFooterOrigoCreationFirst];
        }
        
        if (self.state.aspectIsSelf && [self hasSectionWithKey:kWardSection]) {
            NSString *yourChild = nil;
            NSString *himOrHer = nil;
            
            BOOL allFemale = YES;
            BOOL allMale = YES;
            
            if ([self numberOfRowsInSectionWithKey:kWardSection] == 1) {
                yourChild = ((OMember *)[self entitiesInSectionWithKey:kWardSection][0]).givenName;
            } else {
                yourChild = [OStrings stringForKey:strTermYourChild];
            }
            
            for (OMember *ward in [self entitiesInSectionWithKey:kWardSection]) {
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


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedCell = (OTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    _selectedOrigo = nil;
    _selectedMember = nil;
    
    if (indexPath.section == [self sectionNumberForSectionKey:kUserSection]) {
        if (indexPath.row == kUserRow) {
            _selectedMember = [OMeta m].user;
        } else {
            _selectedOrigo = ((OMembership *)[self entityForIndexPath:indexPath]).origo;
        }
    } else if (indexPath.section == [self sectionNumberForSectionKey:kWardSection]) {
        _selectedMember = [self entityForIndexPath:indexPath];
    } else if (indexPath.section == [self sectionNumberForSectionKey:kOrigoSection]) {
        _selectedOrigo = ((OMembership *)[self entityForIndexPath:indexPath]).origo;
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
            [self.tableView reloadData];
        }
    } else if ([identitifier isEqualToString:kOrigoViewControllerId]) {
        
    }
}

@end
