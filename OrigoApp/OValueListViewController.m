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
static NSInteger const kSectionKeySignOut = 2;

static NSInteger const kSegmentParents = 0;
static NSInteger const kSegmentOrganisers = 1;
static NSInteger const kSegmentMembers = 2;

static NSInteger const kActionSheetTagAdd = 0;
static NSInteger const kButtonTagAddOrganiser = 0;
static NSInteger const kButtonTagAddOrganiserRole = 1;


@interface OValueListViewController () <OTableViewController, UIActionSheetDelegate> {
    id<OOrigo> _origo;

    UISegmentedControl *_titleSegments;
    NSMutableArray *_segmentMappings;
    NSInteger _selectedSegment;
}

@end


@implementation OValueListViewController

#pragma mark - Auxiliary methods

- (void)setTitleSegments
{
    _segmentMappings = [NSMutableArray array];
    NSMutableArray *titleSegments = [NSMutableArray array];
    
    if ([_origo isJuvenile] && ![_origo isOfType:kOrigoTypeGeneral]) {
        [_segmentMappings addObject:@(kSegmentParents)];
        [titleSegments addObject:[[OLanguage nouns][_parent_][pluralIndefinite] stringByCapitalisingFirstLetter]];
    }
    
    if ([_origo isOrganised]) {
        [_segmentMappings addObject:@(kSegmentOrganisers)];
        [titleSegments addObject:NSLocalizedString(_origo.type, kStringPrefixOrganisersTitle)];
    }
    
    if (![_origo isOfType:kOrigoTypePreschoolClass]) {
        [_segmentMappings addObject:@(kSegmentMembers)];
        [titleSegments addObject:NSLocalizedString(_origo.type, kStringPrefixMembersTitle)];
    }
    
    if ([titleSegments count] > 1) {
        _titleSegments = [self setTitleSegments:titleSegments];
        
        [self inferSelectedSegment];
    } else {
        _selectedSegment = kSegmentMembers;
    }
}


- (void)inferSelectedSegment
{
    if ([self targetIs:kTargetRoles]) {
        _selectedSegment = [_segmentMappings[_titleSegments.selectedSegmentIndex] integerValue];
    } else {
        _selectedSegment = _titleSegments.selectedSegmentIndex;
    }
}


#pragma mark - Selector implementations

- (void)performAddAction
{
    if ([self targetIs:kTargetRoles]) {
        if (_selectedSegment == kSegmentParents) {
            [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:@{kTargetRole: kAspectParentRole}];
        } else if (_selectedSegment == kSegmentOrganisers) {
            OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagAdd];
            [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddOrganiserButton) tag:kButtonTagAddOrganiser];
            [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddOrganiserRoleButton) tag:kButtonTagAddOrganiserRole];
            
            [actionSheet show];
        } else if (_selectedSegment == kSegmentMembers) {
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


- (void)didSelectTitleSegment
{
    NSInteger previousSegment = _selectedSegment;
    
    [self inferSelectedSegment];
    
    UITableViewRowAnimation rowAnimation = UITableViewRowAnimationNone;
    
    if ([self numberOfRowsInSectionWithKey:kSectionKeyValues]) {
        if (_selectedSegment > previousSegment) {
            rowAnimation = UITableViewRowAnimationLeft;
        } else {
            rowAnimation = UITableViewRowAnimationRight;
        }
    } else {
        if (_selectedSegment > previousSegment) {
            rowAnimation = UITableViewRowAnimationRight;
        } else {
            rowAnimation = UITableViewRowAnimationLeft;
        }
    }
    
    [self reloadSectionWithKey:kSectionKeyValues rowAnimation:rowAnimation];
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
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
    } else if ([self targetIs:kTargetDevices]) {
        self.title = NSLocalizedString(self.target, kStringPrefixSettingListLabel);
        self.usesPlainTableViewStyle = YES;
    } else if ([self targetIs:kTargetRole]) {
        self.title = self.target;
    } else if ([self targetIs:kTargetRoles]) {
        self.title = NSLocalizedString(@"Responsibilities", @"");
        
        [self setTitleSegments];
        [self inferSelectedSegment];
        
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
    } else if ([self targetIs:kTargetGroups]) {
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
        
        if ([self aspectIs:kAspectEditable]) {
            if ([[_origo groups] count]) {
                self.title = NSLocalizedString(@"Edit subgroups", @"");
                self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:NSLocalizedString(@"Subgroups", @"")];
            } else {
                self.title = NSLocalizedString(@"Subgroups", @"");
            }
            
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
        } else {
            self.title = NSLocalizedString(@"Subgroups", @"");
            
            NSArray *groups = [_origo groups];
            
            if ([groups count]) {
                _titleSegments = [self setTitleSegments:groups];
                _selectedSegment = _titleSegments.selectedSegmentIndex;
            }
            
            if ([_origo userCanEdit]) {
                [self.navigationItem addRightBarButtonItem:[UIBarButtonItem editButtonWithTarget:self]];
            }
        }
    }
}


