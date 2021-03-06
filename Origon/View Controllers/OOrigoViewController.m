//
//  OOrigoViewController.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OOrigoViewController.h"

static NSInteger const kSectionKeyOrigo = 0;
static NSInteger const kSectionKeyOrganisers = 1;
static NSInteger const kSectionKeyParentContacts = 2;
static NSInteger const kSectionKeyMembers = 3;

static NSInteger const kHeaderSegmentMembers = 0;
static NSInteger const kHeaderSegmentParents = 1;
static NSInteger const kHeaderSegmentResidences = 1;

static NSInteger const kActionSheetTagAcceptDecline = 0;
static NSInteger const kButtonTagAcceptDeclineAccept = 0;
static NSInteger const kButtonTagAcceptDeclineDecline = 1;

static NSInteger const kActionSheetTagAdd = 1;
static NSInteger const kButtonTagAddMember = 0;
static NSInteger const kButtonTagAddFromLists = 1;
static NSInteger const kButtonTagAddOrganiser = 2;
static NSInteger const kButtonTagAddParentContact = 3;

static NSInteger const kActionSheetTagEdit = 2;
static NSInteger const kButtonTagEdit = 0;
static NSInteger const kButtonTagEditRoles = 1;

static NSInteger const kActionSheetTagCoHabitants = 3;
static NSInteger const kButtonTagCoHabitantsAll = 0;
static NSInteger const kButtonTagCoHabitantsWards = 1;
static NSInteger const kButtonTagCoHabitantsNew = 2;
static NSInteger const kButtonTagCoHabitantsGuardian = 3;

static NSInteger const kActionSheetTagRecipients = 4;

static NSInteger const kActionSheetTagJoinRequest = 5;
static NSInteger const kButtonTagJoinRequestAccept = 0;
static NSInteger const kButtonTagJoinRequestDecline = 1;


@interface OOrigoViewController () <OTableViewController, OInputCellDelegate, UIActionSheetDelegate> {
@private
    id<OOrigo> _origo;
    id<OMember> _member;
    id<OMembership> _membership;
    id<OMember> _joiningMember;
    
    NSString *_origoType;
    NSArray *_eligibleCandidates;
    
    NSInteger _recipientType;
    NSArray *_recipientCandidates;
    
    BOOL _userIsAdmin;
    BOOL _needsEditDetails;
}

@end


@implementation OOrigoViewController

#pragma mark - Auxiliary methods

- (NSString *)nameKey
{
    NSString *nameKey = nil;
    
    if ([_origo isOfType:kOrigoTypePrivate]) {
        nameKey = kMappedKeyPrivateListName;
    } else if ([_origo isOfType:kOrigoTypeResidence]) {
        nameKey = kMappedKeyResidenceName;
    } else if ([_origo isOfType:kOrigoTypePreschoolClass]) {
        nameKey = kMappedKeyPreschoolClass;
    } else if ([_origo isOfType:kOrigoTypeSchoolClass]) {
        nameKey = kMappedKeySchoolClass;
    } else {
        nameKey = kMappedKeyListName;
    }
    
    return nameKey;
}


- (void)loadRightNavigationBarButtonItems
{
    self.navigationItem.rightBarButtonItems = nil;

    if ([_membership needsUserAcceptance] || [_membership isHidden]) {
        [self.navigationItem addRightBarButtonItem:[UIBarButtonItem acceptDeclineButtonWithTarget:self]];
    } else  {
        if (_userIsAdmin && ![_origo isResidence] && ![_origo isPinned]) {
            [self.navigationItem addRightBarButtonItem:[UIBarButtonItem settingsButtonWithTarget:self]];
        } else {
            [self.navigationItem addRightBarButtonItem:[UIBarButtonItem infoButtonWithTarget:self]];
        }
        
        BOOL canHaveAddress = [_origo isOfType:@[kOrigoTypeResidence, kOrigoTypePreschoolClass, kOrigoTypeSchoolClass, kOrigoTypeSports]];
        
        if (canHaveAddress && [_origo hasAddress]) {
            [self.navigationItem addRightBarButtonItem:[UIBarButtonItem locationButtonWithTarget:self]];
        }

        if (![_origo isResidence] && ([_origo userCanEdit] || [_origo groups].count)) {
            [self.navigationItem addRightBarButtonItem:[UIBarButtonItem groupsButtonWithTarget:self]];
        }
        
        if ([_origo userCanEdit]) {
            [self.navigationItem addRightBarButtonItem:[UIBarButtonItem editButtonWithTarget:self]];
        }
        
        if ([_origo userCanAdd]) {
            [self.navigationItem addRightBarButtonItem:[UIBarButtonItem plusButtonWithTarget:self]];
        }
        
        [self enableOrDisableButtons];
    }
}


- (void)enableOrDisableButtons
{
    [self.navigationItem barButtonItemWithTag:kBarButtonItemTagLocation].enabled = self.isOnline;
    [self.navigationItem barButtonItemWithTag:kBarButtonItemTagGroups].enabled = self.isOnline || [_origo groups].count;
    [self.navigationItem barButtonItemWithTag:kBarButtonItemTagEdit].enabled = self.isOnline;
    [self.navigationItem barButtonItemWithTag:kBarButtonItemTagPlus].enabled = self.isOnline;
}


