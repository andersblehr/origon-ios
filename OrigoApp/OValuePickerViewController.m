//
//  OValuePickerViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OValuePickerViewController.h"

static NSInteger const kAlertTagParentContactRole = 0;
static NSInteger const kButtonIndexOK = 1;


@interface OValuePickerViewController () <OTableViewController, UITextFieldDelegate> {
@private
    BOOL _isMultiValuePicker;
    OTableViewCell *_checkedCell;
    
    id<OSettings> _settings;
    NSString *_settingKey;

    id<OOrigo> _origo;
    NSString *_role;
    UITextField *_roleField;
    UIBarButtonItem *_multiRoleButton;
    UIBarButtonItem *_multiRoleButtonSelected;
    UIBarButtonItem *_leftBarButtonItem;
    NSArray *_righBarButtonItems;
    UIView *_dimmerView;
}

@end


@implementation OValuePickerViewController

#pragma mark - Input dialogues

- (void)presentParentContactRoleDialogue
{
    NSString *prompt = nil;
    
    if ([self.returnData[0] isUser]) {
        prompt = NSLocalizedString(@"What is your contact role?", @"");
    } else {
        prompt = [NSString stringWithFormat:NSLocalizedString(@"What is %@'s contact role?", @""), [self.returnData[0] givenName]];
    }
    
    [OAlert showInputDialogueWithPrompt:prompt placeholder:NSLocalizedString(@"Contact role", @"") text:nil delegate:self tag:kAlertTagParentContactRole];
}


#pragma mark - Selector implementations

- (void)toggleMultiRole
{
    if ([self.returnData count] < 2) {
        UIBarButtonItem *currentButton;
        UIBarButtonItem *toggledButton;
        
        if (_isMultiValuePicker) {
            currentButton = _multiRoleButtonSelected;
            toggledButton = _multiRoleButton;
        } else {
            currentButton = _multiRoleButton;
            toggledButton = _multiRoleButtonSelected;
        }
        
        NSMutableArray *rightBarButtonItems = [NSMutableArray array];
        
        for (UIBarButtonItem *button in self.navigationItem.rightBarButtonItems) {
            if (button == currentButton) {
                [rightBarButtonItems addObject:toggledButton];
            } else {
                [rightBarButtonItems addObject:button];
            }
        }
        
        self.navigationItem.rightBarButtonItems = rightBarButtonItems;
        
        _isMultiValuePicker = !_isMultiValuePicker;
    }
}


- (void)didCancelEditingRole
{
    if ([_role hasValue]) {
        _roleField.text = _role;
        [_roleField resignFirstResponder];
        
        self.navigationItem.leftBarButtonItem = _leftBarButtonItem;
        self.navigationItem.rightBarButtonItems = _righBarButtonItems;
        
        [self.tableView undim];
    }
}


- (void)didFinishEditingRole
{
    if ([_roleField.text hasValue]) {
        [_roleField resignFirstResponder];
        
        if (_role) {
            for (id<OMember> roleHolder in [_origo membersWithRole:_role]) {
                id<OMembership> membership = [_origo membershipForMember:roleHolder];
                
                [membership removeRole:_role ofType:kRoleTypeMemberRole];
                [membership addRole:_roleField.text ofType:kRoleTypeMemberRole];
            }
        } else {
            [self.navigationItem setTitle:_roleField.text editable:YES];
        }
        
        _role = _roleField.text;
        
        self.navigationItem.leftBarButtonItem = _leftBarButtonItem;
        self.navigationItem.rightBarButtonItems = _righBarButtonItems;
        
        [self.tableView undim];
    }
}


#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self targetIs:kTargetRole]) {
        if (!_role) {
            [_roleField becomeFirstResponder];
        }
    }
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
        } else if ([self targetIs:kTargetMembers]) {
            _isMultiValuePicker = YES;
        } else if ([self targetIs:kTargetRole]) {
            _role = self.isModal ? nil : self.target;
            
            if ([self.meta conformsToProtocol:@protocol(OOrigo)]) {
                _origo = self.meta;
                
                if (_role) {
                    if ([self aspectIs:kAspectMemberRole]) {
                        self.returnData = [[_origo membersWithRole:_role] mutableCopy];
                    } else if ([self aspectIs:kAspectParentRole]) {
                        self.returnData = [[_origo parentsWithRole:_role] mutableCopy];
                    }
                    
                    _isMultiValuePicker = ([self.returnData count] > 1);
                }
            }
            
            _roleField = [self.navigationItem setTitle:_role editable:YES withSubtitle:[OUtil commaSeparatedListOfItems:self.returnData conjoinLastItem:NO]];
            _roleField.delegate = self;
            
            if ([self aspectIs:kAspectMemberRole]) {
                _roleField.placeholder = NSLocalizedString(_origo.type, kStringPrefixMemberRoleTitle);
            } else if ([self aspectIs:kAspectParentRole]) {
                _roleField.placeholder = NSLocalizedString(@"Contact role", @"");
            }
            
            if (!_isMultiValuePicker && [self.returnData count] < 2) {
                _multiRoleButton = [UIBarButtonItem multiRoleButtonWithTarget:self selected:NO];
                _multiRoleButtonSelected = [UIBarButtonItem multiRoleButtonWithTarget:self selected:YES];
                
                [self.navigationItem addRightBarButtonItem:_multiRoleButton];
            }
        }
    }
    
    if (self.isModal) {
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
        
        if (_isMultiValuePicker) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
    }
    
    if (!self.returnData) {
        self.returnData = [NSMutableArray array];
    }
}


