//
//  OValuePickerViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OValuePickerViewController.h"


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
    NSSet *peers = nil;
    
    if ([self targetIs:kTargetElder]) {
        peers = [[OMeta m].user peersNotInOrigo:self.meta];
    } else {
        peers = [[OState s].pivotMember peersNotInOrigo:self.meta];
    }
    
    return [[peers allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


#pragma mark - OTableViewControllerInstance conformance

- (void)loadState
{
    if ([self targetIsMemberVariant]) {
        self.usesPlainTableViewStyle = YES;
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButton];
        
        if ([self isMultiValuePicker]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButton];
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


- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey
{
    return NO;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return NO;
}


- (void)willDisplayCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self targetIsMemberVariant]) {
        cell.checked = [self.returnData containsObject:[self dataAtIndexPath:indexPath]];
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
            
            self.navigationItem.rightBarButtonItem.enabled = ([self.returnData count] > 0);
        } else {
            self.returnData = pickedValue;
            
            [self.dismisser dismissModalViewController:self reload:YES];
        }
    } else {
        [_settings setValue:pickedValue forSettingKey:_settingKey];
        [self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma mark - OTableViewListDelegate conformance

- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self targetIsMemberVariant]) {
        id<OMember> peer = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = peer.name;
        cell.detailTextLabel.text = [peer shortAddress];
        cell.imageView.image = [peer smallImage];
    }
}

@end
