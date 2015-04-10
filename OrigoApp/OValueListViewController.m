//
//  OValueListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OValueListViewController.h"

static NSInteger const kSectionKeyValues = 0;
static NSInteger const kSectionKeyLists = 1;
static NSInteger const kSectionKeyActions = 2;

static NSInteger const kTitleSegmentFavourites = 0;
static NSInteger const kTitleSegmentOthers = 1;

static NSInteger const kTitleSegmentParents = 0;
static NSInteger const kTitleSegmentOrganisers = 1;
static NSInteger const kTitleSegmentMembers = 2;

static NSInteger const kPermissionTagEdit = 0;
static NSInteger const kPermissionTagAdd = 1;
static NSInteger const kPermissionTagDelete = 2;

static NSInteger const kActionSheetTagAdd = 0;
static NSInteger const kButtonTagAddOrganiser = 0;
static NSInteger const kButtonTagAddOrganiserRole = 1;


@interface OValueListViewController () <OTableViewController, UIActionSheetDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate> {
    id<OOrigo> _origo;

    UISegmentedControl *_titleSegments;
    NSMutableArray *_titleSegmentMappings;
    NSInteger _titleSegment;
    
    NSArray *_wards;
    NSArray *_candidates;
}

@end


@implementation OValueListViewController

#pragma mark - Auxiliary methods

- (void)setRoleTitleSegments
{
    _titleSegmentMappings = [NSMutableArray array];
    NSMutableArray *titleSegments = [NSMutableArray array];
    
    if ([_origo isJuvenile] && ![_origo isStandard]) {
        [_titleSegmentMappings addObject:@(kTitleSegmentParents)];
        [titleSegments addObject:[[OLanguage nouns][_parent_][pluralIndefinite] stringByCapitalisingFirstLetter]];
    }
    
    if ([_origo isOrganised]) {
        [_titleSegmentMappings addObject:@(kTitleSegmentOrganisers)];
        [titleSegments addObject:NSLocalizedString(_origo.type, kStringPrefixOrganisersTitle)];
    }
    
    if (![_origo isOfType:kOrigoTypePreschoolClass]) {
        [_titleSegmentMappings addObject:@(kTitleSegmentMembers)];
        [titleSegments addObject:NSLocalizedString(_origo.type, kStringPrefixMembersTitle)];
    }
    
    if ([titleSegments count] > 1) {
        _titleSegments = [self titleSegmentsWithTitles:titleSegments];
        
        [self inferTitleSegment];
    } else {
        _titleSegment = kTitleSegmentMembers;
    }
}


- (void)inferTitleSegment
{
    if ([self targetIs:kTargetRoles]) {
        _titleSegment = [_titleSegmentMappings[_titleSegments.selectedSegmentIndex] integerValue];
    } else {
        _titleSegment = _titleSegments.selectedSegmentIndex;
    }
}


- (NSString *)aspectFromTitleSegment
{
    NSString *aspect = nil;
    
    if (_titleSegment == kTitleSegmentFavourites) {
        aspect = kAspectFavourites;
    } else if (_titleSegment == kTitleSegmentOthers) {
        aspect = kAspectNonFavourites;
    }
    
    return aspect;
}


#pragma mark - Selector implementations

- (void)performAddAction
{
    if ([self targetIs:kTargetRoles]) {
        if (_titleSegment == kTitleSegmentParents) {
            [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:@{kTargetRole: kAspectParentRole}];
        } else if (_titleSegment == kTitleSegmentOrganisers) {
            if ([[_origo organisers] count]) {
                OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagAdd];
                [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddOrganiserButton) tag:kButtonTagAddOrganiser];
                [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddOrganiserRoleButton) tag:kButtonTagAddOrganiserRole];
                
                [actionSheet show];
            } else {
                [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetOrganiser];
            }
        } else if (_titleSegment == kTitleSegmentMembers) {
            [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:@{kTargetRole: kAspectMemberRole}];
        }
    } else if ([self targetIs:kTargetGroups]) {
        [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:@{kTargetGroup: kAspectGroup}];
    }
}


