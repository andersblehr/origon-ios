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

- (void)presentAddOrigoSheet
{
    _origoTypes = [NSMutableArray array];
    [_origoTypes addObject:kOrigoTypeStandard];
    
    if (![[OMeta m].user isJuvenile]) {
        if ([_member isJuvenile]) {
            if (![_member isOlderThan:kAgeThresholdInSchool]) {
                [_origoTypes addObject:kOrigoTypePreschoolClass];
            }
            
            [_origoTypes addObjectsFromArray:@[kOrigoTypeSchoolClass, kOrigoTypeTeam]];
        } else {
            [_origoTypes addObjectsFromArray:@[kOrigoTypeCommunity, kOrigoTypeTeam, kOrigoTypeStudyGroup, kOrigoTypeAlumni]];
        }
    }
    
    [_origoTypes addObject:kOrigoTypePrivate];
    
    NSString *prompt = NSLocalizedString(@"What sort of list do you want to create", @"");
    
    if ([_member isWardOfUser]) {
        prompt = [prompt stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"for %@", @""), [_member givenName]] separator:kSeparatorSpace];
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:[prompt stringByAppendingString:@"?"] delegate:self tag:kActionSheetTagOrigoType];
    
    for (NSString *origoType in _origoTypes) {
        if ([origoType isEqualToString:kOrigoTypePrivate]) {
            if ([_member isJuvenile]) {
                [actionSheet addButtonWithTitle:NSLocalizedString(@"Private list of friends", @"")];
            } else {
                [actionSheet addButtonWithTitle:NSLocalizedString(@"Private contact list", @"")];
            }
        } else {
            [actionSheet addButtonWithTitle:NSLocalizedString(origoType, kStringPrefixOrigoTitle)];
        }
    }
    
    [actionSheet show];
}


- (BOOL)canDeleteOrigoAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDelete = NO;
    
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyUser) {
        canDelete = YES;
    } else {
        id<OOrigo> origo = [self dataAtIndexPath:indexPath];
        id<OMember> keyMember = nil;
        
        if ([origo isPrivate]) {
            keyMember = [origo owner];
        } else if ([[origo members] count] == 1) {
            keyMember = [origo members][0];
        }

        if (keyMember && origo != [keyMember pinnedFriendList]) {
            if ([keyMember isUser]) {
                if ([keyMember isJuvenile]) {
                    canDelete = [origo userIsCreator];
                } else {
                    canDelete = YES;
                }
            } else if ([keyMember isWardOfUser]) {
                canDelete = ![keyMember isActive] || [origo userIsCreator];
            }
        }
    }
    
    return canDelete;
}


#pragma mark - Selector implementations

- (void)performSettingsAction
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


- (void)performTextAction
{
    [self presentModalViewControllerWithIdentifier:kIdentifierRecipientPicker target:@{kTargetText: kAspectGlobal}];
}


- (void)performEmailAction
{
    [self presentModalViewControllerWithIdentifier:kIdentifierRecipientPicker target:@{kTargetEmail: kAspectGlobal}];
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
    } else if (![[OMeta m].user isActive]) {
        [[OMeta m].user makeActive];
    }
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    if ([self targetIs:kTargetHiddenOrigos]) {
        self.title = NSLocalizedString(self.target, kStringPrefixSettingLabel);
    } else {
        self.title = [OMeta m].appName;
        [self setSubtitle:[OMeta m].user.name];
        
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem settingsButtonWithTarget:self];
        
        if ([[OMeta m].user isTeenOrOlder]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
        }
    }
}


