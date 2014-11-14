//
//  OOrigoListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OOrigoListViewController.h"

static NSInteger const kActionSheetTagEditParents = 0;
static NSInteger const kButtonTagEditParentsYes = 0;

static NSInteger const kActionSheetTagOrigoType = 1;

static NSInteger const kSectionKeyHouseholds = 0;
static NSInteger const kSectionKeyOrigos = 1;
static NSInteger const kSectionKeyWards = 2;


@interface OOrigoListViewController () <OTableViewController, UIActionSheetDelegate> {
@private
    id<OMember> _member;
    
    BOOL _needsEditParents;
    NSMutableArray *_origoTypes;
}

@end


@implementation OOrigoListViewController

#pragma mark - Auxiliary methods

- (void)assembleOrigoTypes
{
    if ([_member isJuvenile]) {
        if (![_member isOlderThan:kAgeThresholdInSchool]) {
            [_origoTypes addObject:kOrigoTypePreschoolClass];
        }
        
        [_origoTypes addObject:kOrigoTypeSchoolClass];
        [_origoTypes addObject:kOrigoTypeTeam];
    } else {
        [_origoTypes addObject:kOrigoTypeCommunity];
        [_origoTypes addObject:kOrigoTypeOrganisation];
        [_origoTypes addObject:kOrigoTypeTeam];
        [_origoTypes addObject:kOrigoTypeStudyGroup];
        [_origoTypes addObject:kOrigoTypeAlumni];
    }
    
    [_origoTypes addObject:kOrigoTypeGeneral];
    [_origoTypes addObject:kOrigoTypeFriends];
}


#pragma mark - Selector implementations

- (void)openSettings
{
    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetSettings];
}


- (void)performAddAction
{
    NSString *prompt = NSLocalizedString(@"What sort of group du you want to create", @"");
    
    if ([self targetIs:kTargetWard]) {
        prompt = [prompt stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"for %@", @""), [_member givenName]] separator:kSeparatorSpace];
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:[prompt stringByAppendingString:@"?"] delegate:self tag:kActionSheetTagOrigoType];
    
    for (NSString *origoType in _origoTypes) {
        [actionSheet addButtonWithTitle:NSLocalizedString(origoType, kStringPrefixOrigoTitle)];
    }
    
    [actionSheet show];
}


#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (_needsEditParents) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:NSLocalizedString(@"Your household includes minors. Would you like to provide parent relations?", @"") delegate:self tag:kActionSheetTagEditParents];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Yes", @"") tag:kButtonTagEditParentsYes];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"No", @"")];
        
        [actionSheet show];
    } else if ([[OMeta m] userIsSignedIn] && ![[OMeta m] userIsRegistered]) {
        if (![[OMeta m].user.createdBy isEqualToString:[OMeta m].userEmail]) {
            [OAlert showAlertWithTitle:NSLocalizedString(@"Welcome to Origo", @"") text:NSLocalizedString(@"Please verify your details and provide any missing information.", @"")];
            
            for (id<OMember> ward in [[OMeta m].user wards]) {
                _needsEditParents = _needsEditParents || ![ward mother] || ![ward father];
            }
        } else if (![OMeta m].userDidJustSignUp) {
            [OAlert showAlertWithTitle:NSLocalizedString(@"Incomplete registration", @"") text:NSLocalizedString(@"You must complete your registration before you can start using Origo.", @"")];
        }
        
        [self presentModalViewControllerWithIdentifier:kIdentifierMember target:[OMeta m].user];
    }
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    _member = [self.entity proxy];
    _origoTypes = [NSMutableArray array];
    
    self.title = [OMeta m].appName;
    [self setSubtitle:_member.name];
    
    if ([_member isUser]) {
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem settingsButtonWithTarget:self];
    } else {
        self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:[_member givenName]];
    }
    
    if ([[OMeta m].user isTeenOrOlder]) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];

        [self assembleOrigoTypes];
    }
}


