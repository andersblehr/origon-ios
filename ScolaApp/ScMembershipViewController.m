//
//  ScMembershipViewController.m
//  ScolaApp
//
//  Created by Anders Blehr on 17.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScMembershipViewController.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"

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
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBarHidden = NO;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
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
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(addMember)];
        
        self.navigationItem.rightBarButtonItem = addButton;
        self.navigationItem.leftBarButtonItem = doneButton;
    } else {
        self.tabBarController.navigationItem.rightBarButtonItem = addButton;
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    CGFloat height = 1.1f * self.tableView.rowHeight;
    
    if ((indexPath.section == 0) && (indexPath.row == 0)) {
        height = (height * 0.5f) * [scola numberOfLinesInAddress];
    }
    
    return height;
}

@end