- (NSArray *)roleHoldersForRoleAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    NSString *role = [self dataAtIndexPath:indexPath];
    NSArray *roleHolders = nil;
    
    if (sectionKey == kSectionKeyOrganisers) {
        roleHolders = [_origo organisersWithRole:role];
    } else if (sectionKey == kSectionKeyParentContacts) {
        roleHolders = [_origo parentsWithRole:role];
    } else if (sectionKey == kSectionKeyMembers) {
        roleHolders = [_origo membersWithRole:role];
    }
    
    return roleHolders;
}


- (void)setAppearanceForPendingJoinRequestInCell:(OTableViewCell *)cell
{
    cell.textLabel.textColor = [UIColor valueTextColour];
    cell.detailTextLabel.text = OLocalizedString(@"Awaiting approval...", @"");
    cell.detailTextLabel.textColor = [UIColor tonedDownTextColour];
    
    if ([_origo userCanAdd]) {
        cell.embeddedButton = [OButton joinRequestButton];
    }
}


- (void)addMember
{
    NSMutableSet *coHabitantCandidates = nil;
    
    if ([_origo isResidence]) {
        coHabitantCandidates = [NSMutableSet setWithArray:[_member housematesNotInResidence:_origo]];
        
        for (id<OMember> housemate in [_member housemates]) {
            [coHabitantCandidates unionSet:[NSSet setWithArray:[housemate housematesNotInResidence:_origo]]];
        }
    }
    
    if (coHabitantCandidates.count) {
        [self presentCoHabitantsSheetWithCandidates:[coHabitantCandidates allObjects]];
    } else {
        id target = kTargetMember;
        
        if ([_origo isJuvenile]) {
            self.presentStealthilyOnce = YES;
            
            target = kTargetJuvenile;
        } else if ([_origo isResidence] && [self aspectIs:kAspectJuvenile]) {
            target = kTargetGuardian;
        }
        
        [self presentModalViewControllerWithIdentifier:kIdentifierMember target:target];
    }
}


#pragma mark - Actions sheets

- (void)presentCoHabitantsSheetWithCandidates:(NSArray *)candidates
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagCoHabitants];
    
    _eligibleCandidates = [OUtil sortedGroupsOfResidents:candidates excluding:nil];
    
    if (_eligibleCandidates.count == 1) {
        if ([_eligibleCandidates[kButtonTagCoHabitantsAll][0] isJuvenile]) {
            [actionSheet addButtonWithTitle:[OUtil commaSeparatedListOfMembers:_eligibleCandidates[kButtonTagCoHabitantsAll] conjoin:YES subjective:YES] tag:kButtonTagCoHabitantsAll];
        } else {
            for (id<OMember> candidate in _eligibleCandidates[kButtonTagCoHabitantsAll]) {
                [actionSheet addButtonWithTitle:[candidate shortName]];
            }
        }
    } else {
        [actionSheet addButtonWithTitle:[OUtil commaSeparatedListOfMembers:_eligibleCandidates[kButtonTagCoHabitantsAll] conjoin:YES subjective:NO] tag:kButtonTagCoHabitantsAll];
        [actionSheet addButtonWithTitle:[OUtil commaSeparatedListOfMembers:_eligibleCandidates[kButtonTagCoHabitantsWards] conjoin:YES subjective:NO] tag:kButtonTagCoHabitantsWards];
    }
    
    if (![_origo userIsMember] && [_member isWardOfUser]) {
        [actionSheet addButtonWithTitle:OLocalizedString(@"Other guardian", @"") tag:kButtonTagCoHabitantsGuardian];
    } else {
        [actionSheet addButtonWithTitle:OLocalizedString(kOrigoTypeResidence, kStringPrefixAddMemberButton) tag:kButtonTagCoHabitantsNew];
    }
    
    [actionSheet show];
}


- (void)presentRecipientsSheet
{
    NSString *prompt = nil;
    
    if (_recipientCandidates.count > 1) {
        if (_recipientType == kRecipientTypeCall) {
            prompt = OLocalizedString(@"Who do you want to call?", @"");
        } else {
            _recipientCandidates = [_recipientCandidates arrayByAddingObject:[NSArray arrayWithArray:_recipientCandidates]];
            
            if (_recipientType == kRecipientTypeText) {
                prompt = OLocalizedString(@"Who do you want to text?", @"");
            } else if (_recipientType == kRecipientTypeEmail) {
                prompt = OLocalizedString(@"Who do you want to email?", @"");
            }
        }
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagRecipients];
    
    if (_recipientCandidates.count > 1) {
        for (id recipientCandidate in _recipientCandidates) {
            if ([recipientCandidate isKindOfClass:[NSArray class]]) {
                [actionSheet addButtonWithTitle:[OUtil commaSeparatedListOfMembers:recipientCandidate conjoin:YES subjective:YES]];
            } else {
                [actionSheet addButtonWithTitle:[recipientCandidate recipientLabel]];
            }
        }
    } else {
        [actionSheet addButtonWithTitle:[_recipientCandidates[0] recipientLabelForRecipientType:_recipientType]];
    }
    
    [actionSheet show];
}


#pragma mark - Selector implementations

