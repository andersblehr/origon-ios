//
//  OOrigoListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OOrigoListViewController.h"

static NSInteger const kActionSheetTagOrigoType = 1;

static NSInteger const kSectionKeyMember = 0;
static NSInteger const kSectionKeyOrigos = 1;
static NSInteger const kSectionKeyWards = 2;


@interface OOrigoListViewController () <OTableViewController, UIActionSheetDelegate> {
@private
    id<OMember> _member;
    
    NSMutableArray *_origoTypes;
}

@end


@implementation OOrigoListViewController

#pragma mark - Auxiliary methods

- (NSString *)footerText
{
    NSString *footerText = nil;
    
    if ([self hasSectionWithKey:kSectionKeyOrigos]) {
        footerText = NSLocalizedString(@"Tap [+] to create a new group", @"");
    } else {
        footerText = NSLocalizedString(@"Tap [+] to create a group", @"");
    }
    
    if ([self targetIs:kTargetUser] && [self hasSectionWithKey:kSectionKeyWards]) {
        NSString *yourChild = nil;
        NSString *himOrHer = nil;
        
        BOOL allMale = YES;
        BOOL allFemale = YES;
        
        if ([[_member wards] count] == 1) {
            yourChild = [[[_member wards] anyObject] givenName];
        } else {
            yourChild = NSLocalizedString(@"your child", @"");
        }
        
        for (id<OMember> ward in [_member wards]) {
            allMale = allMale && [ward isMale];
            allFemale = allFemale && ![ward isMale];
        }
        
        if (allMale) {
            himOrHer = [OLanguage pronouns][_he_][accusative];
        } else if (allFemale) {
            himOrHer = [OLanguage pronouns][_she_][accusative];
        } else {
            himOrHer = NSLocalizedString(@"him or her", @"");
        }
        
        footerText = [footerText stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"... for yourself. Select %@ to create a group for %@", @""), yourChild, himOrHer] separator:kSeparatorSpace];
    } else if ([self targetIs:kTargetWard]) {
        footerText = [footerText stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"for %@", @""), [_member givenName]] separator:kSeparatorSpace];
    }
    
    return [footerText stringByAppendingString:@"."];
}


#pragma mark - Selector implementations

- (void)openSettings
{
    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetSettings];
}


- (void)addItem
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

    if ([[OMeta m] userIsSignedIn] && ![[OMeta m] userIsRegistered]) {
        if (![[OMeta m].user.createdBy isEqualToString:[OMeta m].user.entityId]) {
            id<OMember> creator = [[OMeta m].context entityWithId:[OMeta m].user.createdBy];
            
            [OAlert showAlertWithTitle:NSLocalizedString(@"Welcome to Origo", @"") text:[NSString stringWithFormat:NSLocalizedString(@"Please verify your details and provide the information that %@ was not authorised to enter when %@ invited you.", @""), [creator givenName], [creator pronoun][nominative]]];
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
    
    if ([_member isUser]) {
        self.title = [OMeta m].appName;
        [self.navigationItem setTitle:[OMeta m].appName withSubtitle:[OMeta m].user.name];
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem settingsButtonWithTarget:self];
    } else {
        self.title = [_member givenName];
    }
    
    if ([[OMeta m].user isTeenOrOlder]) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
        
        if ([_member isJuvenile]) {
            if (![_member isOlderThan:kAgeThresholdInSchool]) {
                [_origoTypes addObject:kOrigoTypePreschoolClass];
            }
            
            [_origoTypes addObject:kOrigoTypeSchoolClass];
        }
        
        [_origoTypes addObject:kOrigoTypeFriends];
        [_origoTypes addObject:kOrigoTypeTeam];
        
        if (![_member isJuvenile]) {
            [_origoTypes addObject:kOrigoTypeOrganisation];
            [_origoTypes addObject:kOrigoTypeOther];
        }
    }
}


- (void)loadData
{
    if (_member) {
        [self setData:[_member origosIncludeResidences:NO] forSectionWithKey:kSectionKeyOrigos];
        
        if ([_member isUser]) {
            [self setData:[_member residences] forSectionWithKey:kSectionKeyMember];
            [self setData:[_member wards] forSectionWithKey:kSectionKeyWards];
        } else {
            [self setData:@[_member] forSectionWithKey:kSectionKeyMember];
        }
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    id entity = [self dataAtIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyMember) {
        if ([_member isUser]) {
            id<OOrigo> residence = entity;
            
            cell.textLabel.text = residence.name;
            cell.detailTextLabel.text = [residence singleLineAddress];
            cell.imageView.image = [OUtil smallImageForOrigo:residence];
            cell.destinationId = kIdentifierOrigo;
        } else {
            id<OMember> member = entity;
            
            cell.textLabel.text = member.name;
            cell.detailTextLabel.text = [OUtil contactInfoForMember:member];
            cell.imageView.image = [OUtil smallImageForMember:member];
            cell.destinationId = kIdentifierMember;
        }
    } else if (sectionKey == kSectionKeyWards) {
        id<OMember> ward = entity;
        
        cell.textLabel.text = [ward givenName];
        cell.imageView.image = [OUtil smallImageForMember:ward];
        cell.destinationId = kIdentifierOrigoList;
        
        NSArray *origos = [ward origosIncludeResidences:NO];
        
        if ([origos count]) {
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfItems:origos conjoinLastItem:NO];
            cell.detailTextLabel.textColor = [UIColor textColour];
        } else {
            cell.detailTextLabel.text = NSLocalizedString(@"(No groups)", @"");
            cell.detailTextLabel.textColor = [UIColor dimmedTextColour];
        }
    } else if (sectionKey == kSectionKeyOrigos) {
        id<OOrigo> origo = entity;
        
        cell.textLabel.text = origo.name;
        cell.imageView.image = [OUtil smallImageForOrigo:origo];
        cell.destinationId = kIdentifierOrigo;
        
        if ([[origo membershipForMember:[OMeta m].user] isInvited]) {
            cell.detailTextLabel.text = NSLocalizedString(@"New listing", @"");
            cell.detailTextLabel.textColor = [UIColor notificationTextColour];
        } else {
            cell.detailTextLabel.text = NSLocalizedString(origo.type, kStringPrefixOrigoTitle);
            cell.detailTextLabel.textColor = [UIColor textColour];
        }
    }
}


- (id)defaultTarget
{
    return [[OMeta m] userIsSignedIn] ? [OMeta m].user : nil;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return ([self isBottomSectionKey:sectionKey] && [[OMeta m].user isTeenOrOlder]);
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kSectionKeyWards) {
        text = NSLocalizedString(@"The kids' groups", @"");
    } else if (sectionKey == kSectionKeyOrigos) {
        text = [[OLanguage possessiveClauseWithPossessor:_member noun:_group_] stringByCapitalisingFirstLetter];
    }
    
    return text;
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    return [self footerText];
}


- (NSString *)sortKeyForSectionWithKey:(NSInteger)sectionKey
{
    NSString *relationshipKey = (sectionKey == kSectionKeyWards) ? nil : kRelationshipKeyOrigo;
    
    return [OUtil sortKeyWithPropertyKey:kPropertyKeyName relationshipKey:relationshipKey];
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
            case kActionSheetTagOrigoType:
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:_origoTypes[buttonIndex]];
                
                break;
                
            default:
                break;
        }
    }
}

@end
