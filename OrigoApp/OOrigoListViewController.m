//
//  OOrigoListViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
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
        footerText = [OStrings stringForKey:strFooterOrigoCreation];
    } else {
        footerText = [OStrings stringForKey:strFooterOrigoCreationFirst];
    }
    
    if ([self targetIs:kTargetUser] && [self hasSectionWithKey:kSectionKeyWards]) {
        NSString *yourChild = nil;
        NSString *himOrHer = nil;
        
        BOOL allMale = YES;
        BOOL allFemale = YES;
        
        if ([[_member wards] count] == 1) {
            yourChild = [[self dataInSectionWithKey:kSectionKeyWards][0] givenName];
        } else {
            yourChild = [OStrings stringForKey:strTermYourChild];
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
            himOrHer = [OStrings stringForKey:strTermHimOrHer];
        }
        
        NSString *wardsAddendum = [NSString stringWithFormat:[OStrings stringForKey:strFooterOrigoCreationWards], yourChild, himOrHer];
        footerText = [NSString stringWithFormat:@"%@ %@.", footerText, wardsAddendum];
    } else if ([self targetIs:kTargetUser]) {
        footerText = [footerText stringByAppendingString:@"."];
    } else if ([self targetIs:kTargetWard]) {
        NSString *forWardName = [NSString stringWithFormat:[OStrings stringForKey:strTermForName], [_member givenName]];
        footerText = [NSString stringWithFormat:@"%@ %@.", footerText, forWardName];
    }
    
    return footerText;
}


#pragma mark - Action sheets & alerts

- (void)presentListedUserAlert
{
    OMember *creator = [[OMeta m].context entityWithId:[OMeta m].user.createdBy];
    
    NSString *alertText = [NSString stringWithFormat:[OStrings stringForKey:strAlertTextListedUserRegistration], [creator givenName], [creator pronoun][nominative]];
    
    [OAlert showAlertWithTitle:[OStrings stringForKey:strAlertTitleListedUserRegistration] text:alertText];
}


#pragma mark - Selector implementations

- (void)openSettings
{
    [self presentModalViewControllerWithIdentifier:kIdentifierValueList data:nil];
}


- (void)addItem
{
    NSString *prompt = [OStrings stringForKey:strSheetPromptOrigoType];
    
    if ([self targetIs:kTargetUser]) {
        prompt = [prompt stringByAppendingString:@"?"];
    } else if ([self targetIs:kTargetWard]) {
        NSString *forWardName = [NSString stringWithFormat:[OStrings stringForKey:strTermForName], [_member givenName]];
        prompt = [NSString stringWithFormat:@"%@ %@?", prompt, forWardName];
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagOrigoType];
    
    for (NSString *origoType in _origoTypes) {
        [actionSheet addButtonWithTitle:[OStrings stringForKey:origoType withKeyPrefix:kKeyPrefixOrigoTitle]];
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
            [OAlert showAlertWithTitle:[OStrings stringForKey:strAlertTitleIncompleteRegistration] text:[OStrings stringForKey:strAlertTextIncompleteRegistration]];
        }
        
        [self presentModalViewControllerWithIdentifier:kIdentifierMember data:[[OMeta m].user initialResidency]];
    }
}


#pragma mark - UIViewController overrides

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self prepareForPushSegue:segue];
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialiseState
{
    _member = self.data ? self.data : [OMeta m].user;
    _origoTypes = [NSMutableArray array];
    
    self.state.target = _member;
    
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


- (void)initialiseData
{
    if (_member) {
        [self setData:[_member participancies] forSectionWithKey:kSectionKeyOrigos];
        
        if ([_member isUser]) {
            [self setData:[_member residencies] forSectionWithKey:kSectionKeyMember];
            [self setData:[_member wards] forSectionWithKey:kSectionKeyWards];
        } else {
            [self setData:@[_member] forSectionWithKey:kSectionKeyMember];
        }
    }
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return ([self isLastSectionKey:sectionKey] && [[OMeta m].user isTeenOrOlder]);
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kSectionKeyWards) {
        text = [OStrings stringForKey:strHeaderWardsOrigos];
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
        origoListViewController.data = [self dataAtIndexPath:indexPath];
        origoListViewController.observer = (OTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        
        [self.navigationController pushViewController:origoListViewController animated:YES];
    } else {
        [self performSegueWithIdentifier:kSegueToOrigoView sender:self];
    }
}


- (void)didDismissModalViewController:(OTableViewController *)viewController
{
    if ([[OMeta m] userIsSignedIn]) {
        [self.tableView reloadData];
    }
}


#pragma mark - OTableViewListDelegate conformance

- (NSString *)sortKeyForSectionWithKey:(NSInteger)sectionKey
{
    NSString *relationshipKey = (sectionKey == kSectionKeyWards) ? nil : kRelationshipKeyOrigo;
    
    return [OUtil sortKeyWithPropertyKey:kPropertyKeyName relationshipKey:relationshipKey];
}


- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    OReplicatedEntity *entity = [self dataAtIndexPath:indexPath];
    
    if ((sectionKey == kSectionKeyMember) && ![_member isUser]) {
        OMember *member = [entity asMember];

        cell.textLabel.text = member.name;
        cell.detailTextLabel.text = [member shortDetails];
        cell.imageView.image = [member smallImage];
    } else if (sectionKey == kSectionKeyWards) {
        OMember *ward = [entity asMember];
        
        cell.textLabel.text = [ward givenName];
        cell.imageView.image = [ward smallImage];
        
        NSArray *sortedOrigos = [ward sortedOrigos];
        
        if ([sortedOrigos count]) {
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfItems:sortedOrigos conjoinLastItem:NO];
        } else {
            cell.detailTextLabel.text = [OStrings stringForKey:strTextNoOrigos];
        }
    } else {
        OMembership *membership = [entity asMembership];
        
        cell.textLabel.text = [membership.origo displayName];
        cell.imageView.image = [membership.origo smallImage];
        
        if (sectionKey == kSectionKeyMember) {
            cell.detailTextLabel.text = [membership.origo singleLineAddress];
        } else {
            cell.detailTextLabel.text = [OStrings stringForKey:membership.origo.type withKeyPrefix:kKeyPrefixOrigoTitle];
        }
    }
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex < actionSheet.cancelButtonIndex) {
        switch (actionSheet.tag) {
            case kActionSheetTagOrigoType:
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo data:_member meta:_origoTypes[buttonIndex]];
                
                break;
                
            default:
                break;
        }
    }
}

@end
