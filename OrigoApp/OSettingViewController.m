//
//  OSettingViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OSettingViewController.h"

static NSInteger const kSectionKeyValues = 0;


@implementation OSettingViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.title = [OStrings stringForKey:_settingKey withKeyPrefix:kKeyPrefixSettingTitle];
}


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
    _settings = [OMeta m].settings;
    _settingKey = self.data;
    
    self.state.target = _settingKey;
}


- (void)initialiseData
{
    // TODO
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
    if ([[self dataAtIndexPath:indexPath] isEqual:[_settings valueForSettingKey:_settingKey]]) {
        cell.checked = YES;
        _valueCell = cell;
    } else {
        cell.checked = NO;
    }
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [cell setSelected:NO animated:YES];
    
    if ([[self dataAtIndexPath:indexPath] isEqualToString:kCustomValue]) {
        // TODO
    } else {
        _valueCell.checked = NO;
        _valueCell = cell;
        _valueCell.checked = YES;
        
        [_settings setValue:[self dataAtIndexPath:indexPath] forSettingKey:_settingKey];
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}


- (void)didResumeFromBackground
{
    [self reloadSectionWithKey:kSectionKeyValues];
}


#pragma mark - OTableViewListDelegate conformance

- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    // TODO
}


- (UITableViewCellStyle)styleForIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellStyleValue1;
}

@end
