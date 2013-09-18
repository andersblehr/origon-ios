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

- (BOOL)newHousemateIsGuardian
{
    return ![_origo userIsMember] && [_membership.member isWardOfUser];
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

- (void)addItem
{
    NSMutableSet *housemateCandidates = nil;
    
    if ([_origo isOfType:kOrigoTypeResidence]) {
        housemateCandidates = [[NSMutableSet alloc] init];
        
        for (OMember *housemate in [_membership.member housemates]) {
            if (![_origo hasMember:housemate]) {
                [housemateCandidates addObject:housemate];
            }
        }
    }
    
    if ([_origo isOfType:kOrigoTypeResidence] && [housemateCandidates count]) {
        [self presentHousemateCandidatesSheet:housemateCandidates];
    } else {
        [self presentModalViewControllerWithIdentifier:kIdentifierMember data:_origo];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([_origo userCanEdit]) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
        
        if (self.isModal) {
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
    
    self.state.target = _origo;
    
    if ([self targetIs:kOrigoTypeResidence] && ![self targetIs:kTargetHousehold]) {
        self.title = [_origo shortAddress];
    } else {
        self.title = _origo.name;
    }
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
    return [self isLastSectionKey:sectionKey] && [_origo userCanEdit];
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kSectionKeyContacts) {
        text = [[OLanguage nouns][_contact_][pluralIndefinite] capitalizedString];
    } else if (sectionKey == kSectionKeyMembers) {
        text = [OStrings labelForOrigoType:_origo.type labelType:kOrigoLabelTypeMemberList];
    }
    
    return text;
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    return [OStrings footerForOrigoType:_origo.type];
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
    
    cell.textLabel.text = member.name;
    cell.detailTextLabel.text = [member shortDetails];
    cell.imageView.image = [member smallImage];
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
                    [self presentModalViewControllerWithIdentifier:kIdentifierMember data:_origo meta:kMemberTypeGuardian];
                } else {
                    [self presentModalViewControllerWithIdentifier:kIdentifierMember data:_origo];
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
