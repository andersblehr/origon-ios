//
//  OSettingListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OSettingListViewController.h"

static NSString * const kSegueToSettingView = @"sequeFromSettingListToSettingView";

static NSInteger const kSectionKeySettings = 0;
static NSInteger const kSectionKeySignOut = 1;


@implementation OSettingListViewController

#pragma mark - Selection implementations

- (void)didFinishEditing
{
    [self.dismisser dismissModalViewController:self reload:NO];
}


#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = [OStrings stringForKey:strViewTitleSettings];
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
}


#pragma mark - UIViewController overrides

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToSettingView]) {
        [self prepareForPushSegue:segue];
    }
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialiseState
{
    self.state.target = kTargetUser;
}


- (void)initialiseData
{
    [self setData:[[OMeta m].settings settingKeys] forSectionWithKey:kSectionKeySettings];
    [self setData:@[kCustomValue] forSectionWithKey:kSectionKeySignOut];
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
    
    if (sectionKey == kSectionKeySettings) {
        [self performSegueWithIdentifier:kSegueToSettingView sender:self];
    } else if (sectionKey == kSectionKeySignOut) {
        [self signOut];
    }
}


#pragma mark - OTableViewListDelegate conformance

- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeySettings) {
        NSString *key = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = [OStrings stringForKey:key withKeyPrefix:kKeyPrefixSettingLabel];
        cell.detailTextLabel.text = [[OMeta m].settings displayValueForSettingKey:key];
    } else if (sectionKey == kSectionKeySignOut) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = [UIColor redColor];
        cell.textLabel.text = [[OStrings stringForKey:strButtonSignOut] stringByAppendingString:[OMeta m].user.name separator:kSeparatorSpace];
    }
}


- (UITableViewCellStyle)styleForIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellStyleValue1;
}

@end
