//
//  OOrigoListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OOrigoListViewController.h"

static NSString * const kSegueToOrigoView = @"segueFromOrigoListToOrigoView";
static NSString * const kSegueToMemberView = @"segueFromOrigoListToMemberView";

static NSInteger const kActionSheetTagOrigoType = 1;

static NSInteger const kSectionKeyMember = 0;
static NSInteger const kSectionKeyOrigos = 1;
static NSInteger const kSectionKeyWards = 2;


@implementation OOrigoListViewController

#pragma mark - Auxiliary methods

- (NSString *)footerText
{
    NSString *footerText = nil;
    
    if ([self hasSectionWithKey:kSectionKeyOrigos]) {
        footerText = NSLocalizedString(@"Tap [+] to create a new origo", @"");
    } else {
        footerText = NSLocalizedString(@"Tap [+] to create an origo", @"");
    }
    
    if ([self targetIs:kTargetUser] && [self hasSectionWithKey:kSectionKeyWards]) {
        NSString *yourChild = nil;
        NSString *himOrHer = nil;
        
        BOOL allMale = YES;
        BOOL allFemale = YES;
        
        if ([[_member wards] count] == 1) {
            yourChild = [[self dataInSectionWithKey:kSectionKeyWards][0] givenName];
        } else {
            yourChild = NSLocalizedString(@"your child", @"");
        }
        
        for (OMember *ward in [_member wards]) {
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
        
        footerText = [footerText stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"... for yourself. Select %@ to create an origo for %@", @""), yourChild, himOrHer] separator:kSeparatorSpace];
    } else if ([self targetIs:kTargetWard]) {
        footerText = [footerText stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"for %@", @""), [_member givenName]] separator:kSeparatorSpace];
    }
    
    return [footerText stringByAppendingString:@"."];
}


#pragma mark - Action sheets & alerts

- (void)presentListedUserAlert
{
    OMember *creator = [[OMeta m].context entityWithId:[OMeta m].user.createdBy];
    
    [OAlert showAlertWithTitle:NSLocalizedString(@"Welcome to Origo", @"") text:[NSString stringWithFormat:NSLocalizedString(@"Please verify your details and provide the information that %@ was not authorised to enter when %@ invited you.", @""), [creator givenName], [creator pronoun][nominative]]];
}


#pragma mark - Selector implementations

- (void)openSettings
{
    [self presentModalViewControllerWithIdentifier:kIdentifierValueList target:kTargetSettings];
}


- (void)addItem
{
    NSString *prompt = NSLocalizedString(@"What sort of origo du you want to create", @"");
    
    if ([self targetIs:kTargetWard]) {
        prompt = [prompt stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"for %@", @""), [_member givenName]] separator:kSeparatorSpace];
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:[prompt stringByAppendingString:@"?"] delegate:self tag:kActionSheetTagOrigoType];
    
    for (NSString *origoType in _origoTypes) {
        [actionSheet addButtonWithTitle:NSLocalizedString(origoType, kKeyPrefixOrigoTitle)];
    }
    
    [actionSheet show];
}


#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if ([[OMeta m] userIsSignedIn] && ![[OMeta m] userIsRegistered]) {
        if (![[OMeta m].user.createdBy isEqualToString:[OMeta m].user.entityId]) {
            [self presentListedUserAlert];
        } else if (![OMeta m].userDidJustSignUp) {
            [OAlert showAlertWithTitle:NSLocalizedString(@"Incomplete registration", @"") text:NSLocalizedString(@"You must complete your registration before you can start using Origo.", @"")];
        }
        
        [self presentModalViewControllerWithIdentifier:kIdentifierMember target:[OMeta m].user];
    }
}


#pragma mark - UIViewController overrides

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self prepareForPushSegue:segue];
}


#pragma mark - OTableViewControllerInstance conformance

- (void)loadState
{
    _member = [self.entityProxy facade];
    _origoTypes = [NSMutableArray array];
    
    if ([_member isUser]) {
        self.title = [OMeta m].appName;
        [self.navigationItem setTitle:[OMeta m].appName withSubtitle:[OMeta m].user.name];
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem settingsButton];
    } else {
        self.title = [_member givenName];
    }
    
    if ([[OMeta m].user isTeenOrOlder]) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButton];
        
        if ([[OState s].pivotMember isJuvenile]) {
            if (![_member isOlderThan:kAgeThresholdInSchool]) {
                [_origoTypes addObject:kOrigoTypePreschoolClass];
            }
            
            [_origoTypes addObject:kOrigoTypeSchoolClass];
        }
        
        [_origoTypes addObject:kOrigoTypeFriends];
        [_origoTypes addObject:kOrigoTypeTeam];
        
        if (![[OState s].pivotMember isJuvenile]) {
            [_origoTypes addObject:kOrigoTypeOrganisation];
            [_origoTypes addObject:kOrigoTypeOther];
        }
    }
}


