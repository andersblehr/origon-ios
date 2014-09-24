//
//  OValuePickerViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OValuePickerViewController.h"


@interface OValuePickerViewController () <OTableViewController> {
@private
    OTableViewCell *_checkedCell;
    NSMutableArray *_pickedValues;
    BOOL _isMultiValuePicker;
    
    id<OSettings> _settings;
    NSString *_settingKey;

    id<OOrigo> _origo;
    NSString *_affiliation;
    NSString *_affiliationType;
    UIBarButtonItem *_multiRoleButtonOff;
    UIBarButtonItem *_multiRoleButtonOn;
}

@end


@implementation OValuePickerViewController

#pragma mark - Selector implementations

- (void)toggleMultiRole
{
    if ([_pickedValues count] < 2) {
        if (_isMultiValuePicker) {
            self.navigationItem.rightBarButtonItem = _multiRoleButtonOff;
        } else {
            self.navigationItem.rightBarButtonItem = _multiRoleButtonOn;
        }
        
        _isMultiValuePicker = !_isMultiValuePicker;
    }
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    self.usesPlainTableViewStyle = YES;
    
    if ([self targetIs:kTargetSetting]) {
        _settingKey = self.target;
        _settings = [OSettings settings];
        
        self.title = NSLocalizedString(_settingKey, kStringPrefixSettingTitle);
    } else {
        self.usesSectionIndexTitles = YES;
        
        if ([self targetIs:kTargetMembers]) {
            _isMultiValuePicker = YES;
        } else if ([self targetIs:kTargetAffiliation]) {
            _origo = self.state.currentOrigo;
            
            if ([@[kTargetRole, kTargetGroup] containsObject:self.target]) {
                _affiliation = nil;
            } else {
                _affiliation = self.target;
            }
            
            NSString *placeholder = nil;
            
            if ([self aspectIs:kAspectMemberRole]) {
                _affiliationType = kAffiliationTypeMemberRole;
                _pickedValues = _affiliation ? [[_origo membersWithRole:_affiliation] mutableCopy] : nil;
                placeholder = NSLocalizedString(_origo.type, kStringPrefixMemberRoleTitle);
            } else if ([self aspectIs:kAspectOrganiserRole]) {
                _affiliationType = kAffiliationTypeOrganiserRole;
                _pickedValues = _affiliation ? [[_origo organisersWithRole:_affiliation] mutableCopy] : nil;
                placeholder = NSLocalizedString(_origo.type, kStringPrefixOrganiserRoleTitle);
            } else if ([self aspectIs:kAspectParentRole]) {
                _affiliationType = kAffiliationTypeParentRole;
                _pickedValues = _affiliation ? [[_origo parentsWithRole:_affiliation] mutableCopy] : nil;
                placeholder = NSLocalizedString(@"Responsibility", @"");
            } else if ([self aspectIs:kAspectGroup]) {
                _affiliationType = kAffiliationTypeGroup;
                _pickedValues = _affiliation ? [[_origo membersOfGroup:_affiliation] mutableCopy] : nil;
                placeholder = NSLocalizedString(@"Name of group", @"");
            }
            
            [self setEditableTitle:_affiliation placeholder:placeholder];
            [self setSubtitle:[OUtil commaSeparatedListOfItems:_pickedValues conjoinLastItem:NO]];
            
            if ([self targetIs:kTargetRole]) {
                _isMultiValuePicker = ([_pickedValues count] > 1);
                
                if (!_isMultiValuePicker && ([_pickedValues count] < 2)) {
                    _multiRoleButtonOn = [UIBarButtonItem multiRoleButtonWithTarget:self on:YES];
                    _multiRoleButtonOff = [UIBarButtonItem multiRoleButtonWithTarget:self on:NO];
                    
                    [self.navigationItem addRightBarButtonItem:_multiRoleButtonOff];
                }
            } else if ([self targetIs:kTargetGroup]) {
                _isMultiValuePicker = YES;
            }
        }
    }
    
    if (self.isModal) {
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
        
        if (_isMultiValuePicker) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
            self.navigationItem.rightBarButtonItem.enabled = ([_pickedValues count] > 0);
        }
    }
    
    if (!_pickedValues) {
        _pickedValues = [NSMutableArray array];
    }
}


