//
//  OMemberListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMemberListViewController.h"

#import "NSManagedObjectContext+OrigoExtensions.h"
#import "UIBarButtonItem+OrigoExtensions.h"
#import "UITableView+OrigoExtensions.h"

#import "OEntityObservingDelegate.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextView.h"

#import "OMember+OrigoExtensions.h"
#import "OMembership+OrigoExtensions.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"

#import "OMemberViewController.h"
#import "OOrigoViewController.h"

static NSString * const kModalSegueToMemberView = @"modalFromMemberListToMemberView";
static NSString * const kPushSegueToMemberView = @"pushFromMemberListToMemberView";
static NSString * const kPushSegueToOrigoView = @"pushFromMemberListToOrigoView";

static NSInteger const kOrigoSection = 0;
static NSInteger const kContactSection = 1;
static NSInteger const kMemberSection = 2;


@implementation OMemberListViewController

#pragma mark - Selector implementations

- (void)addMember
{
    [self performSegueWithIdentifier:kModalSegueToMemberView sender:self];
}


- (void)didFinishEditing
{
    [self.dismisser dismissModalViewControllerWithIdentitifier:kMemberListViewControllerId];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([_origo isResidence]) {
        if ([_origo userIsMember]) {
            self.title = _origo.name;
        } else {
            self.title = [OStrings stringForKey:strViewTitleHousehold];
        }
    } else {
        self.title = [OStrings stringForKey:strViewTitleMembers];
    }
    
    if ([_origo userIsAdmin] || (![_origo hasAdmin] && [_origo userIsCreator])) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem addButtonWithTarget:self];
        self.navigationItem.rightBarButtonItem.action = @selector(addMember);
        
        if (self.dismisser) {
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    OLogState;
}


#pragma mark - Segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kModalSegueToMemberView]) {
        [self prepareForModalSegue:segue data:_origo];
    } else if ([segue.identifier isEqualToString:kPushSegueToOrigoView]) {
        [self prepareForPushSegue:segue data:_membership];
    } else {
        [self prepareForPushSegue:segue];
    }
}


#pragma mark - OTableViewControllerDelegate conformance

- (void)loadState
{
    _membership = self.data;
    _origo = _membership.origo;
    
    self.state.actionIsList = YES;
    self.state.targetIsMember = YES;
    self.state.aspectIsOrigo = YES;
}


- (void)loadData
{
    NSMutableSet *contactMemberships = [[NSMutableSet alloc] init];
    NSMutableSet *regularMemberships = [[NSMutableSet alloc] init];
    
    for (OMembership *membership in _origo.memberships) {
        if ([membership hasContactRole]) {
            [contactMemberships addObject:membership];
        } else {
            [regularMemberships addObject:membership];
        }
    }
    
    [self setData:_origo forSectionWithKey:kOrigoSection];
    [self setData:contactMemberships forSectionWithKey:kContactSection];
    [self setData:regularMemberships forSectionWithKey:kMemberSection];
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return ((sectionKey == kMemberSection) && [_origo userIsAdmin]);
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kContactSection) {
        text = [OStrings stringForKey:strHeaderContacts];
    } else if (sectionKey == kMemberSection) {
        if ([_origo isResidence]) {
            text = [OStrings stringForKey:strHeaderHouseholdMembers];
        } else {
            text = [OStrings stringForKey:strHeaderOrigoMembers];
        }
    }
    
    return text;
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    return [OStrings stringForKey:strFooterHousehold];
}


- (void)didSelectRow:(NSInteger)row inSectionWithKey:(NSInteger)sectionKey
{
    if (sectionKey == kOrigoSection) {
        [self performSegueWithIdentifier:kPushSegueToOrigoView sender:self];
    } else {
        [self performSegueWithIdentifier:kPushSegueToMemberView sender:self];
    }
}


#pragma mark - UITableViewDataSource conformance

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDeleteRow = NO;
    
    if (indexPath.section != kOrigoSection) {
        OMembership *membershipForRow = [self entityForIndexPath:indexPath];
        canDeleteRow = ([_origo userIsAdmin] && ![membershipForRow.member isUser]);
    }
    
    return canDeleteRow;
}


- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [OStrings stringForKey:strButtonDeleteMember];
}

@end
