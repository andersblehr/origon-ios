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
    BOOL _isNoValuePicker;
    
    NSString *_settingKey;
    NSMutableDictionary *_valuesByKey;
    
    id<OOrigo> _origo;
    NSString *_affiliation;
    NSString *_affiliationType;
    
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


- (NSArray *)eligibleOrigoTypesForOrigo:(id<OOrigo>)origo
{
    NSArray *eligibleOrigoTypes = nil;
    
    if ([origo isOfType:kOrigoTypePrivate]) {
        eligibleOrigoTypes = @[kOrigoTypePrivate, kOrigoTypeStandard];
    } else if ([[OMeta m].user isJuvenile]) {
        eligibleOrigoTypes = @[origo.type];
    } else {
        if ([origo isOfType:kOrigoTypeStandard]) {
            if ([origo isJuvenile]) {
                eligibleOrigoTypes = @[kOrigoTypeStandard, kOrigoTypePreschoolClass, kOrigoTypeSchoolClass, kOrigoTypeTeam, kOrigoTypeAlumni];
            } else {
                eligibleOrigoTypes = @[kOrigoTypeStandard, kOrigoTypeStudyGroup, kOrigoTypeTeam, kOrigoTypeAlumni];
            }
        } else if ([origo isOfType:kOrigoTypeAlumni]) {
            eligibleOrigoTypes = @[kOrigoTypeStandard, kOrigoTypeAlumni];
        } else {
            eligibleOrigoTypes = @[origo.type, kOrigoTypeStandard, kOrigoTypeAlumni];
        }
    }
    
    return eligibleOrigoTypes;
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    self.usesPlainTableViewStyle = YES;
    
    if ([self targetIs:kTargetSetting]) {
        _settingKey = self.target;
        
        self.title = NSLocalizedString(_settingKey, kStringPrefixSettingTitle);
    } else if ([self targetIs:kTargetParent]) {
        _isNoValuePicker = YES;
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
        
        _origo = self.state.currentOrigo;
        _isMultiValuePicker = YES;
        _isNoValuePicker = YES;
        
        if ([self targetIs:kTargetMembers]) {
            if ([_origo isCommunity]) {
                self.title = NSLocalizedString(@"Households", @"");
            } else {
                self.title = NSLocalizedString(@"Listed elsewhere", @"");
            }
        } else if ([self targetIs:kTargetAffiliation]) {
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
                placeholder = NSLocalizedString(@"Responsibility", @"");
            } else if ([self aspectIs:kAspectGroup]) {
                _affiliationType = kAffiliationTypeGroup;
                _pickedValues = _affiliation ? [[_origo membersOfGroup:_affiliation] mutableCopy] : nil;
                placeholder = NSLocalizedString(@"Group name", @"");
            } else if ([self targetIs:kTargetAdmins]) {
                self.title = NSLocalizedString(kLabelKeyAdmins, kStringPrefixLabel);
                _pickedValues = [[_origo admins] mutableCopy];
            }
            
            if (!self.title) {
                [self setEditableTitle:_affiliation placeholder:placeholder];
            }
            
            [self setSubtitle:[OUtil commaSeparatedListOfMembers:_pickedValues inOrigo:_origo subjective:[self aspectIs:kAspectGroup]]];
        }
    }
    
    if (self.isModal) {
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
        
        if (_isMultiValuePicker) {
            if ([self targetIs:kTargetMembers]) {
                self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTitle:NSLocalizedString(@"Add", @"") target:self];
            } else {
                self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
            }
            
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
        for (NSString *origoType in [self eligibleOrigoTypesForOrigo:_origo]) {
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
        } else if ([self targetIs:kTargetAdmins]) {
            [self setData:[_origo adminCandidates] sectionIndexLabelKey:kPropertyKeyName];
        }
    } else if ([self targetIs:@[kTargetMember, kTargetMembers]]) {
        [self setData:self.meta sectionIndexLabelKey:kPropertyKeyName];
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self targetIs:kTargetSetting]) {
        cell.checked = [[self dataAtIndexPath:indexPath] isEqual:[OUtil keyValueString:[OMeta m].settings valueForKey:_settingKey]];
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
    } else if ([self targetIs:kTargetAdmins]) {
        id<OMember> candidate = [self dataAtIndexPath:indexPath];
        id<OMembership> membership = [_origo membershipForMember:candidate];
        
        [cell loadMember:candidate inOrigo:_origo excludeRoles:NO excludeRelations:NO];
        cell.checked = [_pickedValues containsObject:candidate];
        
        if ([candidate isActive]) {
            BOOL isActive = NO;
            
            if ([membership isAssociate]) {
                for (id<OMember> ward in [candidate wardsInOrigo:_origo]) {
                    isActive = isActive || [[_origo membershipForMember:ward] isActive];
                }
            } else {
                isActive = [membership isActive];
            }
            
            if (!isActive) {
                cell.textLabel.text = [cell.textLabel.text stringByAppendingFormat:@" (%@)", NSLocalizedString(@"inactive", @"")];
                cell.textLabel.textColor = [UIColor valueTextColour];
                cell.selectable = NO;
            }
        } else {
            cell.textLabel.textColor = [UIColor tonedDownTextColour];
            cell.selectable = NO;
        }
    } else if ([self targetIs:kTargetMembers]) {
        if ([_origo isCommunity]) {
            id<OMember> candidate = [self dataAtIndexPath:indexPath];
            id<OOrigo> primaryResidence = [candidate primaryResidence];
            NSArray *elders = [primaryResidence elders];
            
            cell.textLabel.text = [OUtil labelForElders:elders conjoin:YES];
            cell.detailTextLabel.text = [primaryResidence shortAddress];
            
            if ([elders count] == 1) {
                [cell loadImageForMember:elders[0]];
            } else {
                [cell loadImageForMembers:elders];
            }
            
            if ([primaryResidence hasAddress]) {
                cell.detailTextLabel.textColor = [UIColor tonedDownTextColour];
            } else {
                cell.textLabel.textColor = [UIColor tonedDownTextColour];
                cell.detailTextLabel.textColor = [UIColor valueTextColour];
                cell.selectable = NO;
            }
        } else {
            [cell loadMember:[self dataAtIndexPath:indexPath] inOrigo:nil excludeRoles:YES excludeRelations:YES];
        }
    } else {
        id<OMember> candidate = [self dataAtIndexPath:indexPath];
        
        if ([self aspectIs:kAspectParentRole]) {
            [cell loadMember:candidate inOrigo:_origo excludeRoles:YES excludeRelations:NO];
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
    cell.checked = cell.checked && [_pickedValues count] == 1 ? _isNoValuePicker : !cell.checked;
    
    id oldValue = nil;
    id pickedValue = [self dataAtIndexPath:indexPath];
    
    if (cell.checked) {
        if (!_isMultiValuePicker && cell != _checkedCell) {
            if (_checkedCell) {
                oldValue = [self dataAtIndexPath:[self.tableView indexPathForCell:_checkedCell]];
                
                _checkedCell.checked = NO;
                [_pickedValues removeObject:oldValue];
            }
            
            _checkedCell = cell;
        }
        
        if (![_pickedValues containsObject:pickedValue]) {
            [_pickedValues insertObject:pickedValue atIndex:0];
        }
    } else {
        [_pickedValues removeObject:pickedValue];
    }
    
    if ([self targetIs:kTargetSetting]) {
        [OMeta m].settings = [OUtil keyValueString:[OMeta m].settings setValue:pickedValue forKey:_settingKey];
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
        if ([_origo isCommunity]) {
            NSMutableArray *pickedAddresses = [NSMutableArray array];
            
            for (id<OMember> pickedMember in _pickedValues) {
                [pickedAddresses addObject:[[pickedMember primaryResidence] shortAddress]];
            }
            
            self.subtitle = [OUtil commaSeparatedListOfStrings:pickedAddresses conjoin:NO];
        } else {
            self.subtitle = [OUtil commaSeparatedListOfMembers:_pickedValues inOrigo:_origo subjective:NO];
        }
        
        if (self.isModal) {
            self.returnData = _pickedValues;
        }
    } else if ([self targetIs:kTargetAdmins]) {
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
        
        if ([self targetIs:kTargetGroup]) {
            [self cell:cell loadGroupDetailsForMember:pickedValue];
            [self setSubtitle:[OUtil commaSeparatedListOfMembers:_pickedValues inOrigo:_origo subjective:YES]];
        } else {
            [self setSubtitle:[OUtil commaSeparatedListOfMembers:_pickedValues inOrigo:_origo subjective:NO]];
            
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
