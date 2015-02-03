//
//  OOrigoViewController.m
//  OrigoApp
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
static NSInteger const kButtonTagAddFromGroups = 1;
static NSInteger const kButtonTagAddOrganiser = 2;
static NSInteger const kButtonTagAddParentContact = 3;

static NSInteger const kActionSheetTagEdit = 2;
static NSInteger const kButtonTagEditGroup = 0;
static NSInteger const kButtonTagEditRoles = 1;
static NSInteger const kButtonTagEditSubgroups = 2;

static NSInteger const kActionSheetTagCoHabitants = 3;
static NSInteger const kButtonTagCoHabitantsAll = 0;
static NSInteger const kButtonTagCoHabitantsWards = 1;
static NSInteger const kButtonTagCoHabitantsNew = 2;
static NSInteger const kButtonTagCoHabitantsGuardian = 3;

static NSInteger const kActionSheetTagRecipients = 4;


@interface OOrigoViewController () <OTableViewController, OInputCellDelegate, UIActionSheetDelegate> {
@private
    id<OOrigo> _origo;
    id<OMember> _member;
    id<OMembership> _membership;
    
    NSString *_origoType;
    NSArray *_eligibleCandidates;
    
    NSInteger _recipientType;
    NSArray *_recipientCandidates;
    
    BOOL _isManagedByUser;
}

@end


@implementation OOrigoViewController

#pragma mark - Auxiliary methods

- (void)loadNavigationBarItems
{
    self.navigationItem.rightBarButtonItems = nil;

    BOOL isAwaitingActivation = NO;
    
    if (_membership && ![_membership isActive] && ([_member isUser] || [_member isWardOfUser])) {
        [self.navigationItem addRightBarButtonItem:[UIBarButtonItem acceptDeclineButtonWithTarget:self]];
        
        if ([_membership.status isEqualToString:kMembershipStatusInvited]) {
            _membership.status = kMembershipStatusWaiting;
        } else if ([_membership.status isEqualToString:kMembershipStatusWaiting]) {
            _membership.status = kMembershipStatusActive;
        }
        
        isAwaitingActivation = YES;
    }
    
    [self.navigationItem addRightBarButtonItem:[UIBarButtonItem infoButtonWithTarget:self]];
    
    if ([_origo hasAddress]) {
        [self.navigationItem addRightBarButtonItem:[UIBarButtonItem locationButtonWithTarget:self]];
    }
    
    if ([[_origo groups] count]) {
        [self.navigationItem addRightBarButtonItem:[UIBarButtonItem groupsButtonWithTarget:self]];
    }
    
    if ([_origo isManagedByUser] && !isAwaitingActivation) {
        [self.navigationItem addRightBarButtonItem:[UIBarButtonItem editButtonWithTarget:self]];
        [self.navigationItem addRightBarButtonItem:[UIBarButtonItem plusButtonWithTarget:self]];
    }
}


