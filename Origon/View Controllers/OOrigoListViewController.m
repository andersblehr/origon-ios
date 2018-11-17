//
//  OOrigoListViewController.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OOrigoListViewController.h"

static NSInteger const kActionSheetTagEditParents = 0;
static NSInteger const kButtonTagEditParentsYes = 0;

static NSInteger const kActionSheetTagJoinOrigoTarget = 1;
static NSInteger const kActionSheetTagNewOrigoTarget = 2;
static NSInteger const kButtonTagOrigoTargetUser = 0;

static NSInteger const kActionSheetTagOrigoType = 3;

static NSInteger const kActionSheetTagDeclinedJoinRequest = 4;
static NSInteger const kButtonTagDeclinedJoinRequestDelete = 0;
static NSInteger const kButtonTagDeclinedJoinRequestResend = 1;

static NSInteger const kAlertTagDeleteCell = 0;

static NSInteger const kSectionKeyUser = 0;
static NSInteger const kSectionKeyOrigos = 1;
static NSInteger const kSectionKeyWardOrigos = 2;


@interface OOrigoListViewController () <OTableViewController, UIActionSheetDelegate, UIAlertViewDelegate> {
@private
    id<OMember> _member;
    id<OOrigo> _origo;
    
    NSArray *_wards;
    NSMutableArray *_origoTypes;
    NSIndexPath *_bookmarkedIndexPath;
    
    BOOL _needsEditParents;
}

@end


@implementation OOrigoListViewController

- (void)enableOrDisableButtons
{
    [self.navigationItem barButtonItemWithTag:kBarButtonItemTagPlus].enabled = self.isOnline;
    [self.navigationItem barButtonItemWithTag:kBarButtonItemTagJoin].enabled = self.isOnline;
}


- (void)presentAddOrigoSheet
{
    _origoTypes = [NSMutableArray array];
    [_origoTypes addObject:kOrigoTypeStandard];
    
    if (![[OMeta m].user isJuvenile]) {
        if ([_member isJuvenile]) {
            if (![_member isOlderThan:kAgeThresholdInSchool]) {
                [_origoTypes addObject:kOrigoTypePreschoolClass];
            }
            
            [_origoTypes addObjectsFromArray:@[kOrigoTypeSchoolClass, kOrigoTypeSports]];
        } else {
            [_origoTypes addObjectsFromArray:@[kOrigoTypeCommunity, kOrigoTypeSports]];
        }
    }
    
    [_origoTypes addObject:kOrigoTypePrivate];
    
    NSString *prompt = nil;
    
    if ([_member isUser]) {
        prompt = OLocalizedString(@"What sort of list do you want to create?", @"");
    } else {
        prompt = [NSString stringWithFormat:OLocalizedString(@"What sort of list do you want to create for %@?", @""), [_member givenName]];
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagOrigoType];
    
    for (NSString *origoType in _origoTypes) {
        if ([_member isJuvenile]) {
            if ([origoType isEqualToString:kOrigoTypeStandard] && [_member isUser]) {
                [actionSheet addButtonWithTitle:OLocalizedString(@"Shared list", @"")];
            } else if ([origoType isEqualToString:kOrigoTypePrivate]) {
                if ([_member isUser]) {
                    [actionSheet addButtonWithTitle:OLocalizedString(@"Private list", @"")];
                } else {
                    [actionSheet addButtonWithTitle:OLocalizedString(@"Private list of friends", @"")];
                }
            } else {
                [actionSheet addButtonWithTitle:OLocalizedString(origoType, kStringPrefixOrigoTitle)];
            }
        } else {
            [actionSheet addButtonWithTitle:OLocalizedString(origoType, kStringPrefixOrigoTitle)];
        }
    }
    
    [actionSheet show];
}