- (void)performEditAction
{
    if ([self targetIs:kTargetGroups]) {
        [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:@{kTargetGroups: kAspectEditable}];
    }
}


- (void)performTextAction
{
    if ([self targetIs:kTargetAllContacts]) {
        [self presentModalViewControllerWithIdentifier:kIdentifierRecipientPicker target:@{kTargetText: [self aspectFromTitleSegment]}];
    } else if ([self targetIs:kTargetRole]) {
        NSString *buttonTitle = nil;
        
        if ([_candidates count] == 2) {
            buttonTitle = NSLocalizedString(@"Send text to both", @"");
        } else if ([_candidates count] > 2) {
            buttonTitle = NSLocalizedString(@"Send text to all", @"");
        }
        
        [OActionSheet singleButtonActionSheetWithButtonTitle:buttonTitle action:^{
            NSMutableArray *recipients = [NSMutableArray array];
            
            for (id<OMember> candidate in _candidates) {
                if ([candidate.mobilePhone hasValue]) {
                    [recipients addObject:candidate.mobilePhone];
                }
            }
            
            MFMessageComposeViewController *messageComposer = [[MFMessageComposeViewController alloc] init];
            messageComposer.messageComposeDelegate = self;
            messageComposer.recipients = recipients;
            
            [self presentViewController:messageComposer animated:YES completion:nil];
        }];
    }
}


- (void)performEmailAction
{
    if ([self targetIs:kTargetAllContacts]) {
        [self presentModalViewControllerWithIdentifier:kIdentifierRecipientPicker target:@{kTargetEmail: [self aspectFromTitleSegment]}];
    } else if ([self targetIs:kTargetRole]) {
        NSString *buttonTitle = nil;
        
        if ([_candidates count] == 2) {
            buttonTitle = NSLocalizedString(@"Send email to both", @"");
        } else if ([_candidates count] > 2) {
            buttonTitle = NSLocalizedString(@"Send email to all", @"");
        }
        
        [OActionSheet singleButtonActionSheetWithButtonTitle:buttonTitle action:^{
            NSMutableArray *recipients = [NSMutableArray array];
            
            for (id<OMember> candidate in _candidates) {
                if ([candidate.email hasValue]) {
                    [recipients addObject:candidate.email];
                }
            }
            
            MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
            mailComposer.mailComposeDelegate = self;
            [mailComposer setToRecipients:recipients];
            [mailComposer setMessageBody:NSLocalizedString(@"Sent from Origo - http://origoapp.com", @"") isHTML:NO];
            
            [self presentViewController:mailComposer animated:YES completion:nil];
        }];
    }
}


- (void)didSelectTitleSegment
{
    NSInteger previousSegment = _titleSegment;
    
    [self inferTitleSegment];
    
    if ([self targetIs:kTargetAllContacts]) {
        [self reloadSections];
    } else {
        if ([self numberOfRowsInSectionWithKey:kSectionKeyValues]) {
            if (_titleSegment > previousSegment) {
                self.rowAnimation = UITableViewRowAnimationLeft;
            } else {
                self.rowAnimation = UITableViewRowAnimationRight;
            }
        } else {
            if (_titleSegment > previousSegment) {
                self.rowAnimation = UITableViewRowAnimationRight;
            } else {
                self.rowAnimation = UITableViewRowAnimationLeft;
            }
        }
        
        [self reloadSectionWithKey:kSectionKeyValues];
    }
}


- (void)didTogglePermissionSwitch:(id)sender
{
    UISwitch *permissionSwitch = sender;
    
    if (permissionSwitch.tag == kPermissionTagEdit) {
        _origo.membersCanEdit = permissionSwitch.on;
    } else if (permissionSwitch.tag == kPermissionTagAdd) {
        _origo.membersCanAdd = permissionSwitch.on;
    } else if (permissionSwitch.tag == kPermissionTagDelete) {
        _origo.membersCanDelete = permissionSwitch.on;
    }
}


