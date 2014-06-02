//
//  OValueListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OValueListViewController.h"

static NSString * const kSegueToValuePickerView = @"sequeFromValueListToValuePickerView";

static NSInteger const kSectionKeyValues = 0;
static NSInteger const kSectionKeySignOut = 1;


@interface OValueListViewController () <OTableViewController>

@end


@implementation OValueListViewController

#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    self.title = NSLocalizedString(@"Settings", @"");
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
    
    self.state.target = kTargetUser;
}


- (void)loadData
{
    [self setData:[[OSettings settings] settingKeys] forSectionWithKey:kSectionKeyValues];
    [self setData:@[kCustomData] forSectionWithKey:kSectionKeySignOut];
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyValues) {
        NSString *key = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = NSLocalizedString(key, kStringPrefixSettingLabel);
        cell.detailTextLabel.text = [[OSettings settings] displayValueForSettingKey:key];
    } else if (sectionKey == kSectionKeySignOut) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = [UIColor redColor];
        cell.textLabel.text = [NSLocalizedString(@"Log out", @"") stringByAppendingString:[OMeta m].user.name separator:kSeparatorSpace];
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


- (UITableViewCellStyle)styleForListCellAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellStyleValue1;
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyValues) {
        [self performSegueWithIdentifier:kSegueToValuePickerView sender:self];
    } else if (sectionKey == kSectionKeySignOut) {
        [[OMeta m] signOut];
    }
}

@end
