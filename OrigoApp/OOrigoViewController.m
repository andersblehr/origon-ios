//
//  OOrigoViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OOrigoViewController.h"

static NSInteger const kSectionKeyOrganisers = 1;
static NSInteger const kSectionKeyParentContacts = 2;
static NSInteger const kSectionKeyMembers = 3;

static NSInteger const kActionSheetTagAcceptReject = 0;
static NSInteger const kButtonTagAcceptRejectAccept = 0;
static NSInteger const kButtonTagAcceptRejectReject = 1;

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


@interface OOrigoViewController () <OTableViewController, OInputCellDelegate, UIActionSheetDelegate> {
@private
    id<OOrigo> _origo;
    id<OMember> _member;
    id<OMembership> _membership;
    
    NSString *_origoType;
    NSArray *_eligibleCandidates;
    
    BOOL _isListingResidences;
    BOOL _userCanEdit;
}

@end


@implementation OOrigoViewController

#pragma mark - Auxiliary methods

- (void)loadNavigationBarItems
{
    self.navigationItem.rightBarButtonItems = nil;

    BOOL isAwaitingActivation = NO;
    
    if (_membership && ![_membership isActive] && ([_member isUser] || [_member isWardOfUser])) {
        if ([_origo isOfType:kOrigoTypeResidence] && [[_member addresses] count] == 1) {
            _membership.status = kMembershipStatusActive;
        } else {
            [self.navigationItem addRightBarButtonItem:[UIBarButtonItem acceptRejectButtonWithTarget:self]];
            
            if (_membership.status == kMembershipStatusInvited) {
                _membership.status = kMembershipStatusWaiting;
            } else if (_membership.status == kMembershipStatusWaiting) {
                _membership.status = kMembershipStatusActive;
            }
            
            isAwaitingActivation = YES;
        }
    }
    
    [self.navigationItem addRightBarButtonItem:[UIBarButtonItem infoButtonWithTarget:self]];
    
    if ([_origo hasAddress]) {
        [self.navigationItem addRightBarButtonItem:[UIBarButtonItem mapButtonWithTarget:self]];
    }
    
    if ([[_origo groups] count]) {
        [self.navigationItem addRightBarButtonItem:[UIBarButtonItem groupsButtonWithTarget:self]];
    }
    
    if ([_origo userCanEdit] && !isAwaitingActivation) {
        [self.navigationItem addRightBarButtonItem:[UIBarButtonItem editButtonWithTarget:self]];
        [self.navigationItem addRightBarButtonItem:[UIBarButtonItem plusButtonWithTarget:self]];
    }
}


- (UIView *)segmentedHeaderView
{
    NSArray *headers = @[NSLocalizedString(@"Members", @""), NSLocalizedString(@"Households", @"")];
    CGFloat width0 = [headers[0] sizeWithFont:[UIFont headerFont] maxWidth:CGFLOAT_MAX].width;
    CGFloat width1 = [headers[1] sizeWithFont:[UIFont headerFont] maxWidth:CGFLOAT_MAX].width;
    CGFloat alignmentOffset = (MAX(width0, width1) - width0) / 2.f;
    
    UISegmentedControl *headerSegments = [[UISegmentedControl alloc] initWithItems:headers];
    headerSegments.frame = CGRectMake(kDefaultCellPadding - alignmentOffset, 0.f, headerSegments.frame.size.width, [[UIFont headerFont] headerHeight]);
    headerSegments.tintColor = [UIColor clearColor];
    headerSegments.selectedSegmentIndex = _isListingResidences ? 1 : 0;
    [headerSegments setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor headerTextColour], NSFontAttributeName: [UIFont headerFont]} forState:UIControlStateSelected];
    [headerSegments setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor], NSFontAttributeName: [UIFont headerFont]} forState:UIControlStateNormal];
    [headerSegments addTarget:self action:@selector(didSelectHeaderSegment) forControlEvents:UIControlEventValueChanged];
    
    UIView *segmentedHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, [OMeta screenWidth], [[UIFont headerFont] headerHeight])];
    segmentedHeaderView.backgroundColor = [UIColor clearColor];
    [segmentedHeaderView addSubview:headerSegments];
    
    return segmentedHeaderView;
}