- (void)didTapEmbeddedButton:(OButton *)embeddedButton
{
    _joiningMember = [self dataAtIndexPath:[self.tableView indexPathForCell:embeddedButton.embeddingCell]];
    
    NSArray *joiningMembers = nil;
    NSString *memberLabel = nil;
    
    if ([_origo isCommunity]) {
        joiningMembers = [[_joiningMember primaryResidence] elders];
        memberLabel = [OUtil commaSeparatedListOfMembers:joiningMembers conjoin:YES];
    } else {
        if ([_joiningMember isJuvenile]) {
            memberLabel = [_joiningMember givenName];
        } else {
            memberLabel = [_joiningMember shortName];
        }
    }
    
    NSString *prompt = nil;
    
    if (joiningMembers && joiningMembers.count > 1) {
        prompt = [NSString stringWithFormat:OLocalizedString(@"%@ have requested to join %@", @""), memberLabel, _origo.name];
    } else {
        prompt = [NSString stringWithFormat:OLocalizedString(@"%@ has requested to join %@", @""), memberLabel, _origo.name];
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagJoinRequest];
    [actionSheet addButtonWithTitle:OLocalizedString(@"Accept", @"") tag:kButtonTagJoinRequestAccept];
    [actionSheet addButtonWithTitle:OLocalizedString(@"Decline", @"") tag:kButtonTagJoinRequestDecline];
    
    [actionSheet show];
}


- (void)performAcceptDeclineAction
{
    NSString *prompt = nil;
    NSString *acceptButtonTitle = nil;
    NSString *declineButtonTitle = nil;
    
    if ([_membership isHidden]) {
        prompt = OLocalizedString(@"Do you want to unhide this list?", @"");
        acceptButtonTitle = OLocalizedString(@"Unhide", @"");
        declineButtonTitle = OLocalizedString(@"Keep hidden", @"");
    } else {
        prompt = OLocalizedString(@"Do you want to keep this list?", @"");
        acceptButtonTitle = OLocalizedString(@"Keep", @"");
        
        if ([_origo isResidence]) {
            declineButtonTitle = OLocalizedString(@"Decline", @"");
        } else {
            declineButtonTitle = OLocalizedString(@"Hide", @"");
            prompt = [prompt stringByAppendingString:OLocalizedString(@"If you hide it, you can unhide it later under Settings.", @"") separator:kSeparatorSpace];
        }
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagAcceptDecline];
    [actionSheet addButtonWithTitle:acceptButtonTitle tag:kButtonTagAcceptDeclineAccept];
    [actionSheet addButtonWithTitle:declineButtonTitle tag:kButtonTagAcceptDeclineDecline];
    
    [actionSheet show];
}


- (void)performAddAction
{
    if ([_origo isResidence]) {
        [self addMember];
    } else {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagAdd];
        
        if ([_origo isPrivate]) {
            if ([_member isJuvenile]) {
                [actionSheet addButtonWithTitle:OLocalizedString(@"Register friend", @"") tag:kButtonTagAddMember];
            } else {
                [actionSheet addButtonWithTitle:OLocalizedString(@"Register contact", @"") tag:kButtonTagAddMember];
            }
        } else {
            [actionSheet addButtonWithTitle:OLocalizedString(_origo.type, kStringPrefixAddMemberButton) tag:kButtonTagAddMember];
        }
        
        if ([_origo isCommunity]) {
            _eligibleCandidates = [OUtil singleMemberPerPrimaryResidenceFromMembers:[self.state eligibleCandidates] includeUser:NO];
        } else {
            _eligibleCandidates = [self.state eligibleCandidates];
        }
        
        if (_eligibleCandidates.count) {
            [actionSheet addButtonWithTitle:OLocalizedString(@"Add from other lists", @"") tag:kButtonTagAddFromLists];
        }
        
        if ([_origo isOrganised]) {
            [actionSheet addButtonWithTitle:OLocalizedString(_origo.type, kStringPrefixAddOrganiserButton) tag:kButtonTagAddOrganiser];
            
            if ([_origo isJuvenile]) {
                [actionSheet addButtonWithTitle:OLocalizedString(@"Register parent representative", @"") tag:kButtonTagAddParentContact];
            }
        }
        
        if ([actionSheet numberOfButtons] > 1) {
            [actionSheet show];
        } else {
            [self addMember];
        }
    }
}


- (void)performEditAction
{
    if ([_origo isOfType:@[kOrigoTypeResidence, kOrigoTypePrivate]]) {
        [self scrollToTopAndToggleEditMode];
    } else {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagEdit];
        [actionSheet addButtonWithTitle:OLocalizedString(@"Edit", @"") tag:kButtonTagEdit];
        [actionSheet addButtonWithTitle:OLocalizedString(@"Edit responsibilities", @"") tag:kButtonTagEditRoles];
        
        [actionSheet show];
    }
}


- (void)performGroupsAction
{
    if (![_origo groups].count) {
        self.presentStealthilyOnce = YES;
    }
    
    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetGroups];
}


- (void)performLocationAction
{
    [self presentModalViewControllerWithIdentifier:kIdentifierMap target:_origo];
}


- (void)performSettingsAction
{
    [self performInfoAction];
}