- (void)loadData
{
    if ([self targetIs:kTargetHiddenOrigos]) {
        NSMutableArray *wardsWithHiddenOrigos = [NSMutableArray array];
        
        for (id<OMember> ward in [[OMeta m].user wards]) {
            if ([[ward hiddenOrigos] count]) {
                [wardsWithHiddenOrigos addObject:ward];
            }
        }
        
        _wards = wardsWithHiddenOrigos;
        
        [self setData:[[OMeta m].user hiddenOrigos] forSectionWithKey:kSectionKeyOrigos];
    } else if (_member) {
        _wards = [[OMeta m].user wards];
        
        [self setData:[[OMeta m].user residences] forSectionWithKey:kSectionKeyUser];
        [self appendData:[[OMeta m].user stash] toSectionWithKey:kSectionKeyUser];
        [self setData:[[OMeta m].user origos] forSectionWithKey:kSectionKeyOrigos];
    }
    
    if ([_wards count]) {
        if (self.selectedHeaderSegment > [_wards count] - 1) {
            self.selectedHeaderSegment = [_wards count] - 1;
        }
        
        NSArray *wardOrigos = nil;
        
        if ([self targetIs:kTargetHiddenOrigos]) {
            wardOrigos = [_wards[self.selectedHeaderSegment] hiddenOrigos];
        } else {
            wardOrigos = [_wards[self.selectedHeaderSegment] origos];
        }
        
        [self setData:wardOrigos forSectionWithKey:kSectionKeyWardOrigos];
    } else {
        [self setData:@[] forSectionWithKey:kSectionKeyWardOrigos];
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    id<OOrigo> origo = [self dataAtIndexPath:indexPath];
    
    if ([origo isStash]) {
        cell.textLabel.text = NSLocalizedString(@"Favourites and others", @"");
        cell.destinationId = kIdentifierValueList;
        cell.destinationTarget = kTargetFavourites;
    } else {
        id<OMember> member = sectionKey == kSectionKeyWardOrigos ? _wards[self.selectedHeaderSegment] : [OMeta m].user;
        id<OMembership> membership = [origo membershipForMember:member];
        
        if ([origo isPrivate] && ![member isUser] && [member isJuvenile]) {
            if ([[origo displayName] isEqualToString:NSLocalizedString(@"Friends", @"")]) {
                cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@'s friends", @""), [member givenName]];
            } else {
                cell.textLabel.text = [origo displayName];
            }
        } else {
            cell.textLabel.text = [origo displayName];
        }
        
        cell.destinationId = kIdentifierOrigo;
        
        BOOL userIsOrigoElder = [origo userIsOrganiser] || [origo userIsParentContact];
        
        if (userIsOrigoElder && sectionKey == kSectionKeyOrigos) {
            cell.detailTextLabel.text = [[OUtil commaSeparatedListOfStrings:[membership roles] conjoin:NO conditionallyLowercase:YES] stringByCapitalisingFirstLetter];
        } else {
            if (![membership isHidden] && [membership needsAccepting]) {
                cell.notificationText = NSLocalizedString(@"New!", @"");
            } else {
                cell.notificationText = nil;
            }
            
            if ([origo isResidence]) {
                cell.detailTextLabel.text = [origo singleLineAddress];
            } else {
                cell.detailTextLabel.text = origo.descriptionText;
            }
        }
    }
    
    [cell loadImageForOrigo:origo];
}


- (void)didSetEntity:(id)entity
{
    _member = entity;
}


- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasHeader = sectionKey != kSectionKeyUser;
    
    if ([self targetIs:kTargetHiddenOrigos]) {
        hasHeader = hasHeader && sectionKey != kSectionKeyOrigos;
    }
    
    return hasHeader;
}


- (id)headerContentForSectionWithKey:(NSInteger)sectionKey
{
    id headerContent = nil;
    
    if (sectionKey == kSectionKeyOrigos && ![self targetIs:kTargetHiddenOrigos]) {
        headerContent = NSLocalizedString(@"My lists", @"");
    } else if (sectionKey == kSectionKeyWardOrigos) {
        NSMutableArray *wardGivenNames = [NSMutableArray array];
        
        for (id<OMember> ward in _wards) {
            [wardGivenNames addObject:[ward givenName]];
        }
        
        headerContent = wardGivenNames;
    }
    
    return headerContent;
}


- (NSString *)emptyTableViewFooterText
{
    return [self targetIs:kTargetHiddenOrigos] ? NSLocalizedString(@"No hidden lists.", @"") : nil;
}