- (NSString *)nameKey
{
    NSString *nameKey = nil;
    
    if ([_origo isOfType:kOrigoTypeList]) {
        nameKey = kMappedKeyListName;
    } else if ([_origo isOfType:kOrigoTypeResidence]) {
        nameKey = kMappedKeyResidenceName;
    } else if ([_origo isOfType:kOrigoTypeOrganisation]) {
        nameKey = kMappedKeyOrganisation;
    } else if ([_origo isOfType:kOrigoTypePreschoolClass]) {
        nameKey = kMappedKeyPreschoolClass;
    } else if ([_origo isOfType:kOrigoTypeSchoolClass]) {
        nameKey = kMappedKeySchoolClass;
    } else if ([_origo isOfType:kOrigoTypeTeam]) {
        nameKey = kMappedKeyTeam;
    } else if ([_origo isOfType:kOrigoTypeStudyGroup]) {
        nameKey = kMappedKeyStudyGroup;
    } else {
        nameKey = kPropertyKeyName;
    }
    
    return nameKey;
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


- (void)addMember
{
    NSMutableSet *coHabitantCandidates = nil;
    
    if ([_origo isOfType:kOrigoTypeResidence]) {
        coHabitantCandidates = [NSMutableSet setWithArray:[_member housematesNotInResidence:_origo]];
        
        for (id<OMember> housemate in [_member housemates]) {
            [coHabitantCandidates unionSet:[NSSet setWithArray:[housemate housematesNotInResidence:_origo]]];
        }
    }
    
    if ([coHabitantCandidates count]) {
        [self presentCoHabitantsSheetWithCandidates:[coHabitantCandidates allObjects]];
    } else {
        id target = kTargetMember;
        
        if ([_origo isJuvenile]) {
            self.presentStealthilyOnce = YES;
            
            target = kTargetJuvenile;
        } else if ([_origo isOfType:kOrigoTypeResidence] && [self aspectIs:kAspectJuvenile]) {
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
    
    if ([_eligibleCandidates count] == 1) {
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
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Other guardian", @"") tag:kButtonTagCoHabitantsGuardian];
    } else {
        [actionSheet addButtonWithTitle:NSLocalizedString(kOrigoTypeResidence, kStringPrefixAddMemberButton) tag:kButtonTagCoHabitantsNew];
    }
    
    [actionSheet show];
}


- (void)presentRecipientsSheet
{
    NSString *prompt = nil;
    
    if ([_recipientCandidates count] > 1) {
        if (_recipientType == kRecipientTypeCall) {
            prompt = NSLocalizedString(@"Who do you want to call?", @"");
        } else {
            _recipientCandidates = [_recipientCandidates arrayByAddingObject:[NSArray arrayWithArray:_recipientCandidates]];
            
            if (_recipientType == kRecipientTypeText) {
                prompt = NSLocalizedString(@"Who do you want to text?", @"");
            } else if (_recipientType == kRecipientTypeEmail) {
                prompt = NSLocalizedString(@"Who do you want to email?", @"");
            }
        }
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagRecipients];
    
    if ([_recipientCandidates count] > 1) {
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

- (void)performAcceptDeclineAction
{
    NSString *prompt = nil;
    NSString *acceptButtonTitle = nil;
    NSString *declineButtonTitle = nil;
    
    if ([_membership isHidden]) {
        prompt = NSLocalizedString(@"Do you want to unhide this listing?", @"");
        acceptButtonTitle = NSLocalizedString(@"Unhide", @"");
        declineButtonTitle = NSLocalizedString(@"Keep hidden", @"");
    } else {
        prompt = NSLocalizedString(@"Do you want to keep this listing?", @"");
        acceptButtonTitle = NSLocalizedString(@"Keep", @"");
        declineButtonTitle = [_origo isOfType:kOrigoTypeResidence] ? NSLocalizedString(@"Decline", @"") : NSLocalizedString(@"Hide", @"");
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagAcceptDecline];
    [actionSheet addButtonWithTitle:acceptButtonTitle tag:kButtonTagAcceptDeclineAccept];
    [actionSheet addButtonWithTitle:declineButtonTitle tag:kButtonTagAcceptDeclineDecline];
    
    [actionSheet show];
}


- (void)performAddAction
{
    if ([_origo isOfType:kOrigoTypeResidence]) {
        [self addMember];
    } else {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagAdd];
        
        if ([_origo isOfType:kOrigoTypeList]) {
            if ([_member isJuvenile]) {
                [actionSheet addButtonWithTitle:NSLocalizedString(@"Register friend", @"") tag:kButtonTagAddMember];
            } else {
                [actionSheet addButtonWithTitle:NSLocalizedString(@"Register contact", @"") tag:kButtonTagAddMember];
            }
        } else {
            [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddMemberButton) tag:kButtonTagAddMember];
        }
        
        _eligibleCandidates = [self.state eligibleCandidates];
        
        if ([_eligibleCandidates count]) {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Add from other list", @"") tag:kButtonTagAddFromGroups];
        }
        
        if ([_origo isOrganised]) {
            [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddOrganiserButton) tag:kButtonTagAddOrganiser];
            
            if ([_origo isJuvenile]) {
                [actionSheet addButtonWithTitle:NSLocalizedString(@"Register parent contact", @"") tag:kButtonTagAddParentContact];
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
    if ([_origo isOfType:@[kOrigoTypeResidence, kOrigoTypeList]]) {
        [self scrollToTopAndToggleEditMode];
    } else {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagEdit];
        
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit", @"") tag:kButtonTagEditGroup];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit responsibilities", @"") tag:kButtonTagEditRoles];
        
        if (![_origo isOfType:@[kOrigoTypeResidence, kOrigoTypeList]] && ![[_origo groups] count]) {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit groups", @"") tag:kButtonTagEditSubgroups];
        }
        
        [actionSheet show];
    }
}


- (void)performGroupsAction
{
    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetGroups];
}


- (void)performLocationAction
{
    [self presentModalViewControllerWithIdentifier:kIdentifierMap target:_origo];
}


- (void)performInfoAction
{
    [self presentModalViewControllerWithIdentifier:kIdentifierInfo target:_origo];
}


- (void)performTextAction
{
    NSArray *recipientCandidates = [_origo textRecipients];
    
    if (![_origo isOfType:kOrigoTypeResidence] || [recipientCandidates count] > 2) {
        [self presentModalViewControllerWithIdentifier:kIdentifierRecipientPicker target:kTargetText meta:_origo];
    } else {
        _recipientType = kRecipientTypeText;
        _recipientCandidates = recipientCandidates;
        
        [self presentRecipientsSheet];
    }
}


- (void)performCallAction
{
    NSArray *recipientCandidates = [_origo callRecipients];
    
    if ([recipientCandidates count] > 1) {
        _recipientType = kRecipientTypeCall;
        _recipientCandidates = recipientCandidates;
        
        [self presentRecipientsSheet];
    } else {
        [self callRecipient:_origo];
    }
}


- (void)performEmailAction
{
    NSArray *recipientCandidates = [_origo emailRecipients];
    
    if (![_origo isOfType:kOrigoTypeResidence] || [recipientCandidates count] > 2) {
        [self presentModalViewControllerWithIdentifier:kIdentifierRecipientPicker target:kTargetEmail meta:_origo];
    } else {
        _recipientType = kRecipientTypeEmail;
        _recipientCandidates = recipientCandidates;
        
        [self presentRecipientsSheet];
    }
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    _origo = [self.entity proxy];
    
    if ([_origo hasMember:self.state.currentMember]) {
        _member = self.state.currentMember;
    } else {
        _member = [_origo members][0];
    }
    
    _membership = [_origo membershipForMember:_member];
    _origoType = _origo.type;
    _isManagedByUser = [_origo isManagedByUser];
    
    if ([self actionIs:kActionRegister]) {
        self.title = NSLocalizedString(_origo.type, kStringPrefixOrigoTitle);
        
        if ([_origo isOfType:kOrigoTypeResidence]) {
            id<OOrigo> primaryResidence = [_member primaryResidence];
            
            if ([primaryResidence hasAddress] && [primaryResidence isCommitted]) {
                self.title = NSLocalizedString(kPropertyKeyAddress, kStringPrefixLabel);
            }
            
            self.cancelImpliesSkip = ![_member hasAddress] && ![_origo isReplicated] && ![[_member housemates] count];
        }
    } else if ([self actionIs:kActionDisplay]) {
        if ([_origo isOfType:kOrigoTypeResidence] && ![self aspectIs:kAspectHousehold]) {
            if ([_origo isManagedByUser]) {
                self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:NSLocalizedString(kOrigoTypeResidence, kStringPrefixOrigoTitle)];
            } else {
                self.title = NSLocalizedString(kOrigoTypeResidence, kStringPrefixOrigoTitle);
            }
        } else {
            self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:[_origo displayName]];
        }
        
        if ([_origo isCommitted] && [_member isCommitted]) {
            [self loadNavigationBarItems];
        } else if (![_origo isReplicated]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem editButtonWithTarget:self];
        }
    }
}