#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self targetIs:kTargetGroups]) {
        if (![[_origo groups] count] && ![self aspectIs:kAspectEditable] && !self.wasHidden) {
            [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:@{kTargetGroups: kAspectEditable}];
        }
    }
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    _origo = self.state.currentOrigo;
    
    if ([self targetIs:kTargetSettings]) {
        self.title = NSLocalizedString(@"Settings", @"");
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem closeButtonWithTarget:self];
    } else if ([self targetIs:kTargetPermissions]) {
        self.title = NSLocalizedString(@"Member permissions", @"");
    } else if ([self targetIs:kTargetAdmins]) {
        self.title = NSLocalizedString(kLabelKeyAdmins, kStringPrefixLabel);
    } else if ([self targetIs:kTargetAllContacts]) {
        self.title = NSLocalizedString(@"All contacts", @"");
        self.usesSectionIndexTitles = YES;
        
        _titleSegments = [self titleSegmentsWithTitles:@[NSLocalizedString(@"Favourites", @""), NSLocalizedString(@"Others", @"")]];
        _titleSegment = _titleSegments.selectedSegmentIndex;
    } else if ([self targetIs:kTargetParents]) {
        if (self.meta) {
            _wards = @[self.meta];
        } else {
            _wards = [[[OMeta m].user wards] sortedArrayUsingSelector:@selector(ageCompare:)];
        }
        
        if ([_wards count] == 1) {
            self.title = [_wards[0] givenName];
            
            _titleSegment = 0;
        } else {
            self.title = [[OLanguage nouns][_parent_][pluralIndefinite] stringByCapitalisingFirstLetter];
            
            NSMutableArray *wardNames = [NSMutableArray array];
            
            for (id<OMember> ward in _wards) {
                [wardNames addObject:[ward givenName]];
            }
            
            _titleSegments = [self titleSegmentsWithTitles:wardNames];
            _titleSegment = _titleSegments.selectedSegmentIndex;
        }
        
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
    } else if ([self targetIs:kTargetDevices]) {
        self.title = NSLocalizedString(self.target, kStringPrefixSettingLabel);
        self.usesPlainTableViewStyle = YES;
    } else if ([self targetIs:kTargetRole]) {
        self.title = self.target;
    } else if ([self targetIs:kTargetRoles]) {
        self.title = NSLocalizedString(@"Responsibilities", @"");
        
        [self setRoleTitleSegments];
        [self inferTitleSegment];
        
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
    } else if ([self targetIs:kTargetGroups]) {
        if ([self aspectIs:kAspectEditable]) {
            self.title = NSLocalizedString(@"Edit groups", @"");
            self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:NSLocalizedString(@"Groups", @"")];
            
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
        } else {
            self.title = NSLocalizedString(@"Groups", @"");

            if ([_origo userCanEdit]) {
                self.navigationItem.leftBarButtonItem = [UIBarButtonItem systemEditButtonWithTarget:self];
            }
            
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem closeButtonWithTarget:self];
            self.usesPlainTableViewStyle = YES;
            
            NSArray *groups = [_origo groups];
            
            if ([groups count]) {
                _titleSegments = [self titleSegmentsWithTitles:groups];
                _titleSegment = _titleSegments.selectedSegmentIndex;
            }
        }
    }
}


