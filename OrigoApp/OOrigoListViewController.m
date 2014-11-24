//
//  OOrigoListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OOrigoListViewController.h"

static NSInteger const kActionSheetTagEditParents = 0;
static NSInteger const kButtonTagEditParentsYes = 0;

static NSInteger const kActionSheetTagNewOrigoParticipant = 1;
static NSInteger const kButtonTagNewOrigoParticipantUser = 0;

static NSInteger const kActionSheetTagOrigoType = 2;

static NSInteger const kSectionKeyUser = 0;
static NSInteger const kSectionKeyOrigos = 1;
static NSInteger const kSectionKeyWardOrigos = 2;


@interface OOrigoListViewController () <OTableViewController, UIActionSheetDelegate> {
@private
    id<OMember> _member;
    
    NSArray *_wards;
    NSMutableArray *_origoTypes;
    
    BOOL _needsEditParents;
}

@end


@implementation OOrigoListViewController

#pragma mark - Auxiliary methods

- (void)assembleOrigoTypes
{
    _origoTypes = [NSMutableArray array];
    
    [_origoTypes addObject:kOrigoTypeList];
    [_origoTypes addObject:kOrigoTypeSimple];
    
    if ([_member isJuvenile]) {
        if (![_member isOlderThan:kAgeThresholdInSchool]) {
            [_origoTypes addObject:kOrigoTypePreschoolClass];
        }
        
        [_origoTypes addObject:kOrigoTypeSchoolClass];
        [_origoTypes addObject:kOrigoTypeTeam];
    } else {
        [_origoTypes addObject:kOrigoTypeCommunity];
        [_origoTypes addObject:kOrigoTypeOrganisation];
        [_origoTypes addObject:kOrigoTypeTeam];
        [_origoTypes addObject:kOrigoTypeStudyGroup];
        [_origoTypes addObject:kOrigoTypeAlumni];
    }
}


- (void)presentAddOrigoSheet
{
    [self assembleOrigoTypes];
    
    NSString *prompt = NSLocalizedString(@"What sort of list do you want to create", @"");
    
    if ([_member isWardOfUser]) {
        prompt = [prompt stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"for %@", @""), [_member givenName]] separator:kSeparatorSpace];
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:[prompt stringByAppendingString:@"?"] delegate:self tag:kActionSheetTagOrigoType];
    
    for (NSString *origoType in _origoTypes) {
        [actionSheet addButtonWithTitle:NSLocalizedString(origoType, kStringPrefixOrigoTitle)];
    }
    
    [actionSheet show];
}


#pragma mark - Selector implementations

- (void)openSettings
{
    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetSettings];
}


- (void)performAddAction
{
    if ([_wards count]) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:NSLocalizedString(@"Who do you want to create a list for?", @"") delegate:self tag:kActionSheetTagNewOrigoParticipant];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Yourself", @"") tag:kButtonTagNewOrigoParticipantUser];
        
        for (id<OMember> ward in _wards) {
            [actionSheet addButtonWithTitle:[ward givenName]];
        }
        
        [actionSheet show];
    } else {
        [self presentAddOrigoSheet];
    }
}


#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (_needsEditParents) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:NSLocalizedString(@"Your household includes minors. Would you like to provide parent relations?", @"") delegate:self tag:kActionSheetTagEditParents];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Yes", @"") tag:kButtonTagEditParentsYes];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"No", @"")];
        
        [actionSheet show];
    } else if ([[OMeta m] userIsSignedIn] && ![[OMeta m] userIsRegistered]) {
        if (![[OMeta m].user.createdBy isEqualToString:[OMeta m].userEmail]) {
            [OAlert showAlertWithTitle:NSLocalizedString(@"Welcome to Origo", @"") text:NSLocalizedString(@"Please verify your details and provide any missing information.", @"")];
            
            for (id<OMember> ward in [[OMeta m].user wards]) {
                _needsEditParents = _needsEditParents || ![ward mother] || ![ward father];
            }
        } else if (![OMeta m].userDidJustSignUp) {
            [OAlert showAlertWithTitle:NSLocalizedString(@"Incomplete registration", @"") text:NSLocalizedString(@"You must complete your registration before you can start using Origo.", @"")];
        }
        
        [self presentModalViewControllerWithIdentifier:kIdentifierMember target:[OMeta m].user];
    }
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    self.title = [OMeta m].appName;
    [self setSubtitle:[OMeta m].user.name];
    
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem settingsButtonWithTarget:self];
    
    if ([[OMeta m].user isTeenOrOlder]) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
    }
}