- (BOOL)toolbarHasSendTextButton
{
    BOOL hasSendTextButton = NO;
    
    for (id<OMember> recipientCandidate in [self.state eligibleCandidates]) {
        if ([recipientCandidate.mobilePhone hasValue]) {
            hasSendTextButton = YES;
            
            break;
        }
    }
    
    return hasSendTextButton;
}


- (BOOL)toolbarHasSendEmailButton
{
    BOOL hasSendEmailButton = NO;
    
    for (id<OMember> recipientCandidate in [self.state eligibleCandidates]) {
        if ([recipientCandidate.email hasValue]) {
            hasSendEmailButton = YES;
            
            break;
        }
    }
    
    return hasSendEmailButton;
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (![self targetIs:kTargetHiddenOrigos]) {
        if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyWardOrigos) {
            id<OMember> ward = _wards[self.selectedHeaderSegment];
            
            self.target = ward;
            self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:[ward givenName]];
        } else if (self.target != [OMeta m].user) {
            self.target = [OMeta m].user;
            self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:[OMeta m].appName];
        }
    }
}


- (BOOL)canDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDelete = NO;
    
    if (![self targetIs:kTargetHiddenOrigos]) {
        NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
        id<OOrigo> origo = [self dataAtIndexPath:indexPath];
        
        if (sectionKey == kSectionKeyUser) {
            if (![origo isStash]) {
                canDelete = [[[OMeta m].user residences] count] > 1;
            }
        } else if (sectionKey == kSectionKeyOrigos) {
            if ([[OMeta m].user isJuvenile]) {
                canDelete = [origo userIsCreator] || [origo isCommunity];
            } else {
                canDelete = YES;
            }
        } else if (sectionKey == kSectionKeyWardOrigos) {
            if ([origo isPrivate]) {
                canDelete = [self canDeleteOrigoAtIndexPath:indexPath];
            } else {
                canDelete = YES;
            }
        }
    }

    return canDelete;
}


- (NSString *)deleteConfirmationButtonTitleForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *buttonTitle = nil;
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyUser) {
        buttonTitle = NSLocalizedString(@"Move out", @"");
    } else {
        id<OOrigo> origo = [self dataAtIndexPath:indexPath];
        
        if (![origo isPrivate] && ![self canDeleteOrigoAtIndexPath:indexPath]) {
            buttonTitle = NSLocalizedString(@"Hide", @"");
        }
    }
    
    return buttonTitle;
}


- (BOOL)shouldDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL shouldDeleteCell = YES;
    
    id<OOrigo> origo = [self dataAtIndexPath:indexPath];
    
    if ([[origo members] count] > 1 && [origo userIsAdmin]) {
        [OAlert showAlertWithTitle:NSLocalizedString(@"You are administrator", @"") text:NSLocalizedString(@"You are an administrator of this list. If you want to hide it, you must appoint another administrator and remove yourself as administrator.", @"")];
        
        shouldDeleteCell = NO;
    }
    
    return shouldDeleteCell;
}


- (void)deleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    id<OOrigo> origo = [self dataAtIndexPath:indexPath];
    id<OMember> keyMember = nil;
    
    if (sectionKey == kSectionKeyUser || sectionKey == kSectionKeyOrigos) {
        keyMember = [OMeta m].user;
    } else if (sectionKey == kSectionKeyWardOrigos) {
        keyMember = _wards[self.selectedHeaderSegment];
    }
    
    if ([self canDeleteOrigoAtIndexPath:indexPath]) {
        if ([origo isPrivate]) {
            for (id<OMember> member in [origo members]) {
                [[origo membershipForMember:member] expire];
            }
        }
        
        [[origo membershipForMember:keyMember] expire];
    } else {
        [origo membershipForMember:keyMember].status = kMembershipStatusListed;
    }
    
    [[OMeta m].replicator replicate];
}


- (BOOL)supportsPullToRefresh
{
    return YES;
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