- (void)loadData
{
    [self setDataForInputSection];
    
    if ([self actionIs:kActionRegister]) {
        [self setData:[_origo members] forSectionWithKey:kSectionKeyMembers];
    } else {
        if ([_origo isOfType:kOrigoTypeResidence] && ![_origo userIsMember]) {
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
            } else if ([_origo isOfType:kOrigoTypeCommunity]) {
                if (self.selectedHeaderSegment == kHeaderSegmentMembers) {
                    [self setData:[_origo members] forSectionWithKey:kSectionKeyMembers];
                } else if (self.selectedHeaderSegment == kHeaderSegmentResidences) {
                    [self setData:[_origo memberResidences] forSectionWithKey:kSectionKeyMembers];
                }
            } else {
                [self setData:[_origo regulars] forSectionWithKey:kSectionKeyMembers];
            }
        }
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyMembers) {
        if ([[self dataAtIndexPath:indexPath] conformsToProtocol:@protocol(OOrigo)]) {
            id<OOrigo> residence = [self dataAtIndexPath:indexPath];
            
            cell.textLabel.text = [residence shortAddress];
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfMembers:[residence elders] withRolesInOrigo:_origo];
            [cell loadImageForOrigo:residence];
            cell.destinationId = [_membership isHidden] ? nil : kIdentifierOrigo;
        } else {
            id<OOrigo> origo = self.state.baseOrigo ? self.state.baseOrigo : _origo;
            id<OMember> member = [self dataAtIndexPath:indexPath];
            
            if ([_origo isJuvenile] && self.selectedHeaderSegment == kHeaderSegmentParents) {
                [cell loadMember:member inOrigo:origo excludeRoles:YES excludeRelations:NO];
            } else if (origo == _origo || [member isJuvenile]) {
                [cell loadMember:member inOrigo:_origo];
            } else {
                [cell loadMember:member inOrigo:origo excludeRoles:NO excludeRelations:YES];
            }
            
            cell.destinationId = [_membership isHidden] ? nil : kIdentifierMember;
        }
    } else {
        NSString *role = [self dataAtIndexPath:indexPath];
        NSArray *roleHolders = [self roleHoldersForRoleAtIndexPath:indexPath];
        
        cell.textLabel.text = role;
        
        if ([roleHolders count] == 1) {
            id<OMember> roleHolder = roleHolders[0];
            
            if (sectionKey == kSectionKeyParentContacts) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", roleHolder.name, [OUtil commaSeparatedListOfMembers:[roleHolder wardsInOrigo:_origo] inOrigo:_origo subjective:NO]];
            } else {
                cell.detailTextLabel.text = roleHolder.name;
            }
            
            [cell loadImageForMember:roleHolder];
            cell.destinationId = [_membership isHidden] ? nil : kIdentifierMember;
        } else {
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfMembers:roleHolders conjoin:NO];
            [cell loadTonedDownIconWithFileName:kIconFileRoleHolders];
            
            if (![_membership isHidden]) {
                cell.destinationId = kIdentifierValueList;
                cell.destinationMeta = role;
            }
        }
    }
    
    cell.selectable = ![_membership isHidden];
}