- (void)loadData
{
    if (_member) {
        _wards = [[OMeta m].user wards];
        
        [self setData:[[OMeta m].user residences] forSectionWithKey:kSectionKeyUser];
        [self appendData:[[OMeta m].user stash] toSectionWithKey:kSectionKeyUser];
        
        if ([_wards count]) {
            [self setData:[_wards[self.selectedHeaderSegment] origos] forSectionWithKey:kSectionKeyWardOrigos];
        }
        
        [self setData:[[OMeta m].user origos] forSectionWithKey:kSectionKeyOrigos];
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    id<OOrigo> origo = [self dataAtIndexPath:indexPath];
    
    if ([origo isOfType:kOrigoTypeUserStash]) {
        cell.textLabel.text = NSLocalizedString(@"Favourites and others", @"");
        cell.destinationId = kIdentifierValueList;
    } else {
        id<OMember> member = sectionKey == kSectionKeyWardOrigos ? _wards[self.selectedHeaderSegment] : [OMeta m].user;
        id<OMembership> membership = [origo membershipForMember:member];
        
        if ([origo isOfType:kOrigoTypeList] && ![member isUser] && [member isJuvenile]) {
            if ([origo.name isEqualToString:NSLocalizedString(@"Friends", @"")]) {
                cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@'s friends", @""), [member givenName]];
            } else {
                cell.textLabel.text = origo.name;
            }
        } else {
            cell.textLabel.text = origo.name;
        }
        
        cell.destinationId = kIdentifierOrigo;
        
        BOOL userIsOrigoElder = [origo userIsOrganiser] || [origo userIsParentContact];
        
        if (userIsOrigoElder && sectionKey == kSectionKeyOrigos) {
            cell.detailTextLabel.text = [[OUtil commaSeparatedListOfStrings:[membership roles] conjoin:NO conditionallyLowercase:YES] stringByCapitalisingFirstLetter];
        } else {
            if ([membership.status isEqualToString:kMembershipStatusInvited]) {
                cell.detailTextLabel.text = NSLocalizedString(@"New listing", @"");
                cell.detailTextLabel.textColor = [UIColor notificationTextColour];
            } else {
                if ([origo isOfType:kOrigoTypeResidence]) {
                    cell.detailTextLabel.text = [origo singleLineAddress];
                } else {
                    cell.detailTextLabel.text = origo.descriptionText;
                }
                
                cell.detailTextLabel.textColor = [UIColor textColour];
            }
        }
    }
    
    [cell loadImageForOrigo:origo];
}


- (void)didSetEntity:(id)entity
{
    _member = entity;
}


- (id)defaultTarget
{
    return [[OMeta m] userIsSignedIn] ? [OMeta m].user : nil;
}


- (id)destinationTargetForIndexPath:(NSIndexPath *)indexPath
{
    id target = [self dataAtIndexPath:indexPath];
    
    if ([target isOfType:kOrigoTypeUserStash]) {
        target = kTargetFavourites;
    }
    
    return target;
}


- (id)headerContentForSectionWithKey:(NSInteger)sectionKey
{
    id headerContent = nil;
    
    if (sectionKey == kSectionKeyOrigos) {
        headerContent = NSLocalizedString(@"My lists", @"");
    } else if (sectionKey == kSectionKeyWardOrigos) {
        if ([_wards count] > 1) {
            NSMutableArray *wardGivenNames = [NSMutableArray array];
            
            for (id<OMember> ward in _wards) {
                [wardGivenNames addObject:[ward givenName]];
            }
            
            headerContent = wardGivenNames;
        } else {
            headerContent = [_wards[0] givenName];
        }
    }
    
    return headerContent;
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyWardOrigos) {
        id<OMember> ward = _wards[self.selectedHeaderSegment];
        
        self.target = ward;
        self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:[ward givenName]];
    } else if (self.target != [OMeta m].user) {
        self.target = [OMeta m].user;
        self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:[OMeta m].appName];
    }
}


- (BOOL)canDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDelete = NO;
    
    if ([self sectionKeyForIndexPath:indexPath] != kSectionKeyUser) {
        id<OOrigo> origo = [self dataAtIndexPath:indexPath];
        
        if ([origo userCanEdit]) {
            NSArray *members = [origo members];
            
            if ([members count] == 1) {
                canDelete = [members[0] isUser] || [members[0] isWardOfUser];
            }
        }
    }
    
    return canDelete;
}


- (void)willDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    id<OOrigo> origo = [self dataAtIndexPath:indexPath];
    
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyWardOrigos) {
        [[origo membershipForMember:_wards[self.selectedHeaderSegment]] expire];
    } else {
        [[origo membershipForMember:[OMeta m].user] expire];
    }
}


- (void)didDismissModalViewController:(OTableViewController *)viewController
{
    if ([[OMeta m] userIsSignedIn]) {
        [self reloadSections];
    }
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
        
        switch (actionSheet.tag) {
            case kActionSheetTagNewOrigoParticipant:
                if (buttonTag == kButtonTagNewOrigoParticipantUser) {
                    self.target = [OMeta m].user;
                } else {
                    NSInteger selectedWardIndex = buttonIndex - 1;
                    
                    if ([_wards count] > 1 && self.selectedHeaderSegment != selectedWardIndex) {
                        self.selectedHeaderSegment = selectedWardIndex;
                        [self reloadSectionWithKey:kSectionKeyWardOrigos];
                    }
                    
                    self.target = _wards[selectedWardIndex];
                }
                
                break;
                
            default:
                break;
        }
    }
}


- (void)actionSheet:(OActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
        
        switch (actionSheet.tag) {
            case kActionSheetTagEditParents:
                if (buttonTag == kButtonTagEditParentsYes) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetParents];
                }
                
                _needsEditParents = NO;
                
                break;
                
            case kActionSheetTagNewOrigoParticipant:
                [self presentAddOrigoSheet];
                
                break;
                
            case kActionSheetTagOrigoType:
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:_origoTypes[buttonIndex]];
                
                break;
                
            default:
                break;
        }
    }
}

@end