- (void)performInfoAction
{
    [self presentModalViewControllerWithIdentifier:kIdentifierInfo target:_origo];
}


- (void)performTextAction
{
    NSArray *recipientCandidates = [_origo textRecipients];
    
    if (![_origo isResidence] || recipientCandidates.count > 2) {
        [self presentModalViewControllerWithIdentifier:kIdentifierRecipientPicker target:kTargetText meta:_origo];
    } else {
        _recipientType = kRecipientTypeText;
        _recipientCandidates = recipientCandidates;
        
        [self presentRecipientsSheet];
    }
}


- (void)performCallAction
{
    _recipientType = kRecipientTypeCall;
    _recipientCandidates = [_origo callRecipients];
    
    [self presentRecipientsSheet];
}


- (void)performEmailAction
{
    NSArray *recipientCandidates = [_origo emailRecipients];
    
    if (![_origo isResidence] || recipientCandidates.count > 2) {
        [self presentModalViewControllerWithIdentifier:kIdentifierRecipientPicker target:kTargetEmail meta:_origo];
    } else {
        _recipientType = kRecipientTypeEmail;
        _recipientCandidates = recipientCandidates;
        
        [self presentRecipientsSheet];
    }
}


#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self actionIs:kActionDisplay]) {
        if ([_membership.status isEqualToString:kMembershipStatusInvited]) {
            _membership.status = kMembershipStatusWaiting;
        }
        
        if ([_membership needsUserAcceptance] || [_membership isHidden]) {
            [self performAcceptDeclineAction];
        } else if (_needsEditDetails || ([_origo isResidence] && ![_origo hasAddress])) {
            [self toggleEditMode];
            
            _needsEditDetails = NO;
        }
    }
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    _origo = [self.entity proxy];
    _member = self.state.currentMember;
    
    if ([_origo isResidence] && ![_origo hasMember:_member]) {
        _member = [_origo elders][0];
    }
    
    _membership = [_origo membershipForMember:_member];
    _origoType = _origo.type;
    _userIsAdmin = [_origo userIsAdmin];
    
    if ([self actionIs:kActionRegister]) {
        if ([_origo isResidence]) {
            id<OOrigo> primaryResidence = [_member primaryResidence];
            
            if ([primaryResidence hasAddress] && [primaryResidence isCommitted]) {
                self.title = OLocalizedString(kPropertyKeyAddress, kStringPrefixLabel);
            } else {
                self.title = OLocalizedString(_origo.type, kStringPrefixOrigoTitle);
            }

            if (![self.state.baseOrigo isCommunity]) {
                self.cancelImpliesSkip = self.dismisser.isModal && ![_member hasAddress];
            }
        } else if ([_member isJuvenile]) {
            if ([_origo isStandard] && [_member isUser]) {
                self.title = OLocalizedString(@"Shared list", @"");
            } else if ([_origo isPrivate]) {
                if ([_member isUser]) {
                    self.title = OLocalizedString(@"Private list", @"");
                } else {
                    self.title = OLocalizedString(@"Private list of friends", @"");
                }
            } else {
                self.title = OLocalizedString(_origo.type, kStringPrefixOrigoTitle);
            }
        } else {
            self.title = OLocalizedString(_origo.type, kStringPrefixOrigoTitle);
        }
    } else if ([self actionIs:kActionDisplay]) {
        if ([_origo isResidence] && ![self aspectIs:kAspectHousehold]) {
            self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:OLocalizedString(kOrigoTypeResidence, kStringPrefixOrigoTitle)];
        } else {
            self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:[_origo displayName]];
        }
        
        if ([_origo isCommitted] && [_member isCommitted]) {
            [self loadRightNavigationBarButtonItems];
        } else if (![_origo isReplicated]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem editButtonWithTarget:self];
        }
    }
}


