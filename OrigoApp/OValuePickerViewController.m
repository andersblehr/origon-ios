//
//  OValuePickerViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OValuePickerViewController.h"

static NSInteger const kSectionKeyValues = 0;

static NSInteger const kActionSheetTagJoinCode = 0;
static NSInteger const kButtonTagJoinCodeEdit = 0;
static NSInteger const kButtonTagJoinCodeDelete = 1;


@interface OValuePickerViewController () <OTableViewController, UIActionSheetDelegate> {
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
    
    OTableViewCell *_joinCodeCell;
    NSString *_joinCode;
    NSString *_internalJoinCode;
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
                eligibleOrigoTypes = @[kOrigoTypeStandard, kOrigoTypePreschoolClass, kOrigoTypeSchoolClass, kOrigoTypeSports];
            } else {
                eligibleOrigoTypes = @[kOrigoTypeStandard, kOrigoTypeSports];
            }
        } else {
            eligibleOrigoTypes = @[origo.type, kOrigoTypeStandard];
        }
    }
    
    return eligibleOrigoTypes;
}


- (NSString *)joinCodeFooterText
{
    NSString *footerText = nil;
    
    if ([_origo isJuvenile]) {
        footerText = [NSString stringWithFormat:NSLocalizedString(@"The join code can be shared with other %@ users whose children should be included in this list. They can then use the code to join their children to the list themselves by tapping the join button (circled plus sign) in the start view.", @""), [OMeta m].appName];
    } else {
        footerText = [NSString stringWithFormat:NSLocalizedString(@"The join code can be shared with other %@ users who should be included in this list. They can then use the code to join the list themselves by tapping the join button (circled plus sign) in the start view.", @""), [OMeta m].appName];
    }
    
    return footerText;
}


