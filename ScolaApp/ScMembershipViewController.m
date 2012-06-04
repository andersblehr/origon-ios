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

#import "ScMember.h"
#import "ScMembership.h"
#import "ScScola.h"

#import "ScMember+ScMemberExtensions.h"
#import "ScScola+ScScolaExtensions.h"


static NSString * const kReuseIdentifierEditableText = @"ptCellEditableText";
static NSString * const kReuseIdentifierEditableMember = @"ptCellEditableMember";

static NSInteger kSectionAddress = 0;
static NSInteger kSectionAdultsOrMinors = 1;
static NSInteger kSectionMinors = 2;


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
    
    addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMember)];
    
    unsortedAdults = [[NSMutableSet alloc] init];
    unsortedMinors = [[NSMutableSet alloc] init];
    
    for (ScMembership *membership in scola.memberships) {
        if ([membership.member isMinor]) {
            [unsortedMinors addObject:membership.member];
        } else {
            [unsortedAdults addObject:membership.member];
        }
    }
    
    adults = [[unsortedAdults allObjects] sortedArrayUsingSelector:@selector(compare:)];
    minors = [[unsortedMinors allObjects] sortedArrayUsingSelector:@selector(compare:)];
    
    isForHousehold = ([scola.residencies count] > 0);
    
    if (isForHousehold) {
        if ([scola.residencies count] == 1) {
            self.title = [ScStrings stringForKey:strMembershipViewHomeScolaTitle1];
        } else {
            self.title = [ScStrings stringForKey:strMembershipViewHomeScolaTitle2];
        }
    } else {
        self.title = [ScStrings stringForKey:strMembershipViewDefaultTitle];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tabBarController.title = self.title;
    
    if (isRegistrationWizardStep) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didFinishAddingMembers)];
        
        self.navigationItem.leftBarButtonItem = doneButton;
        self.navigationItem.rightBarButtonItem = addButton;
    } else {
        self.tabBarController.navigationItem.rightBarButtonItem = addButton;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //self.tableView.frame = CGRectMake(-20, 0, self.tableView.frame.size.width + 40, self.tableView.frame.size.height);
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
    NSInteger numberOfSections = isRegistrationWizardStep ? 0 : 1;
    
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
    NSInteger logicSection = isRegistrationWizardStep ? section + 1 : section;
    NSInteger numberOfRows = 0;
    
    if (logicSection == kSectionAddress) {
        if ([scola hasLandline]) {
            numberOfRows = 2;
        } else {
            numberOfRows = 1;
        }
    } else if (logicSection == kSectionAdultsOrMinors) {
        numberOfRows = [adults count] ? [adults count] : [minors count];
    } else if (logicSection == kSectionMinors) {
        numberOfRows = [minors count];
    }
    
	return numberOfRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int logicSection = isRegistrationWizardStep ? indexPath.section + 1 : indexPath.section;
    
    NSString *reuseIdentifier = nil;
    
    if (logicSection == kSectionAddress) {
        reuseIdentifier = kReuseIdentifierEditableText;
    } else {
        reuseIdentifier = kReuseIdentifierEditableMember;
    }
    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:reuseIdentifier];
	}
    
    if (logicSection == kSectionAddress) {
        if (indexPath.row == 0) {
            cell.textLabel.text = [ScStrings stringForKey:strAddress];;
            cell.detailTextLabel.text = [scola addressAsMultipleLines];
            cell.detailTextLabel.numberOfLines = [scola numberOfLinesInAddress];
        } else if (indexPath.row == 1) {
            cell.textLabel.text = [ScStrings stringForKey:strLandline];
            cell.detailTextLabel.text = scola.landline;
        }
    } else {
        NSArray *memberSubset = nil;
        
        if (logicSection == kSectionAdultsOrMinors) {
            memberSubset = [adults count] ? adults : minors;
        } else if (logicSection == kSectionMinors) {
            memberSubset = minors;
        }
        
        ScMember *member = [memberSubset objectAtIndex:indexPath.row];
        
        cell.textLabel.text = member.name;
        cell.detailTextLabel.text = member.mobilePhone;
    }
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int logicSection = isRegistrationWizardStep ? indexPath.section + 1 : indexPath.section;
    
    CGFloat height = 1.1f * self.tableView.rowHeight;
    
    if ((logicSection == 0) && (indexPath.row == 0)) {
        height = (height * 0.5f) * [scola numberOfLinesInAddress];
    }
    
    return height;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight = [self tableView:tableView heightForRowAtIndexPath:indexPath] + 1;
    
    cell.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, cell.backgroundView.frame.size.width, cellHeight)];
    cell.backgroundView.backgroundColor = [UIColor isabellineColor];
    
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, cell.backgroundView.frame.size.width, cellHeight)];
    cell.selectedBackgroundView.backgroundColor = [UIColor ashGrayColor];
    
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    
    int logicSection = isRegistrationWizardStep ? indexPath.section + 1 : indexPath.section;
    
    if (!((logicSection == 0) && (indexPath.row == 0))) {
        [cell.backgroundView addShadow];
    }
}


@end
