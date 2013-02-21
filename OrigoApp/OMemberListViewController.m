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

static NSInteger const kOrigoSectionKey = 0;
static NSInteger const kContactSection = 1;
static NSInteger const kMemberSection = 2;

static NSInteger const kHousemateSheetTag = 0;


@implementation OMemberListViewController

#pragma mark - Actions sheets

- (void)promptForHousemate:(NSSet *)candidates
{
    _candidateHousemates = [candidates sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:kPropertyKeyName ascending:YES]]];
    
    UIActionSheet *housemateSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    for (OMember *candidate in _candidateHousemates) {
        [housemateSheet addButtonWithTitle:candidate.name];
    }
    
    [housemateSheet addButtonWithTitle:[OStrings stringForKey:strButtonNewHousemate]];
    [housemateSheet addButtonWithTitle:[OStrings stringForKey:strButtonCancel]];
    housemateSheet.cancelButtonIndex = [candidates count] + 1;
    housemateSheet.tag = kHousemateSheetTag;
    
    [housemateSheet showInView:self.view];
}


#pragma mark - Selector implementations

- (void)addMember
{
    NSMutableSet *candidates = [[NSMutableSet alloc] init];
    
    if ([_origo isOfType:kOrigoTypeResidence]) {
        for (OMember *housemate in [_membership.member housemates]) {
            if (![_origo hasMember:housemate]) {
                [candidates addObject:housemate];
            }
        }
    }
    
    if ([candidates count]) {
        [self promptForHousemate:candidates];
    } else {
        [self performSegueWithIdentifier:kModalSegueToMemberView sender:self];
    }
}


- (void)didFinishEditing
{
    [self.dismisser dismissModalViewControllerWithIdentitifier:kMemberListViewControllerId];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([_origo isOfType:kOrigoTypeResidence]) {
        if ([_origo userIsMember]) {
            self.title = _origo.name;
        } else {
            self.title = [OStrings stringForKey:strViewTitleHousehold];
        }
    } else {
        self.title = [OStrings stringForKey:strViewTitleMembers];
    }
    
    if ([_origo userCanEdit]) {
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


#pragma mark - UIViewController overrides

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

- (void)prepareState
{
    _membership = self.data;
    _origo = _membership.origo;
    
    self.aspectCarrier = _origo;
}


- (void)populateDataSource
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
    
    [self setData:_origo forSectionWithKey:kOrigoSectionKey];
    [self setData:contactMemberships forSectionWithKey:kContactSection];
    [self setData:regularMemberships forSectionWithKey:kMemberSection];
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return ([super hasFooterForSectionWithKey:sectionKey] && [_origo userCanEdit]);
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kContactSection) {
        text = [OStrings stringForKey:strHeaderContacts];
    } else if (sectionKey == kMemberSection) {
        if ([_origo isOfType:kOrigoTypeResidence]) {
            text = [OStrings stringForKey:strHeaderHouseholdMembers];
        } else {
            text = [OStrings stringForKey:strHeaderOrigoMembers];
        }
    }
    
    return text;
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if ([_origo isOfType:kOrigoTypeResidence]) {
        text = [OStrings stringForKey:strFooterResidence];
    } else if ([_origo isOfType:kOrigoTypeSchoolClass]) {
        text = [OStrings stringForKey:strFooterSchoolClass];
    } else if ([_origo isOfType:kOrigoTypePreschoolClass]) {
        text = [OStrings stringForKey:strFooterPreschoolClass];
    } else if ([_origo isOfType:kOrigoTypeSportsTeam]) {
        text = [OStrings stringForKey:strFooterSportsTeam];
    } else {
        text = [OStrings stringForKey:strFooterOtherOrigo];
    }
    
    return text;
}


- (void)didSelectRow:(NSInteger)row inSectionWithKey:(NSInteger)sectionKey
{
    if (sectionKey == kOrigoSectionKey) {
        [self performSegueWithIdentifier:kPushSegueToOrigoView sender:self];
    } else {
        [self performSegueWithIdentifier:kPushSegueToMemberView sender:self];
    }
}


#pragma mark - OTableViewListCellDelegate conformance

- (NSString *)listTextForIndexPath:(NSIndexPath *)indexPath
{
    OMember *member = [[self entityForIndexPath:indexPath] member];
    
    return [member isMinor] ? [member displayNameAndAge] : member.name;
}


- (NSString *)listDetailsForIndexPath:(NSIndexPath *)indexPath
{
    return [[[self entityForIndexPath:indexPath] member] displayContactDetails];
}


- (UIImage *)listImageForIndexPath:(NSIndexPath *)indexPath
{
    return [[[self entityForIndexPath:indexPath] member] displayImage];
}


#pragma mark - UITableViewDataSource conformance

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDeleteRow = NO;
    
    if (indexPath.section != kOrigoSectionKey) {
        OMembership *membershipForRow = [self entityForIndexPath:indexPath];
        canDeleteRow = ([_origo userIsAdmin] && ![membershipForRow.member isUser]);
    }
    
    return canDeleteRow;
}


- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [OStrings stringForKey:strButtonDeleteMember];
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case kHousemateSheetTag:
            if (buttonIndex == actionSheet.numberOfButtons - 2) {
                [self performSegueWithIdentifier:kModalSegueToMemberView sender:self];
            } else if (buttonIndex < actionSheet.numberOfButtons - 2) {
                [_origo addResident:_candidateHousemates[buttonIndex]];
                [self reloadSectionsIfNeeded];
            }
            
            break;
            
        default:
            break;
    }
}

@end
