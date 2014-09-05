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
    NSInteger _selectedSegment;
    NSString *_addedRole;
}

@end


@implementation OValueListViewController

#pragma mark - Auxiliary methods

- (void)inferSelectedSegment
{
    if ((_titleSegments.numberOfSegments == 3) || [_origo isJuvenile]) {
        _selectedSegment = _titleSegments.selectedSegmentIndex;
    } else {
        _selectedSegment = _titleSegments.selectedSegmentIndex + 1;
    }
}


#pragma mark - Selector implementations

- (void)performAddAction
{
    if (_selectedSegment == kSegmentParents) {
        [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:@{kTargetRole: kAspectParentRole} meta:_origo];
    } else if (_selectedSegment == kSegmentOrganisers) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagAdd];
        [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddOrganiserButton) tag:kButtonTagAddOrganiser];
        [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAddOrganiserRoleButton) tag:kButtonTagAddOrganiserRole];
        
        [actionSheet show];
    } else if (_selectedSegment == kSegmentMembers) {
        [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:@{kTargetRole: kAspectMemberRole} meta:_origo];
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
    
    [self reloadSectionWithKey:kSectionKeyValues withRowAnimation:rowAnimation];
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.didResurface) {
        [self reloadSectionWithKey:kSectionKeyValues];
    }
}


#pragma mark - UIViewController overrides

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    
    [segue.destinationViewController setMeta:_origo];
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    if ([self targetIs:kTargetSettings]) {
        self.title = NSLocalizedString(@"Settings", @"");
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
    } else if ([self targetIs:kTargetDevices]) {
        self.title = NSLocalizedString(self.target, kStringPrefixSettingListLabel);
        self.usesPlainTableViewStyle = YES;
    } else if ([self targetIs:kTargetRoles]) {
        _origo = self.meta;
        
        NSMutableArray *titleSegments = [NSMutableArray array];
        
        self.title = NSLocalizedString(@"Roles", @"");
        
        if ([_origo isJuvenile] && ![_origo isOfType:kOrigoTypeFriends]) {
            [titleSegments addObject:[[OLanguage nouns][_parent_][pluralIndefinite] stringByCapitalisingFirstLetter]];
        }
        
        if ([_origo isOrganised]) {
            [titleSegments addObject:NSLocalizedString(_origo.type, kStringPrefixOrganisersTitle)];
        }
        
        if ([_origo isOfType:@[kOrigoTypeTeam, kOrigoTypeSchoolClass, kOrigoTypeStudyGroup]]) {
            [titleSegments addObject:NSLocalizedString(_origo.type, kStringPrefixMembersTitle)];
        }
        
        if ([titleSegments count] > 1) {
            _titleSegments = [self setTitleSegments:titleSegments];
            
            [self inferSelectedSegment];
        } else {
            _selectedSegment = kSegmentMembers;
        }
        
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
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
    } else if ([self targetIs:kTargetRoles]) {
        if (_selectedSegment == kSegmentParents) {
            [self setData:[_origo parentRoles] forSectionWithKey:kSectionKeyValues];
        } else if (_selectedSegment == kSegmentOrganisers) {
            [self setData:[_origo organiserRoles] forSectionWithKey:kSectionKeyValues];
        } else if (_selectedSegment == kSegmentMembers) {
            [self setData:[_origo memberRoles] forSectionWithKey:kSectionKeyValues];
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
    }
}


- (id)destinationViewControllerTargetForIndexPath:(NSIndexPath *)indexPath
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
    }
    
    return target;
}


- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey
{
    return NO;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return NO;
}


- (UITableViewCellStyle)listCellStyleForSectionWithKey:(NSInteger)sectionKey
{
    UITableViewCellStyle style = UITableViewCellStyleValue1;
    
    if ([self targetIs:kTargetDevices]) {
        style = UITableViewCellStyleSubtitle;
    }
    
    return style;
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
    } else if ([self targetIs:kTargetRoles]) {
        canDelete = YES;
    }
    
    return canDelete;
}


- (void)willDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self targetIs:kTargetDevices]) {
        [[self dataAtIndexPath:indexPath] expire];
    } else if ([self targetIs:kTargetRoles]) {
        NSString *role = [self dataAtIndexPath:indexPath];

        if (_selectedSegment == kSegmentParents) {
            for (id<OMember> roleHolder in [_origo parentsWithRole:role]) {
                [[_origo membershipForMember:roleHolder] removeRole:role ofType:kRoleTypeParentRole];
            }
        } else if (_selectedSegment == kSegmentOrganisers) {
            for (id<OMember> roleHolder in [_origo organisersWithRole:role]) {
                [[_origo membershipForMember:roleHolder] removeRole:role ofType:kRoleTypeOrganiserRole];
            }
        } else if (_selectedSegment == kSegmentMembers) {
            for (id<OMember> roleHolder in [_origo membersWithRole:role]) {
                [[_origo membershipForMember:roleHolder] removeRole:role ofType:kRoleTypeMemberRole];
            }
        }
    }
}


- (void)willDismissModalViewController:(OTableViewController *)viewController
{
    if (!viewController.didCancel) {
        if ([viewController.identifier isEqualToString:kIdentifierValuePicker]) {
            if ([viewController targetIs:_addedRole]) {
                id<OMembership> membership = [_origo membershipForMember:viewController.returnData];
                [membership addRole:_addedRole ofType:kRoleTypeMemberRole];
                
                [[OMeta m].replicator replicate];
                [self reloadSectionWithKey:kSectionKeyValues];
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
                    [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:@{kTargetRole: kAspectOrganiserRole} meta:_origo];
                } else if (buttonTag == kButtonTagAddOrganiser) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetOrganiser meta:_origo];
                }
            }
            
            break;
            
        default:
            break;
    }
}

@end
