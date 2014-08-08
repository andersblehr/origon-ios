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
    id<OSettings> _settings;
    NSString *_settingKey;
}

@end


@implementation OValuePickerViewController

#pragma mark - Auxiliary methods

- (BOOL)targetIsMemberVariant
{
    BOOL targetIsMemberVariant = NO;
    
    targetIsMemberVariant = targetIsMemberVariant || [self targetIs:kTargetMember];
    targetIsMemberVariant = targetIsMemberVariant || [self targetIs:kTargetMembers];
    targetIsMemberVariant = targetIsMemberVariant || [self targetIs:kTargetContact];
    targetIsMemberVariant = targetIsMemberVariant || [self targetIs:kTargetParentContact];
    targetIsMemberVariant = targetIsMemberVariant || [self targetIs:kTargetElder];
    
    return targetIsMemberVariant;
}


- (BOOL)isMultiValuePicker
{
    return [self targetIs:kTargetMembers];
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    if ([self targetIs:kTargetRole]) {
        if (self.isModal) {
            self.title = NSLocalizedString(@"Role owner", @"");
            self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
        } else {
            
        }
    } else if ([self targetIsMemberVariant]) {
        self.usesPlainTableViewStyle = YES;
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
        
        if ([self isMultiValuePicker]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
    } else {
        _settings = [OSettings settings];
        _settingKey = self.target;
        
        self.title = NSLocalizedString(_settingKey, kStringPrefixSettingTitle);
    }
}


- (void)loadData
{
    if ([self targetIsMemberVariant] || [self targetIs:kTargetRole]) {
        [self setData:[self.meta regulars] sectionIndexLabelKey:kPropertyKeyName];
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self targetIs:kTargetRole]) {
        id<OMember> candidate = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = [candidate publicName];
        cell.imageView.image = [OUtil smallImageForMember:candidate];
        
        if ([candidate isJuvenile]) {
            cell.detailTextLabel.text = [OUtil guardianInfoForMember:candidate];
        }
    } else if ([self targetIsMemberVariant]) {
        id<OMember> candidate = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = [candidate publicName];
        cell.imageView.image = [OUtil smallImageForMember:candidate];
        
        if ([self isMultiValuePicker]) {
            cell.checked = [self.returnData containsObject:candidate];
        }
        
        if ([candidate isJuvenile]) {
            cell.detailTextLabel.text = [OUtil guardianInfoForMember:candidate];
        } else if ([self targetIs:kTargetParentContact]) {
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfItems:[candidate wards] conjoinLastItem:NO];
        } else {
            cell.detailTextLabel.text = [[candidate residence] shortAddress];
        }
    } else {
        cell.checked = [[self dataAtIndexPath:indexPath] isEqual:[_settings valueForSettingKey:_settingKey]];
    }
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.checked = !cell.checked;
    cell.selected = NO;
    
    id pickedValue = [self dataAtIndexPath:indexPath];
    
    if ([self targetIs:kTargetRole]) {
        self.returnData = pickedValue;
        
        [self.dismisser dismissModalViewController:self];
    } else if ([self targetIsMemberVariant]) {
        if ([self isMultiValuePicker]) {
            if (!self.returnData) {
                self.returnData = [NSMutableArray array];
            }
            
            if (cell.checked) {
                [self.returnData addObject:pickedValue];
            } else {
                [self.returnData removeObject:pickedValue];
            }
            
            self.navigationItem.rightBarButtonItem.enabled = [self.returnData count] > 0;
        } else {
            self.returnData = pickedValue;
            
            [self.dismisser dismissModalViewController:self];
        }
    } else {
        [_settings setValue:pickedValue forSettingKey:_settingKey];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