- (void)loadData
{
    if ([self targetIs:kTargetSetting]) {
        // TODO
    } else {
        if ([self targetIs:kTargetAffiliation]) {
            if ([self aspectIs:kAspectMemberRole]) {
                [self setData:[_origo regulars] sectionIndexLabelKey:kPropertyKeyName];
            } else if ([self aspectIs:kAspectOrganiserRole]) {
                [self setData:[_origo organisers] sectionIndexLabelKey:kPropertyKeyName];
            } else if ([self aspectIs:kAspectParentRole]) {
                [self setData:[_origo guardians] sectionIndexLabelKey:kPropertyKeyName];
            } else if ([self aspectIs:kAspectGroup]) {
                [self setData:[_origo regulars] sectionIndexLabelKey:kPropertyKeyName];
            }
        } else if ([self targetIs:kTargetMember] || [self targetIs:kTargetMembers]) {
            [self setData:self.meta sectionIndexLabelKey:kPropertyKeyName];
        }
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self targetIs:kTargetSetting]) {
        cell.checked = [[self dataAtIndexPath:indexPath] isEqual:[_settings valueForSettingKey:_settingKey]];
    } else {
        id<OMember> candidate = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = [candidate publicName];
        [OUtil setImageForMember:candidate inTableViewCell:cell];
        
        if ([_pickedValues count]) {
            cell.checked = [_pickedValues containsObject:candidate];
        }
        
        if ([self aspectIs:kAspectParentRole]) {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"(%@)", [OUtil commaSeparatedListOfItems:[candidate wardsInOrigo:_origo] conjoinLastItem:NO]];
        } else if ([self aspectIs:kAspectGroup]) {
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfItems:[[_origo membershipForMember:candidate] groups] conjoinLastItem:NO];
        } else if ([candidate isJuvenile]) {
            cell.detailTextLabel.text = [OUtil guardianInfoForMember:candidate];
        } else {
            cell.detailTextLabel.text = [OUtil associationInfoForMember:candidate];
        }
    }
    
    if (cell.checked && !_isMultiValuePicker) {
        _checkedCell = cell;
    }
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.selected = NO;
    cell.checked = _isMultiValuePicker ? !cell.checked : YES;
    
    id oldValue = nil;
    id pickedValue = [self dataAtIndexPath:indexPath];
    
    if (cell.checked) {
        if (!_isMultiValuePicker && (_checkedCell != cell)) {
            if (_checkedCell) {
                oldValue = [self dataAtIndexPath:[self.tableView indexPathForCell:_checkedCell]];
                
                _checkedCell.checked = NO;
                [_pickedValues removeAllObjects];
            }
            
            _checkedCell = cell;
        }
        
        [_pickedValues insertObject:pickedValue atIndex:0];
    } else {
        [_pickedValues removeObject:pickedValue];
    }
    
    if ([self targetIs:kTargetSetting]) {
        [_settings setValue:pickedValue forSettingKey:_settingKey];
        [self.navigationController popViewControllerAnimated:YES];
    } else if ([self targetIs:kTargetMember]) {
        self.returnData = pickedValue;
        [self.dismisser dismissModalViewController:self];
    } else if ([self targetIs:kTargetAffiliation]) {
        if (cell.checked) {
            [[_origo membershipForMember:pickedValue] addAffiliation:_affiliation ofType:_affiliationType];
            
            if (!_isMultiValuePicker) {
                [[_origo membershipForMember:oldValue] removeAffiliation:_affiliation ofType:_affiliationType];
            }
        } else {
            [[_origo membershipForMember:pickedValue] removeAffiliation:_affiliation ofType:_affiliationType];
        }
        
        [self setSubtitle:[OUtil commaSeparatedListOfItems:_pickedValues conjoinLastItem:NO]];
    }
    
    if (_isMultiValuePicker) {
        if (self.isModal) {
            if ([_pickedValues count]) {
                if (self.navigationItem.rightBarButtonItem == _multiRoleButtonOn) {
                    self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
                }
            }
            
            self.navigationItem.rightBarButtonItem.enabled = ([_pickedValues count] > 0);
        }
    } else {
        if (self.isModal) {
            self.returnData = _pickedValues;
            [self.dismisser dismissModalViewController:self];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}


- (void)viewWillBeDismissed
{
    if (self.isModal && _isMultiValuePicker) {
        if (self.didCancel) {
            if ([self targetIs:kTargetRole]) {
                NSString *roleType = [self.state roleTypeFromAspect];
                NSArray *roleHolders = [_origo holdersOfRole:_affiliation ofType:roleType];
                
                for (id<OMember> roleHolder in roleHolders) {
                    [[_origo membershipForMember:roleHolder] removeAffiliation:_affiliation ofType:_affiliationType];
                }
            } else if ([self targetIs:kTargetGroup]) {
                for (id<OMember> groupMember in [_origo membersOfGroup:_affiliation]) {
                    [[_origo membershipForMember:groupMember] removeAffiliation:_affiliation ofType:kAffiliationTypeGroup];
                }
            }
        } else {
            self.returnData = _pickedValues;
        }
    }
}


- (void)maySetViewTitle:(NSString *)newTitle
{
    if (_affiliation && newTitle) {
        NSString *roleType = [self.state roleTypeFromAspect];
        
        for (id<OMember> roleHolder in [_origo holdersOfRole:_affiliation ofType:roleType]) {
            id<OMembership> membership = [_origo membershipForMember:roleHolder];
            
            [membership addAffiliation:newTitle ofType:_affiliationType];
            [membership removeAffiliation:_affiliation ofType:_affiliationType];
        }
    }
    
    if (newTitle) {
        _affiliation = newTitle;
    }
}

@end
