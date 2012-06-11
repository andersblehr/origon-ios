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
#import "UIView+ScViewExtensions.h"

#import "ScLogging.h"
#import "ScMeta.h"
#import "ScStrings.h"
#import "ScTableViewCell.h"

#import "ScMember.h"
#import "ScMembership.h"
#import "ScScola.h"

#import "ScMember+ScMemberExtensions.h"
#import "ScScola+ScScolaExtensions.h"

#import "ScMemberViewController.h"


static NSInteger kAddressSection = 0;
static NSInteger kAdultsSection = 1;
static NSInteger kMinorsSection = 2;

static CGFloat kScreenWidth = 320.f;
static CGFloat kHeaderWidth = 300.f;
static CGFloat kFooterWidth = 280.f;
static CGFloat kHeaderMargin = 10.f;
static CGFloat kFooterMargin = 20.f;
static CGFloat kFooterViewOffset = 10.f;

static CGFloat kDefaultHeaderFooterHeight = 0.f;
static CGFloat kMinimumHeaderFooterHeight = 1.f;
static CGFloat kSectionSpacing = 10.f;

static CGFloat kHeaderFontSize = 17.f;
static CGFloat kFooterFontSize = 13.f;


@implementation ScMembershipViewController


@synthesize scola;
@synthesize isRegistrationWizardStep;


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
    
    adminIds = [[NSMutableSet alloc] init];
    unsortedAdults = [[NSMutableSet alloc] init];
    unsortedMinors = [[NSMutableSet alloc] init];
    
    for (ScMembership *membership in scola.memberships) {
        if ([[membership isAdmin] boolValue]) {
            [adminIds addObject:membership.member.entityId];
            
            if ([membership.member.entityId isEqualToString:[ScMeta m].userId]) {
                isUserScolaAdmin = YES;
            }
        }
             
        if ([membership.member isMinor]) {
            [unsortedMinors addObject:membership.member];
        } else {
            [unsortedAdults addObject:membership.member];
        }
    }
    
    adults = [[unsortedAdults allObjects] sortedArrayUsingSelector:@selector(compare:)];
    minors = [[unsortedMinors allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    isForHousehold = ([scola.residencies count] > 0);
    
    if (isRegistrationWizardStep) {
        if ([scola.residencies count] == 1) {
            self.title = [ScStrings stringForKey:strMembershipViewHomeScolaTitle1];
        } else {
            self.title = [ScStrings stringForKey:strMembershipViewHomeScolaTitle2];
        }
    } else if (isForHousehold) {
        self.title = [ScStrings stringForKey:strHousehold];
        
        if ([scola.residencies count] == 1) {
            longTitle = [ScStrings stringForKey:strMembershipViewHomeScolaTitle1];
        } else {
            longTitle = [ScStrings stringForKey:strMembershipViewHomeScolaTitle2];
        }
    } else {
        self.title = [ScStrings stringForKey:strMembershipViewDefaultTitle];
    }
    
    if (isUserScolaAdmin) {
        addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMember)];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (isRegistrationWizardStep) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didFinishAddingMembers)];
        
        self.navigationItem.leftBarButtonItem = doneButton;
        self.navigationItem.rightBarButtonItem = addButton;
    } else {
        self.tabBarController.title = isForHousehold ? longTitle : self.title;
        self.tabBarController.navigationItem.rightBarButtonItem = addButton;
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    if (didAddMembers && !isRegistrationWizardStep && !isViewModallyHidden) {
        [self didFinishAddingMembers];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Adding members

- (void)addMember
{
    ScMemberViewController *memberViewController = [self.storyboard instantiateViewControllerWithIdentifier:kMemberViewController];
    
    memberViewController.membershipViewController = self;
    memberViewController.isForHousehold = isForHousehold;
    memberViewController.isInserting = YES;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:memberViewController];
    
    [self.navigationController presentModalViewController:navigationController animated:YES];
    
    isViewModallyHidden = YES;
}


- (void)insertAddedMemberInTableView:(ScMember *)member
{
    NSIndexPath *indexPath = nil;
    
    BOOL doAddTopShadowToPreceding = NO;
    BOOL doAddCentreShadowToPreceding = NO;
    BOOL doAddCentreShadowToFollowing = NO;
    BOOL doAddBottomShadowToFollowing = NO;

    NSInteger sectionCount;
    NSInteger section;
    NSInteger row;
    
    if ([member isMinor]) {
        [unsortedMinors addObject:member];
        minors = [[unsortedMinors allObjects] sortedArrayUsingSelector:@selector(compare:)];

        sectionCount = [minors count];
        section = kMinorsSection;
        row = [minors indexOfObject:member];
    } else {
        [unsortedAdults addObject:member];
        adults = [[unsortedAdults allObjects] sortedArrayUsingSelector:@selector(compare:)];

        sectionCount = [adults count];
        section = kAdultsSection;
        row = [adults indexOfObject:member];
    }
    
    doAddTopShadowToPreceding = ((row == 1) && (sectionCount == 2));
    doAddCentreShadowToPreceding = ((row == sectionCount - 1) && (sectionCount > 2));
    doAddCentreShadowToFollowing = ((row == 0) && (sectionCount > 2));
    doAddBottomShadowToFollowing = ((row == 0) && (sectionCount == 2));
    
    indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];

    if (doAddTopShadowToPreceding || doAddCentreShadowToPreceding) {
        UITableViewCell *precedingCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row - 1 inSection:section]];
        
        if (doAddTopShadowToPreceding) {
            [precedingCell.backgroundView addTopShadow];
        } else if (doAddCentreShadowToPreceding) {
            [precedingCell.backgroundView addCentreShadow];
        }
    }
    
    if (doAddCentreShadowToFollowing || doAddBottomShadowToFollowing) {
        UITableViewCell *followingCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row + 1 inSection:section]];
        
        if (doAddCentreShadowToFollowing) {
            [followingCell.backgroundView addCentreShadow];
        } else if (doAddBottomShadowToFollowing) {
            [followingCell.backgroundView addBottomShadow];
        }
    }
    
    didAddMembers = YES;
    isViewModallyHidden = NO;
}


