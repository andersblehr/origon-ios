//
//  OValuePickerViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OValuePickerViewController.h"

static NSInteger const kAlertTagParentContactRole = 0;
static NSInteger const kAlertTagEditRole = 1;
static NSInteger const kButtonIndexOK = 1;


@interface OValuePickerViewController () <OTableViewController, UIAlertViewDelegate, UITextFieldDelegate> {
@private
    NSString *_settingKey;
    NSString *_role;
    
    id<OSettings> _settings;
    id<OOrigo> _origo;
    id<OMember> _roleHolder;
    
    OTableViewCell *_checkedCell;
}

@end


@implementation OValuePickerViewController

#pragma mark - Auxiliary methods

- (BOOL)isMultiValuePicker
{
    return [self targetIs:kTargetMembers];
}


#pragma mark - Input dialogues

- (void)presentParentContactRoleDialogue
{
    NSString *prompt = nil;
    
    if ([_roleHolder isUser]) {
        prompt = NSLocalizedString(@"What is your contact role?", @"");
    } else {
        prompt = [NSString stringWithFormat:NSLocalizedString(@"What is %@'s contact role?", @""), [_roleHolder givenName]];
    }
    
    [OAlert showInputDialogueWithPrompt:prompt placeholder:NSLocalizedString(@"Contact role", @"") text:nil delegate:self tag:kAlertTagParentContactRole];
}


#pragma mark - Selector implementations

- (void)performEditAction
{
    [OAlert showInputDialogueWithPrompt:NSLocalizedString(@"Edit role", @"") placeholder:NSLocalizedString(@"Role designation", @"") text:_role delegate:self tag:kAlertTagEditRole];
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    if ([self targetIs:kTargetSetting]) {
        _settingKey = self.target;
        _settings = [OSettings settings];
        
        self.title = NSLocalizedString(_settingKey, kStringPrefixSettingTitle);
    } else {
        self.usesPlainTableViewStyle = YES;
        
        if ([self targetIs:kTargetParentContact]) {
            _origo = self.meta;
            
            self.title = [[OLanguage nouns][_parentContact_][singularIndefinite] stringByCapitalisingFirstLetter];
        } else if (![self targetIs:kTargetMembers]) {
            _role = self.target;
            
            if ([self.meta conformsToProtocol:@protocol(OOrigo)]) {
                _origo = self.meta;
                _roleHolder = [_origo membersWithRole:_role][0];
                
                self.navigationItem.rightBarButtonItem = [UIBarButtonItem editButtonWithTarget:self];
            }
            
            self.title = _role;
        }
    }
    
    if (self.isModal) {
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
    } else if ([self isMultiValuePicker]) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.returnData = [NSMutableArray array];
    }
}


- (void)loadData
{
    if ([self targetIs:kTargetSetting]) {
        // TODO
    } else {
        if (_origo) {
            if ([self targetIs:kTargetParentContact]) {
                [self setData:[_origo guardians] sectionIndexLabelKey:kPropertyKeyName];
            } else {
                [self setData:[_origo regulars] sectionIndexLabelKey:kPropertyKeyName];
            }
        } else {
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
        cell.imageView.image = [OUtil smallImageForMember:candidate];
        
        if (_origo) {
            cell.checked = [[_origo membersWithRole:_role] containsObject:candidate];
        }
        
        if ([candidate isJuvenile]) {
            cell.detailTextLabel.text = [OUtil guardianInfoForMember:candidate];
        } else if ([self targetIs:kTargetParentContact]) {
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfItems:[candidate wards] conjoinLastItem:NO];
        } else {
            cell.detailTextLabel.text = [[candidate residence] shortAddress];
        }
    }
    
    if (cell.checked && ![self isMultiValuePicker]) {
        _checkedCell = cell;
    }
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.checked = !cell.checked;
    cell.selected = NO;
    
    id pickedValue = [self dataAtIndexPath:indexPath];
    
    if ([self targetIs:kTargetSetting]) {
        [_settings setValue:pickedValue forSettingKey:_settingKey];
        [self.navigationController popViewControllerAnimated:YES];
    } else if ([self isMultiValuePicker]) {
        if (cell.checked) {
            [self.returnData addObject:pickedValue];
        } else {
            [self.returnData removeObject:pickedValue];
        }
        
        self.navigationItem.rightBarButtonItem.enabled = [self.returnData count] > 0;
    } else {
        _checkedCell.checked = NO;
        _checkedCell = cell;
        _checkedCell.checked = YES;
        
        if ([self targetIs:kTargetParentContact]) {
            _roleHolder = pickedValue;
            
            [self presentParentContactRoleDialogue];
        } else {
            self.returnData = pickedValue;
            
            if (self.isModal) {
                [self.dismisser dismissModalViewController:self];
            } else {
                [[_origo membershipForMember:_roleHolder] removeRole:_role ofType:kRoleTypeMemberRole];
                [[_origo membershipForMember:pickedValue] addRole:_role ofType:kRoleTypeMemberRole];
                
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    }
}


#pragma mark - UIAlertViewDelegate conformance

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertTagEditRole:
            if (buttonIndex == kButtonIndexOK) {
                NSString *role = [alertView textFieldAtIndex:0].text;
                
                for (id<OMember> roleHolder in [_origo membersWithRole:_role]) {
                    id<OMembership> membership = [_origo membershipForMember:roleHolder];
                    
                    [membership removeRole:_role ofType:kRoleTypeMemberRole];
                    [membership addRole:role ofType:kRoleTypeMemberRole];
                }
                
                self.title = role;
                _role = role;
            }
            
            break;
            
        default:
            break;
    }
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertTagParentContactRole:
            if (buttonIndex == kButtonIndexOK) {
                id<OMembership> membership = [_origo addMember:_roleHolder];
                NSString *role = [alertView textFieldAtIndex:0].text;
                
                [membership addRole:role ofType:kRoleTypeParentContact];
            } else {
                self.didCancel = YES;
            }
            
            [self.dismisser dismissModalViewController:self];
            
            break;
            
        default:
            break;
    }
    
}

@end