- (void)loadData
{
    if ([self targetIs:kTargetSetting]) {
        // TODO
    } else {
        if ([self targetIs:kTargetRole]) {
            if ([self aspectIs:kAspectMemberRole]) {
                [self setData:[_origo regulars] sectionIndexLabelKey:kPropertyKeyName];
            } else if ([self aspectIs:kAspectParentRole]) {
                [self setData:[_origo guardians] sectionIndexLabelKey:kPropertyKeyName];
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
        
        if ([self.returnData count]) {
            cell.checked = [self.returnData containsObject:candidate];
        }
        
        if ([candidate isJuvenile]) {
            cell.detailTextLabel.text = [OUtil guardianInfoForMember:candidate];
        } else if ([self targetIs:kTargetRole]) {
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfItems:[candidate wards] conjoinLastItem:NO];
        } else {
            cell.detailTextLabel.text = [[candidate residence] shortAddress];
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
                [self.returnData removeAllObjects];
            }
            
            _checkedCell = cell;
        }
        
        [self.returnData addObject:pickedValue];
    } else {
        [self.returnData removeObject:pickedValue];
    }
    
    if ([self targetIs:kTargetSetting]) {
        [_settings setValue:pickedValue forSettingKey:_settingKey];
        [self.navigationController popViewControllerAnimated:YES];
    } else if ([self targetIs:kTargetMember]) {
        self.returnData = pickedValue;
        [self.dismisser dismissModalViewController:self];
    } else if ([self targetIs:kTargetParentContact]) {
        [self presentParentContactRoleDialogue];
    } else if ([self targetIs:kTargetRole]) {
        NSString *roleType = [self aspectIs:kAspectMemberRole] ? kRoleTypeMemberRole : kRoleTypeParentRole;
        
        if (cell.checked) {
            [[_origo membershipForMember:pickedValue] addRole:_role ofType:roleType];
            
            if (!_isMultiValuePicker) {
                [[_origo membershipForMember:oldValue] removeRole:_role ofType:roleType];
            }
        } else {
            [[_origo membershipForMember:pickedValue] removeRole:_role ofType:roleType];
        }
        
        [self.navigationItem setSubtitle:[OUtil commaSeparatedListOfItems:self.returnData conjoinLastItem:NO]];
        
        if (_isMultiValuePicker) {
            if (self.isModal) {
                if ([self.returnData count]) {
                    if (self.navigationItem.rightBarButtonItem == _multiRoleButtonSelected) {
                        self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
                    }
                }
                
                self.navigationItem.rightBarButtonItem.enabled = [self.returnData count] > 0;
            }
        } else {
            if (self.isModal) {
                [self.dismisser dismissModalViewController:self];
            } else {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
            
    }
}


#pragma mark - UITextFieldDelegate conformance

- (void)textFieldDidBeginEditing:(OTextField *)textField
{
    if ([textField.text hasValue]) {
        textField.selectedTextRange = [textField textRangeFromPosition:textField.beginningOfDocument toPosition:textField.endOfDocument];
    }
    
    _leftBarButtonItem = self.navigationItem.leftBarButtonItem;
    
    if (!self.isModal) {
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTitle:NSLocalizedString(@"Cancel", @"") target:self action:@selector(didCancelEditingRole)];
    }
    
    _righBarButtonItems = self.navigationItem.rightBarButtonItems;
    
    self.navigationItem.rightBarButtonItems = @[[UIBarButtonItem doneButtonWithTitle:NSLocalizedString(@"Use", @"") target:self action:@selector(didFinishEditingRole)]];
    
    [self.tableView dim];
}


- (BOOL)textFieldShouldReturn:(OTextField *)textField
{
    if ([textField.text hasValue]) {
        [textField resignFirstResponder];
    }
    
    return NO;
}


- (void)textFieldDidEndEditing:(OTextField *)textField
{
    [self didFinishEditingRole];
}


#pragma mark - UIAlertViewDelegate conformance

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertTagParentContactRole:
            if (buttonIndex == kButtonIndexOK) {
                id<OMembership> membership = [_origo addMember:self.returnData[0]];
                NSString *role = [alertView textFieldAtIndex:0].text;
                
                [membership addRole:role ofType:kRoleTypeParentRole];
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