- (void)loadData
{
    [self setDataForInputSection];
    
    if ([_origo isResidence]) {
        [self setData:[_origo residents] forSectionWithKey:kSectionKeyMembers];
    } else {
        [self setData:[_origo organiserRoles] forSectionWithKey:kSectionKeyOrganisers];
        
        if ([_origo isJuvenile]) {
            [self setData:[_origo parentRoles] forSectionWithKey:kSectionKeyParentContacts];
            
            if (self.selectedHeaderSegment == kHeaderSegmentMembers) {
                [self setData:[_origo regulars] forSectionWithKey:kSectionKeyMembers];
            } else if (self.selectedHeaderSegment == kHeaderSegmentParents) {
                [self setData:[_origo guardians] forSectionWithKey:kSectionKeyMembers];
            }
        } else if ([_origo isCommunity]) {
            if (self.selectedHeaderSegment == kHeaderSegmentMembers) {
                [self setData:[_origo members] forSectionWithKey:kSectionKeyMembers];
            } else if (self.selectedHeaderSegment == kHeaderSegmentResidences) {
                [self setData:[OUtil singleMemberPerPrimaryResidenceFromMembers:[_origo members] includeUser:YES] forSectionWithKey:kSectionKeyMembers];
            }
        } else {
            [self setData:[_origo regulars] forSectionWithKey:kSectionKeyMembers];
        }
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyMembers) {
        id<OMember> member = [self dataAtIndexPath:indexPath];

        if ([_origo isCommunity] && self.selectedHeaderSegment == kHeaderSegmentResidences) {
            id<OOrigo> communityResidence = [member primaryResidence];
            NSArray *elders = [communityResidence elders];
            
            cell.textLabel.text = [OUtil labelForElders:elders conjoin:YES];
            cell.detailTextLabel.text = [communityResidence shortAddress];
            
            if (elders.count == 1) {
                [cell loadImageForMember:elders[0]];
            } else {
                [cell loadImageForMembers:elders];
            }
            
            if (![_membership isHidden]) {
                cell.destinationId = kIdentifierOrigo;
                cell.destinationTarget = communityResidence;
                
                if ([[_origo membershipForMember:member] needsPeerAcceptance]) {
                    [self setAppearanceForPendingJoinRequestInCell:cell];
                }
            }
        } else {
            id<OOrigo> origo = self.state.baseOrigo ? self.state.baseOrigo : _origo;
            
            if ([_origo isJuvenile] && self.selectedHeaderSegment == kHeaderSegmentParents) {
                [cell loadMember:member inOrigo:origo excludeRoles:YES excludeRelations:NO];
            } else if (origo == _origo || [member isJuvenile]) {
                [cell loadMember:member inOrigo:_origo];
            } else {
                [cell loadMember:member inOrigo:origo excludeRoles:NO excludeRelations:YES];
            }
            
            if (![_membership isHidden]) {
                cell.destinationId = kIdentifierMember;
                
                if ([[_origo membershipForMember:member] needsPeerAcceptance]) {
                    [self setAppearanceForPendingJoinRequestInCell:cell];
                }
            }
        }
    } else {
        NSString *role = [self dataAtIndexPath:indexPath];
        NSArray *roleHolders = [self roleHoldersForRoleAtIndexPath:indexPath];
        
        cell.textLabel.text = role;
        
        if (roleHolders.count == 1) {
            id<OMember> roleHolder = roleHolders[0];
            
            if (sectionKey == kSectionKeyParentContacts) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", roleHolder.name, [OUtil commaSeparatedListOfMembers:[roleHolder wardsInOrigo:_origo] inOrigo:_origo subjective:NO]];
            } else {
                cell.detailTextLabel.text = roleHolder.name;
            }
            
            [cell loadImageForMember:roleHolder];
            
            if (![_membership isHidden]) {
                cell.destinationId = kIdentifierMember;
                cell.destinationTarget = roleHolder;
                
                if ([[_origo membershipForMember:roleHolder] needsPeerAcceptance]) {
                    [self setAppearanceForPendingJoinRequestInCell:cell];
                }
            }
        } else {
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfMembers:roleHolders conjoin:NO];
            [cell loadImageForMembers:roleHolders];
            
            if (![_membership isHidden]) {
                cell.destinationId = kIdentifierValueList;
                
                if (sectionKey == kSectionKeyOrganisers) {
                    cell.destinationTarget = @{role: kAspectOrganiserRole};
                } else if (sectionKey == kSectionKeyParentContacts) {
                    cell.destinationTarget = @{role: kAspectParentRole};
                }
            }
        }
    }
    
    if ([_membership isHidden]) {
        cell.selectable = NO;
    }
}


- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasHeader = NO;
    
    if (sectionKey != kSectionKeyOrigo) {
        hasHeader = [_member isJuvenile] ? YES : ![_origo isPrivate];
    }
    
    return hasHeader;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasFooter = NO;
    
    if ([self isBottomSectionKey:sectionKey]) {
        if ([self actionIs:kActionRegister]) {
            hasFooter = [_origo isPrivate];
        } else if (self.isModal || ([_origo isPrivate] && ![_origo members].count)) {
            hasFooter = YES;
        }
    }
    
    return hasFooter;
}


- (id)headerContentForSectionWithKey:(NSInteger)sectionKey
{
    id headerContent = nil;
    NSInteger number;
    
    if (sectionKey == kSectionKeyOrganisers) {
        NSString *contactTitle = nil;
        
        if ([_origo isOfType:kOrigoTypePreschoolClass]) {
            contactTitle = _preschoolTeacher_;
        } else if ([_origo isOfType:kOrigoTypeSchoolClass]) {
            contactTitle = _teacher_;
        } else if ([_origo isOfType:kOrigoTypeSports]) {
            contactTitle = _coach_;
        }
        
        number = [_origo organisers].count > 1 ? pluralIndefinite : singularIndefinite;
        headerContent = [[OLanguage nouns][contactTitle][number] stringByCapitalisingFirstLetter];
    } else if (sectionKey == kSectionKeyParentContacts) {
        number = [_origo parentContacts].count > 1 ? pluralIndefinite : singularIndefinite;
        headerContent = [[OLanguage nouns][_parentContact_][number] stringByCapitalisingFirstLetter];
    } else if (sectionKey == kSectionKeyMembers) {
        NSString *membersTitle = OLocalizedString(_origo.type, kStringPrefixMembersTitle);
        
        if ([_origo isJuvenile]) {
            headerContent = @[membersTitle, [[OLanguage nouns][_parent_][pluralIndefinite] stringByCapitalisingFirstLetter]];
        } else if ([_origo isCommunity]) {
            headerContent = @[membersTitle, OLocalizedString(@"Households", @"")];
        } else {
            if (![_origo isCommitted] && [_origo isResidence]) {
                if (![_member isCommitted] && [self aspectIs:kAspectJuvenile]) {
                    headerContent = OLocalizedString(@"Guardians in the household", @"");
                } else {
                    headerContent = membersTitle;
                }
            } else {
                headerContent = membersTitle;
            }
        }
    }
    
    return headerContent;
}


