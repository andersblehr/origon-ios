//
//  OValuePickerViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OValuePickerViewController.h"

static NSInteger const kSectionKeyValues = 0;

static NSInteger const kSegmentedTitleIndexAdults = 0;
static NSInteger const kSegmentedTitleIndexMinors = 1;


@implementation OValuePickerViewController

#pragma mark - Auxiliary methods

- (BOOL)targetIsJuvenileElder
{
    BOOL targetIsJuvenileElder = NO;
    
    targetIsJuvenileElder = targetIsJuvenileElder || [self targetIs:kTargetGuardian];
    targetIsJuvenileElder = targetIsJuvenileElder || [self targetIs:kTargetContact];
    targetIsJuvenileElder = targetIsJuvenileElder || [self targetIs:kTargetParentContact];
    
    return targetIsJuvenileElder;
}


- (BOOL)targetIsMemberVariant
{
    BOOL targetIsMemberVariant = [self targetIsJuvenileElder];
    
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
    NSMutableSet *peers = nil;
    
    if (_segmentedTitle) {
        if ([[OState s].pivotMember isMinor] == _segmentedTitle.selectedSegmentIndex) {
            peers = [[[OState s].pivotMember peers] mutableCopy];
        } else {
            peers = [[[OState s].pivotMember crossGenerationalPeers] mutableCopy];
        }
    } else if ([self targetIsJuvenileElder]) {
        peers = [[[OState s].pivotMember crossGenerationalPeers] mutableCopy];
    } else {
        peers = [[[OState s].pivotMember peers] mutableCopy];
    }
    
    for (OMembership *membership in [self.data fullMemberships]) {
        [peers removeObject:membership.member];
    }
    
    return [[peers allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


#pragma mark - Selector implementations

- (void)didSelectTitleSegment
{
    [self reloadSections];
}


#pragma mark - View lifecycle

- (void)viewWillDisappear:(BOOL)animated
{
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        [self.observer entityDidChange];
    }
    
    [super viewWillDisappear:animated];
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialiseState
{
    self.state.target = self.meta ? self.meta : self.data;

    if ([self targetIsMemberVariant]) {
        if ([self.data isCrossGenerational]) {
            _segmentedTitle = [self.navigationItem addSegmentedTitle:[OStrings stringForKey:strSegmentedTitleAdultsMinors]];
            
            if ([[OState s].pivotMember isMinor]) {
                _segmentedTitle.selectedSegmentIndex = kSegmentedTitleIndexMinors;
            } else {
                _segmentedTitle.selectedSegmentIndex = kSegmentedTitleIndexAdults;
            }
        }
        
        self.usesPlainTableViewStyle = YES;
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButton];
        
        if ([self isMultiValuePicker]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButton];
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
    } else {
        self.title = [OStrings stringForKey:_settingKey withKeyPrefix:kKeyPrefixSettingTitle];
        
        _settings = [OMeta m].settings;
        _settingKey = self.state.target;
    }
}


- (void)initialiseData
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

- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self targetIsMemberVariant]) {
        OMember *peer = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = peer.name;
        cell.detailTextLabel.text = [peer shortAddress];
        cell.imageView.image = [peer smallImage];
    }
}

@end
