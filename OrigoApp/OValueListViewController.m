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
static NSInteger const kSectionKeyAccount = 2;

static NSInteger const kTitleSubsegmentFavourites = 0;
static NSInteger const kTitleSubsegmentOthers = 1;

static NSInteger const kTitleSubsegmentParents = 0;
static NSInteger const kTitleSubsegmentOrganisers = 1;
static NSInteger const kTitleSubsegmentMembers = 2;

static NSInteger const kActionSheetTagAdd = 0;
static NSInteger const kButtonTagAddOrganiser = 0;
static NSInteger const kButtonTagAddOrganiserRole = 1;


@interface OValueListViewController () <OTableViewController, UIActionSheetDelegate> {
    id<OOrigo> _origo;

    UISegmentedControl *_titleSubsegments;
    NSMutableArray *_titleSubSegmentMappings;
    NSInteger _selectedTitleSubsegment;
    
    NSArray *_wards;
}

@end


@implementation OValueListViewController

#pragma mark - Auxiliary methods

- (void)setRoleTitleSubsegments
{
    _titleSubSegmentMappings = [NSMutableArray array];
    NSMutableArray *titleSegments = [NSMutableArray array];
    
    if ([_origo isJuvenile] && ![_origo isOfType:kOrigoTypeSimple]) {
        [_titleSubSegmentMappings addObject:@(kTitleSubsegmentParents)];
        [titleSegments addObject:[[OLanguage nouns][_parent_][pluralIndefinite] stringByCapitalisingFirstLetter]];
    }
    
    if ([_origo isOrganised]) {
        [_titleSubSegmentMappings addObject:@(kTitleSubsegmentOrganisers)];
        [titleSegments addObject:NSLocalizedString(_origo.type, kStringPrefixOrganisersTitle)];
    }
    
    if (![_origo isOfType:kOrigoTypePreschoolClass]) {
        [_titleSubSegmentMappings addObject:@(kTitleSubsegmentMembers)];
        [titleSegments addObject:NSLocalizedString(_origo.type, kStringPrefixMembersTitle)];
    }
    
    if ([titleSegments count] > 1) {
        _titleSubsegments = [self titleSubsegmentsWithTitles:titleSegments];
        
        [self inferSelectedTitleSubsegment];
    } else {
        _selectedTitleSubsegment = kTitleSubsegmentMembers;
    }
}


- (void)inferSelectedTitleSubsegment
{
    if ([self targetIs:kTargetRoles]) {
        _selectedTitleSubsegment = [_titleSubSegmentMappings[_titleSubsegments.selectedSegmentIndex] integerValue];
    } else {
        _selectedTitleSubsegment = _titleSubsegments.selectedSegmentIndex;
    }
}


#pragma mark - Selector implementations