- (void)loadData
{
    if ([self targetIs:kTargetSettings]) {
        [self setData:[[OMeta m].user settingKeys] forSectionWithKey:kSectionKeyValues];
        [self setData:[[OMeta m].user settingListKeys] forSectionWithKey:kSectionKeyLists];
        [self setData:@[kActionKeyChangePassword, kActionKeyLogout] forSectionWithKey:kSectionKeyActions];
    } else if ([self targetIs:kTargetPermissions]) {
        [self setData:[_origo permissionKeys] forSectionWithKey:kSectionKeyValues];
    } else if ([self targetIs:kTargetAdmins]) {
        [self setData:[_origo admins] forSectionWithKey:kSectionKeyValues];
    } else if ([self targetIs:kTargetAllContacts]) {
        _candidates = [self.state eligibleCandidates];
        
        if (_titleSegment == kTitleSegmentFavourites) {
            [self setData:[[OMeta m].user favourites] sectionIndexLabelKey:kPropertyKeyName];
        } else if (_titleSegment == kTitleSegmentOthers) {
            [self setData:[[OMeta m].user nonFavourites] sectionIndexLabelKey:kPropertyKeyName];
        }
    } else if ([self targetIs:kTargetParents]) {
        [self setData:@[kPropertyKeyMotherId, kPropertyKeyFatherId] forSectionWithKey:kSectionKeyValues];
    } else if ([self targetIs:kTargetDevices]) {
        [self setData:[[OMeta m].user activeDevices] forSectionWithKey:kSectionKeyValues];
    } else if ([self targetIs:kTargetRole]) {
        if ([self aspectIs:kAspectOrganiserRole]) {
            _candidates = [_origo organisersWithRole:self.target];
        } else if ([self aspectIs:kAspectParentRole]) {
            _candidates = [_origo parentsWithRole:self.target];
        }
        
        [self setData:_candidates forSectionWithKey:kSectionKeyValues];
    } else if ([self targetIs:kTargetRoles]) {
        if (_titleSegment == kTitleSegmentParents) {
            [self setData:[_origo parentRoles] forSectionWithKey:kSectionKeyValues];
        } else if (_titleSegment == kTitleSegmentOrganisers) {
            [self setData:[_origo organiserRoles] forSectionWithKey:kSectionKeyValues];
        } else if (_titleSegment == kTitleSegmentMembers) {
            [self setData:[_origo memberRoles] forSectionWithKey:kSectionKeyValues];
        }
    } else if ([self targetIs:kTargetGroups]) {
        NSArray *groups = [_origo groups];
        
        if ([self aspectIs:kAspectEditable]) {
            [self setData:groups forSectionWithKey:kSectionKeyValues];
        } else {
            NSString *group = [groups count] ? groups[_titleSegment] : @"";
            
            [self setData:[_origo membersOfGroup:group] forSectionWithKey:kSectionKeyValues];
        }
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if ([self targetIs:kTargetSettings]) {
        if (sectionKey == kSectionKeyValues) {
            NSString *settingKey = [self dataAtIndexPath:indexPath];
            
            cell.textLabel.text = NSLocalizedString(settingKey, kStringPrefixSettingLabel);
            //cell.detailTextLabel.text = TODO;
            cell.destinationId = kIdentifierValuePicker;
        } else if (sectionKey == kSectionKeyLists) {
            NSString *target = [self dataAtIndexPath:indexPath];
            
            cell.textLabel.text = NSLocalizedString(target, kStringPrefixSettingLabel);
            
            NSInteger numberOfDevices = [[[OMeta m].user activeDevices] count];
            NSInteger numberOfHiddenOrigos = [[[OMeta m].user hiddenOrigos] count];
            NSInteger numberOfDeclinedOrigos = [[[OMeta m].user declinedOrigos] count];
            
            for (id<OMember> ward in [[OMeta m].user wards]) {
                numberOfHiddenOrigos += [[ward hiddenOrigos] count];
                numberOfDeclinedOrigos += [[ward declinedOrigos] count];
            }
            
            if ([target isEqualToString:kTargetDevices]) {
                cell.detailTextLabel.text = [@(numberOfDevices) description];
                cell.destinationId = kIdentifierValueList;
            } else if ([target isEqualToString:kTargetHiddenOrigos]) {
                cell.detailTextLabel.text = [@(numberOfHiddenOrigos) description];
                cell.destinationId = kIdentifierOrigoList;
            }
        } else if (sectionKey == kSectionKeyActions) {
            NSString *accountKey = [self dataAtIndexPath:indexPath];
            
            if ([accountKey isEqualToString:kActionKeyLogout]) {
                cell.textLabel.textColor = [UIColor redColor];
                cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(accountKey, kStringPrefixLabel), [OMeta m].user.name];
            } else {
                cell.textLabel.text = NSLocalizedString(accountKey, kStringPrefixLabel);
            }
        }
    } else if ([self targetIs:kTargetPermissions]) {
        NSString *permissionKey = [self dataAtIndexPath:indexPath];
        UISwitch *permissionSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        permissionSwitch.tag = indexPath.row;
        [permissionSwitch addTarget:self action:@selector(didTogglePermissionSwitch:) forControlEvents:UIControlEventValueChanged];
        permissionSwitch.on = [_origo hasPermissionWithKey:permissionKey];
        
        cell.textLabel.text = NSLocalizedString(permissionKey, kStringPrefixSettingLabel);
        cell.accessoryView = permissionSwitch;
        cell.selectable = NO;
    } else if ([self targetIs:kTargetAdmins]) {
        [cell loadMember:[self dataAtIndexPath:indexPath] inOrigo:_origo];
        cell.destinationId = kIdentifierMember;
    } else if ([self targetIs:kTargetAllContacts]) {
        id<OMember> member = [self dataAtIndexPath:indexPath];
        
        if (_titleSegment == kTitleSegmentFavourites) {
            [cell loadMember:member inOrigo:[[OMeta m].user stash]];
        } else if (_titleSegment == kTitleSegmentOthers) {
            [cell loadMember:member inOrigo:nil excludeRoles:YES excludeRelations:YES];
        }
        
        cell.destinationId = kIdentifierMember;
    } else if ([self targetIs:kTargetParents]) {
        NSString *parentKey = [self dataAtIndexPath:indexPath];
        id<OMember> ward = _wards[_titleSegment];
        
        cell.textLabel.text = NSLocalizedString(parentKey, kStringPrefixLabel);
        
        if ([parentKey isEqualToString:kPropertyKeyMotherId]) {
            cell.detailTextLabel.text = [ward mother].name;
        } else if ([parentKey isEqualToString:kPropertyKeyFatherId]) {
            cell.detailTextLabel.text = [ward father].name;
        }
        
        cell.destinationId = kIdentifierValuePicker;
        cell.destinationTarget = @{parentKey: kAspectParent};
        cell.destinationMeta = ward;
    } else if ([self targetIs:kTargetDevices]) {
        ODevice *device = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = device.name;
        cell.selectable = NO;
        
        if ([device.entityId isEqualToString:[OMeta m].deviceId]) {
            cell.detailTextLabel.text = NSLocalizedString(@"This device", @"");
            cell.detailTextLabel.textColor = [UIColor globalTintColour];
        }
        
        if ([device isOfType:kDeviceType_iPhone]) {
            cell.imageView.image = [UIImage imageNamed:kIconFile_iPhone];
        } else if ([device isOfType:kDeviceType_iPodTouch]) {
            cell.imageView.image = [UIImage imageNamed:kIconFile_iPodTouch];
        } else if ([device isOfType:kDeviceType_iPad]) {
            cell.imageView.image = [UIImage imageNamed:kIconFile_iPad];
        }
    } else if ([self targetIs:kTargetRole]) {
        [cell loadMember:[self dataAtIndexPath:indexPath] inOrigo:_origo excludeRoles:YES excludeRelations:NO];
        cell.destinationId = kIdentifierMember;
        cell.destinationMeta = self.target;
    } else if ([self targetIs:kTargetRoles]) {
        NSString *role = [self dataAtIndexPath:indexPath];
        NSArray *roleHolders = nil;
        
        if (_titleSegment == kTitleSegmentParents) {
            roleHolders = [_origo parentsWithRole:role];
            cell.destinationTarget = @{role: kAspectParentRole};
        } else if (_titleSegment == kTitleSegmentOrganisers) {
            roleHolders = [_origo organisersWithRole:role];
            cell.destinationTarget = @{role: kAspectOrganiserRole};
        } else if (_titleSegment == kTitleSegmentMembers) {
            roleHolders = [_origo membersWithRole:role];
            cell.destinationTarget = @{role: kAspectMemberRole};
        }
        
        cell.textLabel.text = role;
        cell.detailTextLabel.text = [OUtil commaSeparatedListOfMembers:roleHolders inOrigo:_origo subjective:NO];
        cell.destinationId = kIdentifierValuePicker;
    } else if ([self targetIs:kTargetGroups]) {
        if ([self aspectIs:kAspectEditable]) {
            NSString *group = [self dataAtIndexPath:indexPath];
            
            cell.textLabel.text = group;
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfMembers:[_origo membersOfGroup:group] inOrigo:_origo subjective:YES];
            cell.destinationId = kIdentifierValuePicker;
            cell.destinationTarget = @{group: kAspectGroup};
        } else {
            [cell loadMember:[self dataAtIndexPath:indexPath] inOrigo:_origo excludeRoles:NO excludeRelations:YES];
            cell.selectable = NO;
        }
    }
}


