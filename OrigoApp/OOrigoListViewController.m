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

static NSInteger const kActionSheetTagNewOrigoParticipant = 1;
static NSInteger const kButtonTagNewOrigoParticipantUser = 0;

static NSInteger const kActionSheetTagOrigoType = 2;

static NSInteger const kSectionKeyHouseholds = 0;
static NSInteger const kSectionKeyOrigos = 1;
static NSInteger const kSectionKeyWards = 2;


@interface OOrigoListViewController () <OTableViewController, UIActionSheetDelegate> {
@private
    id<OMember> _member;
    
    NSArray *_wards;
    NSMutableArray *_origoTypes;
    
    BOOL _needsEditParents;
}

@end


@implementation OOrigoListViewController

#pragma mark - Auxiliary methods

- (void)assembleOrigoTypes
{
    _origoTypes = [NSMutableArray array];
    
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


- (void)presentAddOrigoSheet
{
    [self assembleOrigoTypes];
    
    NSString *prompt = NSLocalizedString(@"What sort of list du you want to create", @"");
    
    if ([_member isWardOfUser]) {
        prompt = [prompt stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"for %@", @""), [_member givenName]] separator:kSeparatorSpace];
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:[prompt stringByAppendingString:@"?"] delegate:self tag:kActionSheetTagOrigoType];
    
    for (NSString *origoType in _origoTypes) {
        [actionSheet addButtonWithTitle:NSLocalizedString(origoType, kStringPrefixOrigoTitle)];
    }
    
    [actionSheet show];
}


#pragma mark - Selector implementations

- (void)didSelectHeaderSegment
{
    self.selectedHeaderSegment = self.segmentedHeader.selectedSegmentIndex;
    
    [self reloadSectionWithKey:kSectionKeyWards];
}


- (void)openSettings
{
    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetSettings];
}


- (void)performAddAction
{
    if ([_wards count]) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:NSLocalizedString(@"Who will be included in the new list?", @"") delegate:self tag:kActionSheetTagNewOrigoParticipant];
        [actionSheet addButtonWithTitle:[[OLanguage pronouns][_you_][nominative] stringByCapitalisingFirstLetter] tag:kButtonTagNewOrigoParticipantUser];
        
        for (id<OMember> ward in _wards) {
            [actionSheet addButtonWithTitle:[ward givenName]];
        }
        
        [actionSheet show];
    } else {
        [self presentAddOrigoSheet];
    }
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
    self.title = [OMeta m].appName;
    [self setSubtitle:[OMeta m].user.name];
    
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem settingsButtonWithTarget:self];
    
    if ([[OMeta m].user isTeenOrOlder]) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
    }
}


- (void)loadData
{
    if (_member) {
        _wards = [[OMeta m].user wards];
        
        [self setData:[[OMeta m].user residences] forSectionWithKey:kSectionKeyHouseholds];
        [self setData:[_wards[self.selectedHeaderSegment] origos] forSectionWithKey:kSectionKeyWards];
        [self setData:[[OMeta m].user origos] forSectionWithKey:kSectionKeyOrigos];
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    id<OOrigo> origo = [self dataAtIndexPath:indexPath];
    id<OMember> member = sectionKey == kSectionKeyWards ? _wards[self.selectedHeaderSegment] : [OMeta m].user;
    id<OMembership> membership = [origo membershipForMember:member];
    
    cell.textLabel.text = origo.name;
    [cell loadImageForOrigo:origo];
    cell.destinationId = kIdentifierOrigo;
    
    BOOL userIsOrigoElder = [origo userIsOrganiser] || [origo userIsParentContact];
    
    if (userIsOrigoElder && sectionKey == kSectionKeyOrigos) {
        cell.detailTextLabel.text = [[OUtil commaSeparatedListOfStrings:[membership roles] conjoin:NO conditionallyLowercase:YES] stringByCapitalisingFirstLetter];
    } else {
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


- (void)didSetEntity:(id)entity
{
    _member = entity;
}


- (id)defaultTarget
{
    return [[OMeta m] userIsSignedIn] ? [OMeta m].user : nil;
}


- (id)headerContentForSectionWithKey:(NSInteger)sectionKey
{
    id headerContent = nil;
    
    if (sectionKey == kSectionKeyWards) {
        if ([_wards count] > 1) {
            NSMutableArray *wardGivenNames = [NSMutableArray array];
            
            for (id<OMember> ward in _wards) {
                [wardGivenNames addObject:[ward givenName]];
            }
            
            headerContent = wardGivenNames;
        } else {
            headerContent = [_wards[0] givenName];
        }
    } else if (sectionKey == kSectionKeyOrigos) {
        headerContent = NSLocalizedString(@"My lists", @"");
    }
    
    return headerContent;
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyWards) {
        self.target = _wards[self.selectedHeaderSegment];
    } else if (self.target != [OMeta m].user) {
        self.target = [OMeta m].user;
    }
}


- (BOOL)canDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDelete = NO;
    
    if ([self sectionKeyForIndexPath:indexPath] != kSectionKeyHouseholds) {
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

- (void)actionSheet:(OActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
        
        switch (actionSheet.tag) {
            case kActionSheetTagNewOrigoParticipant:
                if (buttonTag == kButtonTagNewOrigoParticipantUser) {
                    self.target = [OMeta m].user;
                } else {
                    NSInteger selectedWardIndex = buttonIndex - 1;
                    
                    if ([_wards count] > 1 && self.selectedHeaderSegment != selectedWardIndex) {
                        self.selectedHeaderSegment = selectedWardIndex;
                        [self reloadSectionWithKey:kSectionKeyWards];
                    }
                    
                    self.target = _wards[selectedWardIndex];
                }
                
                break;
                
            default:
                break;
        }
    }
}


- (void)actionSheet:(OActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
        
        switch (actionSheet.tag) {
            case kActionSheetTagEditParents:
                if (buttonTag == kButtonTagEditParentsYes) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetParents];
                }
                
                _needsEditParents = NO;
                
                break;
                
            case kActionSheetTagNewOrigoParticipant:
                [self presentAddOrigoSheet];
                
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