- (BOOL)canDeleteOrigoAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDelete = NO;
    
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyUser) {
        canDelete = YES;
    } else {
        id<OOrigo> origo = [self dataAtIndexPath:indexPath];
        id<OMembership> membership = nil;
        
        if (sectionKey == kSectionKeyOrigos) {
            membership = [origo userMembership];
        } else if (sectionKey == kSectionKeyWardOrigos) {
            membership = [origo membershipForMember:_wards[self.selectedHeaderSegment]];
        }
        
        if (([origo userIsAdmin] && ![origo isPrivate]) || [membership isRequested]) {
            canDelete = YES;
        } else {
            id<OMember> keyMember = nil;
            
            if ([origo isPrivate]) {
                keyMember = [origo owner];
            } else {
                if ([origo isCommunity] && [origo userIsCreator]) {
                    canDelete = YES;
                    
                    for (id<OMember> member in [origo members]) {
                        canDelete = canDelete && [member isHousemateOfUser];
                    }
                } else if ([origo members].count == 1) {
                    keyMember = [origo members][0];
                }
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
    }
    
    return canDelete;
}


#pragma mark - Selector implementations

- (void)didTapEmbeddedButton:(OButton *)embeddedButton
{
    id<OOrigo> origo = [self dataAtIndexPath:[self.tableView indexPathForCell:embeddedButton.embeddingCell]];
    
    [OAlert showAlertWithTitle:OLocalizedString(@"Join requests", @"") message:[NSString stringWithFormat:OLocalizedString(@"%@ has pending join requests.", @""), origo.name]];
}


- (void)performSettingsAction
{
    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetSettings];
}


- (void)performAddAction
{
    if (_wards.count) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:OLocalizedString(@"Who do you want to create a list for?", @"") delegate:self tag:kActionSheetTagNewOrigoTarget];
        [actionSheet addButtonWithTitle:OLocalizedString(@"Yourself", @"") tag:kButtonTagOrigoTargetUser];
        
        for (id<OMember> ward in _wards) {
            [actionSheet addButtonWithTitle:[ward givenName]];
        }
        
        [actionSheet show];
    } else {
        [self presentAddOrigoSheet];
    }
}


- (void)performJoinAction
{
    if (_wards.count) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:OLocalizedString(@"Who do you want to join to a list?", @"") delegate:self tag:kActionSheetTagJoinOrigoTarget];
        [actionSheet addButtonWithTitle:OLocalizedString(@"Yourself", @"") tag:kButtonTagOrigoTargetUser];
        
        for (id<OMember> ward in _wards) {
            [actionSheet addButtonWithTitle:[ward givenName]];
        }
        
        [actionSheet show];
    } else {
        [self presentModalViewControllerWithIdentifier:kIdentifierJoiner target:kTargetOrigo];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([[OMeta m] userIsAllSet]) {
        [[OMeta m].replicator refreshWithRefreshHandler:self];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (_needsEditParents) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:OLocalizedString(@"Your household includes minors. Would you like to provide parent relations?", @"") delegate:self tag:kActionSheetTagEditParents];
        [actionSheet addButtonWithTitle:OLocalizedString(@"Yes", @"") tag:kButtonTagEditParentsYes];
        [actionSheet addButtonWithTitle:OLocalizedString(@"No", @"")];
        
        [actionSheet show];
    } else if ([[OMeta m] userIsLoggedIn] && ![[OMeta m] userIsRegistered]) {
        if (![[OMeta m].user.createdBy isEqualToString:[OMeta m].userId]) {
            [OAlert showAlertWithTitle:OLocalizedString(@"Welcome to Origon", @"") message:OLocalizedString(@"Please verify your details and provide any missing information.", @"")];
            
            for (id<OMember> ward in [[OMeta m].user wards]) {
                _needsEditParents = _needsEditParents || ![ward mother] || ![ward father];
            }
        } else if (![OMeta m].userDidJustRegister) {
            [OAlert showAlertWithTitle:OLocalizedString(@"Incomplete registration", @"") message:OLocalizedString(@"You must complete your registration before you can start using Origon.", @"")];
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
        self.title = OLocalizedString(self.target, kStringPrefixSettingLabel);
    } else {
        self.titleView = [OTitleView titleViewWithTitle:[OMeta m].appName subtitle:[OMeta m].user.name];
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem settingsButtonWithTarget:self];
        
        if ([[OMeta m].user isTeenOrOlder]) {
            self.navigationItem.rightBarButtonItems = @[[UIBarButtonItem plusButtonWithTarget:self], [UIBarButtonItem joinButtonWithTarget:self]];
            
            [self enableOrDisableButtons];
        }
    }
}