- (NSString *)nameKey
{
    NSString *nameKey = nil;
    
    if ([_origo isOfType:kOrigoTypeResidence]) {
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
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:NSLocalizedString(@"Register household member", @"") delegate:self tag:kActionSheetTagCoHabitants];
    
    _eligibleCandidates = [OUtil sortedGroupsOfResidents:candidates excluding:nil];
    
    if ([_eligibleCandidates count] == 1) {
        if ([_eligibleCandidates[kButtonTagCoHabitantsAll][0] isJuvenile]) {
            [actionSheet addButtonWithTitle:[OUtil commaSeparatedListOfItems:_eligibleCandidates[kButtonTagCoHabitantsAll] conjoin:YES] tag:kButtonTagCoHabitantsAll];
        } else {
            for (id<OMember> candidate in _eligibleCandidates[kButtonTagCoHabitantsAll]) {
                [actionSheet addButtonWithTitle:[candidate givenName]];
            }
        }
    } else {
        [actionSheet addButtonWithTitle:[OUtil commaSeparatedListOfItems:_eligibleCandidates[kButtonTagCoHabitantsAll] conjoin:YES] tag:kButtonTagCoHabitantsAll];
        [actionSheet addButtonWithTitle:[OUtil commaSeparatedListOfItems:_eligibleCandidates[kButtonTagCoHabitantsWards] conjoin:YES] tag:kButtonTagCoHabitantsWards];
    }
    
    if (![_origo userIsMember] && [_member isWardOfUser]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Other guardian", @"") tag:kButtonTagCoHabitantsGuardian];
    } else {
        [actionSheet addButtonWithTitle:NSLocalizedString(kOrigoTypeResidence, kStringPrefixAddMemberButton) tag:kButtonTagCoHabitantsNew];
    }
    
    [actionSheet show];
}


#pragma mark - Selector implementations

- (void)didSelectHeaderSegment
{
    _isListingResidences = !_isListingResidences;
    
    [self reloadSectionWithKey:kSectionKeyMembers];
}


- (void)performAcceptRejectAction
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:NSLocalizedString(@"Do you want to keep this listing?", @"") delegate:self tag:kActionSheetTagAcceptReject];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Keep", @"") tag:kButtonTagAcceptRejectAccept];
    
    if ([_origo isOfType:kOrigoTypeResidence]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Decline", @"") tag:kButtonTagAcceptRejectReject];
    } else {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Hide", @"") tag:kButtonTagAcceptRejectReject];
    }
    
    [actionSheet show];
}


- (void)performAddAction
{
    if ([_origo isOfType:kOrigoTypeResidence]) {
        [self addMember];
    } else {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagAdd];
        
        [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddMemberButton) tag:kButtonTagAddMember];
        
        _eligibleCandidates = [self.state eligibleCandidates];
        
        if ([_eligibleCandidates count]) {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Register from other group", @"") tag:kButtonTagAddFromGroups];
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
    if ([_origo isOfType:@[kOrigoTypeResidence, kOrigoTypeFriends]]) {
        [self scrollToTopAndToggleEditMode];
    } else {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagEdit];
        
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit", @"") tag:kButtonTagEditGroup];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit responsibilities", @"") tag:kButtonTagEditRoles];
        
        if (![_origo isOfType:@[kOrigoTypeResidence, kOrigoTypeFriends]]) {
            if (![[_origo groups] count]) {
                [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit subgroups", @"") tag:kButtonTagEditSubgroups];
            }
        }
        
        [actionSheet show];
    }
}


- (void)performGroupsAction
{
    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetGroups];
}


- (void)performMapAction
{
    
}