- (UITableViewCellStyle)listCellStyleForSectionWithKey:(NSInteger)sectionKey
{
    UITableViewCellStyle style = kTableViewCellStyleValueList;
    
    if ([self targetIs:@[kTargetAdmins, kTargetAllContacts, kTargetDevices, kTargetRole]]) {
        style = kTableViewCellStyleDefault;
    }
    
    return style;
}


- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey
{
    return NO;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return NO;
}


- (NSString *)emptyTableViewFooterText
{
    NSString *footerText = nil;
    
    if ([self targetIs:kTargetAllContacts]) {
        if (_titleSegment == kTitleSegmentFavourites) {
            footerText = NSLocalizedString(@"All persons marked as favourites will be listed here ...", @"");
        } else if (_titleSegment == kTitleSegmentOthers) {
            footerText = NSLocalizedString(@"All who are not marked as favourites will be listed here.", @"");
        }
    } else if ([self targetIs:kTargetRoles]) {
        footerText = NSLocalizedString(@"Tap + to add a responsibility.", @"");
    } else if ([self targetIs:kTargetGroups]) {
        footerText = NSLocalizedString(@"Tap + to create a group.", @"");
    }
    
    return footerText;
}


- (BOOL)toolbarHasSendTextButton
{
    BOOL hasSendTextButton = NO;
    
    if ([self targetIs:@[kTargetAllContacts, kTargetRole]]) {
        for (id<OMember> recipientCandidate in _candidates) {
            if ([recipientCandidate.mobilePhone hasValue]) {
                hasSendTextButton = YES;
                
                break;
            }
        }
    }
    
    return hasSendTextButton;
}