- (void)loadData
{
    if ([self targetIs:kTargetHiddenOrigos]) {
        NSMutableArray *wardsWithHiddenOrigos = [NSMutableArray array];
        
        for (id<OMember> ward in [[OMeta m].user wards]) {
            if ([ward hiddenOrigos].count) {
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
    
    if (_wards.count) {
        if (self.selectedHeaderSegment > _wards.count - 1) {
            self.selectedHeaderSegment = _wards.count - 1;
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
    id<OMembership> membership = nil;

    if (sectionKey == kSectionKeyUser) {
        if ([origo isStash]) {
            cell.textLabel.text = OLocalizedString(@"All contacts", @"");
            cell.destinationId = kIdentifierValueList;
            cell.destinationTarget = kTargetAllContacts;
        } else if ([origo isResidence]) {
            membership = [origo userMembership];
            
            BOOL shouldUseAddressForDefaultName = NO;
            
            if ([origo.name isEqualToString:kPlaceholderDefault]) {
                for (id<OOrigo> residence in [[OMeta m].user residences]) {
                    if (residence != origo && [residence.name isEqualToString:kPlaceholderDefault]) {
                        shouldUseAddressForDefaultName = YES;
                    }
                }
            }
            
            if (shouldUseAddressForDefaultName) {
                cell.textLabel.text = [origo shortAddress];
            } else {
                cell.textLabel.text = [origo displayName];
                cell.detailTextLabel.text = [origo singleLineAddress];
            }
        }
    } else if (sectionKey == kSectionKeyOrigos) {
        membership = [origo userMembership];
        
        cell.textLabel.text = [origo displayName];
        
        if ([membership roles].count) {
            cell.detailTextLabel.text = [[OUtil commaSeparatedListOfNouns:[membership roles] conjoin:NO] stringByCapitalisingFirstLetter];
        } else if ([origo.descriptionText hasValue]) {
            cell.detailTextLabel.text = origo.descriptionText;
        } else if ([origo isCommunity] && [membership isAssociate]) {
            cell.detailTextLabel.text = OLocalizedString(origo.type, kStringPrefixOrigoTitle);
            cell.detailTextLabel.textColor = [UIColor tonedDownTextColour];
        }
    } else if (sectionKey == kSectionKeyWardOrigos) {
        id<OMember> ward = _wards[self.selectedHeaderSegment];
        membership = [origo membershipForMember:ward];
        
        if ([origo isPinned] && [origo.name isEqualToString:kPlaceholderDefault]) {
            cell.textLabel.text = [NSString stringWithFormat:OLocalizedString(@"%@'s friends", @""), [ward givenName]];
        } else {
            cell.textLabel.text = origo.name;
            cell.detailTextLabel.text = origo.descriptionText;
        }
    }

    if ([membership needsUserAcceptance]) {
        cell.destinationId = kIdentifierOrigo;
        cell.notificationView = [OLabel genericLabelWithText:OLocalizedString(@"New!", @"")];
    } else if ([membership isRequested]) {
        cell.textLabel.textColor = [UIColor valueTextColour];
        cell.detailTextLabel.text = OLocalizedString(@"Awaiting approval...", @"");
        cell.detailTextLabel.textColor = [UIColor tonedDownTextColour];
        cell.selectable = NO;
    } else if ([membership isDeclined]) {
        cell.textLabel.textColor = [UIColor valueTextColour];
        cell.detailTextLabel.text = OLocalizedString(@"Join request declined", @"");
        cell.detailTextLabel.textColor = [UIColor redColor];
    } else if (![origo isStash]) {
        cell.destinationId = kIdentifierOrigo;
        
        if ([origo hasPendingJoinRequests] && [origo userCanAdd]) {
            cell.embeddedButton = [OButton infoButton];
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
    
    if (sectionKey == kSectionKeyOrigos && [self hasHeaderForSectionWithKey:sectionKey]) {
        headerContent = OLocalizedString(@"My lists", @"");
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
    NSString *footerText = nil;
    
    if ([self targetIs:kTargetHiddenOrigos]) {
        footerText = OLocalizedString(@"No hidden lists.", @"");
    }
    
    return footerText;
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
            self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:OLocalizedString(@"Lists", @"")];
        }
    }
    
    if (!cell.destinationId) {
        _member = self.target;
        _origo = [self dataAtIndexPath:indexPath];

        if ([[_origo membershipForMember:_member] isDeclined]) {
            OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagDeclinedJoinRequest];
            [actionSheet addButtonWithTitle:OLocalizedString(@"Delete join request", @"") tag:kButtonTagDeclinedJoinRequestDelete];
            [actionSheet addButtonWithTitle:OLocalizedString(@"Resend join request", @"") tag:kButtonTagDeclinedJoinRequestResend];
            actionSheet.destructiveButtonIndex = 0;
            
            [actionSheet show];
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
                canDelete = [[OMeta m].user residences].count > 1;
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
    
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyUser) {
        buttonTitle = OLocalizedString(@"Move out", @"");
    } else if (![self canDeleteOrigoAtIndexPath:indexPath]) {
        buttonTitle = OLocalizedString(@"Hide", @"");
    }
    
    return buttonTitle;
}


- (BOOL)shouldDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL shouldDeleteCell = YES;
    
    if ([self canDeleteOrigoAtIndexPath:indexPath]) {
        id<OOrigo> origo = [self dataAtIndexPath:indexPath];

        if (![origo isPrivate] && [origo members].count > 1 && [origo userIsAdmin]) {
            _bookmarkedIndexPath = indexPath;
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:OLocalizedString(@"Delete shared list?", @"") message:[NSString stringWithFormat:OLocalizedString(@"You are about to permanently delete the shared contact list '%@'. It will be removed from Origon for all members of the list. Are you sure you want to delete it?", @""), origo.name] delegate:self cancelButtonTitle:OLocalizedString(@"Cancel", @"") otherButtonTitles:OLocalizedString(@"Yes", @""), nil];
            alert.tag = kAlertTagDeleteCell;
            
            [alert show];
            
            shouldDeleteCell = NO;
        }
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
        if ([origo isPrivate] || ([origo members].count > 1 && [origo userIsAdmin])) {
            for (id<OMember> member in [origo members]) {
                [[origo membershipForMember:member] expire];
            }
        }
        
        [[origo membershipForMember:keyMember] expire];
        
        origo.joinCode = nil;
        origo.internalJoinCode = nil;
    } else {
        [origo membershipForMember:keyMember].status = kMembershipStatusListed;
    }
    
    [OMember clearCachedPeers];
}


- (BOOL)supportsPullToRefresh
{
    return YES;
}


- (void)onlineStatusDidChange
{
    [self enableOrDisableButtons];
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
    
    switch (actionSheet.tag) {
        case kActionSheetTagJoinOrigoTarget:
        case kActionSheetTagNewOrigoTarget:
            if (buttonTag == kButtonTagOrigoTargetUser) {
                self.target = [OMeta m].user;
            } else if (buttonIndex != actionSheet.cancelButtonIndex) {
                NSInteger selectedWardIndex = buttonIndex - 1;
                
                if (_wards.count > 1 && self.selectedHeaderSegment != selectedWardIndex) {
                    self.selectedHeaderSegment = selectedWardIndex;
                    [self reloadSectionWithKey:kSectionKeyWardOrigos];
                }
                
                self.target = _wards[selectedWardIndex];
            }
            
            break;
            
        case kActionSheetTagDeclinedJoinRequest:
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];

            if (buttonIndex != actionSheet.cancelButtonIndex) {
                NSArray *requestingMembers = nil;
                
                if ([_origo isCommunity]) {
                    requestingMembers = [[_member primaryResidence] elders];
                } else {
                    requestingMembers = @[_member];
                }
                
                for (id<OMember> member in requestingMembers) {
                    if (buttonTag == kButtonTagDeclinedJoinRequestDelete) {
                        [[_origo membershipForMember:member] expire];
                    } else if (buttonTag == kButtonTagDeclinedJoinRequestResend) {
                        [_origo membershipForMember:member].status = kMembershipStatusRequested;
                    }
                }
                
                [self reloadSections];
            }
            
            break;
            
        default:
            break;
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
                
            case kActionSheetTagJoinOrigoTarget:
                [self presentModalViewControllerWithIdentifier:kIdentifierJoiner target:kTargetOrigo];
                
                break;
                
            case kActionSheetTagNewOrigoTarget:
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


#pragma mark - UIAlertViewDelegate conformance

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertTagDeleteCell:
            if (buttonIndex != alertView.cancelButtonIndex) {
                self.forceDeleteCell = YES;
                
                [self tableView:self.tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:_bookmarkedIndexPath];
            }
            
            break;
            
        default:
            break;
    }
}

@end
