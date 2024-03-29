//
//  ORecipientPickerViewController.m
//  Origon
//
//  Created by Anders Blehr on 11/12/14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "ORecipientPickerViewController.h"

static NSInteger const kTitleSegmentFavourites = 0;
static NSInteger const kTitleSegmentOthers = 1;

static NSInteger const kCellCheckedStateNone = 0;
static NSInteger const kCellCheckedStateTo = 1;
static NSInteger const kCellCheckedStateCc = 2;


@interface ORecipientPickerViewController () <OTableViewController, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate> {
@private
    id<OOrigo> _origo;
    
    UISegmentedControl *_titleSegments;
    NSInteger _segmentMembers;
    NSInteger _segmentParents;
    NSInteger _segmentGroupedParents;
    NSInteger _segmentGrouped;
    NSInteger _segmentOrganisers;
    
    NSMutableDictionary *_recipientCandidatesByMemberId;
    NSMutableArray *_toRecipients;
    NSMutableArray *_ccRecipients;
}

@end


@implementation ORecipientPickerViewController

#pragma mark - Auxiliary methods

- (BOOL)hasSegment:(NSInteger)segment
{
    return segment != UISegmentedControlNoSegment;
}


- (void)inferTitleAndSubtitle
{
    NSString *title = nil;
    NSString *subtitle = nil;
    
    if (_toRecipients.count) {
        title = [NSString stringWithFormat:@"%@: %@", OLocalizedString(@"To", @""), [OUtil commaSeparatedListOfMembers:_toRecipients conjoin:NO subjective:YES]];
    } else {
        title = OLocalizedString(@"Recipients", @"");
    }
    
    if ([self targetIs:kTargetEmail]) {
        if (_ccRecipients.count) {
            subtitle = [NSString stringWithFormat:@"%@: %@", OLocalizedString(@"Cc", @""), [OUtil commaSeparatedListOfMembers:_ccRecipients conjoin:NO subjective:YES]];
        } else {
            subtitle = nil;
        }
    }
    
    if (self.titleView) {
        self.titleView.title = title;
        self.titleView.subtitle = subtitle;
    } else {
        self.titleView = [OTitleView titleViewWithTitle:title subtitle:subtitle];
    }
}


- (void)addCandidates:(NSArray *)candidates toRecipients:(NSMutableArray *)recipients
{
    for (id<OMember> candidate in [[candidates reverseObjectEnumerator] allObjects]) {
        if (![recipients containsObject:candidate]) {
            [recipients insertObject:candidate atIndex:0];
        }
    }
}


#pragma mark - Selector implementations

- (void)didSelectTitleSegment
{
    [self reloadSections];
}


