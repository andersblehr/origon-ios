//
//  OValueListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OValueListViewController.h"

static NSString * const kSegueToValuePickerView = @"sequeFromValueListToValuePickerView";

static NSInteger const kSectionKeyValues = 0;
static NSInteger const kSectionKeySignOut = 1;


@implementation OValueListViewController

#pragma mark - UIViewController overrides

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToValuePickerView]) {
        [self prepareForPushSegue:segue];
    }
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialiseState
{
    self.title = NSLocalizedString(@"Settings", @"");
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButton];
    
    self.state.target = kTargetUser;
}


- (void)initialiseData
{
    [self setData:[[OMeta m].settings settingKeys] forSectionWithKey:kSectionKeyValues];
    [self setData:@[kCustomData] forSectionWithKey:kSectionKeySignOut];
}


- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey
{
    return NO;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return NO;
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyValues) {
        [self performSegueWithIdentifier:kSegueToValuePickerView sender:self];
    } else if (sectionKey == kSectionKeySignOut) {
        [self signOut];
    }
}


#pragma mark - OTableViewListDelegate conformance

- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyValues) {
        NSString *key = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = NSLocalizedString(key, kKeyPrefixSettingLabel);
        cell.detailTextLabel.text = [[OMeta m].settings displayValueForSettingKey:key];
    } else if (sectionKey == kSectionKeySignOut) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = [UIColor redColor];
        cell.textLabel.text = [NSLocalizedString(@"Log out", @"") stringByAppendingString:[OMeta m].user.name separator:kSeparatorSpace];
    }
}


- (UITableViewCellStyle)styleForIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellStyleValue1;
}

@end
