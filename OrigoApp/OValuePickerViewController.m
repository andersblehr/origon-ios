//
//  OValuePickerViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OValuePickerViewController.h"

static NSInteger const kSectionKeyValues = 0;


@interface OValuePickerViewController () <OTableViewController> {
@private
    OTableViewCell *_checkedCell;
    NSMutableArray *_pickedValues;
    BOOL _isMultiValuePicker;
    
    id<OSettings> _settings;
    NSString *_settingKey;
    NSMutableDictionary *_valuesByKey;
    
    id<OOrigo> _origo;
    NSString *_affiliation;
    NSString *_affiliationType;
    UIBarButtonItem *_multiRoleButtonOff;
    UIBarButtonItem *_multiRoleButtonOn;
    
    id<OMember> _ward;
    NSString *_parentGender;
    NSArray *_parentCandidates;
}

@end


@implementation OValuePickerViewController

#pragma mark - Auxiliary methods

- (void)cell:(OTableViewCell *)cell loadGroupDetailsForMember:(id<OMember>)member
{
    NSArray *groups = [[_origo membershipForMember:member] groups];
    
    cell.detailTextLabel.text = [OUtil commaSeparatedListOfStrings:groups conjoin:NO];
    
    if ([groups containsObject:_affiliation]) {
        cell.detailTextLabel.textColor = [UIColor textColour];
    } else {
        cell.detailTextLabel.textColor = [UIColor tonedDownTextColour];
    }
}


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
    } else if ([self targetIs:kTargetParent]) {
        _ward = self.meta;
        _parentGender = [self.target isEqualToString:kPropertyKeyMotherId] ? kGenderFemale : kGenderMale;
        _parentCandidates = [_ward parentCandidatesWithGender:_parentGender];
        
        if (![_parentCandidates count]) {
            self.usesPlainTableViewStyle = NO;
        }
        
        self.title = NSLocalizedString(self.target, kStringPrefixLabel);
    } else if ([self targetIs:kTargetOrigoType]) {
        _origo = self.state.currentOrigo;
        _valuesByKey = [NSMutableDictionary dictionary];

        self.title = NSLocalizedString(@"Type", @"");
    } else if ([self targetIs:kTargetGender]) {
        _valuesByKey = [NSMutableDictionary dictionary];
        
        self.title = NSLocalizedString(kPropertyKeyGender, kStringPrefixLabel);
    } else {
        self.usesSectionIndexTitles = YES;
        
        if ([self targetIs:kTargetMembers]) {
            _origo = self.state.currentOrigo;
            _isMultiValuePicker = YES;
            
            self.title = NSLocalizedString(_origo.type, kStringPrefixNewMembersTitle);
        } else if ([self targetIs:kTargetAffiliation]) {
            _origo = self.state.currentOrigo;
            
            if ([@[kTargetRole, kTargetGroup] containsObject:self.target]) {
                _affiliation = nil;
            } else {
                _affiliation = self.target;
            }
            
            NSString *placeholder = nil;
            
            if ([self aspectIs:kAspectParentRole]) {
                _affiliationType = kAffiliationTypeParentRole;
                _pickedValues = _affiliation ? [[_origo parentsWithRole:_affiliation] mutableCopy] : nil;
                placeholder = NSLocalizedString(@"Responsibility", @"");
            } else if ([self aspectIs:kAspectOrganiserRole]) {
                _affiliationType = kAffiliationTypeOrganiserRole;
                _pickedValues = _affiliation ? [[_origo organisersWithRole:_affiliation] mutableCopy] : nil;
                placeholder = NSLocalizedString(_origo.type, kStringPrefixOrganiserRoleTitle);
            } else if ([self aspectIs:kAspectMemberRole]) {
                _affiliationType = kAffiliationTypeMemberRole;
                _pickedValues = _affiliation ? [[_origo membersWithRole:_affiliation] mutableCopy] : nil;
                placeholder = NSLocalizedString(_origo.type, kStringPrefixMemberRoleTitle);
            } else if ([self aspectIs:kAspectGroup]) {
                _affiliationType = kAffiliationTypeGroup;
                _pickedValues = _affiliation ? [[_origo membersOfGroup:_affiliation] mutableCopy] : nil;
                placeholder = NSLocalizedString(@"Group name", @"");
            } else if ([self aspectIs:kAspectAdmin]) {
                self.title = self.target;
                _pickedValues = [[_origo admins] mutableCopy];
            }
            
            if (!self.title) {
                [self editableTitle:_affiliation withPlaceholder:placeholder];
            }
            
            [self setSubtitle:[OUtil commaSeparatedListOfMembers:_pickedValues inOrigo:_origo conjoin:NO]];
            
            if ([self targetIs:kTargetRole]) {
                _isMultiValuePicker = [_pickedValues count] > 1;
                
                if (!_isMultiValuePicker) {
                    _multiRoleButtonOn = [UIBarButtonItem multiRoleButtonWithTarget:self on:YES];
                    _multiRoleButtonOff = [UIBarButtonItem multiRoleButtonWithTarget:self on:NO];
                    
                    [self.navigationItem addRightBarButtonItem:_multiRoleButtonOff];
                }
            } else if ([self targetIs:@[kTargetGroup, kTargetAdmin]]) {
                _isMultiValuePicker = YES;
            }
        }
    }
    
    if (self.isModal) {
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
        
        if (_isMultiValuePicker) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
            self.navigationItem.rightBarButtonItem.enabled = [_pickedValues count] > 0;
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
    } else if ([self targetIs:kTargetParent]) {
        if ([_parentCandidates count]) {
            [self setData:_parentCandidates forSectionWithKey:kSectionKeyValues];
        }
    } else if ([self targetIs:kTargetOrigoType]) {
        for (NSString *origoType in [OUtil eligibleOrigoTypesForOrigo:_origo]) {
            _valuesByKey[origoType] = NSLocalizedString(origoType, kStringPrefixOrigoTitle);
        }
        
        [self setData:[[_valuesByKey allValues] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] forSectionWithKey:kSectionKeyValues];
    } else if ([self targetIs:kTargetGender]) {
        BOOL isJuvenile = [self.state.currentMember isJuvenile];
        
        for (NSString *gender in @[kGenderFemale, kGenderMale]) {
            _valuesByKey[gender] = [OLanguage genderTermForGender:gender isJuvenile:isJuvenile];
        }
        
        [self setData:@[_valuesByKey[kGenderMale], _valuesByKey[kGenderFemale]] forSectionWithKey:kSectionKeyValues];
    } else if ([self targetIs:kTargetAffiliation]) {
        if ([self aspectIs:kAspectMemberRole]) {
            [self setData:[_origo regulars] sectionIndexLabelKey:kPropertyKeyName];
        } else if ([self aspectIs:kAspectOrganiserRole]) {
            [self setData:[_origo organisers] sectionIndexLabelKey:kPropertyKeyName];
        } else if ([self aspectIs:kAspectParentRole]) {
            [self setData:[_origo guardians] sectionIndexLabelKey:kPropertyKeyName];
        } else if ([self aspectIs:kAspectGroup]) {
            [self setData:[_origo regulars] sectionIndexLabelKey:kPropertyKeyName];
        } else if ([self aspectIs:kAspectAdmin]) {
            [self setData:[_origo adminCandidates] sectionIndexLabelKey:kPropertyKeyName];
        }
    } else if ([self targetIs:@[kTargetMember, kTargetMembers]]) {
        [self setData:self.meta sectionIndexLabelKey:kPropertyKeyName];
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self targetIs:kTargetSetting]) {
        cell.checked = [[self dataAtIndexPath:indexPath] isEqual:[_settings valueForSettingKey:_settingKey]];
    } else if ([self targetIs:kTargetParent]) {
        id<OMember> parentCandidate = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = parentCandidate.name;
        
        if ([_parentGender isEqualToString:kGenderFemale]) {
            cell.checked = [parentCandidate.entityId isEqualToString:_ward.motherId];
        } else {
            cell.checked = [parentCandidate.entityId isEqualToString:_ward.fatherId];
        }
    } else if ([self targetIs:kTargetOrigoType]) {
        NSString *origoTitle = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = origoTitle;
        
        if ([origoTitle isEqualToString:NSLocalizedString(_origo.type, kStringPrefixOrigoTitle)]) {
            cell.checked = YES;
        }
    } else if ([self targetIs:kTargetGender]) {
        NSString *gender = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = [gender stringByCapitalisingFirstLetter];
        cell.checked = [gender isEqualToString:[OLanguage genderTermForGender:self.state.currentMember.gender isJuvenile:[self.state.currentMember isJuvenile]]];
    } else if ([self aspectIs:kAspectAdmin]) {
        id<OMember> candidate = [self dataAtIndexPath:indexPath];
        
        [cell loadMember:candidate inOrigo:_origo excludeRoles:NO excludeRelations:NO];
        cell.checked = [_pickedValues containsObject:candidate];
        
        if (![candidate isActive]) {
            cell.textLabel.textColor = [UIColor valueTextColour];
            cell.detailTextLabel.textColor = [UIColor tonedDownTextColour];
            cell.selectable = NO;
        }
    } else {
        id<OMember> candidate = [self dataAtIndexPath:indexPath];
        
        if ([self targetIs:kTargetMembers]) {
            [cell loadMember:candidate inOrigo:nil excludeRoles:YES excludeRelations:YES];
        } else {
            [cell loadMember:candidate inOrigo:_origo excludeRoles:YES excludeRelations:YES];
            
            if ([self targetIs:kTargetGroup]) {
                [self cell:cell loadGroupDetailsForMember:candidate];
            }
        }
        
        if ([_pickedValues count]) {
            cell.checked = [_pickedValues containsObject:candidate];
        }
    }
    
    if (cell.checked && !_isMultiValuePicker) {
        _checkedCell = cell;
    }
}