- (void)performRecipientGroupsAction
{
    NSArray *groups = [_origo groups];
    
    BOOL hasMembers = [self hasSegment:_segmentMembers];
    BOOL hasParents = [self hasSegment:_segmentParents];
    BOOL hasOrganisers = [self hasSegment:_segmentOrganisers];
    BOOL parentsOnly = hasParents && !hasMembers && !hasOrganisers;
    BOOL isClass = [_origo isOfType:@[kOrigoTypePreschoolClass, kOrigoTypeSchoolClass]];
    
    OActionSheet *actionSheet;
    
    if ((!groups.count && (!_titleSegments || [_origo isCommunity])) || (parentsOnly && !isClass)) {
        actionSheet = [[OActionSheet alloc] initWithPrompt:nil];
        [actionSheet addButtonWithTitle:OLocalizedString(@"Select all", @"") action:^{
            if (hasMembers) {
                [self setRecipients:[self->_origo regulars]];
            }
            if (hasParents) {
                [self setRecipients:[self->_origo guardians]];
            }
            if (hasOrganisers) {
                [self setRecipients:[self->_origo organisers]];
            }
        }];
    } else {
        BOOL needsEverybody = NO;
        
        actionSheet = [[OActionSheet alloc] initWithPrompt:OLocalizedString(@"Select recipients", @"")];

        if (hasMembers) {
            if (_titleSegments) {
                NSString *buttonTitle = nil;
                
                if ([_origo isPrivate] || [_origo isStandard]) {
                    buttonTitle = [_origo displayName];
                } else {
                    buttonTitle = OLocalizedString(_origo.type, kStringPrefixMembersTitle);
                }
                
                [actionSheet addButtonWithTitle:buttonTitle action:^{
                    [self setRecipients:[self->_origo regulars]];
                }];
            }
            
            for (NSString *group in groups) {
                NSString *buttonTitle = nil;
                
                if (_titleSegments) {
                    buttonTitle = [NSString stringWithFormat:OLocalizedString(@"%@ in %@", @""), OLocalizedString(_origo.type, kStringPrefixMembersTitle), group];
                } else {
                    buttonTitle = group;
                }
                
                [actionSheet addButtonWithTitle:buttonTitle action:^{
                    [self setRecipients:[self->_origo membersOfGroup:group]];
                }];
            }
        }
        
        if (hasParents) {
            needsEverybody = hasMembers;
            
            [actionSheet addButtonWithTitle:OLocalizedString(@"Parents", @"") action:^{
                [self setRecipients:[self->_origo guardians]];
            }];
            
            for (NSString *group in groups) {
                [actionSheet addButtonWithTitle:[NSString stringWithFormat:OLocalizedString(@"Parents in %@", @""), group] action:^{
                    [self setRecipients:[self->_origo guardiansOfWardsInGroup:group]];
                }];
            }
            
            if ([_origo isOfType:@[kOrigoTypePreschoolClass, kOrigoTypeSchoolClass]]) {
                if ([_origo userIsOrganiser]) {
                    [actionSheet addButtonWithTitle:OLocalizedString(@"Parents of boys", @"") action:^{
                        [self setRecipients:[self->_origo guardiansOfWardsWithGender:kGenderMale]];
                    }];
                    [actionSheet addButtonWithTitle:OLocalizedString(@"Parents of girls", @"") action:^{
                        [self setRecipients:[self->_origo guardiansOfWardsWithGender:kGenderFemale]];
                    }];
                } else if (![_origo userIsMember]) {
                    if ([[OState s].currentMember isMale]) {
                        [actionSheet addButtonWithTitle:OLocalizedString(@"Parents of boys", @"") action:^{
                            [self setRecipients:[self->_origo guardiansOfWardsWithGender:kGenderMale]];
                        }];
                    } else {
                        [actionSheet addButtonWithTitle:OLocalizedString(@"Parents of girls", @"") action:^{
                            [self setRecipients:[self->_origo guardiansOfWardsWithGender:kGenderFemale]];
                        }];
                    }
                }
            }
        }
        
        if (hasOrganisers) {
            needsEverybody = needsEverybody || hasMembers || hasParents;

            [actionSheet addButtonWithTitle:OLocalizedString(_origo.type, kStringPrefixOrganisersTitle) action:^{
                [self setRecipients:[self->_origo organisers]];
            }];
        }
        
        if (needsEverybody) {
            [actionSheet addButtonWithTitle:[NSString stringWithFormat:OLocalizedString(@"Everybody", @""), [OLocalizedString(self->_origo.type, kStringPrefixOrganisersTitle) stringByLowercasingFirstLetter]] action:^{
                if (hasMembers) {
                    [self setRecipients:[self->_origo regulars]];
                }
                if (hasParents) {
                    [self setRecipients:[self->_origo guardians]];
                }
                if (hasOrganisers) {
                    [self setRecipients:[self->_origo organisers]];
                }
            }];
        }
    }
    
    [actionSheet show];
}


- (void)setRecipients:(NSArray *)recipientCandidates {
    if ([self targetIs:kTargetText]) {
        _toRecipients = [[_origo textRecipientsInSet:recipientCandidates] mutableCopy];
    } else if ([self targetIs:kTargetEmail]) {
        _toRecipients = [[_origo emailRecipientsInSet:recipientCandidates] mutableCopy];
    }

    if (_toRecipients.count) {
        [self inferTitleAndSubtitle];
        [self reloadSections];

        self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItem];
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}


