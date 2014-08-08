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

static NSInteger const kSectionKeyRoles = 0;
static NSInteger const kSectionKeyAddRole = 1;

static NSInteger const kAlertTagMemberRole = 0;
static NSInteger const kButtonIndexOK = 1;


@interface OValueListViewController () <OTableViewController> {
    id<OOrigo> _origo;
    id<OMember> _roleOwner;
}

@end


@implementation OValueListViewController

- (void)presentMemberRoleDialogue
{
    NSString *message = nil;
    
    if ([_roleOwner isUser]) {
        message = NSLocalizedString(@"What is your role?", @"");
    } else {
        message = [NSString stringWithFormat:NSLocalizedString(@"What is %@'s role?", @""), [_roleOwner givenName]];
    }
    
    UIAlertView *dialogueView = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
    dialogueView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [dialogueView textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
    [dialogueView textFieldAtIndex:0].placeholder = NSLocalizedString(@"Contact role", @"");
    dialogueView.tag = kAlertTagMemberRole;
    
    [dialogueView show];
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    if ([self targetIs:kTargetSettings]) {
        self.title = NSLocalizedString(@"Settings", @"");
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
    } else if ([self targetIs:kTargetRoles]) {
        _origo = self.meta;
        
        self.title = NSLocalizedString(_origo.type, kStringPrefixRolesTitle);
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTarget:self];
    }
}


- (void)loadData
{
    if ([self targetIs:kTargetSettings]) {
        [self setData:[[OSettings settings] settingKeys] forSectionWithKey:kSectionKeyValues];
        [self setData:@[kCustomData] forSectionWithKey:kSectionKeySignOut];
    } else if ([self targetIs:kTargetRoles]) {
        [self setData:[_origo memberContacts] forSectionWithKey:kSectionKeyRoles];
        [self setData:kCustomData forSectionWithKey:kSectionKeyAddRole];
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
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.textColor = [UIColor redColor];
            cell.textLabel.text = [NSLocalizedString(@"Log out", @"") stringByAppendingString:[OMeta m].user.name separator:kSeparatorSpace];
        }
    } else if ([self targetIs:kTargetRoles]) {
        if (sectionKey == kSectionKeyRoles) {
            id<OMembership> membership = [_origo membershipForMember:[self dataAtIndexPath:indexPath]];
            
            cell.textLabel.text = [membership memberRoles][0];
            cell.detailTextLabel.text = [membership.member publicName];
        } else if (sectionKey == kSectionKeyAddRole) {
            cell.textLabel.text = NSLocalizedString(@"Add role", @"");
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
    } else if ([self targetIs:kTargetRoles]) {
        if (sectionKey == kSectionKeyRoles) {
            
        } else if (sectionKey == kSectionKeyAddRole) {
            [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:kTargetRole meta:_origo];
        }
    }
}


- (void)didDismissModalViewController:(OTableViewController *)viewController
{
    if (!viewController.didCancel) {
        if ([viewController.identifier isEqualToString:kIdentifierValuePicker]) {
            if ([viewController targetIs:kTargetRole]) {
                _roleOwner = viewController.returnData;
                
                [self presentMemberRoleDialogue];
            }
        }
    }
}


#pragma mark - UIAlertViewDelegateConformance

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertTagMemberRole:
            if (buttonIndex == kButtonIndexOK) {
                id<OMembership> membership = [_origo membershipForMember:_roleOwner];
                [membership addRole:[alertView textFieldAtIndex:0].text ofType:kRoleTypeMemberContact];
                
                [[OMeta m].replicator replicate];
                [self reloadSectionWithKey:kSectionKeyRoles];
            }
            
            break;
            
        default:
            break;
    }
}

@end
