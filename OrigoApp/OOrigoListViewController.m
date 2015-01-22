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
    
    NSString *prompt = NSLocalizedString(@"What sort of list do you want to create", @"");
    
    if ([_member isWardOfUser]) {
        prompt = [prompt stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"for %@", @""), [_member givenName]] separator:kSeparatorSpace];
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:[prompt stringByAppendingString:@"?"] delegate:self tag:kActionSheetTagOrigoType];
    
    for (NSString *origoType in _origoTypes) {
        if ([origoType isEqualToString:kOrigoTypeList]) {
            if ([_member isJuvenile]) {
                [actionSheet addButtonWithTitle:@"Privat venneliste"];
            } else {
                [actionSheet addButtonWithTitle:@"Privat kontaktliste"];
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
        
        if ([origo isOfType:kOrigoTypeList]) {
            keyMember = [origo owner];
        } else if ([[origo members] count] == 1) {
            keyMember = [origo members][0];
        }

        canDelete = [keyMember isUser] || ([keyMember isWardOfUser] && ![keyMember isActive]);
    }
    
    return canDelete;
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
    }
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    if ([self targetIs:kTargetHiddenOrigos]) {
        self.title = NSLocalizedString(self.target, kStringPrefixSettingListLabel);
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
        [self setData:[NSArray array] forSectionWithKey:kSectionKeyWardOrigos];
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    id<OOrigo> origo = [self dataAtIndexPath:indexPath];
    
    if ([origo isOfType:kOrigoTypeStash]) {
        cell.textLabel.text = NSLocalizedString(@"Favourites and others", @"");
        cell.destinationId = kIdentifierValueList;
    } else {
        id<OMember> member = sectionKey == kSectionKeyWardOrigos ? _wards[self.selectedHeaderSegment] : [OMeta m].user;
        id<OMembership> membership = [origo membershipForMember:member];
        
        if ([origo isOfType:kOrigoTypeList] && ![member isUser] && [member isJuvenile]) {
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
            if ([membership.status isEqualToString:kMembershipStatusInvited]) {
                cell.notificationText = NSLocalizedString(@"New!", @"");
            } else {
                cell.notificationText = nil;
            }
            
            if ([origo isOfType:kOrigoTypeResidence]) {
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


- (id)defaultTarget
{
    return [[OMeta m] userIsSignedIn] ? [OMeta m].user : nil;
}


- (id)destinationTargetForIndexPath:(NSIndexPath *)indexPath
{
    id target = [self dataAtIndexPath:indexPath];
    
    if ([target isOfType:kOrigoTypeStash]) {
        target = kTargetFavourites;
    }
    
    return target;
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
    
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyUser) {
        if (![[self dataAtIndexPath:indexPath] isOfType:kOrigoTypeStash]) {
            canDelete = [[[OMeta m].user residences] count] > 1;
        }
    } else {
        canDelete = YES;
    }
    
    return canDelete;
}


- (NSString *)deleteConfirmationButtonTitleForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *buttonTitle = nil;
    
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyUser) {
        buttonTitle = NSLocalizedString(@"Move out", @"");
    } else if (![self canDeleteOrigoAtIndexPath:indexPath]) {
        buttonTitle = NSLocalizedString(@"Hide", @"");
    }
    
    return buttonTitle;
}


- (BOOL)shouldDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL shouldDeleteCell = YES;
    
    id<OOrigo> origo = [self dataAtIndexPath:indexPath];
    
    if ([origo userIsAdmin] && [[origo admins] count] == 1) {
        [OAlert showAlertWithTitle:NSLocalizedString(@"You are administrator", @"") text:NSLocalizedString(@"You are the only administrator of this group ...", @"")];
        
        shouldDeleteCell = NO;
    }
    
    return shouldDeleteCell;
}


- (void)willDeleteCellAtIndexPath:(NSIndexPath *)indexPath
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
        if ([origo isOfType:kOrigoTypeList]) {
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