- (void)performTextAction
{
    NSMutableArray *recipients = [NSMutableArray array];
    
    for (id<OMember> recipient in _toRecipients) {
        [recipients addObject:recipient.mobilePhone];
    }
    
    MFMessageComposeViewController *messageComposer = [[MFMessageComposeViewController alloc] init];
    messageComposer.messageComposeDelegate = self;
    messageComposer.recipients = recipients;
    
    [self presentViewController:messageComposer animated:YES completion:nil];
}


- (void)performEmailAction
{
    NSMutableArray *toRecipients = [NSMutableArray array];
    NSMutableArray *ccRecipients = [NSMutableArray array];
    
    for (id<OMember> toRecipient in _toRecipients) {
        [toRecipients addObject:toRecipient.email];
    }
    
    for (id<OMember> ccRecipient in _ccRecipients) {
        [ccRecipients addObject:ccRecipient.email];
    }
    
    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
    mailComposer.mailComposeDelegate = self;
    [mailComposer setToRecipients:toRecipients];
    [mailComposer setCcRecipients:ccRecipients];
    [mailComposer setMessageBody:OLocalizedString(@"Sent from Origon - http://origon.co", @"") isHTML:NO];
    
    [self presentViewController:mailComposer animated:YES completion:nil];
}


#pragma mark - OTableViewController conformance

- (void)loadState
{
    _origo = self.meta;
    _toRecipients = [NSMutableArray array];
    
    if ([self targetIs:kTargetEmail]) {
        _ccRecipients = [NSMutableArray array];
    }
    
    self.usesSectionIndexTitles = YES;
    
    [self inferTitleAndSubtitle];
    
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
    
    if ([self targetIs:kTargetText]) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem sendTextButtonWithTarget:self];
        
        if (![self targetIs:kTargetAllContacts] && [_origo textRecipients].count > 1) {
            [self.navigationItem addRightBarButtonItem:[UIBarButtonItem recipientGroupsButtonWithTarget:self]];
        }
    } else if ([self targetIs:kTargetEmail]) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem sendEmailButtonWithTarget:self];
        
        if (![self targetIs:kTargetAllContacts] && [_origo emailRecipients].count > 1) {
            [self.navigationItem addRightBarButtonItem:[UIBarButtonItem recipientGroupsButtonWithTarget:self]];
        }
    }
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    _segmentMembers = UISegmentedControlNoSegment;
    _segmentParents = UISegmentedControlNoSegment;
    _segmentGroupedParents = UISegmentedControlNoSegment;
    _segmentGrouped = UISegmentedControlNoSegment;
    _segmentOrganisers = UISegmentedControlNoSegment;
    
    if ([self targetIs:kTargetAllContacts]) {
        if ([[OMeta m].user favourites].count) {
            _titleSegments = [self titleSegmentsWithTitles:@[OLocalizedString(@"Favourites", @""), OLocalizedString(@"Others", @"")]];
            
            if ([self aspectIs:kAspectFavourites]) {
                _titleSegments.selectedSegmentIndex = kTitleSegmentFavourites;
            } else if ([self aspectIs:kAspectNonFavourites]) {
                _titleSegments.selectedSegmentIndex = kTitleSegmentOthers;
            }
        }
    } else {
        NSArray *segmentTitles = nil;
        
        if ([_origo isCommunity]) {
            segmentTitles = @[OLocalizedString(_origo.type, kStringPrefixMembersTitle), OLocalizedString(@"Households", @"")];
            
            _segmentMembers = 0;
            _segmentGrouped = 1;
        } else {
            NSArray *organisers = [_origo organisers];
            BOOL hasOrganisers = organisers.count > 0;
            BOOL userIsOrganiser = hasOrganisers && [_origo userIsOrganiser];
            BOOL showsOrganisers = hasOrganisers && (!userIsOrganiser || organisers.count > 1);
            
            if (showsOrganisers) {
                NSMutableArray *reachableOrganisers = [organisers mutableCopy];
                
                if (userIsOrganiser) {
                    [reachableOrganisers removeObject:[OMeta m].user];
                }
                
                if ([self targetIs:kTargetText]) {
                    showsOrganisers = [_origo textRecipientsInSet:reachableOrganisers].count > 0;
                } else if ([self targetIs:kTargetEmail]) {
                    showsOrganisers = [_origo emailRecipientsInSet:reachableOrganisers].count > 0;
                }
            }
            
            if ([_origo isJuvenile]) {
                _segmentGrouped = 0;
                
                BOOL listsMembers = ![_origo isJuvenile] || [[OMeta m].user isJuvenile] || (([_origo isPrivate] || [_origo userIsOrganiser]) && [_origo hasTeenRegulars]);
                
                if (listsMembers) {
                    if ([self targetIs:kTargetText]) {
                        listsMembers = [_origo textRecipientsInSet:[_origo regulars]].count > 0;
                    } else if ([self targetIs:kTargetEmail]) {
                        listsMembers = [_origo emailRecipientsInSet:[_origo regulars]].count > 0;
                    }
                }
                
                if (listsMembers) {
                    segmentTitles = @[OLocalizedString(_origo.type, kStringPrefixMembersTitle), OLocalizedString(@"Parents", @"")];
                    
                    _segmentMembers = 0;
                    
                    if (userIsOrganiser || [_origo userIsMember] || [[_origo owner] isUser]) {
                        _segmentGrouped = 1;
                    } else {
                        _segmentParents = 1;
                        _segmentGrouped = 2;
                        
                        segmentTitles = [segmentTitles arrayByAddingObject:OLocalizedString(@"Grouped", @"")];
                    }
                } else if (userIsOrganiser && showsOrganisers) {
                    segmentTitles = @[OLocalizedString(@"Parents", @"")];
                } else if (!userIsOrganiser) {
                    segmentTitles = @[OLocalizedString(@"Parents", @""), OLocalizedString(@"Grouped", @"")];
                    
                    _segmentParents = 0;
                    _segmentGrouped = 1;
                }
                
                _segmentGroupedParents = _segmentGrouped;
                
                if (![self hasSegment:_segmentParents]) {
                    _segmentParents = _segmentGroupedParents;
                }
            } else {
                _segmentMembers = 0;
                
                if (showsOrganisers) {
                    segmentTitles = @[OLocalizedString(_origo.type, kStringPrefixMembersTitle)];
                }
            }

            if (showsOrganisers) {
                segmentTitles = [segmentTitles arrayByAddingObject:OLocalizedString(_origo.type, kStringPrefixOrganisersTitle)];
                
                _segmentOrganisers = segmentTitles.count - 1;
            }
        }
        
        _titleSegments = [self titleSegmentsWithTitles:segmentTitles];
        _recipientCandidatesByMemberId = [NSMutableDictionary dictionary];
    }
}