- (NSString *)footerContentForSectionWithKey:(NSInteger)sectionKey
{
    NSString *footerContent = OLocalizedString(_origo.type, kStringPrefixFooter);
    
    if ([_origo isResidence]) {
        if (self.isModal && [self aspectIs:kAspectJuvenile]) {
            footerContent = OLocalizedString(@"Tap + to register additional guardians in the household.", @"");
        }
    } else if ([_origo isPrivate]) {
        if ([self actionIs:kActionRegister]) {
            if ([_member isJuvenile] && [_member guardians].count) {
                if ([_member isUser]) {
                    footerContent = OLocalizedString(@"This list will only be visible to you and adult members of your family.", @"");
                } else if ([_member isActive]) {
                    footerContent = [NSString stringWithFormat:OLocalizedString(@"This list will only be visible to %@ and adult members of the family.", @""), [_member givenName]];
                } else {
                    footerContent = OLocalizedString(@"This list will only be visible to adult members of the family.", @"");
                }
            } else {
                footerContent = OLocalizedString(@"This list will only be visible to you.", @"");
            }
        } else if (self.isModal || ![_origo members].count) {
            if ([_member isJuvenile]) {
                footerContent = OLocalizedString(@"Tap + to register friends.", @"");
            } else {
                footerContent = OLocalizedString(@"Tap + to register contacts.", @"");
            }
        }
    }
    
    return footerContent;
}


- (BOOL)toolbarHasSendTextButton
{
    return [_origo textRecipients].count > 0;
}


- (BOOL)toolbarHasCallButton
{
    return [_origo callRecipients].count > 0;
}


- (BOOL)toolbarHasSendEmailButton
{
    return [_origo emailRecipients].count > 0;
}


- (BOOL)canCompareObjectsInSectionWithKey:(NSInteger)sectionKey
{
    return [self targetIs:kOrigoTypeResidence] && sectionKey == kSectionKeyMembers;
}


- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2
{
    NSComparisonResult result = NSOrderedSame;
    
    id<OMember> member1 = object1;
    id<OMember> member2 = object2;
    
    BOOL isMinor1 = [member1 isJuvenile];
    BOOL isMinor2 = [member2 isJuvenile];
    
    if (isMinor1 != isMinor2) {
        if (isMinor1 && !isMinor2) {
            result = NSOrderedDescending;
        } else {
            result = NSOrderedAscending;
        }
    } else {
        result = [member1.name localizedCaseInsensitiveCompare:member2.name];
    }
    
    return result;
}


- (BOOL)canDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDeleteCell = NO;
    
    if (!self.isModal && [_origo isCommitted]) {
        NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
        
        if (sectionKey == kSectionKeyMembers && [_origo userCanDelete]) {
            id<OMember> member = [self dataAtIndexPath:indexPath];
            
            if ([_origo isCommunity]) {
                if (self.selectedHeaderSegment == kHeaderSegmentResidences) {
                    canDeleteCell = ![[member primaryResidence] userIsMember];
                }
            } else if (self.selectedHeaderSegment == kHeaderSegmentMembers) {
                canDeleteCell = ![member isUser];
            }
        } else if ([_origo userCanEdit]) {
            canDeleteCell = [self roleHoldersForRoleAtIndexPath:indexPath].count == 1;
        }
    }
    
    return canDeleteCell;
}


- (NSString *)deleteConfirmationButtonTitleForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *buttonTitle = nil;
    
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyMembers) {
        buttonTitle = OLocalizedString(@"Remove", @"");
    }
    
    return buttonTitle;
}


- (void)deleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyMembers) {
        id<OMember> member = [self dataAtIndexPath:indexPath];
        
        if (self.selectedHeaderSegment == kHeaderSegmentMembers) {
            if (![_origo isCommunity]) {
                id<OMembership> membership = [_origo membershipForMember:member];
                
                if ([membership isResidency] && member.email && [member residencies].count == 1) {
                    id<OOrigo> newPrimaryResidence = [OOrigo instanceWithType:kOrigoTypeResidence];
                    [newPrimaryResidence addMember:member];
                    
                    if (![member isJuvenile]) {
                        for (id<OMember> minor in [_origo minors]) {
                            [newPrimaryResidence addMember:minor];
                        }
                    }
                }
                
                [membership expire];
                
                if ([_origo userIsMember]) {
                    [self.inputCell readData];
                }
            }
        } else if (self.selectedHeaderSegment == kHeaderSegmentResidences) {
            [[_origo membershipForMember:member] expire];
        }
    } else {
        NSString *role = [self dataAtIndexPath:indexPath];
        id<OMember> member = [self roleHoldersForRoleAtIndexPath:indexPath][0];
        id<OMembership> membership = [_origo membershipForMember:member];
        
        if (sectionKey == kSectionKeyOrganisers) {
            [membership removeAffiliation:role ofType:kAffiliationTypeOrganiserRole];
        } else if (sectionKey == kSectionKeyParentContacts) {
            [membership removeAffiliation:role ofType:kAffiliationTypeParentRole];
        }
    }
}