- (id)destinationTargetForIndexPath:(NSIndexPath *)indexPath
{
    id target = [self dataAtIndexPath:indexPath];
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey != kSectionKeyMembers) {
        NSArray *roleHolders = [self roleHoldersForRoleAtIndexPath:indexPath];
        
        if ([roleHolders count] == 1) {
            target = roleHolders[0];
        } else {
            NSString *role = [self dataAtIndexPath:indexPath];
            
            if (sectionKey == kSectionKeyOrganisers) {
                target = @{role: kAspectOrganiserRole};
            } else if (sectionKey == kSectionKeyParentContacts) {
                target = @{role: kAspectParentRole};
            }
        }
    }
    
    return target;
}


- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasHeader = NO;
    
    if (sectionKey != kSectionKeyOrigo) {
        hasHeader = [_member isJuvenile] ? YES : ![_origo isOfType:kOrigoTypeList];
    }
    
    return hasHeader;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasFooter = NO;
    
    if ([self isBottomSectionKey:sectionKey]) {
        if ([self actionIs:kActionRegister]) {
            hasFooter = [_origo isOfType:kOrigoTypeList];
        } else if ([_origo isOfType:kOrigoTypeResidence]) {
            hasFooter = [_origo isActiveResidence] && ![self aspectIs:kAspectHousehold];
        } else {
            hasFooter = self.isModal || ![[_origo members] count];
        }
    }
    
    return hasFooter;
}