- (void)performAddAction
{
    if ([self targetIs:kTargetRoles]) {
        if (_selectedTitleSubsegment == kTitleSubsegmentParents) {
            [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:@{kTargetRole: kAspectParentRole}];
        } else if (_selectedTitleSubsegment == kTitleSubsegmentOrganisers) {
            if ([[_origo organisers] count]) {
                OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagAdd];
                [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddOrganiserButton) tag:kButtonTagAddOrganiser];
                [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddOrganiserRoleButton) tag:kButtonTagAddOrganiserRole];
                
                [actionSheet show];
            } else {
                [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetOrganiser];
            }
        } else if (_selectedTitleSubsegment == kTitleSubsegmentMembers) {
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


- (void)didSelectTitleSubsegment
{
    NSInteger previousSegment = _selectedTitleSubsegment;
    
    [self inferSelectedTitleSubsegment];
    
    if ([self targetIs:kTargetFavourites]) {
        if (_selectedTitleSubsegment == kTitleSubsegmentFavourites) {
            self.title = NSLocalizedString(@"Favourites", @"");
        } else if (_selectedTitleSubsegment == kTitleSubsegmentOthers) {
            self.title = NSLocalizedString(@"Others", @"");
        }
        
        [self reloadSections];
    } else {
        if ([self numberOfRowsInSectionWithKey:kSectionKeyValues]) {
            if (_selectedTitleSubsegment > previousSegment) {
                self.rowAnimation = UITableViewRowAnimationLeft;
            } else {
                self.rowAnimation = UITableViewRowAnimationRight;
            }
        } else {
            if (_selectedTitleSubsegment > previousSegment) {
                self.rowAnimation = UITableViewRowAnimationRight;
            } else {
                self.rowAnimation = UITableViewRowAnimationLeft;
            }
        }
        
        [self reloadSectionWithKey:kSectionKeyValues];
    }
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.didResurface) {
        [self reloadSectionWithKey:kSectionKeyValues];
    }
}


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
    } else if ([self targetIs:kTargetFavourites]) {
        NSString *favouritesLabel = NSLocalizedString(@"Favourites", @"");
        
        self.title = favouritesLabel;
        self.usesSectionIndexTitles = YES;
        
        _titleSubsegments = [self titleSubsegmentsWithTitles:@[favouritesLabel, NSLocalizedString(@"Others", @"")]];
        _selectedTitleSubsegment = _titleSubsegments.selectedSegmentIndex;
    } else if ([self targetIs:kTargetParents]) {
        if (self.meta) {
            _wards = @[self.meta];
        } else {
            _wards = [[[OMeta m].user wards] sortedArrayUsingSelector:@selector(ageCompare:)];
        }
        
        if ([_wards count] == 1) {
            self.title = [_wards[0] givenName];
            
            _selectedTitleSubsegment = 0;
        } else {
            self.title = [[OLanguage nouns][_parent_][pluralIndefinite] stringByCapitalisingFirstLetter];
            
            NSMutableArray *wardNames = [NSMutableArray array];
            
            for (id<OMember> ward in _wards) {
                [wardNames addObject:[ward givenName]];
            }
            
            _titleSubsegments = [self titleSubsegmentsWithTitles:wardNames];
            _selectedTitleSubsegment = _titleSubsegments.selectedSegmentIndex;
        }
        
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
    } else if ([self targetIs:kTargetDevices]) {
        self.title = NSLocalizedString(self.target, kStringPrefixSettingListLabel);
        self.usesPlainTableViewStyle = YES;
    } else if ([self targetIs:kTargetRole]) {
        self.title = self.target;
    } else if ([self targetIs:kTargetRoles]) {
        self.title = NSLocalizedString(@"Responsibilities", @"");
        
        [self setRoleTitleSubsegments];
        [self inferSelectedTitleSubsegment];
        
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
    } else if ([self targetIs:kTargetGroups]) {
        if ([self aspectIs:kAspectEditable]) {
            if ([[_origo groups] count]) {
                self.title = NSLocalizedString(@"Edit groups", @"");
                self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:NSLocalizedString(@"Groups", @"")];
            } else {
                self.title = NSLocalizedString(@"Groups", @"");
            }
            
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
        } else {
            self.title = NSLocalizedString(@"Groups", @"");
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem closeButtonWithTarget:self];
            self.usesPlainTableViewStyle = YES;
            
            if ([_origo isManagedByUser]) {
                self.navigationItem.rightBarButtonItem = [UIBarButtonItem editButtonWithTarget:self];
            }
            
            NSArray *groups = [_origo groups];
            
            if ([groups count]) {
                _titleSubsegments = [self titleSubsegmentsWithTitles:groups];
                _selectedTitleSubsegment = _titleSubsegments.selectedSegmentIndex;
            }
        }
    }
}


