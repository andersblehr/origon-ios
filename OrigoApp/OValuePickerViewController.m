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
    
    targetIsMemberVariant = targetIsMemberVariant || [self targetIs:kTargetElder];
    targetIsMemberVariant = targetIsMemberVariant || [self targetIs:kTargetMember];
    targetIsMemberVariant = targetIsMemberVariant || [self targetIs:kTargetMembers];
    
    return targetIsMemberVariant;
}


- (BOOL)isMultiValuePicker
{
    return [self targetIs:kTargetMembers];
}


- (NSArray *)sortedPeers
{
    return [[[OUtil eligibleCandidatesForOrigo:self.meta isElder:[self targetIs:kTargetElder]] allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    if ([self targetIsMemberVariant]) {
        self.usesPlainTableViewStyle = YES;
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
        
        if ([self isMultiValuePicker]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
    } else {
        self.title = NSLocalizedString(_settingKey, kStringPrefixSettingTitle);
        
        _settings = [OSettings settings];
        _settingKey = self.state.target;
    }
}


- (void)loadData
{
    if ([self targetIsMemberVariant]) {
        [self setData:[self sortedPeers] sectionIndexLabelKey:kPropertyKeyName];
        
        if (!self.returnData) {
            self.returnData = [NSMutableArray array];
        }
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self targetIsMemberVariant]) {
        id<OMember> peer = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = peer.name;
        cell.detailTextLabel.text = [[peer residence] shortAddress];
        cell.imageView.image = [OUtil smallImageForMember:peer];
        cell.checked = [self.returnData containsObject:peer];
    } else {
        cell.checked = [[self dataAtIndexPath:indexPath] isEqual:[_settings valueForSettingKey:_settingKey]];
    }
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.checked = !cell.checked;
    cell.selected = NO;
    
    id pickedValue = [self dataAtIndexPath:indexPath];
    
    if ([self targetIsMemberVariant]) {
        if ([self isMultiValuePicker]) {
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