- (void)loadData
{
    if (_member) {
        if ([_member isUser]) {
            [self setData:[_member residences] forSectionWithKey:kSectionKeyHouseholds];
            [self setData:[_member wards] forSectionWithKey:kSectionKeyWards];
        }
        
        [self setData:[_member origos] forSectionWithKey:kSectionKeyOrigos];
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    id entity = [self dataAtIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyWards) {
        id<OMember> ward = entity;
        
        cell.textLabel.text = [ward givenName];
        [cell loadImageForMember:ward];
        cell.destinationId = kIdentifierOrigoList;
        
        NSArray *origos = [ward origos];
        
        if ([origos count]) {
            NSMutableArray *origoNames = [NSMutableArray array];
            
            for (id<OOrigo> origo in origos) {
                [origoNames addObject:origo.name];
            }
            
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfStrings:origoNames conjoin:NO];
            cell.detailTextLabel.textColor = [UIColor textColour];
        } else {
            cell.detailTextLabel.text = NSLocalizedString(@"(No groups)", @"");
            cell.detailTextLabel.textColor = [UIColor tonedDownTextColour];
        }
    } else {
        id<OOrigo> origo = entity;
        id<OMembership> membership = [origo membershipForMember:_member];
        
        [cell loadImageForOrigo:origo];
        cell.destinationId = kIdentifierOrigo;
        
        if ([_member isUser] && ([origo userIsOrganiser] || [origo userIsParentContact])) {
            cell.textLabel.text = [NSString stringWithFormat:@"%@, %@", origo.name, origo.descriptionText];
            cell.detailTextLabel.text = [[OUtil commaSeparatedListOfStrings:[membership roles] conjoin:NO conditionallyLowercase:YES] stringByCapitalisingFirstLetter];
        } else {
            cell.textLabel.text = origo.name;
        
            if ([membership.status isEqualToString:kMembershipStatusInvited]) {
                cell.detailTextLabel.text = NSLocalizedString(@"New listing", @"");
                cell.detailTextLabel.textColor = [UIColor notificationTextColour];
            } else {
                if ([origo isOfType:kOrigoTypeResidence]) {
                    cell.detailTextLabel.text = [origo singleLineAddress];
                } else {
                    cell.detailTextLabel.text = origo.descriptionText;
                }
                
                cell.detailTextLabel.textColor = [UIColor textColour];
            }
        }
    }
}


- (id)defaultTarget
{
    return [[OMeta m] userIsSignedIn] ? [OMeta m].user : nil;
}


- (id)headerContentForSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kSectionKeyWards) {
        text = NSLocalizedString(@"The kids' groups", @"");
    } else if (sectionKey == kSectionKeyOrigos) {
        text = [[OLanguage possessiveClauseWithPossessor:_member noun:_group_] stringByCapitalisingFirstLetter];
    }
    
    return text;
}


- (BOOL)canDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDelete = NO;
    
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyOrigos) {
        id<OOrigo> origo = [self dataAtIndexPath:indexPath];
        
        if ([origo userCanEdit]) {
            NSArray *members = [origo members];
            
            if ([members count] == 1) {
                canDelete = [members[0] isUser] || [members[0] isWardOfUser];
            }
        }
    }
    
    return canDelete;
}


- (void)didDismissModalViewController:(OTableViewController *)viewController
{
    if ([[OMeta m] userIsSignedIn]) {
        [self reloadSections];
    }
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex < actionSheet.cancelButtonIndex) {
        switch (actionSheet.tag) {
            case kActionSheetTagEditParents:
                if ([actionSheet tagForButtonIndex:buttonIndex] == kButtonTagEditParentsYes) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetParents];
                }
                
                _needsEditParents = NO;
                
                break;
                
            case kActionSheetTagOrigoType:
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:_origoTypes[buttonIndex]];
                
                break;
                
            default:
                break;
        }
    }
}

@end
