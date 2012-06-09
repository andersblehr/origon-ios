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


static NSInteger kSectionAddress = 0;
static NSInteger kSectionAdultsOrMinors = 1;
static NSInteger kSectionMinors = 2;

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
    
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dark_linen-640x960.png"]];
    
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
    
    if (!isRegistrationWizardStep && didAddMembers) {
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
    
    memberViewController.isForHousehold = isForHousehold;
    memberViewController.isEditing = YES;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:memberViewController];
    
    [self.navigationController presentModalViewController:navigationController animated:YES];
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
    NSInteger numberOfSections = 1;
    
    if ([adults count]) {
        numberOfSections++;
    }
    
    if ([minors count]) {
        numberOfSections++;
    }
    
	return numberOfSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    if (section == kSectionAddress) {
        numberOfRows = 1;
    } else if (section == kSectionAdultsOrMinors) {
        numberOfRows = [adults count] ? [adults count] : [minors count];
    } else if (section == kSectionMinors) {
        numberOfRows = [minors count];
    }
    
	return numberOfRows;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.f;
    
    if (indexPath.section == kSectionAddress) {
        height = [ScTableViewCell heightForEntity:scola];
    } else {
        height = 1.2 * self.tableView.rowHeight;
    }
    
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ScTableViewCell *cell = [ScTableViewCell defaultCellForTableView:tableView];
    
    if (indexPath.section == kSectionAddress) {
        [cell populateWithEntity:scola];
        
        if (isUserScolaAdmin) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else {
        NSArray *memberSubset = nil;
        
        if (indexPath.section == kSectionAdultsOrMinors) {
            memberSubset = [adults count] ? adults : minors;
        } else if (indexPath.section == kSectionMinors) {
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
    BOOL canEdit = isUserScolaAdmin;
    
    if (!canEdit && (indexPath.section != indexPath.section)) {
        ScMember *member = nil;
        
        if (indexPath.section == kSectionAdultsOrMinors) {
            if ([adults count]) {
                member = [adults objectAtIndex:indexPath.row];
            } else {
                member = [minors objectAtIndex:indexPath.row];
            }
        } else {
            member = [minors objectAtIndex:indexPath.row];
        }
        
        canEdit = [member.entityId isEqualToString:[ScMeta m].userId];
    }
    
    return canEdit;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{   
    [cell.backgroundView addShadow];
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0;
    
    if (section != kSectionAddress) {
        height = 4.f * [UIFont boldSystemFontOfSize:kHeaderFontSize].xHeight;
    }
    
    return height;
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat height = 0;
    
    if (section != kSectionAddress) {
        NSString *footer = [ScStrings stringForKey:strHouseholdMemberListFooter];
        UIFont *footerFont = [UIFont systemFontOfSize:kFooterFontSize];
        CGSize footerSize = [footer sizeWithFont:footerFont constrainedToSize:CGSizeMake(280.f, 10.f * footerFont.xHeight) lineBreakMode:UILineBreakModeWordWrap];
        
        height = footerSize.height + 15.f;
    }
    
    return height;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = nil;
    
    if (section != kSectionAddress) {
        CGFloat headerHeight = [self tableView:tableView heightForHeaderInSection:section];
        CGRect headerViewFrame = CGRectMake(0.f, 0.f, 320.f, headerHeight);
        CGRect headerFrame = CGRectMake(10.f, 0.f, 300.f, headerHeight);
        
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
    
    if ((section != kSectionAddress) && isUserScolaAdmin) {
        CGFloat footerHeight = [self tableView:tableView heightForFooterInSection:section];
        CGRect footerViewFrame = CGRectMake(0.f, 0.f, 320.f, footerHeight);
        CGRect footerFrame = CGRectMake(20.f, 10.f, 280.f, footerHeight);
        
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
    
    if (indexPath.section != kSectionAddress) {
        deleteConfirmationTitle = [ScStrings stringForKey:strDeleteConfirmation];
    }
    
    return deleteConfirmationTitle;
}

@end