- (id)headerContentForSectionWithKey:(NSInteger)sectionKey
{
    id content = nil;
    NSInteger number;
    
    if (sectionKey == kSectionKeyOrganisers) {
        NSString *contactTitle = nil;
        
        if ([_origo isOfType:kOrigoTypePreschoolClass]) {
            contactTitle = _preschoolTeacher_;
        } else if ([_origo isOfType:kOrigoTypeSchoolClass]) {
            contactTitle = _teacher_;
        } else if ([_origo isOfType:kOrigoTypeTeam]) {
            contactTitle = _coach_;
        } else if ([_origo isOfType:kOrigoTypeStudyGroup]) {
            contactTitle = _lecturer_;
        }
        
        number = [[_origo organisers] count] > 1 ? pluralIndefinite : singularIndefinite;
        content = [[OLanguage nouns][contactTitle][number] stringByCapitalisingFirstLetter];
    } else if (sectionKey == kSectionKeyParentContacts) {
        number = [[_origo parentContacts] count] > 1 ? pluralIndefinite : singularIndefinite;
        content = [[OLanguage nouns][_parentContact_][number] stringByCapitalisingFirstLetter];
    } else if (sectionKey == kSectionKeyMembers) {
        NSString *membersTitle = NSLocalizedString(_origo.type, kStringPrefixMembersTitle);
        
        if ([_origo isJuvenile]) {
            if ([self actionIs:kActionRegister]) {
                content = membersTitle;
            } else {
                content = @[membersTitle, [[OLanguage nouns][_parent_][pluralIndefinite] stringByCapitalisingFirstLetter]];
            }
        } else if ([_origo isOfType:kOrigoTypeCommunity]) {
            if ([self actionIs:kActionRegister]) {
                content = membersTitle;
            } else {
                content = @[membersTitle, NSLocalizedString(@"Households", @"")];
            }
        } else {
            if (![_origo isCommitted] && [_origo isOfType:kOrigoTypeResidence]) {
                if (![_member isCommitted] && [self aspectIs:kAspectJuvenile]) {
                    content = NSLocalizedString(@"Guardians in the household", @"");
                } else {
                    content = membersTitle;
                }
            } else {
                content = membersTitle;
            }
        }
    }
    
    return content;
}


- (NSString *)footerContentForSectionWithKey:(NSInteger)sectionKey
{
    NSString *footerText = nil;
    
    if ([_origo isOfType:kOrigoTypeResidence]) {
        if ([_origo isActiveResidence] && ![self aspectIs:kAspectHousehold]) {
            footerText = NSLocalizedString(@"This household has active members.", @"");
        } else if ([self aspectIs:kAspectJuvenile]) {
            footerText = NSLocalizedString(@"Tap + to register additional guardians in the household.", @"");
        }
    } else if ([_origo isOfType:kOrigoTypeList]) {
        if ([self actionIs:kActionRegister]) {
            footerText = NSLocalizedString(@"Private lists are not shared and are not visible to others.", @"");
        } else if ([_member isJuvenile]) {
            footerText = NSLocalizedString(@"Tap + to register friends.", @"");
        } else {
            footerText = NSLocalizedString(@"Tap + to register contacts.", @"");
        }
    } else {
        footerText = NSLocalizedString(_origo.type, kStringPrefixFooter);
    }
    
    return footerText;
}