- (void)performInfoAction
{
    [self presentModalViewControllerWithIdentifier:kIdentifierInfo target:_origo];
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    _origo = [self.entity proxy];
    _member = self.state.currentMember;
    _membership = [_origo membershipForMember:_member];
    _origoType = _origo.type;
    _userCanEdit = [_origo userCanEdit];
    
    if ([self actionIs:kActionRegister]) {
        self.title = NSLocalizedString(_origo.type, kStringPrefixNewOrigoTitle);
        
        if ([_origo isOfType:kOrigoTypeResidence]) {
            id<OOrigo> residence = [_member primaryResidence];
            
            if (![residence hasAddress] || ![residence isCommitted]) {
                self.title = NSLocalizedString(kOrigoTypeResidence, kStringPrefixOrigoTitle);
            } else {
                self.title = NSLocalizedString(kOrigoTypeResidence, kStringPrefixNewOrigoTitle);
            }
            
            self.cancelImpliesSkip = ![_member hasAddress] && ![_origo isReplicated] && ![[_member housemates] count];
        }
    } else if ([self actionIs:kActionDisplay]) {
        if ([_origo isOfType:kOrigoTypeResidence] && ![self aspectIs:kAspectHousehold]) {
            self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:NSLocalizedString(kOrigoTypeResidence, kStringPrefixOrigoTitle)];
        } else {
            self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:_origo.name];
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
            [self setData:[_origo parentRoles] forSectionWithKey:kSectionKeyParentContacts];
            
            if ([_origo isOfType:kOrigoTypeCommunity]) {
                if (_isListingResidences) {
                    [self setData:[_origo memberResidences] forSectionWithKey:kSectionKeyMembers];
                } else {
                    [self setData:[_origo members] forSectionWithKey:kSectionKeyMembers];
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
        if (_isListingResidences) {
            id<OOrigo> residence = [self dataAtIndexPath:indexPath];
            
            cell.textLabel.text = [residence shortAddress];
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfMembers:[residence elders] withRolesInOrigo:_origo];
            [cell loadImageForOrigo:residence];
            cell.destinationId = kIdentifierOrigo;
        } else {
            id<OOrigo> origo = self.state.baseOrigo ? self.state.baseOrigo : _origo;
            id<OMember> member = [self dataAtIndexPath:indexPath];
            
            if (origo == _origo || ([_origo isOfType:kOrigoTypeResidence] && [member isJuvenile])) {
                [cell loadMember:member inOrigo:_origo];
            } else {
                [cell loadMember:member inOrigo:origo excludeRoles:NO excludeRelations:YES];
            }
            
            cell.destinationId = kIdentifierMember;
        }
    } else {
        NSString *role = [self dataAtIndexPath:indexPath];
        NSArray *roleHolders = [self roleHoldersForRoleAtIndexPath:indexPath];
        
        cell.textLabel.text = role;
        
        if ([roleHolders count] == 1) {
            id<OMember> roleHolder = roleHolders[0];
            
            if (sectionKey == kSectionKeyParentContacts) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@)", roleHolder.name, [OUtil commaSeparatedListOfMembers:[roleHolder wardsInOrigo:_origo] inOrigo:_origo conjoin:NO]];
            } else {
                cell.detailTextLabel.text = roleHolder.name;
            }
            
            [cell loadImageForMember:roleHolder];
            cell.destinationId = kIdentifierMember;
        } else {
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfMembers:roleHolders conjoin:NO];
            [cell loadTonedDownIconWithFileName:kIconFileRoleHolders];
            cell.destinationId = kIdentifierValueList;
            cell.destinationMeta = role;
        }
    }
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


- (NSArray *)toolbarButtons
{
    NSArray *toolbarButtons = nil;
    
    if ([_origo isCommitted]) {
        toolbarButtons = [[OMeta m].switchboard toolbarButtonsForOrigo:_origo presenter:self];
    }
    
    return toolbarButtons;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasFooter = NO;
    
    if (self.isModal && ![self actionIs:kActionRegister]) {
        hasFooter = [self isBottomSectionKey:sectionKey] && [_origo userCanEdit];
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
        if ([_origo isOfType:kOrigoTypeCommunity]) {
            content = [self segmentedHeaderView];
        } else {
            if ([self actionIs:kActionRegister] && [_origo isOfType:kOrigoTypeResidence]) {
                if (![_member hasAddress] && [self aspectIs:kAspectJuvenile]) {
                    content = NSLocalizedString(@"Guardians in the household", @"");
                } else {
                    content = NSLocalizedString(_origo.type, kStringPrefixMembersTitle);
                }
            } else {
                content = NSLocalizedString(_origo.type, kStringPrefixMembersTitle);
            }
        }
    }
    
    return content;
}


- (NSString *)footerContentForSectionWithKey:(NSInteger)sectionKey
{
    NSString *footerText = nil;
    
    if ([self aspectIs:kAspectJuvenile]) {
        footerText = NSLocalizedString(@"Tap [+] to register additional guardians in the household.", @"");
    } else {
        footerText = NSLocalizedString(_origo.type, kStringPrefixFooter);
    }
    
    return footerText;
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


- (void)willDisplayInputCell:(OTableViewCell *)inputCell
{
    if ([self actionIs:kActionRegister] && [_origo isOfType:kOrigoTypeResidence]) {
        if ([_member isUser] && ![_member hasAddress]) {
            [[inputCell inputFieldForKey:kMappedKeyResidenceName] setValue:NSLocalizedString(kMappedKeyResidenceName, kStringPrefixDefault)];
        }
    }
}


- (BOOL)canDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDeleteCell = NO;
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if ([_origo isCommitted] && [_origo userCanEdit]) {
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



- (void)willDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyMembers) {
        if (_isListingResidences) {
            [_origo expireCommunityResidence:[self dataAtIndexPath:indexPath]];
        } else {
            [[_origo membershipForMember:[self dataAtIndexPath:indexPath]] expire];
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
                _isListingResidences = NO;
                _origoType = _origo.type;
            }
            
            if (_userCanEdit && ![_origo userCanEdit]) {
                _userCanEdit = NO;
                
                [self loadNavigationBarItems];
            }
        }
    }
}


