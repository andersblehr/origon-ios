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

static NSInteger const kAddressSection = 0;
static NSInteger const kAdultsSection = 1;
static NSInteger const kMinorsSection = 2;

static CGFloat const kDefaultHeaderFooterHeight = 0.f;
static CGFloat const kMinimumHeaderFooterHeight = 1.f;
static CGFloat const kSectionSpacing = 5.f;

static CGFloat const kHeaderWidth = 300.f;
static CGFloat const kFooterWidth = 280.f;
static CGFloat const kHeaderPadding = 10.f;
static CGFloat const kFooterPadding = 20.f;
static CGFloat const kFooterViewOffset = 10.f;

static CGFloat const kHeaderFontSize = 17.f;
static CGFloat const kFooterFontSize = 13.f;


@implementation ScMembershipViewController

@synthesize delegate;
@synthesize scola;


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
            [unsortedMinors addObject:membership];
        } else {
            [unsortedAdults addObject:membership];
        }
    }
    
    adults = [[unsortedAdults allObjects] sortedArrayUsingSelector:@selector(compare:)];
    minors = [[unsortedMinors allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    isForHousehold = ([scola.residencies count] > 0);
    
    if ([ScMeta m].appState == ScAppStateHouseholdMemberRegistration) {
        if ([scola.residencies count] == 1) {
            self.title = [ScStrings stringForKey:strMembershipViewTitleMyPlace];
        } else {
            self.title = [ScStrings stringForKey:strMembershipViewTitleOurPlace];
        }
    } else if (isForHousehold) {
        self.title = [ScStrings stringForKey:strHousehold];
        
        if ([scola.residencies count] == 1) {
            longTitle = [ScStrings stringForKey:strMembershipViewTitleMyPlace];
        } else {
            longTitle = [ScStrings stringForKey:strMembershipViewTitleOurPlace];
        }
    } else {
        self.title = [ScStrings stringForKey:strMembershipViewTitleDefault];
    }
    
    if (isUserScolaAdmin) {
        addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMembership)];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([ScMeta m].appState == ScAppStateHouseholdMemberRegistration) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didFinishEditingMemberships)];
        
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
    
    BOOL isRegistrationWizardStep = ([ScMeta m].appState == ScAppStateHouseholdMemberRegistration);
    
    if (didAddOrRemoveMemberships && !isRegistrationWizardStep && !isViewModallyHidden) {
        [self didFinishEditingMemberships];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Adding memberships

- (void)addMembership
{
    ScMemberViewController *memberViewController = [self.storyboard instantiateViewControllerWithIdentifier:kMemberViewControllerId];
    memberViewController.delegate = self;
    memberViewController.scola = scola;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:memberViewController];
    
    if ([ScMeta m].appState == ScAppStateDisplayScolaMemberships) {
        [ScMeta m].appState = ScAppStateScolaMemberRegistration;
    } else if ([ScMeta m].appState == ScAppStateDisplayHouseholdMemberships) {
        [ScMeta m].appState = ScAppStateHouseholdMemberRegistration;
    }
    
    [self.navigationController presentViewController:navigationController animated:YES completion:NULL];
    
    isViewModallyHidden = YES;
}


- (void)didFinishEditingMemberships
{
    if (didAddOrRemoveMemberships) {
        [[ScMeta m].managedObjectContext synchronise];
    }
    
    if ([ScMeta m].appState == ScAppStateHouseholdMemberRegistration) {
        [delegate shouldDismissViewControllerWithIdentitifier:kMemberViewControllerId];
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
        height = [ScTableViewCell heightForEntity:scola whenEditing:YES];
    } else {
        height = 1.1f * self.tableView.rowHeight;
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ScTableViewCell *cell = nil;
    
    if (indexPath.section == kAddressSection) {
        cell = [tableView cellForEntity:scola];
        
        if (isUserScolaAdmin) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else {
        cell = [tableView cellWithReuseIdentifier:kReuseIdentifierDefault];
        
        NSArray *memberships = (indexPath.section == kAdultsSection) ? adults : minors;
        
        ScMembership *membership = [memberships objectAtIndex:indexPath.row];
        
        cell.textLabel.text = membership.member.name;
        cell.detailTextLabel.text = membership.member.mobilePhone;
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        ScMembership *membershipToDelete = nil;
        
        if (indexPath.section == kAdultsSection) {
            membershipToDelete = [adults objectAtIndex:indexPath.row];
            
            [unsortedAdults removeObject:membershipToDelete];
            adults = [[unsortedAdults allObjects] sortedArrayUsingSelector:@selector(compare:)];
        } else if (indexPath.section == kMinorsSection) {
            membershipToDelete = [minors objectAtIndex:indexPath.row];
            
            [unsortedMinors removeObject:membershipToDelete];
            minors = [[unsortedMinors allObjects] sortedArrayUsingSelector:@selector(compare:)];
        }
        
        [[ScMeta m].managedObjectContext deleteEntity:membershipToDelete];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        didAddOrRemoveMemberships = YES;
    }   
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{   
    NSInteger numberOfRowsInSection = 1;
    
    if (indexPath.section == kAdultsSection) {
        numberOfRowsInSection = [adults count];
    } else if (indexPath.section == kMinorsSection) {
        numberOfRowsInSection = [minors count];
    }
    
    BOOL isLastRowInSection = (indexPath.row == numberOfRowsInSection - 1);
    
    if (isLastRowInSection) {
        [cell.backgroundView addShadowForBottomTableViewCell];
    } else {
        [cell.backgroundView addShadowForNonBottomTableViewCell];
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
        
        height = footerSize.height + 2 * kSectionSpacing;
    }
    
    return height;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = nil;
    
    if (section == kAdultsSection) {
        CGFloat headerHeight = [self tableView:tableView heightForHeaderInSection:section];
        CGRect headerViewFrame = CGRectMake(0.f, 0.f, kScreenWidth, headerHeight);
        CGRect headerFrame = CGRectMake(kHeaderPadding, 0.f, kHeaderWidth, headerHeight);
        
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
        CGRect footerFrame = CGRectMake(kFooterPadding, kFooterViewOffset, kFooterWidth, footerHeight);
        
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


#pragma mark - ScMemberViewControllerDelegate methods

- (void)shouldDismissViewControllerWithIdentitifier:(NSString *)identitifier
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    isViewModallyHidden = NO;
}


- (void)insertMembershipInTableView:(ScMembership *)membership
{
    NSInteger section;
    NSInteger row;
    
    if ([membership.member isMinor]) {
        [unsortedMinors addObject:membership];
        minors = [[unsortedMinors allObjects] sortedArrayUsingSelector:@selector(compare:)];
        
        section = kMinorsSection;
        row = [minors indexOfObject:membership];
    } else {
        [unsortedAdults addObject:membership];
        adults = [[unsortedAdults allObjects] sortedArrayUsingSelector:@selector(compare:)];
        
        section = kAdultsSection;
        row = [adults indexOfObject:membership];
    }
    
    [self.tableView insertCellForRow:row inSection:section];
    
    didAddOrRemoveMemberships = YES;
}

@end
