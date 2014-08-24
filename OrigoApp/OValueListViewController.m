//
//  OValueListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OValueListViewController.h"

static NSInteger const kSectionKeyValues = 0;
static NSInteger const kSectionKeySignOut = 1;

static NSInteger const kAlertTagMemberRole = 0;
static NSInteger const kButtonIndexOK = 1;


@interface OValueListViewController () <OTableViewController> {
    id<OOrigo> _origo;
    
    NSString *_addedRole;
}

@end


@implementation OValueListViewController

#pragma mark - Selector implementations

- (void)performAddAction
{
    [OAlert showInputDialogueWithPrompt:NSLocalizedString(@"What role do you want to create?", @"") placeholder:NSLocalizedString(_origo.type, kStringPrefixMemberRoleTitle) text:nil delegate:self tag:kAlertTagMemberRole];
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.didResurface) {
        [self reloadSectionWithKey:kSectionKeyValues];
    }
}


#pragma mark - UIViewController overrides

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    
    [segue.destinationViewController setMeta:_origo];
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    if ([self targetIs:kTargetSettings]) {
        self.title = NSLocalizedString(@"Settings", @"");
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
    } else if ([self targetIs:kTargetRoles]) {
        _origo = self.meta;
        
        self.title = NSLocalizedString(_origo.type, kStringPrefixMemberRolesTitle);
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
    }
}


- (void)loadData
{
    if ([self targetIs:kTargetSettings]) {
        [self setData:[[OSettings settings] settingKeys] forSectionWithKey:kSectionKeyValues];
        [self setData:@[kCustomData] forSectionWithKey:kSectionKeySignOut];
    } else if ([self targetIs:kTargetRoles]) {
        [self setData:[_origo memberRoles] forSectionWithKey:kSectionKeyValues];
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if ([self targetIs:kTargetSettings]) {
        if (sectionKey == kSectionKeyValues) {
            NSString *key = [self dataAtIndexPath:indexPath];
            
            cell.textLabel.text = NSLocalizedString(key, kStringPrefixSettingLabel);
            cell.detailTextLabel.text = [[OSettings settings] displayValueForSettingKey:key];
        } else if (sectionKey == kSectionKeySignOut) {
            cell.textLabel.textColor = [UIColor redColor];
            cell.textLabel.text = [NSLocalizedString(@"Log out", @"") stringByAppendingString:[OMeta m].user.name separator:kSeparatorSpace];
        }
    } else if ([self targetIs:kTargetRoles]) {
        NSString *role = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = role;
        cell.detailTextLabel.text = [OUtil commaSeparatedListOfItems:[_origo membersWithRole:role] conjoinLastItem:NO];
        cell.destinationId = kIdentifierValuePicker;
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
    
    if ([self targetIs:kTargetSettings]) {
        if (sectionKey == kSectionKeySignOut) {
            [[OMeta m] signOut];
        } else {
            // TODO;
        }
    }
}


- (BOOL)canDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    return [self targetIs:kTargetRoles];
}


- (void)willDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self targetIs:kTargetRoles]) {
        NSString *role = [self dataAtIndexPath:indexPath];
        
        for (id<OMember> roleHolder in [_origo membersWithRole:role]) {
            [[_origo membershipForMember:roleHolder] removeRole:role ofType:kRoleTypeMemberRole];
        }
    }
}


- (void)willDismissModalViewController:(OTableViewController *)viewController
{
    if (!viewController.didCancel) {
        if ([viewController.identifier isEqualToString:kIdentifierValuePicker]) {
            if ([viewController targetIs:_addedRole]) {
                id<OMembership> membership = [_origo membershipForMember:viewController.returnData];
                [membership addRole:_addedRole ofType:kRoleTypeMemberRole];
                
                [[OMeta m].replicator replicate];
                [self reloadSectionWithKey:kSectionKeyValues];
            }
        }
    }
}


#pragma mark - UIAlertViewDelegateConformance

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertTagMemberRole:
            if (buttonIndex == kButtonIndexOK) {
                _addedRole = [alertView textFieldAtIndex:0].text;
                
                [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:_addedRole meta:[_origo regulars]];
            }
            
            break;
            
        default:
            break;
    }
}

@end