- (void)willDismissModalViewController:(OTableViewController *)viewController
{
    if (!viewController.didCancel) {
        if ([viewController.identifier isEqualToString:kIdentifierMember]) {
            if ([_origo isResidence]) {
                [self.inputCell readData];
            } else if ([_origo isCommunity]) {
                [_origo addMember:viewController.returnData];
            }
        } if ([viewController.identifier isEqualToString:kIdentifierValueList]) {
            if ([viewController targetIs:kTargetRoles]) {
                [self reloadSections];
            }
        } else if ([viewController.identifier isEqualToString:kIdentifierValuePicker]) {
            if ([viewController targetIs:kTargetMembers]) {
                for (id<OMember> member in viewController.returnData) {
                    [_origo addMember:member];
                }
            }
            
            [[OMeta m].replicator replicateIfNeeded];
        } else if ([viewController.identifier isEqualToString:kIdentifierInfo]) {
            if (![_origoType isEqualToString:_origo.type]) {
                self.selectedHeaderSegment = 0;
                _origoType = _origo.type;
                _needsEditDetails = YES;
                
                [self loadRightNavigationBarButtonItems];
                self.needsReloadInputSection = YES;
            }
            
            if (_userIsAdmin && ![_origo userIsAdmin]) {
                _userIsAdmin = NO;
                
                [self loadRightNavigationBarButtonItems];
            }
        }
    }
}


- (BOOL)supportsPullToRefresh
{
    return ![_origo isOfType:@[kOrigoTypeResidence, kOrigoTypePrivate]];
}


- (void)onlineStatusDidChange
{
    [self enableOrDisableButtons];
}


