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
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem signOutButtonWithTarget:self];
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
    
    if (![OMeta m].settings.countryCode) {
        [OMeta m].settings.countryCode = [[OMeta m] inferredCountryCode];
    }
}


- (void)initialiseData
{
    [self setData:[[OMeta m].settings settingKeys] forSectionWithKey:kSectionKeySettings];
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return NO;
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:kSegueToSettingView sender:self];
}


#pragma mark - OTableViewListDelegate conformance

- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSString *settingKey = [self dataAtIndexPath:indexPath];
    
    cell.textLabel.text = [OStrings labelForSettingKey:settingKey];
    cell.detailTextLabel.text = [[OMeta m].settings displayValueForSettingKey:settingKey];
}


- (UITableViewCellStyle)styleForIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellStyleValue1;
}

@end