- (void)showJoinCodeSetAlertAndReplicate
{
    [OAlert showAlertWithTitle:NSLocalizedString(@"The code has been set", @"") text:[NSString stringWithFormat:NSLocalizedString(@"The join code for %@ is '%@'. You may now share it with other %@ users who should be in the list.", @""), _origo.name, _origo.joinCode, [OMeta m].appName]];
    
    [[OMeta m].replicator replicateIfNeeded];
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
    } else if ([self targetIs:kPropertyKeyJoinCode]) {
        _origo = self.state.currentOrigo;
        
        self.title = NSLocalizedString(kPropertyKeyJoinCode, kStringPrefixLabel);
        self.usesPlainTableViewStyle = NO;
        self.requiresSynchronousServerCalls = YES;
    } else {
        self.usesSectionIndexTitles = YES;
        
        _origo = self.state.currentOrigo;
        _isMultiValuePicker = ![self targetIs:kTargetMember];
        _isNoValuePicker = YES;
        
        if ([self targetIs:@[kTargetMember, kTargetMembers]]) {
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
                _affiliation = NSLocalizedString(kLabelKeyAdmins, kStringPrefixLabel);
                _pickedValues = [[_origo admins] mutableCopy];
            }
            
            self.titleView = [OTitleView titleViewWithTitle:_affiliation subtitle:[OUtil commaSeparatedListOfMembers:_pickedValues inOrigo:_origo subjective:[self aspectIs:kAspectGroup]]];
            
            if (placeholder) {
                self.titleView.placeholder = placeholder;
            }
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
    } else if ([self targetIs:kPropertyKeyJoinCode]) {
        if ([_origo.joinCode hasValue] || [_origo userIsAdmin]) {
            [self setData:@[kPropertyKeyJoinCode] forSectionWithKey:kSectionKeyValues];
        }
    } else if ([self targetIs:kTargetAffiliation]) {
        if ([self aspectIs:kAspectMemberRole]) {
            [self setData:[_origo regulars] sectionIndexLabelKey:kPropertyKeyName];
        } else if ([self aspectIs:kAspectOrganiserRole]) {
            [self setData:[_origo organiserCandidates] sectionIndexLabelKey:kPropertyKeyName];
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
    } else if ([self targetIs:kPropertyKeyJoinCode]) {
        if ([_origo userIsAdmin]) {
            _joinCodeCell = cell;
            
            OInputField *joinCodeField = [_joinCodeCell inlineField];
            joinCodeField.placeholder = NSLocalizedString(kPropertyKeyJoinCode, kStringPrefixLabel);
            
            if ([_origo.joinCode hasValue]) {
                joinCodeField.value = _origo.joinCode;
            } else {
                [self editInlineInCell:_joinCodeCell];
            }
        } else if ([_origo.joinCode hasValue]) {
            cell.textLabel.text = _origo.joinCode;
            cell.selectable = NO;
        }
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
            cell.detailTextLabel.textColor = [UIColor tonedDownTextColour];
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


- (UITableViewCellStyle)listCellStyleForSectionWithKey:(NSInteger)sectionKey
{
    UITableViewCellStyle style = kTableViewCellStyleDefault;
    
    if ([self targetIs:kPropertyKeyJoinCode] && [_origo userIsAdmin]) {
        style = kTableViewCellStyleInline;
    }
    
    return style;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return [self targetIs:kPropertyKeyJoinCode];
}


- (id)footerContentForSectionWithKey:(NSInteger)sectionKey
{
    return [self targetIs:kPropertyKeyJoinCode] ? [self joinCodeFooterText] : nil;
}


- (NSString *)emptyTableViewFooterText
{
    NSString *footerText = nil;
    
    if ([self targetIs:kTargetParent]) {
        NSString *hisHerParent = [OLanguage labelForParentWithGender:_parentGender relativeToOffspringWithGender:_ward.gender];
        
        footerText = [NSString stringWithFormat:NSLocalizedString(@"%@ and %@ must be listed at the same address. You may register a separate address for them if you do not live with %@.", @""), [_ward givenName], hisHerParent, hisHerParent];
    } else if ([self targetIs:kPropertyKeyJoinCode]) {
        footerText = [[self joinCodeFooterText] stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"You may ask an administrator to create a join code for %@.", @""), _origo.name] separator:kSeparatorParagraph];
    }
    
    return footerText;
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    id oldValue = nil;
    id pickedValue = [self dataAtIndexPath:indexPath];
    
    if (![self targetIs:kPropertyKeyJoinCode]) {
        cell.selected = NO;
        cell.checked = cell.checked && [_pickedValues count] == 1 ? _isNoValuePicker : !cell.checked;
        
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
    } else if ([self targetIs:kPropertyKeyJoinCode]) {
        if ([_origo userIsAdmin]) {
            OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagJoinCode];
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit join code", @"") tag:kButtonTagJoinCodeEdit];
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete join code", @"") tag:kButtonTagJoinCodeDelete];
            
            [actionSheet show];
        }
    } else if ([self targetIs:kTargetMember]) {
        self.returnData = pickedValue;
    } else if ([self targetIs:kTargetMembers]) {
        if ([_origo isCommunity]) {
            NSMutableArray *pickedAddresses = [NSMutableArray array];
            
            for (id<OMember> pickedMember in _pickedValues) {
                [pickedAddresses addObject:[[pickedMember primaryResidence] shortAddress]];
            }
            
            self.titleView.subtitle = [OUtil commaSeparatedListOfStrings:pickedAddresses conjoin:NO];
        } else {
            self.titleView.subtitle = [OUtil commaSeparatedListOfMembers:_pickedValues inOrigo:_origo subjective:NO];
        }
        
        if (self.isModal) {
            self.returnData = _pickedValues;
        }
    } else if ([self targetIs:kTargetAdmins]) {
        [_origo membershipForMember:pickedValue].isAdmin = @(cell.checked);
        self.titleView.subtitle = [OUtil commaSeparatedListOfMembers:_pickedValues conjoin:NO subjective:NO];
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
            self.titleView.subtitle = [OUtil commaSeparatedListOfMembers:_pickedValues inOrigo:_origo subjective:YES];
        } else {
            self.titleView.subtitle = [OUtil commaSeparatedListOfMembers:_pickedValues inOrigo:_origo subjective:NO];
            
        }
    }
    
    if (self.isModal) {
        if (_isMultiValuePicker) {
            self.navigationItem.rightBarButtonItem.enabled = [_pickedValues count] > 0;
        } else {
            [self.dismisser dismissModalViewController:self];
        }
    } else if (!_isMultiValuePicker) {
        if (![self targetIs:@[kTargetParent, kPropertyKeyJoinCode]] || cell.checked) {
            [self.navigationController popViewControllerAnimated:YES];
        }
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


- (void)didFinishEditingInlineField:(OInputField *)inlineField
{
    if (self.didCancel) {
        inlineField.value = _origo.joinCode;
        
        if (![_origo.joinCode hasValue]) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        _joinCode = inlineField.value;
        _internalJoinCode = [_joinCode stringByLowercasingAndRemovingWhitespace];
        
        if ([_internalJoinCode isEqualToString:_origo.internalJoinCode]) {
            _origo.joinCode = _joinCode;
            
            [self showJoinCodeSetAlertAndReplicate];
        } else {
            [[OConnection connectionWithDelegate:self] lookupOrigoWithJoinCode:_joinCode];
        }
    }
}


#pragma mark - OTitleViewDelegate conformance

- (BOOL)shouldFinishEditingTitleView:(OTitleView *)titleView
{
    BOOL shouldFinishEditing = [super shouldFinishEditingTitleView:titleView];
    
    if (shouldFinishEditing) {
        NSString *editedAffiliation = titleView.titleField.text;
        
        if ([self targetIs:kTargetGroup] && ![editedAffiliation isEqualToString:_affiliation]) {
            shouldFinishEditing = ![[_origo groups] containsObject:titleView.title];
        }
    }
    
    return shouldFinishEditing;
}


- (void)didFinishEditingTitleView:(OTitleView *)titleView
{
    [super didFinishEditingTitleView:titleView];
    
    NSString *oldAffiliation = _affiliation;
    _affiliation = titleView.title;
    
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


#pragma mark - OConnectionDelegate conformance

- (void)connection:(OConnection *)connection didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    [super connection:connection didCompleteWithResponse:response data:data];
    
    if ([self targetIs:kPropertyKeyJoinCode]) {
        if (response.statusCode == kHTTPStatusNotFound) {
            _origo.joinCode = _joinCode;
            _origo.internalJoinCode = _internalJoinCode;
            
            [self showJoinCodeSetAlertAndReplicate];
        } else {
            [OAlert showAlertWithTitle:NSLocalizedString(@"The code is in use", @"") text:[NSString stringWithFormat:NSLocalizedString(@"The join code '%@' is already in use. Please try to make the code more specific, for instance by including a location and/or a year.", @""), _joinCode]];
            
            [self editInlineInCell:_joinCodeCell];
        }
    }
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
    
    switch (actionSheet.tag) {
        case kActionSheetTagJoinCode:
            _joinCodeCell.selected = NO;
            
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                if (buttonTag == kButtonTagJoinCodeDelete) {
                    _origo.joinCode = nil;
                    [_joinCodeCell inlineField].value = nil;
                }
                
                [self editInlineInCell:_joinCodeCell];
            }
            
            break;
            
        default:
            break;
    }
}

@end