- (void)didToggleEditMode
{
    if ([_origo isResidence] && !self.isModal) {
        self.title = nil;
        
        if (![_origo hasAddress]) {
            if ([self actionIs:kActionEdit]) {
                self.title = OLocalizedString(@"Register address", @"");
            } else {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    }
}


#pragma mark - OInputCellDelegate conformance

- (id)targetEntity
{
    return _origo;
}


- (OInputCellBlueprint *)inputCellBlueprint
{
    OInputCellBlueprint *blueprint = [[OInputCellBlueprint alloc] init];
    
    blueprint.titleKey = [self nameKey];

    if ([_origo isOfType:kOrigoTypeResidence]) {
        blueprint.detailKeys = @[kPropertyKeyAddress, kPropertyKeyTelephone];
        blueprint.multiLineKeys = @[kPropertyKeyAddress];
    } else if ([_origo isOfType:kOrigoTypePreschoolClass]) {
        blueprint.detailKeys = @[kMappedKeyPreschool, kPropertyKeyAddress];
        blueprint.multiLineKeys = @[kPropertyKeyAddress];
    } else if ([_origo isOfType:kOrigoTypeSchoolClass]) {
        blueprint.detailKeys = @[kMappedKeySchool, kPropertyKeyAddress];
        blueprint.multiLineKeys = @[kPropertyKeyAddress];
    } else if ([_origo isOfType:kOrigoTypeSports]) {
        blueprint.detailKeys = @[kMappedKeyClub, kMappedKeyArena, kPropertyKeyAddress];
        blueprint.multiLineKeys = @[kPropertyKeyAddress];
    } else if (![_origo isOfType:kOrigoTypePrivate]) {
        blueprint.detailKeys = @[kPropertyKeyDescriptionText];
        blueprint.multiLineKeys = @[kPropertyKeyDescriptionText];
    }
    
    return blueprint;
}


- (BOOL)isReceivingInput
{
    return [self actionIs:kActionInput];
}


- (BOOL)inputIsValid
{
    BOOL isValid = NO;
    
    if ([self targetIs:kOrigoTypeResidence]) {
        isValid = isValid || [self.inputCell hasValidValueForKey:kPropertyKeyAddress];
        isValid = isValid || [self.inputCell hasValidValueForKey:kPropertyKeyTelephone];
    } else {
        isValid = [self.inputCell hasValidValueForKey:[self nameKey]];
    }
    
    return isValid;
}


- (void)processInput
{
    [self.inputCell writeInput];
    
    if ([self actionIs:kActionRegister]) {
        if (!_membership) {
            _membership = [_origo addMember:_member];
        }
        
        if ([_member isUser] && ![_member isActive]) {
            [_member makeActive];
            
            _membership.status = kMembershipStatusActive;
        }
        
        if ([_origo isResidence] && ![_origo hasAddress]) {
            [self.dismisser dismissModalViewController:self];
        } else {
            [self toggleEditMode];
            [self reloadSections];
            
            if ([_origo isPrivate]) {
                [self reloadFooterForSectionWtihKey:kSectionKeyOrigo];
            }
            
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
            self.navigationItem.rightBarButtonItems = @[[UIBarButtonItem doneButtonWithTarget:self]];
        }
    } else {
        [self toggleEditMode];

        if ([self actionIs:kActionDisplay]) {
            UIBarButtonItem *locationButton = [self.navigationItem barButtonItemWithTag:kBarButtonItemTagLocation];
            
            if (!locationButton && [_origo hasAddress]) {
                [self.navigationItem insertRightBarButtonItem:[UIBarButtonItem locationButtonWithTarget:self] atIndex:1];
            } else if (locationButton && ![_origo hasAddress]) {
                [self.navigationItem removeRightBarButtonItem:locationButton];
            }
        }
    }
}


- (BOOL)isDisplayableFieldWithKey:(NSString *)key
{
    return ![key isEqualToString:kMappedKeyResidenceName] || [_origo userIsMember];
}


- (BOOL)shouldCommitEntity:(id)entity
{
    return [self.entity.ancestor isCommitted] || [self.state.baseOrigo isCommunity];
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
        
        switch (actionSheet.tag) {
            case kActionSheetTagAcceptDecline:
                if (buttonTag == kButtonTagAcceptDeclineAccept) {
                    BOOL wasHidden = [_membership isHidden];
                    
                    _membership.status = kMembershipStatusActive;
                    
                    if (wasHidden) {
                        [self.navigationController popViewControllerAnimated:YES];
                    } else {
                        [self loadRightNavigationBarButtonItems];
                    }
                } else if (buttonTag == kButtonTagAcceptDeclineDecline) {
                    if (![_membership isHidden]) {
                        if ([_origo isResidence]) {
                            [_membership expire];
                        } else {
                            _membership.status = kMembershipStatusListed;
                        }
                        
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                }
                
                [OMember clearCachedPeers];
                
                break;
                
            case kActionSheetTagEdit:
                if (buttonTag == kButtonTagEdit) {
                    [self scrollToTopAndToggleEditMode];
                }
                
                break;
                
            default:
                break;
        }
    }
}


- (void)actionSheet:(OActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex < actionSheet.cancelButtonIndex) {
        NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
        
        switch (actionSheet.tag) {
            case kActionSheetTagEdit:
                if (buttonTag == kButtonTagEditRoles) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetRoles];
                }
                
                break;
                
            case kActionSheetTagAdd:
                if (buttonTag == kButtonTagAddMember) {
                    [self addMember];
                } else if (buttonTag == kButtonTagAddFromLists) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:kTargetMembers meta:_eligibleCandidates];
                } else if (buttonTag == kButtonTagAddOrganiser) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetOrganiser];
                } else if (buttonTag == kButtonTagAddParentContact) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:@{kTargetRole: kAspectParentRole}];
                }
                
                break;
                
            case kActionSheetTagCoHabitants:
                if (buttonTag == kButtonTagCoHabitantsNew) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetMember];
                } else if (buttonTag == kButtonTagCoHabitantsGuardian) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetGuardian];
                } else {
                    NSArray *coHabitants = nil;
                    
                    if (_eligibleCandidates.count == 1) {
                        if ([_eligibleCandidates[kButtonTagCoHabitantsAll][0] isJuvenile]) {
                            coHabitants = _eligibleCandidates[kButtonTagCoHabitantsAll];
                        } else {
                            coHabitants = @[_eligibleCandidates[kButtonTagCoHabitantsAll][buttonIndex]];
                        }
                    } else if (buttonTag == kButtonTagCoHabitantsAll) {
                        coHabitants = _eligibleCandidates[kButtonTagCoHabitantsAll];
                    } else if (buttonTag == kButtonTagCoHabitantsWards) {
                        coHabitants = _eligibleCandidates[kButtonTagCoHabitantsWards];
                    }
                    
                    for (id<OMember> coHabitant in coHabitants) {
                        [_origo addMember:coHabitant];
                    }
                    
                    [self reloadSections];
                }
                
                break;
                
            case kActionSheetTagRecipients:
                if (_recipientType == kRecipientTypeText) {
                    [self sendTextToRecipients:_recipientCandidates[buttonIndex]];
                } else if (_recipientType == kRecipientTypeCall) {
                    [self callRecipient:_recipientCandidates[buttonIndex]];
                } else if (_recipientType == kRecipientTypeEmail) {
                    [self sendEmailToRecipients:_recipientCandidates[buttonIndex] cc:nil];
                }
                
                break;
                
            case kActionSheetTagJoinRequest:
                if (buttonIndex != actionSheet.cancelButtonIndex) {
                    NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
                    NSArray *joiningMembers = nil;
                    
                    if ([_origo isCommunity]) {
                        joiningMembers = [[_joiningMember primaryResidence] elders];
                    } else {
                        joiningMembers = @[_joiningMember];
                    }
                    
                    for (id<OMember> member in joiningMembers) {
                        id<OMembership> membership = [_origo membershipForMember:member];
                        
                        if (buttonTag == kButtonTagJoinRequestAccept) {
                            membership.status = kMembershipStatusActive;
                        } else if (buttonTag == kButtonTagJoinRequestDecline) {
                            membership.status = kMembershipStatusDeclined;
                            membership.affiliations = nil;
                        }
                    }
                    
                    [self reloadSections];
                    
                    [[OMeta m].replicator replicate];
                }
                
                break;
                
            default:
                break;
        }
    }
}

@end