- (void)loadData
{
    if ([self targetIs:kTargetSettings]) {
        [self setData:[[OSettings settings] settingKeys] forSectionWithKey:kSectionKeyValues];
        [self setData:[[OSettings settings] settingListKeys] forSectionWithKey:kSectionKeyLists];
        [self setData:@[kCustomData] forSectionWithKey:kSectionKeySignOut];
    } else if ([self targetIs:kTargetDevices]) {
        [self setData:[[[OMeta m].user.devices allObjects] sortedArrayUsingSelector:@selector(compare:)] forSectionWithKey:kSectionKeyValues];
    } else if ([self targetIs:kTargetRole]) {
        if ([self aspectIs:kAspectOrganiserRole]) {
            [self setData:[_origo organisersWithRole:self.target] forSectionWithKey:kSectionKeyValues];
        } else if ([self aspectIs:kAspectParentRole]) {
            [self setData:[_origo parentsWithRole:self.target] forSectionWithKey:kSectionKeyValues];
        }
    } else if ([self targetIs:kTargetRoles]) {
        if (_selectedSegment == kSegmentParents) {
            [self setData:[_origo parentRoles] forSectionWithKey:kSectionKeyValues];
        } else if (_selectedSegment == kSegmentOrganisers) {
            [self setData:[_origo organiserRoles] forSectionWithKey:kSectionKeyValues];
        } else if (_selectedSegment == kSegmentMembers) {
            [self setData:[_origo memberRoles] forSectionWithKey:kSectionKeyValues];
        }
    } else if ([self targetIs:kTargetGroups]) {
        NSArray *groups = [_origo groups];
        
        if ([self aspectIs:kAspectEditable]) {
            [self setData:groups forSectionWithKey:kSectionKeyValues];
        } else {
            NSString *group = [groups count] ? groups[_selectedSegment] : [NSString string];
            
            [self setData:[_origo membersOfGroup:group] forSectionWithKey:kSectionKeyValues];
        }
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if ([self targetIs:kTargetSettings]) {
        NSString *key = [self dataAtIndexPath:indexPath];
        
        if (sectionKey == kSectionKeyValues) {
            cell.textLabel.text = NSLocalizedString(key, kStringPrefixSettingLabel);
            cell.detailTextLabel.text = [[OSettings settings] displayValueForSettingKey:key];
            cell.destinationId = kIdentifierValuePicker;
        } else if (sectionKey == kSectionKeyLists) {
            cell.textLabel.text = NSLocalizedString(key, kStringPrefixSettingListLabel);
            cell.destinationId = kIdentifierValueList;
        } else if (sectionKey == kSectionKeySignOut) {
            cell.textLabel.textColor = [UIColor redColor];
            cell.textLabel.text = [NSLocalizedString(@"Log out", @"") stringByAppendingString:[OMeta m].user.name separator:kSeparatorSpace];
        }
    } else if ([self targetIs:kTargetDevices]) {
        ODevice *device = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = device.name;
        cell.selectable = NO;
        
        if ([device.entityId isEqualToString:[OMeta m].deviceId]) {
            cell.detailTextLabel.text = NSLocalizedString(@"This device", @"");
            cell.detailTextLabel.textColor = [UIColor windowTintColour];
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
        [cell loadMember:[self dataAtIndexPath:indexPath] inOrigo:_origo includeRelations:YES];
        cell.destinationId = kIdentifierMember;
        cell.destinationMeta = self.target;
    } else if ([self targetIs:kTargetRoles]) {
        NSString *role = [self dataAtIndexPath:indexPath];
        NSArray *roleHolders = nil;
        
        if (_selectedSegment == kSegmentParents) {
            roleHolders = [_origo parentsWithRole:role];
        } else if (_selectedSegment == kSegmentOrganisers) {
            roleHolders = [_origo organisersWithRole:role];
        } else if (_selectedSegment == kSegmentMembers) {
            roleHolders = [_origo membersWithRole:role];
        }
        
        cell.textLabel.text = role;
        cell.detailTextLabel.text = [OUtil commaSeparatedListOfItems:roleHolders conjoinLastItem:NO];
        cell.destinationId = kIdentifierValuePicker;
    } else if ([self targetIs:kTargetGroups]) {
        if ([self aspectIs:kAspectEditable]) {
            NSString *group = [self dataAtIndexPath:indexPath];
            
            cell.textLabel.text = group;
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfItems:[_origo membersOfGroup:group] conjoinLastItem:NO];
            cell.destinationId = kIdentifierValuePicker;
        } else {
            [cell loadMember:[self dataAtIndexPath:indexPath] inOrigo:_origo includeRelations:YES];
            cell.selectable = NO;
        }
    }
}


- (id)destinationTargetForIndexPath:(NSIndexPath *)indexPath
{
    id target = [self dataAtIndexPath:indexPath];
    
    if ([self targetIs:kTargetRoles]) {
        if (_selectedSegment == kSegmentParents) {
            target = @{target: kAspectParentRole};
        } else if (_selectedSegment == kSegmentOrganisers) {
            target = @{target: kAspectOrganiserRole};
        } else if (_selectedSegment == kSegmentMembers) {
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
    
    if ([self targetIs:kTargetDevices] || [self targetIs:kTargetRole]) {
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


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if ([self targetIs:kTargetSettings]) {
        if (sectionKey == kSectionKeySignOut) {
            [[OMeta m] signOut];
        } else {
            // TODO;
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
        canDelete = canDelete || [self targetIs:kTargetGroups];
    }
    
    return canDelete;
}


- (void)willDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self targetIs:kTargetDevices]) {
        [[self dataAtIndexPath:indexPath] expire];
    } else if ([self targetIs:kTargetRole]) {
        id<OMembership> membership = [_origo membershipForMember:[self dataAtIndexPath:indexPath]];
        [membership removeAffiliation:self.target ofType:[self.state roleTypeFromAspect]];
    } else if ([self targetIs:kTargetRoles]) {
        NSString *role = [self dataAtIndexPath:indexPath];

        if (_selectedSegment == kSegmentParents) {
            for (id<OMember> roleHolder in [_origo parentsWithRole:role]) {
                [[_origo membershipForMember:roleHolder] removeAffiliation:role ofType:kAffiliationTypeParentRole];
            }
        } else if (_selectedSegment == kSegmentOrganisers) {
            for (id<OMember> roleHolder in [_origo organisersWithRole:role]) {
                [[_origo membershipForMember:roleHolder] removeAffiliation:role ofType:kAffiliationTypeOrganiserRole];
            }
        } else if (_selectedSegment == kSegmentMembers) {
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
                    if (_selectedSegment == UISegmentedControlNoSegment) {
                        self.rowAnimation = UITableViewRowAnimationLeft;
                    }
                    
                    _titleSegments = [self setTitleSegments:groups];
                    _selectedSegment = _titleSegments.selectedSegmentIndex;
                } else if (_titleSegments) {
                    _titleSegments = [self setTitleSegments:nil];
                    _selectedSegment = 0;
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
        deleteTitle = NSLocalizedString(@"Not in use", @"");
    } else if ([self targetIs:kTargetRole]) {
        deleteTitle = NSLocalizedString(@"Remove", @"");
    } else {
        deleteTitle = NSLocalizedString(kButtonKeyDeleteRow, kStringPrefixDefault);
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