- (BOOL)toolbarHasSendTextButton
{
    return [[_origo textRecipients] count] > 0;
}


- (BOOL)toolbarHasCallButton
{
    return [[_origo callRecipients] count] > 0;
}


- (BOOL)toolbarHasSendEmailButton
{
    return [[_origo emailRecipients] count] > 0;
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
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if ([_origo isCommitted] && [_origo isManagedByUser]) {
        if (sectionKey == kSectionKeyMembers) {
            id entity = [self dataAtIndexPath:indexPath];
            
            if ([entity conformsToProtocol:@protocol(OMember)]) {
                canDeleteCell = ![_origo isOfType:kOrigoTypeCommunity] && ![entity isUser];
            } else if ([entity conformsToProtocol:@protocol(OOrigo)]) {
                canDeleteCell = ![[[OMeta m].user residences] containsObject:entity];
            }
        } else {
            canDeleteCell = [[self roleHoldersForRoleAtIndexPath:indexPath] count] == 1;
        }
    }
    
    return canDeleteCell;
}


- (NSString *)deleteConfirmationButtonTitleForCellAtIndexPath:(NSIndexPath *)indexPath
{
    return NSLocalizedString(@"Remove", @"");
}


- (void)willDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyMembers) {
        if ([[self dataAtIndexPath:indexPath] conformsToProtocol:@protocol(OOrigo)]) {
            [_origo expireCommunityResidence:[self dataAtIndexPath:indexPath]];
        } else {
            id<OMember> member = [self dataAtIndexPath:indexPath];
            id<OMembership> membership = [_origo membershipForMember:member];
            
            if ([membership isResidency] && member.email && [[member residencies] count] == 1) {
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
            if ([viewController targetIs:kTargetOrganiser]) {
                [self reloadSectionWithKey:kSectionKeyOrganisers];
            } else {
                [self reloadSectionWithKey:kSectionKeyMembers];
                
                if ([_origo isOfType:kOrigoTypeResidence]) {
                    [self.inputCell readData];
                }
            }
        } if ([viewController.identifier isEqualToString:kIdentifierValueList]) {
            if ([viewController targetIs:kTargetRoles]) {
                [self reloadSections];
            } else if ([viewController targetIs:kTargetGroups]) {
                BOOL hasGroups = [[_origo groups] count] > 0;
                UIBarButtonItem *groupsButton = [self.navigationItem rightBarButtonItemWithTag:kBarButtonTagGroups];
                
                if (!groupsButton && hasGroups) {
                    [self.navigationItem insertRightBarButtonItem:[UIBarButtonItem groupsButtonWithTarget:self] atIndex:[_origo hasAddress] ? 2 : 1];
                } else if (groupsButton && !hasGroups) {
                    [self.navigationItem removeRightBarButtonItem:groupsButton];
                }
            }
        } else if ([viewController.identifier isEqualToString:kIdentifierValuePicker]) {
            if ([viewController targetIs:kTargetMembers]) {
                for (id<OMember> member in viewController.returnData) {
                    [_origo addMember:member];
                }
                
                [self reloadSectionWithKey:kSectionKeyMembers];
            } else if ([viewController aspectIs:kAspectParentRole]) {
                [self reloadSectionWithKey:kSectionKeyParentContacts];
            }
            
            [[OMeta m].replicator replicateIfNeeded];
        } else if ([viewController.identifier isEqualToString:kIdentifierInfo]) {
            if (![_origoType isEqualToString:_origo.type]) {
                self.selectedHeaderSegment = 0;
                _origoType = _origo.type;
            }
            
            if (_isManagedByUser && ![_origo isManagedByUser]) {
                _isManagedByUser = NO;
                
                [self loadNavigationBarItems];
            }
        }
    }
}