- (void)didFinishAddingMembers
{
    if (didAddMembers) {
        [[ScMeta m].managedObjectContext synchronise];
    }
    
    if (isRegistrationWizardStep) {
        [self dismissModalViewControllerAnimated:YES];
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
        numberOfRows = [adults count];
    } else if (section == kMinorsSection) {
        numberOfRows = [minors count];
    }
    
	return numberOfRows;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height;
    
    if (indexPath.section == kAddressSection) {
        height = [ScTableViewCell heightForEntity:scola];
    } else {
        height = 1.1f * self.tableView.rowHeight;
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ScTableViewCell *cell = nil;
    
    if (indexPath.section == kAddressSection) {
        cell = [ScTableViewCell entityCellForEntity:scola tableView:tableView];
        
        if (isUserScolaAdmin) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else {
        cell = [ScTableViewCell defaultCellForTableView:tableView];
        
        NSArray *memberSubset = nil;
        
        if (indexPath.section == kAdultsSection) {
            memberSubset = [adults count] ? adults : minors;
        } else if (indexPath.section == kMinorsSection) {
            memberSubset = minors;
        }
        
        ScMember *member = [memberSubset objectAtIndex:indexPath.row];
        
        cell.textLabel.text = member.name;
        cell.detailTextLabel.text = member.mobilePhone;
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (indexPath.section == kAdultsSection) {
            [unsortedAdults removeObject:[adults objectAtIndex:indexPath.row]];
            adults = [[unsortedAdults allObjects] sortedArrayUsingSelector:@selector(compare:)];
        } else if (indexPath.section == kMinorsSection) {
            [unsortedMinors removeObject:[minors objectAtIndex:indexPath.row]];
            minors = [[unsortedMinors allObjects] sortedArrayUsingSelector:@selector(compare:)];
        }
        
        // TODO: Remove from Core Data as well!
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{   
    NSInteger numberOfAdults = [adults count];
    NSInteger numberOfMinors = [minors count];
    
    BOOL isOnlyRowInSection = NO;
    BOOL isFirstRowInSection = NO;
    BOOL isLastRowInSection = NO;
    
    if (indexPath.section == kAddressSection) {
        isOnlyRowInSection = YES;
    } else {
        isFirstRowInSection = (indexPath.row == 0);
        
        if (indexPath.section == kAdultsSection) {
            isOnlyRowInSection = (numberOfAdults == 1);
            isLastRowInSection = (indexPath.row == numberOfAdults - 1);
        } else {
            isOnlyRowInSection = (numberOfMinors == 1);
            isLastRowInSection = (indexPath.row == numberOfMinors - 1);
        }
    }
    
    if (isOnlyRowInSection) {
        [cell.backgroundView addShadow];
    } else {
        if (isFirstRowInSection) {
            [cell.backgroundView addTopShadow];
        } else if (isLastRowInSection) {
            [cell.backgroundView addBottomShadow];
        } else {
            [cell.backgroundView addCentreShadow];
        }
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = kDefaultHeaderFooterHeight;
    
    if (section == kAdultsSection) {
        height = 4.f * [UIFont boldSystemFontOfSize:kHeaderFontSize].xHeight;
    } else if ((section == kMinorsSection) && (![minors count])) {
        height = kMinimumHeaderFooterHeight;
    }
    
    return height;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = kDefaultHeaderFooterHeight;

    if (section == kAdultsSection) {
        if ([adults count] && [minors count]) {
            height = kSectionSpacing;
        } else {
            height = kMinimumHeaderFooterHeight;
        }
    } else if (section == kMinorsSection) {
        NSString *footer = [ScStrings stringForKey:strHouseholdMemberListFooter];
        UIFont *footerFont = [UIFont systemFontOfSize:kFooterFontSize];
        CGSize footerSize = [footer sizeWithFont:footerFont constrainedToSize:CGSizeMake(280.f, 10.f * footerFont.xHeight) lineBreakMode:UILineBreakModeWordWrap];
        
        height = footerSize.height + kSectionSpacing;
    }
    
    return height;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = nil;
    
    if (section == kAdultsSection) {
        CGFloat headerHeight = [self tableView:tableView heightForHeaderInSection:section];
        CGRect headerViewFrame = CGRectMake(0.f, 0.f, kScreenWidth, headerHeight);
        CGRect headerFrame = CGRectMake(kHeaderMargin, 0.f, kHeaderWidth, headerHeight);
        
        headerView = [[UIView alloc] initWithFrame:headerViewFrame];
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:headerFrame];
        
        headerLabel.font = [UIFont boldSystemFontOfSize:kHeaderFontSize];
        headerLabel.backgroundColor = [UIColor clearColor];
        headerLabel.textColor = [UIColor ghostWhiteColor];
        headerLabel.shadowColor = [UIColor blackColor];
        headerLabel.shadowOffset = CGSizeMake(0.f, 3.f);
        headerLabel.text = [ScStrings stringForKey:strHouseholdMembers];
        
        [headerView addSubview:headerLabel];
    }
    
    return headerView;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = nil;
    
    if ((section == kMinorsSection) && isUserScolaAdmin) {
        CGFloat footerHeight = [self tableView:tableView heightForFooterInSection:section];
        CGRect footerViewFrame = CGRectMake(0.f, 0.f, kScreenWidth, footerHeight);
        CGRect footerFrame = CGRectMake(kFooterMargin, kFooterViewOffset, kFooterWidth, footerHeight);
        
        footerView = [[UIView alloc] initWithFrame:footerViewFrame];
        UILabel *footerLabel = [[UILabel alloc] initWithFrame:footerFrame];
        
        footerLabel.font = [UIFont systemFontOfSize:kFooterFontSize];
        footerLabel.textAlignment = UITextAlignmentCenter;
        footerLabel.backgroundColor = [UIColor clearColor];
        footerLabel.textColor = [UIColor lightTextColor];
        footerLabel.shadowColor = [UIColor blackColor];
        footerLabel.shadowOffset = CGSizeMake(0.f, 2.f);
        footerLabel.numberOfLines = 0;
        footerLabel.text = [ScStrings stringForKey:strHouseholdMemberListFooter];
        
        [footerView addSubview:footerLabel];
    }
    
    return footerView;
}


- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *deleteConfirmationTitle = nil;
    
    if (indexPath.section != kAddressSection) {
        deleteConfirmationTitle = [ScStrings stringForKey:strDeleteConfirmation];
    }
    
    return deleteConfirmationTitle;
}

@end