- (NSString *)emptyTableViewFooterText
{
    NSString *footerText = nil;
    
    if ([self targetIs:kTargetParent]) {
        NSString *hisHerParent = [OLanguage labelForParentWithGender:_parentGender relativeToOffspringWithGender:_ward.gender];
        
        footerText = [NSString stringWithFormat:NSLocalizedString(@"%@ and %@ must be listed at the same address. You may register a separate address for them if you do not live with %@.", @""), [_ward givenName], hisHerParent, hisHerParent];
    }
    
    return footerText;
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.selected = NO;
    cell.checked = _isMultiValuePicker || [self targetIs:kTargetParent] ? !cell.checked : YES;
    
    id oldValue = nil;
    id pickedValue = [self dataAtIndexPath:indexPath];
    
    if (cell.checked) {
        if (!_isMultiValuePicker && _checkedCell != cell) {
            if (_checkedCell) {
                oldValue = [self dataAtIndexPath:[self.tableView indexPathForCell:_checkedCell]];
                
                _checkedCell.checked = NO;
                [_pickedValues removeAllObjects];
            }
            
            _checkedCell = cell;
        }
        
        [_pickedValues insertObject:pickedValue atIndex:0];
    } else {
        if ([_pickedValues count] > 1 || [self targetIs:kTargetParent]) {
            [_pickedValues removeObject:pickedValue];
        } else {
            cell.checked = YES;
        }
    }
    
    if ([self targetIs:kTargetSetting]) {
        [_settings setValue:pickedValue forSettingKey:_settingKey];
    } else if ([self targetIs:kTargetParent]) {
        if ([_parentGender isEqualToString:kGenderFemale]) {
            _ward.motherId = cell.checked ? [pickedValue entityId] : nil;
        } else {
            _ward.fatherId = cell.checked ? [pickedValue entityId] : nil;
        }
    } else if ([self targetIs:kTargetOrigoType]) {
        [_origo convertToType:[_valuesByKey allKeysForObject:pickedValue][0]];
    } else if ([self targetIs:kTargetGender]) {
        self.state.currentMember.gender = [_valuesByKey allKeysForObject:pickedValue][0];
    } else if ([self targetIs:kTargetMember]) {
        self.returnData = pickedValue;
    } else if ([self targetIs:kTargetMembers]) {
        self.subtitle = [OUtil commaSeparatedListOfMembers:_pickedValues inOrigo:_origo conjoin:NO];
        self.subtitleColour = [UIColor textColour];
        
        if (self.isModal) {
            self.returnData = _pickedValues;
        }
    } else if ([self aspectIs:kAspectAdmin]) {
        [_origo membershipForMember:pickedValue].isAdmin = @(cell.checked);
        [self setSubtitle:[OUtil commaSeparatedListOfMembers:_pickedValues conjoin:NO subjective:NO]];
    } else if ([self targetIs:kTargetAffiliation]) {
        if (cell.checked) {
            [[_origo membershipForMember:pickedValue] addAffiliation:_affiliation ofType:_affiliationType];
            
            if (!_isMultiValuePicker) {
                [[_origo membershipForMember:oldValue] removeAffiliation:_affiliation ofType:_affiliationType];
            }
        } else {
            [[_origo membershipForMember:pickedValue] removeAffiliation:_affiliation ofType:_affiliationType];
        }
        
        [self setSubtitle:[OUtil commaSeparatedListOfMembers:_pickedValues inOrigo:_origo conjoin:NO]];
        
        if ([self targetIs:kTargetGroup]) {
            [self cell:cell loadGroupDetailsForMember:pickedValue];
        }
        
        if (self.isModal && _isMultiValuePicker && [_pickedValues count]) {
            if (self.navigationItem.rightBarButtonItem == _multiRoleButtonOn) {
                self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
            }
        }
    }
    
    if (self.isModal) {
        if (_isMultiValuePicker) {
            self.navigationItem.rightBarButtonItem.enabled = [_pickedValues count] > 0;
        } else {
            [self.dismisser dismissModalViewController:self];
        }
    } else if (!_isMultiValuePicker && (![self targetIs:kTargetParent] || cell.checked)) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (void)viewWillBeDismissed
{
    if (self.isModal && _isMultiValuePicker && self.didCancel) {
        if ([self targetIs:@[kTargetRole, kTargetGroup]]) {
            NSString *affiliationType = [self.state affiliationTypeFromAspect];
            NSArray *holders = [_origo holdersOfAffiliation:_affiliation ofType:affiliationType];
            
            for (id<OMember> holder in holders) {
                [[_origo membershipForMember:holder] removeAffiliation:_affiliation ofType:_affiliationType];
            }
        }
    }
}


- (BOOL)shouldFinishEditingViewTitleField:(UITextField *)viewTitleField
{
    BOOL shouldFinishEditing = YES;
    
    if ([self targetIs:kTargetGroup] && ![viewTitleField.text isEqualToString:_affiliation]) {
        shouldFinishEditing = ![[_origo groups] containsObject:viewTitleField.text];
    }
    
    return shouldFinishEditing;
}


- (void)didFinishEditingViewTitleField:(UITextField *)viewTitleField
{
    NSString *oldAffiliation = _affiliation;
    _affiliation = viewTitleField.text;
    
    if (oldAffiliation && ![_affiliation isEqualToString:oldAffiliation]) {
        NSArray *holders = [_origo holdersOfAffiliation:oldAffiliation ofType:_affiliationType];
        
        for (id<OMember> holder in holders) {
            id<OMembership> membership = [_origo membershipForMember:holder];
            
            [membership addAffiliation:_affiliation ofType:_affiliationType];
            [membership removeAffiliation:oldAffiliation ofType:_affiliationType];
        }
        
        if ([self targetIs:kTargetGroup]) {
            [self reloadSections];
        }
    }
}

@end
