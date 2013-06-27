//
//  OMemberListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMemberListViewController.h"

#import "UIBarButtonItem+OrigoExtensions.h"

#import "NSDate+OrigoExtensions.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"

#import "OMember+OrigoExtensions.h"
#import "OMembership+OrigoExtensions.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"

static NSString * const kSegueToMemberView = @"segueFromMemberListToMemberView";
static NSString * const kSegueToOrigoView = @"segueFromMemberListToOrigoView";

static NSInteger const kOrigoSectionKey = 0;
static NSInteger const kContactSectionKey = 1;
static NSInteger const kMemberSectionKey = 2;

static NSInteger const kHousemateSheetTag = 0;


@implementation OMemberListViewController

#pragma mark - Auxiliary methods

- (BOOL)targetIsMinors
{
    BOOL targetIsMinors = NO;
    
    targetIsMinors = targetIsMinors || [self targetIs:kOrigoTypePreschoolClass];
    targetIsMinors = targetIsMinors || [self targetIs:kOrigoTypeSchoolClass];
    
    return targetIsMinors;
}


- (NSString *)listCellTextForMember:(OMember *)member
{
    NSString *text = nil;
    
    if ([member isMinor]) {
        text = [member.givenName stringByAppendingFormat:@" (%d)", [member.dateOfBirth yearsBeforeNow]];
    } else {
        text = member.name;
    }
    
    return text;
}


- (NSString *)listCellDetailTextForMember:(OMember *)member
{
    NSString *detailText = nil;
    
    if ([member hasValueForKey:kPropertyKeyMobilePhone]) {
        detailText = [NSString stringWithFormat:@"(%@) %@", [OStrings stringForKey:strLabelAbbreviatedMobilePhone], member.mobilePhone];
    } else if ([member hasValueForKey:kPropertyKeyEmail]) {
        detailText = [NSString stringWithFormat:@"(%@) %@", [OStrings stringForKey:strLabelAbbreviatedEmail], member.email];
    }
    
    return detailText;
}


- (UIImage *)listCellImageForMember:(OMember *)member
{
    UIImage *image = nil;
    
    if (member.photo || member.dateOfBirth) {
        image = [member listCellImage];
    } else {
        if ([self targetIsMinors]) {
            if ([_origo memberIsContact:member]) {
                image = [UIImage imageNamed:[member isMale] ? kIconFileMan : kIconFileWoman];
            } else {
                image = [UIImage imageNamed:[member isMale] ? kIconFileBoy : kIconFileGirl];
            }
        } else {
            image = [UIImage imageNamed:[member isMale] ? kIconFileMan : kIconFileWoman];
        }
    }
    
    return image;
}


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
        [self presentModalViewControllerWithIdentifier:kViewControllerMember data:_origo];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = _origo.name;
    
    if ([_origo userCanEdit]) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem addButtonWithTarget:self];
        self.navigationItem.rightBarButtonItem.action = @selector(addMember);
        
        if (self.dismisser) {
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
        }
    }
}


#pragma mark - UIViewController overrides

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToOrigoView]) {
        [self prepareForPushSegue:segue data:_membership];
    } else {
        [self prepareForPushSegue:segue];
    }
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialiseState
{
    _membership = self.data;
    _origo = _membership.origo;
    
    self.target = _origo;
}


- (void)initialiseDataSource
{
    NSMutableSet *contactMemberships = [[NSMutableSet alloc] init];
    NSMutableSet *regularMemberships = [[NSMutableSet alloc] init];
    
    for (OMembership *membership in [_origo fullMemberships]) {
        if ([membership hasContactRole]) {
            [contactMemberships addObject:membership];
        } else {
            [regularMemberships addObject:membership];
        }
    }
    
    [self setData:_origo forSectionWithKey:kOrigoSectionKey];
    [self setData:contactMemberships forSectionWithKey:kContactSectionKey];
    [self setData:regularMemberships forSectionWithKey:kMemberSectionKey];
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return ([super hasFooterForSectionWithKey:sectionKey] && [_origo userCanEdit]);
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kContactSectionKey) {
        text = [OStrings stringForKey:strHeaderContacts];
    } else if (sectionKey == kMemberSectionKey) {
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


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kOrigoSectionKey) {
        [self performSegueWithIdentifier:kSegueToOrigoView sender:self];
    } else if ((sectionKey == kContactSectionKey) || (sectionKey == kMemberSectionKey)) {
        [self performSegueWithIdentifier:kSegueToMemberView sender:self];
    }
}


#pragma mark - OTableViewListCellDelegate conformance

- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    OMember *member = [[self dataAtIndexPath:indexPath] asMembership].member;
    
    cell.textLabel.text = [self listCellTextForMember:member];
    cell.detailTextLabel.text = [self listCellDetailTextForMember:member];
    cell.imageView.image = [self listCellImageForMember:member];
}


#pragma mark - UITableViewDataSource conformance

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDeleteRow = NO;
    
    if (indexPath.section != kOrigoSectionKey) {
        OMembership *membershipForRow = [self dataAtIndexPath:indexPath];
        canDeleteRow = [_origo userIsAdmin] && ![membershipForRow.member isUser];
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
                [self presentModalViewControllerWithIdentifier:kViewControllerMember data:_origo];
            } else if (buttonIndex < actionSheet.numberOfButtons - 2) {
                [_origo addMember:_candidateHousemates[buttonIndex]];
                [self reloadSectionsIfNeeded];
            }
            
            break;
            
        default:
            break;
    }
}

@end