- (void)loadData
{
    if ([self targetIs:kTargetAllContacts]) {
        if (_titleSegments) {
            if (_titleSegments.selectedSegmentIndex == kTitleSegmentFavourites) {
                [self setData:[[OMeta m].user favourites] sectionIndexLabelKey:kPropertyKeyName];
            } else if (_titleSegments.selectedSegmentIndex == kTitleSegmentOthers) {
                [self setData:[[OMeta m].user nonFavourites] sectionIndexLabelKey:kPropertyKeyName];
            }
        } else {
            [self setData:[[OMeta m].user nonFavourites] sectionIndexLabelKey:kPropertyKeyName];
        }
    } else {
        NSMutableArray *recipientHubs = nil;
        
        if (_titleSegments) {
            if (_titleSegments.selectedSegmentIndex == _segmentMembers) {
                recipientHubs = [[_origo regulars] mutableCopy];
            } else if (_titleSegments.selectedSegmentIndex == _segmentGroupedParents) {
                recipientHubs = [[_origo regulars] mutableCopy];
            } else if (_titleSegments.selectedSegmentIndex == _segmentParents) {
                recipientHubs = [[_origo guardians] mutableCopy];
            } else if (_titleSegments.selectedSegmentIndex == _segmentGrouped) {
                recipientHubs = [[OUtil singleMemberPerPrimaryResidenceFromMembers:[_origo members] includeUser:NO] mutableCopy];
            } else if (_titleSegments.selectedSegmentIndex == _segmentOrganisers) {
                recipientHubs = [[_origo organisers] mutableCopy];
            }
        } else if ([self hasSegment:_segmentMembers] || [self hasSegment:_segmentGroupedParents]) {
            recipientHubs = [[_origo regulars] mutableCopy];
        }
        
        if ([recipientHubs containsObject:[OMeta m].user]) {
            [recipientHubs removeObject:[OMeta m].user];
        } else if ([_origo isJuvenile]) {
            for (id<OMember> ward in [[OMeta m].user wards]) {
                if ([recipientHubs containsObject:ward] && [ward guardians].count == 1) {
                    [recipientHubs removeObject:ward];
                }
            }
        }
        
        [self setData:recipientHubs sectionIndexLabelKey:kPropertyKeyName];
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self targetIs:kTargetEmail] && !cell.checkedStateAccessoryViews) {
        UILabel *toLabel = [OLabel genericLabelWithText:OLocalizedString(@"To", @"")];
        UILabel *ccLabel = [OLabel genericLabelWithText:OLocalizedString(@"Cc", @"")];
        
        cell.checkedStateAccessoryViews = @[[NSNull null], toLabel, ccLabel];
    }
    
    id<OMember> member = [self dataAtIndexPath:indexPath];
    
    if (_titleSegments.selectedSegmentIndex == _segmentGrouped) {
        id<OOrigo> residence = [_origo isCommunity] ? [member primaryResidence] : nil;
        
        NSMutableArray *recipientCandidates = [NSMutableArray array];
        id elders = [_origo isCommunity] ? [residence elders] : [member parentsOrGuardians];
        
        if ([elders containsObject:[OMeta m].user]) {
            elders = [elders mutableCopy];
            [elders removeObject:[OMeta m].user];
        }
        
        for (id<OMember> elder in elders) {
            BOOL isRecipientCandidate = NO;
            
            if ([self targetIs:kTargetText]) {
                isRecipientCandidate = [elder.mobilePhone hasValue];
            } else if ([self targetIs:kTargetEmail]) {
                isRecipientCandidate = [elder.email hasValue];
            }
            
            if (isRecipientCandidate) {
                [recipientCandidates addObject:elder];
            }
        }
        
        if ([self targetIs:kTargetText]) {
            BOOL includesSome = NO;
            BOOL includesAll = recipientCandidates.count > 0;
            
            for (id<OMember> recipientCandidate in recipientCandidates) {
                if ([_toRecipients containsObject:recipientCandidate]) {
                    includesSome = YES;
                } else {
                    includesAll = NO;
                }
            }
            
            cell.checked = includesAll;
            
            if (!cell.checked) {
                cell.partiallyChecked = includesSome;
            }
        } else if ([self targetIs:kTargetEmail]) {
            BOOL includesSomeAsTo = NO;
            BOOL includesSomeAsCc = NO;
            BOOL includesAllAsTo = recipientCandidates.count > 0;
            BOOL includesAllAsCc = recipientCandidates.count > 0;
            
            for (id<OMember> recipientCandidate in recipientCandidates) {
                if ([_toRecipients containsObject:recipientCandidate]) {
                    includesSomeAsTo = YES;
                } else if ([_ccRecipients containsObject:recipientCandidate]) {
                    includesSomeAsCc = YES;
                } else {
                    includesAllAsTo = NO;
                    includesAllAsCc = NO;
                }
            }
            
            if (includesSomeAsTo) {
                cell.checkedState = kCellCheckedStateTo;
                cell.partiallyChecked = !includesAllAsTo;
            } else if (includesSomeAsCc) {
                cell.checkedState = kCellCheckedStateCc;
                cell.partiallyChecked = !includesAllAsCc;
            } else {
                cell.checkedState = kCellCheckedStateNone;
            }
        }
        
        cell.textLabel.text = [OUtil labelForElders:elders conjoin:YES];
        
        if ([_origo isCommunity]) {
            cell.detailTextLabel.text = [residence shortAddress];
        } else {
            cell.detailTextLabel.text = [member displayNameInOrigo:_origo];
            cell.detailTextLabel.textColor = [UIColor tonedDownTextColour];
        }
        
        cell.selectable = recipientCandidates.count > 0;
        
        if (cell.selectable) {
            _recipientCandidatesByMemberId[member.entityId] = recipientCandidates;
        }
        
        if ([elders count] == 1) {
            [cell loadImageForMember:elders[0]];
        } else {
            [cell loadImageForMembers:elders];
        }
    } else {
        if ([self targetIs:kTargetText]) {
            cell.checked = [_toRecipients containsObject:member];
        } else if ([self targetIs:kTargetEmail]) {
            if ([_toRecipients containsObject:member]) {
                cell.checkedState = kCellCheckedStateTo;
            } else if ([_ccRecipients containsObject:member]) {
                cell.checkedState = kCellCheckedStateCc;
            }
        }
        
        NSInteger titleSegment;
        
        if ([self targetIs:kTargetAllContacts] && !_titleSegments) {
            titleSegment = kTitleSegmentOthers;
        } else {
            titleSegment = _titleSegments.selectedSegmentIndex;
        }
        
        if ([self targetIs:kTargetAllContacts] && titleSegment == kTitleSegmentOthers) {
            [cell loadMember:member inOrigo:nil excludeRoles:YES excludeRelations:YES];
        } else {
            [cell loadMember:member inOrigo:_origo];
        }
        
        if ([self targetIs:kTargetText]) {
            cell.selectable = [member.mobilePhone hasValue];
        } else if ([self targetIs:kTargetEmail]) {
            cell.selectable = [member.email hasValue];
        }
    }
    
    if (!cell.selectable) {
        cell.textLabel.textColor = [UIColor tonedDownTextColour];
        cell.detailTextLabel.textColor = [UIColor tonedDownTextColour];
    }
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    id<OMember> member = [self dataAtIndexPath:indexPath];
    
    if ([self targetIs:kTargetText]) {
        if (_titleSegments.selectedSegmentIndex == _segmentGrouped) {
            cell.checked = cell.partiallyChecked ? YES : !cell.checked;
            
            if (cell.checked) {
                [self addCandidates:_recipientCandidatesByMemberId[member.entityId] toRecipients:_toRecipients];
            } else {
                [_toRecipients removeObjectsInArray:_recipientCandidatesByMemberId[member.entityId]];
            }
        } else {
            cell.checked = !cell.checked;
            
            if (cell.checked) {
                [self addCandidates:@[member] toRecipients:_toRecipients];
            } else {
                [_toRecipients removeObject:member];
            }
        }
    } else if ([self targetIs:kTargetEmail]) {
        [cell bumpCheckedState];

        if (_titleSegments.selectedSegmentIndex == _segmentGrouped) {
            NSArray *recipientCandidates = _recipientCandidatesByMemberId[member.entityId];
            
            if (cell.checkedState == kCellCheckedStateTo) {
                [self addCandidates:recipientCandidates toRecipients:_toRecipients];
            } else if (cell.checkedState == kCellCheckedStateCc) {
                [_toRecipients removeObjectsInArray:recipientCandidates];
                [self addCandidates:recipientCandidates toRecipients:_ccRecipients];
            } else if (cell.checkedState == kCellCheckedStateNone) {
                [_ccRecipients removeObjectsInArray:recipientCandidates];
            }
        } else {
            if (cell.checkedState == kCellCheckedStateTo) {
                [self addCandidates:@[member] toRecipients:_toRecipients];
            } else if (cell.checkedState == kCellCheckedStateCc) {
                [_toRecipients removeObject:member];
                [self addCandidates:@[member] toRecipients:_ccRecipients];
            } else if (cell.checkedState == kCellCheckedStateNone) {
                [_ccRecipients removeObject:member];
            }
        }
    }
    
    [self inferTitleAndSubtitle];

    if (_toRecipients.count || _ccRecipients.count) {
        if (self.navigationItem.rightBarButtonItems.count > 1) {
            self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItem];
        }
    } else {
        if (self.navigationItem.rightBarButtonItems.count == 1) {
            [self.navigationItem addRightBarButtonItem:[UIBarButtonItem recipientGroupsButtonWithTarget:self]];
        }
    }
    
    self.navigationItem.rightBarButtonItem.enabled = _toRecipients.count > 0;
}


#pragma mark - MFMessageComposeViewControllerDelegate conformance

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    if (result == MessageComposeResultCancelled) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.dismisser dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark - MFMailComposeViewControllerDelegate conformance

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (result == MFMailComposeResultCancelled) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.dismisser dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