- (void)loadData
{
    if ([self targetIs:kTargetSettings]) {
        OSettings *settings = [OSettings settings];
        
        [self setData:[settings settingKeys] forSectionWithKey:kSectionKeyValues];
        [self setData:[settings settingListKeys] forSectionWithKey:kSectionKeyLists];
        [self setData:[settings accountKeys] forSectionWithKey:kSectionKeyAccount];
    } else if ([self targetIs:kTargetFavourites]) {
        NSArray *favourites = [[OMeta m].user favourites];
        
        if (_selectedTitleSubsegment == kTitleSubsegmentFavourites) {
            [self setData:favourites sectionIndexLabelKey:kPropertyKeyName];
        } else if (_selectedTitleSubsegment == kTitleSubsegmentOthers) {
            NSMutableArray *others = [[[OMeta m].user peersNotInSet:favourites] mutableCopy];
            [others removeObject:[OMeta m].user];
            
            if ([[OMeta m].user isJuvenile]) {
                NSMutableSet *guardians = [NSMutableSet set];
                
                for (id<OMember> other in others) {
                    [guardians addObjectsFromArray:[other guardians]];
                }
                
                [others addObjectsFromArray:[guardians allObjects]];
            }
            
            [self setData:[others sortedArrayUsingSelector:@selector(compare:)] sectionIndexLabelKey:kPropertyKeyName];
        }
    } else if ([self targetIs:kTargetParents]) {
        [self setData:@[kPropertyKeyMotherId, kPropertyKeyFatherId] forSectionWithKey:kSectionKeyValues];
    } else if ([self targetIs:kTargetDevices]) {
        [self setData:[[OMeta m].user registeredDevices] forSectionWithKey:kSectionKeyValues];
    } else if ([self targetIs:kTargetRole]) {
        if ([self aspectIs:kAspectOrganiserRole]) {
            [self setData:[_origo organisersWithRole:self.target] forSectionWithKey:kSectionKeyValues];
        } else if ([self aspectIs:kAspectParentRole]) {
            [self setData:[_origo parentsWithRole:self.target] forSectionWithKey:kSectionKeyValues];
        }
    } else if ([self targetIs:kTargetRoles]) {
        if (_selectedTitleSubsegment == kTitleSubsegmentParents) {
            [self setData:[_origo parentRoles] forSectionWithKey:kSectionKeyValues];
        } else if (_selectedTitleSubsegment == kTitleSubsegmentOrganisers) {
            [self setData:[_origo organiserRoles] forSectionWithKey:kSectionKeyValues];
        } else if (_selectedTitleSubsegment == kTitleSubsegmentMembers) {
            [self setData:[_origo memberRoles] forSectionWithKey:kSectionKeyValues];
        }
    } else if ([self targetIs:kTargetGroups]) {
        NSArray *groups = [_origo groups];
        
        if ([self aspectIs:kAspectEditable]) {
            [self setData:groups forSectionWithKey:kSectionKeyValues];
        } else {
            NSString *group = [groups count] ? groups[_selectedTitleSubsegment] : [NSString string];
            
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
            cell.detailTextLabel.text = [[OSettings settings] displayValueForSettingKey:settingKey];
            cell.destinationId = kIdentifierValuePicker;
        } else if (sectionKey == kSectionKeyLists) {
            NSString *target = [self dataAtIndexPath:indexPath];
            
            cell.textLabel.text = NSLocalizedString(target, kStringPrefixSettingListLabel);
            
            if ([target isEqualToString:kTargetDevices]) {
                cell.destinationId = kIdentifierValueList;
            } else if ([target isEqualToString:kTargetHiddenOrigos]) {
                cell.destinationId = kIdentifierOrigoList;
            }
        } else if (sectionKey == kSectionKeyAccount) {
            NSString *accountKey = [self dataAtIndexPath:indexPath];
            
            if ([accountKey isEqualToString:kExternalKeySignOut]) {
                cell.textLabel.textColor = [UIColor redColor];
                cell.textLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(accountKey, kStringPrefixLabel), [OMeta m].user.name];
            } else {
                cell.textLabel.text = NSLocalizedString(accountKey, kStringPrefixLabel);
            }
        }
    } else if ([self targetIs:kTargetFavourites]) {
        id<OMember> member = [self dataAtIndexPath:indexPath];
        
        if (_selectedTitleSubsegment == kTitleSubsegmentFavourites) {
            [cell loadMember:member inOrigo:[[OMeta m].user stash]];
        } else if (_selectedTitleSubsegment == kTitleSubsegmentOthers) {
            [cell loadMember:member inOrigo:nil excludeRoles:YES excludeRelations:YES];
        }
        
        cell.destinationId = kIdentifierMember;
    } else if ([self targetIs:kTargetParents]) {
        NSString *parentKey = [self dataAtIndexPath:indexPath];
        id<OMember> ward = _wards[_selectedTitleSubsegment];
        
        cell.textLabel.text = NSLocalizedString(parentKey, kStringPrefixLabel);
        
        if ([parentKey isEqualToString:kPropertyKeyMotherId]) {
            cell.detailTextLabel.text = [ward mother].name;
        } else if ([parentKey isEqualToString:kPropertyKeyFatherId]) {
            cell.detailTextLabel.text = [ward father].name;
        }
        
        cell.destinationId = kIdentifierValuePicker;
        cell.destinationMeta = ward;
    } else if ([self targetIs:kTargetDevices]) {
        ODevice *device = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = device.name;
        cell.selectable = NO;
        
        if ([device.entityId isEqualToString:[OMeta m].deviceId]) {
            cell.detailTextLabel.text = NSLocalizedString(@"This device", @"");
            cell.detailTextLabel.textColor = [UIColor globalTintColour];
        } else {
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Last seen %@", @""), [device.lastSeen localisedDateTimeString]];
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
        
        if (_selectedTitleSubsegment == kTitleSubsegmentParents) {
            roleHolders = [_origo parentsWithRole:role];
        } else if (_selectedTitleSubsegment == kTitleSubsegmentOrganisers) {
            roleHolders = [_origo organisersWithRole:role];
        } else if (_selectedTitleSubsegment == kTitleSubsegmentMembers) {
            roleHolders = [_origo membersWithRole:role];
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
        } else {
            [cell loadMember:[self dataAtIndexPath:indexPath] inOrigo:_origo excludeRoles:NO excludeRelations:YES];
            cell.selectable = NO;
        }
    }
}