- (void)loadData
{
    if (_member) {
        [self setData:[_member origos] forSectionWithKey:kSectionKeyOrigos];
        
        if ([_member isUser]) {
            [self setData:[_member residences] forSectionWithKey:kSectionKeyMember];
            [self setData:[_member wards] forSectionWithKey:kSectionKeyWards];
        } else {
            [self setData:@[_member] forSectionWithKey:kSectionKeyMember];
        }
    }
}


- (id)defaultTarget
{
    return [[OMeta m] userIsSignedIn] ? [OMeta m].user : nil;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return ([self isLastSectionKey:sectionKey] && [[OMeta m].user isTeenOrOlder]);
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kSectionKeyWards) {
        text = NSLocalizedString(@"The kids' origos", @"");
    } else if (sectionKey == kSectionKeyOrigos) {
        text = [[OLanguage possessiveClauseWithPossessor:_member noun:_origo_] stringByCapitalisingFirstLetter];
    }
    
    return text;
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    return [self footerText];
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if ((sectionKey == kSectionKeyMember) && ![_member isUser]) {
        [self performSegueWithIdentifier:kSegueToMemberView sender:self];
    } else if (sectionKey == kSectionKeyWards) {
        OOrigoListViewController *origoListViewController = [self.storyboard instantiateViewControllerWithIdentifier:kIdentifierOrigoList];
        origoListViewController.target = [self dataAtIndexPath:indexPath];
        origoListViewController.observer = (OTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        
        [self.navigationController pushViewController:origoListViewController animated:YES];
    } else {
        [self performSegueWithIdentifier:kSegueToOrigoView sender:self];
    }
}


- (void)didDismissModalViewController:(OTableViewController *)viewController
{
    if ([[OMeta m] userIsSignedIn]) {
        [self reloadSections];
    }
}


#pragma mark - OTableViewListDelegate conformance

- (NSString *)sortKeyForSectionWithKey:(NSInteger)sectionKey
{
    NSString *relationshipKey = (sectionKey == kSectionKeyWards) ? nil : kRelationshipKeyOrigo;
    
    return [OUtil sortKeyWithPropertyKey:kPropertyKeyName relationshipKey:relationshipKey];
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    id entity = [self dataAtIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyMember) {
        if ([_member isUser]) {
            OOrigo *residence = entity;
            
            cell.textLabel.text = [residence displayName];
            cell.detailTextLabel.text = [residence singleLineAddress];
            cell.imageView.image = [residence smallImage];
        } else {
            OMember *member = entity;
            
            cell.textLabel.text = member.name;
            cell.detailTextLabel.text = [member shortDetails];
            cell.imageView.image = [member smallImage];
        }
    } else if (sectionKey == kSectionKeyWards) {
        OMember *ward = entity;
        
        cell.textLabel.text = [ward givenName];
        cell.imageView.image = [ward smallImage];
        
        NSArray *origos = [ward origos];
        
        if ([origos count]) {
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfItems:origos conjoinLastItem:NO];
            cell.detailTextLabel.textColor = [UIColor textColour];
        } else {
            cell.detailTextLabel.text = NSLocalizedString(@"(No origos)", @"");
            cell.detailTextLabel.textColor = [UIColor dimmedTextColour];
        }
    } else if (sectionKey == kSectionKeyOrigos) {
        OOrigo *origo = entity;

        cell.textLabel.text = [origo displayName];
        cell.imageView.image = [origo smallImage];
        
        if ([[origo membershipForMember:[OMeta m].user] isInvited]) {
            cell.detailTextLabel.text = NSLocalizedString(@"New listing", @"");
            cell.detailTextLabel.textColor = [UIColor notificationTextColour];
        } else {
            cell.detailTextLabel.text = NSLocalizedString(origo.type, kKeyPrefixOrigoTitle);
            cell.detailTextLabel.textColor = [UIColor textColour];
        }
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