#pragma mark - OInputCellDelegate conformance

- (OInputCellBlueprint *)inputCellBlueprint
{
    OInputCellBlueprint *blueprint = [[OInputCellBlueprint alloc] init];
    
    blueprint.titleKey = [self nameKey];

    if ([_origo isOfType:kOrigoTypeResidence]) {
        blueprint.detailKeys = @[kPropertyKeyAddress, kPropertyKeyTelephone];
        blueprint.multiLineTextKeys = @[kPropertyKeyAddress];
    } else if ([_origo isOfType:kOrigoTypeOrganisation]) {
        blueprint.detailKeys = @[kMappedKeyOrganisationDescription, kPropertyKeyAddress, kPropertyKeyTelephone];
        blueprint.multiLineTextKeys = @[kMappedKeyOrganisationDescription, kPropertyKeyAddress];
    } else if ([_origo isOfType:kOrigoTypePreschoolClass]) {
        blueprint.detailKeys = @[kMappedKeyPreschool, kPropertyKeyAddress];
        blueprint.multiLineTextKeys = @[kPropertyKeyAddress];
    } else if ([_origo isOfType:kOrigoTypeSchoolClass]) {
        blueprint.detailKeys = @[kMappedKeySchool, kPropertyKeyAddress];
        blueprint.multiLineTextKeys = @[kPropertyKeyAddress];
    } else if ([_origo isOfType:kOrigoTypeTeam]) {
        blueprint.detailKeys = @[kMappedKeyClub];
    } else if ([_origo isOfType:kOrigoTypeStudyGroup]) {
        blueprint.detailKeys = @[kMappedKeyInstitution];
    } else {
        blueprint.titleKey = kPropertyKeyName;
        blueprint.detailKeys = @[kPropertyKeyDescriptionText];
        blueprint.multiLineTextKeys = @[kPropertyKeyDescriptionText];
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
            [self.inputCell readData];
            
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
            self.navigationItem.rightBarButtonItems = @[[UIBarButtonItem plusButtonWithTarget:self]];
        }
    } else {
        [self toggleEditMode];

        if ([self actionIs:kActionDisplay]) {
            UIBarButtonItem *mapButton = [self.navigationItem rightBarButtonItemWithTag:kBarButtonTagMap];
            
            if (!mapButton && [_origo hasAddress]) {
                [self.navigationItem insertRightBarButtonItem:[UIBarButtonItem mapButtonWithTarget:self] atIndex:1];
            } else if (mapButton && ![_origo hasAddress]) {
                [self.navigationItem removeRightBarButtonItem:mapButton];
            }
        }
    }
}


- (BOOL)isDisplayableFieldWithKey:(NSString *)key
{
    BOOL isVisible = ![key isEqualToString:kMappedKeyResidenceName];
    
    if (!isVisible && [_origo userIsMember]) {
        isVisible = YES;
    }
    
    return isVisible;
}


- (BOOL)shouldCommitEntity:(id)entity
{
    return [self.entity.ancestor isCommitted];
}


#pragma mark - UITableViewDataSource conformance

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NSLocalizedString(@"Remove", @"");
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
        
        switch (actionSheet.tag) {
            case kActionSheetTagAcceptReject:
                if (buttonTag == kButtonTagAcceptRejectAccept) {
                    id<OMembership> membership = [_origo membershipForMember:_member];
                    membership.status = kMembershipStatusActive;
                    
                    NSMutableArray *rightBarButtonItems = [NSMutableArray array];
                    
                    for (UIBarButtonItem *button in self.navigationItem.rightBarButtonItems) {
                        if (button.tag != kBarButtonTagAcceptReject) {
                            [rightBarButtonItems addObject:button];
                        }
                    }
                    
                    [self.navigationItem setRightBarButtonItems:rightBarButtonItems animated:YES];
                    
                    if ([_origo userCanEdit]) {
                        [self.navigationItem addRightBarButtonItem:[UIBarButtonItem editButtonWithTarget:self]];
                        [self.navigationItem addRightBarButtonItem:[UIBarButtonItem plusButtonWithTarget:self]];
                    }
                } else if (buttonTag == kButtonTagAcceptRejectReject) {
                    id<OMembership> membership = [_origo membershipForMember:_member];
                    
                    if ([_origo isOfType:kOrigoTypeResidence]) {
                        [membership expire];
                    } else {
                        membership.status = kMembershipStatusRejected;
                    }
                    
                    [self.navigationController popViewControllerAnimated:YES];
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
                
            default:
                break;
        }
    }
}

@end