- (BOOL)toolbarHasSendEmailButton
{
    BOOL hasSendEmailButton = NO;
    
    if ([self targetIs:@[kTargetAllContacts, kTargetRole]]) {
        for (id<OMember> recipientCandidate in _candidates) {
            if ([recipientCandidate.email hasValue]) {
                hasSendEmailButton = YES;
                
                break;
            }
        }
    }
    
    return hasSendEmailButton;
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if ([self targetIs:kTargetSettings]) {
        if (sectionKey == kSectionKeyActions) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
            
            NSString *actionKey = [self dataAtIndexPath:indexPath];
            
            if ([actionKey isEqualToString:kActionKeyChangePassword]) {
                [self presentModalViewControllerWithIdentifier:kIdentifierAuth target:kTargetPassword];
            } else if ([actionKey isEqualToString:kActionKeyLogout]) {
                [[OMeta m] logout];
            }
        }
    }
}


- (BOOL)canDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDelete = NO;
    
    if ([self targetIs:kTargetDevices]) {
        ODevice *device = [self dataAtIndexPath:indexPath];
        
        canDelete = ![device.entityId isEqualToString:[OMeta m].deviceId];
    } else {
        canDelete = canDelete || [self targetIs:kTargetRole];
        canDelete = canDelete || [self targetIs:kTargetRoles];
        canDelete = canDelete || ([self targetIs:kTargetGroups] && [self aspectIs:kAspectEditable]);
    }
    
    return canDelete;
}


- (NSString *)deleteConfirmationButtonTitleForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *buttonTitle = nil;
    
    if ([self targetIs:kTargetDevices]) {
        buttonTitle = NSLocalizedString(kActionKeyLogout, kStringPrefixLabel);
    }
    
    return buttonTitle;
}


- (void)deleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self targetIs:kTargetDevices]) {
        [[self dataAtIndexPath:indexPath] expire];
    } else if ([self targetIs:kTargetRole]) {
        id<OMembership> membership = [_origo membershipForMember:[self dataAtIndexPath:indexPath]];
        [membership removeAffiliation:self.target ofType:[self.state affiliationTypeFromAspect]];
    } else if ([self targetIs:kTargetRoles]) {
        NSString *role = [self dataAtIndexPath:indexPath];

        if (_titleSegment == kTitleSegmentParents) {
            for (id<OMember> roleHolder in [_origo parentsWithRole:role]) {
                [[_origo membershipForMember:roleHolder] removeAffiliation:role ofType:kAffiliationTypeParentRole];
            }
        } else if (_titleSegment == kTitleSegmentOrganisers) {
            for (id<OMember> roleHolder in [_origo organisersWithRole:role]) {
                [[_origo membershipForMember:roleHolder] removeAffiliation:role ofType:kAffiliationTypeOrganiserRole];
            }
        } else if (_titleSegment == kTitleSegmentMembers) {
            for (id<OMember> roleHolder in [_origo membersWithRole:role]) {
                [[_origo membershipForMember:roleHolder] removeAffiliation:role ofType:kAffiliationTypeMemberRole];
            }
        }
    } else if ([self targetIs:kTargetGroups]) {
        NSString *group = [self dataAtIndexPath:indexPath];
        
        for (id<OMember> groupMember in [_origo membersOfGroup:group]) {
            [[_origo membershipForMember:groupMember] removeAffiliation:group ofType:kAffiliationTypeGroup];
        }
    }
}


- (BOOL)shouldRelayDismissalOfModalViewController:(OTableViewController *)viewController
{
    BOOL shouldRelay = NO;
    
    if ([self targetIs:kTargetGroups]) {
        if ([viewController.identifier isEqualToString:kIdentifierValueList]) {
            shouldRelay = ![[_origo groups] count];
        }
    }
    
    return shouldRelay;
}


- (void)willDismissModalViewController:(OTableViewController *)viewController
{
    if ([self targetIs:kTargetGroups]) {
        if (!viewController.didCancel) {
            if ([viewController.identifier isEqualToString:kIdentifierValueList]) {
                NSArray *groups = [_origo groups];
                
                if ([groups count]) {
                    if (_titleSegment == UISegmentedControlNoSegment) {
                        self.rowAnimation = UITableViewRowAnimationLeft;
                    }
                    
                    _titleSegments = [self titleSegmentsWithTitles:groups];
                    _titleSegment = _titleSegments.selectedSegmentIndex;
                } else if (_titleSegments) {
                    _titleSegments = [self titleSegmentsWithTitles:nil];
                    _titleSegment = 0;
                }
            }
        }
    }
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
    
    switch (actionSheet.tag) {
        case kActionSheetTagAdd:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                if (buttonTag == kButtonTagAddOrganiserRole) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:@{kTargetRole: kAspectOrganiserRole}];
                } else if (buttonTag == kButtonTagAddOrganiser) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetOrganiser];
                }
            }
            
            break;
            
        default:
            break;
    }
}


#pragma mark - MFMessageComposeViewControllerDelegate conformance

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - MFMailComposeViewControllerDelegate conformance

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
