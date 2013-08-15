//
//  OMemberListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMemberListViewController.h"

static NSString * const kSegueToMemberView = @"segueFromMemberListToMemberView";
static NSString * const kSegueToOrigoView = @"segueFromMemberListToOrigoView";

static NSInteger const kSectionKeyOrigo = 0;
static NSInteger const kSectionKeyContacts = 1;
static NSInteger const kSectionKeyMembers = 2;

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


- (BOOL)newHousemateIsGuardian
{
    return ![_origo userIsMember] && [_membership.member isWardOfUser];
}


- (NSString *)listCellTextForMember:(OMember *)member
{
    NSString *text = nil;
    
    if ([member isMinor] && [self targetIs:kOrigoTypeResidence]) {
        text = [member givenName];
        
        if ([member hasValueForKey:kPropertyKeyDateOfBirth]) {
            text = [text stringByAppendingFormat:@" (%d)", [member.dateOfBirth yearsBeforeNow]];
        }
    } else {
        text = member.name;
    }
    
    return text;
}


- (NSString *)listCellDetailTextForMember:(OMember *)member
{
    NSString *detailText = nil;
    
    if ([member hasValueForKey:kPropertyKeyMobilePhone]) {
        detailText = [member labeledMobilePhone];
    }
    
    return detailText;
}


- (UIImage *)listCellImageForMember:(OMember *)member
{
    UIImage *image = nil;
    
    if (member.photo || member.dateOfBirth) {
        image = [member smallImage];
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

- (void)presentHousemateCandidatesSheet:(NSSet *)candidates
{
    _housemateCandidates = [candidates sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:kPropertyKeyName ascending:YES]]];
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    for (OMember *candidate in _housemateCandidates) {
        [sheet addButtonWithTitle:candidate.name];
    }
    
    if ([self newHousemateIsGuardian]) {
        [sheet addButtonWithTitle:[OStrings stringForKey:strButtonOtherGuardian]];
    } else {
        [sheet addButtonWithTitle:[OStrings stringForKey:strButtonNewHousemate]];
    }
    
    [sheet addButtonWithTitle:[OStrings stringForKey:strButtonCancel]];
    sheet.cancelButtonIndex = [candidates count] + 1;
    sheet.tag = kHousemateSheetTag;
    
    [sheet showInView:self.actionSheetView];
}


#pragma mark - Selector implementations

- (void)presentActionSheet
{
    
}


- (void)addItem
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
        [self presentHousemateCandidatesSheet:candidates];
    } else {
        [self presentModalViewControllerWithIdentifier:kVCIdentifierMember data:_origo];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self targetIs:kOrigoTypeResidence] && ![self targetIs:kTargetHousehold]) {
        self.title = [_origo shortAddress];
    } else {
        self.title = _origo.name;
    }

    NSMutableArray *rightBarButtonItems = [[NSMutableArray alloc] init];
    
    if (![self targetIs:kOrigoTypeResidence]) {
        [rightBarButtonItems addObject:[UIBarButtonItem actionButtonWithTarget:self]];
    }
    
    if ([_origo userCanEdit]) {
        [rightBarButtonItems addObject:[UIBarButtonItem addButtonWithTarget:self]];
        
        if (self.isModal) {
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
        }
    }
    
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
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
    
    self.state.target = _origo;
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
    
    [self setData:_origo forSectionWithKey:kSectionKeyOrigo];
    [self setData:contactMemberships forSectionWithKey:kSectionKeyContacts];
    [self setData:regularMemberships forSectionWithKey:kSectionKeyMembers];
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return ([super hasFooterForSectionWithKey:sectionKey] && [_origo userCanEdit]);
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kSectionKeyContacts) {
        text = [OStrings stringForKey:strHeaderContacts];
    } else if (sectionKey == kSectionKeyMembers) {
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
    
    if (sectionKey == kSectionKeyOrigo) {
        [self performSegueWithIdentifier:kSegueToOrigoView sender:self];
    } else if ((sectionKey == kSectionKeyContacts) || (sectionKey == kSectionKeyMembers)) {
        [self performSegueWithIdentifier:kSegueToMemberView sender:self];
    }
}


- (BOOL)canDeleteRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDeleteRow = NO;
    
    if (indexPath.section != kSectionKeyOrigo) {
        OMembership *membershipForRow = [self dataAtIndexPath:indexPath];
        canDeleteRow = [_origo userIsAdmin] && ![membershipForRow.member isUser];
    }
    
    return canDeleteRow;
}


#pragma mark - OTableViewListDelegate conformance

- (NSString *)sortKeyForSectionWithKey:(NSInteger)sectionKey
{
    return [OUtil sortKeyWithPropertyKey:kPropertyKeyName relationshipKey:kRelationshipKeyMember];
}


- (BOOL)willCompareObjectsInSectionWithKey:(NSInteger)sectionKey
{
    return [self targetIs:kOrigoTypeResidence] && (sectionKey == kSectionKeyMembers);
}


- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2
{
    NSComparisonResult result = NSOrderedSame;
    
    OMember *member1 = [object1 asMembership].member;
    OMember *member2 = [object2 asMembership].member;
    
    BOOL member1IsMinor = [member1 isMinor];
    BOOL member2IsMinor = [member2 isMinor];
    
    if (member1IsMinor != member2IsMinor) {
        if (member1IsMinor && !member2IsMinor) {
            result = NSOrderedDescending;
        } else {
            result = NSOrderedAscending;
        }
    } else {
        result = [member1.name localizedCaseInsensitiveCompare:member2.name];
    }
    
    return result;
}


- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    OMember *member = [[self dataAtIndexPath:indexPath] asMembership].member;
    
    cell.textLabel.text = [self listCellTextForMember:member];
    cell.detailTextLabel.text = [self listCellDetailTextForMember:member];
    cell.imageView.image = [self listCellImageForMember:member];
}


#pragma mark - UITableViewDataSource conformance

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [OStrings stringForKey:strButtonDeleteMember];
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case kHousemateSheetTag:
            if (buttonIndex == actionSheet.cancelButtonIndex - 1) {
                if ([self newHousemateIsGuardian]) {
                    [self presentModalViewControllerWithIdentifier:kVCIdentifierMember data:_origo meta:kMemberTypeGuardian];
                } else {
                    [self presentModalViewControllerWithIdentifier:kVCIdentifierMember data:_origo];
                }
            } else if (buttonIndex < actionSheet.cancelButtonIndex - 1) {
                [_origo addMember:_housemateCandidates[buttonIndex]];
                [self reloadSections];
            }
            
            break;
            
        default:
            break;
    }
}

@end
