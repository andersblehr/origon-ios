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
#import "NSString+OStringExtensions.h"
#import "UIBarButtonItem+OBarButtonItemExtensions.h"
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
#import "OOrigoViewController.h"

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

- (void)addItem
{
    [OState s].actionIsRegister = YES;
    
    _origoTypes = [[NSMutableArray alloc] init];
    
    NSString *sheetTitle = [OStrings stringForKey:strSheetTitleOrigoType];
    
    if ([OState s].aspectIsSelf) {
        sheetTitle = [sheetTitle stringByAppendingString:@"?"];
    } else if ([OState s].aspectIsWard) {
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
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    self.title = [OStrings stringForKey:strTabBarTitleOrigo];
    
    if (_member) {
        [OState s].aspectIsWard = YES;
        
        self.navigationItem.title = [NSString stringWithFormat:[OStrings stringForKey:strViewTitleWardOrigoList], _member.givenName];
        self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:_member.givenName];
    } else {
        [OState s].aspectIsSelf = YES;
        
        _member = [OMeta m].user;
        _sortedResidences = [[_member.residencies allObjects] sortedArrayUsingSelector:@selector(compare:)];
        _sortedWards = [[[_member wards] allObjects] sortedArrayUsingSelector:@selector(compare:)];
    }
    
    if ([[OMeta m].user isTeenOrOlder]) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem addButtonWithTarget:self];
    }
    
    _sortedOrigos = [[[_member origoMemberships] allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [OState s].targetIsOrigo = YES;
    [OState s].actionIsList = YES;
    [[OState s] setAspectForMember:_member];
    
    OLogState;

    if ([OState s].aspectIsSelf) {
        BOOL hasOnlyResidenceSection = ([self.tableView numberOfSections] == 1);
        NSRange reloadRange = {0, 0};
        
        if ([_member.residencies count] != [_sortedResidences count]) {
            _sortedResidences = [[_member.residencies allObjects] sortedArrayUsingSelector:@selector(compare:)];
            
            reloadRange.location = kResidenceSection;
            reloadRange.length = 1;
        }
        
        NSSet *wards = [_member wards];
        
        if ([wards count] != [_sortedWards count]) {
            BOOL hasWardsSection = ([_sortedWards count] > 0);
            _sortedWards = [[wards allObjects] sortedArrayUsingSelector:@selector(compare:)];
            
            if ([wards count]) {
                if (!hasWardsSection) {
                    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:kWardSection] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
                
                if (!reloadRange.length) {
                    reloadRange.location = kWardSection;
                }
                
                reloadRange.length++;
            } else {
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:kWardSection] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
        
        if (reloadRange.length) {
            if ((reloadRange.location > kResidenceSection) && hasOnlyResidenceSection) {
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kResidenceSection] withRowAnimation:UITableViewRowAnimationNone];
            }
            
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:reloadRange] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToMemberListView]) {
        OMemberListViewController *memberListViewController = segue.destinationViewController;
        memberListViewController.origo = _selectedOrigo;
        memberListViewController.entityObservingDelegate = _selectedCell;
    }
}


#pragma mark - UITableViewDataSource conformance

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
    return kDefaultTableViewCellHeight;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTableViewCell *cell = nil;
    
    OMembership *membership = nil;
    OMember *ward = nil;
    
    if ([self sectionIsResidenceSection:indexPath.section]) {
        membership = _sortedResidences[indexPath.row];
    } else if ([self sectionIsWardSection:indexPath.section]) {
        ward = _sortedWards[indexPath.row];
    } else if ([self sectionIsOrigoSection:indexPath.section]) {
        membership = _sortedOrigos[indexPath.row];
    }
    
    if (membership) {
        cell = [tableView listCellForEntity:membership.origo];
    } else if (ward) {
        cell = [tableView listCellForEntity:ward];
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate conformance

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = kDefaultPadding;
    
    if (section >= kWardSection) {
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
        
        if ([OState s].aspectIsSelf && [_sortedWards count]) {
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
        } else if ([OState s].aspectIsSelf) {
            footerText = [footerText stringByAppendingString:@"."];
        } else if ([OState s].aspectIsWard) {
            NSString *forWardName = [NSString stringWithFormat:[OStrings stringForKey:strTermForName], _member.givenName];
            footerText = [NSString stringWithFormat:@"%@ %@.", footerText, forWardName];
        }
        
        footerView = [tableView footerViewWithText:footerText];
    }
    
    return footerView;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1) {
        [cell.backgroundView addDropShadowForTrailingTableViewCell];
    } else {
        [cell.backgroundView addDropShadowForInternalTableViewCell];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedCell = (OTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    _selectedOrigo = nil;
    _selectedWard = nil;
    
    if ([self sectionIsResidenceSection:indexPath.section]) {
        _selectedOrigo = ((OMembership *)_sortedResidences[indexPath.row]).origo;
    } else if ([self sectionIsWardSection:indexPath.section]) {
        _selectedWard = _sortedWards[indexPath.row];
    } else if ([self sectionIsOrigoSection:indexPath.section]) {
        _selectedOrigo = ((OMembership *)_sortedOrigos[indexPath.row]).origo;
    }
    
    if (_selectedOrigo) {
        [self performSegueWithIdentifier:kSegueToMemberListView sender:self];
    } else if (_selectedWard) {
        OOrigoListViewController *wardOrigoListViewController = [self.storyboard instantiateViewControllerWithIdentifier:kOrigoListViewControllerId];
        wardOrigoListViewController.member = _selectedWard;
        
        [self.navigationController pushViewController:wardOrigoListViewController animated:YES];
    }
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        OOrigoViewController *origoViewController = [self.storyboard instantiateViewControllerWithIdentifier:kOrigoViewControllerId];
        origoViewController.delegate = self;
        origoViewController.origoType = _origoTypes[buttonIndex];
        
        UINavigationController *modalController = [[UINavigationController alloc] initWithRootViewController:origoViewController];
        modalController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        [self.navigationController presentViewController:modalController animated:YES completion:NULL];
    }
}


#pragma mark - OModalViewControllerDelegate conformance

- (void)dismissViewControllerWithIdentitifier:(NSString *)identitifier
{
    if ([identitifier isEqualToString:kOrigoViewControllerId]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}


- (void)insertEntityInTableView:(OReplicatedEntity *)entity
{
    
}

@end