- (BOOL)supportsPullToRefresh
{
    return ![_origo isOfType:kOrigoTypeResidence] && ![_origo isOfType:kOrigoTypeList];
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
    } else if ([_origo isOfType:kOrigoTypeOrganisation]) {
        blueprint.detailKeys = @[kMappedKeyOrganisationDescription, kPropertyKeyAddress, kPropertyKeyTelephone];
        blueprint.multiLineKeys = @[kMappedKeyOrganisationDescription, kPropertyKeyAddress];
    } else if ([_origo isOfType:kOrigoTypePreschoolClass]) {
        blueprint.detailKeys = @[kMappedKeyPreschool, kPropertyKeyAddress];
        blueprint.multiLineKeys = @[kPropertyKeyAddress];
    } else if ([_origo isOfType:kOrigoTypeSchoolClass]) {
        blueprint.detailKeys = @[kMappedKeySchool, kPropertyKeyAddress];
        blueprint.multiLineKeys = @[kPropertyKeyAddress];
    } else if ([_origo isOfType:kOrigoTypeTeam]) {
        blueprint.detailKeys = @[kMappedKeyClub];
    } else if ([_origo isOfType:kOrigoTypeStudyGroup]) {
        blueprint.detailKeys = @[kMappedKeyInstitution];
    } else if (![_origo isOfType:kOrigoTypeList]) {
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
        isValid = [self.inputCell hasValidValueForKey:kPropertyKeyAddress];
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
        
        if ([_origo isOfType:kOrigoTypeResidence] && ![_origo hasAddress]) {
            [self.dismisser dismissModalViewController:self];
        } else {
            [self toggleEditMode];
            [self reloadSections];
            
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
            self.navigationItem.rightBarButtonItems = @[[UIBarButtonItem plusButtonWithTarget:self]];
        }
    } else {
        [self toggleEditMode];

        if ([self actionIs:kActionDisplay]) {
            UIBarButtonItem *locationButton = [self.navigationItem rightBarButtonItemWithTag:kBarButtonTagLocation];
            
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
    return [self.entity.ancestor isCommitted];
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
                        NSMutableArray *rightBarButtonItems = [NSMutableArray array];
                        
                        for (UIBarButtonItem *button in self.navigationItem.rightBarButtonItems) {
                            if (button.tag != kBarButtonTagAcceptDecline) {
                                [rightBarButtonItems addObject:button];
                            }
                        }
                        
                        [self.navigationItem setRightBarButtonItems:rightBarButtonItems animated:YES];
                        
                        if ([_origo isManagedByUser]) {
                            [self.navigationItem addRightBarButtonItem:[UIBarButtonItem editButtonWithTarget:self]];
                            [self.navigationItem addRightBarButtonItem:[UIBarButtonItem plusButtonWithTarget:self]];
                        }
                    }
                } else if (buttonTag == kButtonTagAcceptDeclineDecline) {
                    if (![_membership isHidden]) {
                        if ([_origo isOfType:kOrigoTypeResidence]) {
                            [_membership expire];
                        } else {
                            _membership.status = kMembershipStatusListed;
                        }
                        
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                }
                
                break;
                
            case kActionSheetTagEdit:
                if (buttonTag == kButtonTagEditGroup) {
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
                } else if (buttonTag == kButtonTagEditSubgroups) {
                    self.presentStealthilyOnce = YES;
                    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetGroups];
                }
                
                break;
                
            case kActionSheetTagAdd:
                if (buttonTag == kButtonTagAddMember) {
                    [self addMember];
                } else if (buttonTag == kButtonTagAddFromGroups) {
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
                    
                    if ([_eligibleCandidates count] == 1) {
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
                
            default:
                break;
        }
    }
}

@end