- (id)destinationTargetForIndexPath:(NSIndexPath *)indexPath
{
    id target = [self dataAtIndexPath:indexPath];
    
    if ([self targetIs:kTargetParents]) {
        target = @{target: kAspectParent};
    } else if ([self targetIs:kTargetRoles]) {
        if (_selectedTitleSubsegment == kTitleSubsegmentParents) {
            target = @{target: kAspectParentRole};
        } else if (_selectedTitleSubsegment == kTitleSubsegmentOrganisers) {
            target = @{target: kAspectOrganiserRole};
        } else if (_selectedTitleSubsegment == kTitleSubsegmentMembers) {
            target = @{target: kAspectMemberRole};
        }
    } else if ([self targetIs:kTargetGroups]) {
        target = @{target: kAspectGroup};
    }
    
    return target;
}


- (UITableViewCellStyle)listCellStyleForSectionWithKey:(NSInteger)sectionKey
{
    UITableViewCellStyle style = UITableViewCellStyleValue1;
    
    if ([self targetIs:@[kTargetFavourites, kTargetDevices, kTargetRole]]) {
        style = UITableViewCellStyleSubtitle;
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
    
    if ([self targetIs:kTargetFavourites]) {
        if (_selectedTitleSubsegment == kTitleSubsegmentFavourites) {
            footerText = NSLocalizedString(@"All persons marked as favourites will be listed here ...", @"");
        } else if (_selectedTitleSubsegment == kTitleSubsegmentOthers) {
            footerText = NSLocalizedString(@"All who are not marked as favourites will be listed here.", @"");
        }
    }
    
    return footerText;
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if ([self targetIs:kTargetSettings]) {
        if (sectionKey == kSectionKeyAccount) {
            NSString *actionKey = [self dataAtIndexPath:indexPath];
            
            if ([actionKey isEqualToString:kExternalKeyChangePassword]) {
                [self presentModalViewControllerWithIdentifier:kIdentifierAuth target:kTargetPassword];
            } else if ([actionKey isEqualToString:kExternalKeySignOut]) {
                [[OMeta m] signOut];
            }
        } else {
            // TODO
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


- (void)willDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self targetIs:kTargetDevices]) {
        [[self dataAtIndexPath:indexPath] expire];
    } else if ([self targetIs:kTargetRole]) {
        id<OMembership> membership = [_origo membershipForMember:[self dataAtIndexPath:indexPath]];
        [membership removeAffiliation:self.target ofType:[self.state affiliationTypeFromAspect]];
    } else if ([self targetIs:kTargetRoles]) {
        NSString *role = [self dataAtIndexPath:indexPath];

        if (_selectedTitleSubsegment == kTitleSubsegmentParents) {
            for (id<OMember> roleHolder in [_origo parentsWithRole:role]) {
                [[_origo membershipForMember:roleHolder] removeAffiliation:role ofType:kAffiliationTypeParentRole];
            }
        } else if (_selectedTitleSubsegment == kTitleSubsegmentOrganisers) {
            for (id<OMember> roleHolder in [_origo organisersWithRole:role]) {
                [[_origo membershipForMember:roleHolder] removeAffiliation:role ofType:kAffiliationTypeOrganiserRole];
            }
        } else if (_selectedTitleSubsegment == kTitleSubsegmentMembers) {
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
                    if (_selectedTitleSubsegment == UISegmentedControlNoSegment) {
                        self.rowAnimation = UITableViewRowAnimationLeft;
                    }
                    
                    _titleSubsegments = [self titleSubsegmentsWithTitles:groups];
                    _selectedTitleSubsegment = _titleSubsegments.selectedSegmentIndex;
                } else if (_titleSubsegments) {
                    _titleSubsegments = [self titleSubsegmentsWithTitles:nil];
                    _selectedTitleSubsegment = 0;
                }
            }
        }
    }
}


#pragma mark - UITableViewDataSource conformance

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *deleteTitle = nil;
    
    if ([self targetIs:kTargetDevices]) {
        deleteTitle = NSLocalizedString(kExternalKeySignOut, kStringPrefixLabel);
    } else if ([self targetIs:kTargetRole]) {
        deleteTitle = NSLocalizedString(@"Remove", @"");
    } else {
        deleteTitle = NSLocalizedString(@"Delete", @"");
    }
    
    return deleteTitle;
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

@end
