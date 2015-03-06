//
//  ORecipientPickerViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 11/12/14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "ORecipientPickerViewController.h"

static NSInteger const kTitleSubsegmentFavourites = 0;
static NSInteger const kTitleSubsegmentOthers = 1;
static NSInteger const kTitleSubsegmentAll = 0;
static NSInteger const kTitleSubsegmentGrouped = 1;

static NSInteger const kCellCheckedStateNone = 0;
static NSInteger const kCellCheckedStateTo = 1;
static NSInteger const kCellCheckedStateCc = 2;

static NSInteger const kActionSheetTagGroups = 0;
static NSInteger const kButtonTagGroupAll = 0;
static NSInteger const kButtonTagGroupMembers = 1;
static NSInteger const kButtonTagGroupOrganisers = 2;
static NSInteger const kButtonTagGroupParents = 3;
static NSInteger const kButtonTagGroupCoGenderParents = 4;
static NSInteger const kButtonTagGroupCoGroup = 5;


@interface ORecipientPickerViewController () <UIActionSheetDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate> {
@private
    id<OOrigo> _origo;
    
    UISegmentedControl *_titleSubsegments;
    NSInteger _titleSubsegment;
    
    NSMutableDictionary *_recipientCandidatesByMemberId;
    NSMutableArray *_toRecipients;
    NSMutableArray *_ccRecipients;
}

@end


@implementation ORecipientPickerViewController

#pragma mark - Auxiliary methods

- (void)inferTitleAndSubtitle
{
    NSString *title = nil;
    NSString *subtitle = nil;
    
    if ([_toRecipients count]) {
        title = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"To", @""), [OUtil commaSeparatedListOfMembers:_toRecipients conjoin:NO subjective:YES]];
    } else {
        title = NSLocalizedString(@"Pick recipients", @"");
    }
    
    if ([self targetIs:kTargetEmail]) {
        if ([_ccRecipients count]) {
            subtitle = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Cc", @""), [OUtil commaSeparatedListOfMembers:_ccRecipients conjoin:NO subjective:YES]];
        } else {
            subtitle = nil;
        }
    }
    
    [self.navigationItem setTitle:title editable:NO withSubtitle:subtitle];
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

- (void)didSelectTitleSubsegment
{
    _titleSubsegment = _titleSubsegments.selectedSegmentIndex;
    
    [self reloadSections];
}


- (void)performGroupsAction
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagGroups];
    
    if ([_origo isOrganised]) {
        if (_titleSubsegment == kTitleSubsegmentAll) {
            if ([[_origo organisers] count]) {
                [actionSheet addButtonWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Everybody", @""), [NSLocalizedString(_origo.type, kStringPrefixOrganisersTitle) stringByLowercasingFirstLetter]] tag:kButtonTagGroupAll];
                [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixOrganisersTitle) tag:kButtonTagGroupOrganisers];
            }
            
            if ([_origo isJuvenile]) {
                [actionSheet addButtonWithTitle:NSLocalizedString(@"Parents", @"") tag:kButtonTagGroupParents];
            } else {
                [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixMembersTitle) tag:kButtonTagGroupMembers];
            }
        } else if (_titleSubsegment == kTitleSubsegmentGrouped) {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"All parents", @"") tag:kButtonTagGroupParents];
        }
        
        if ([_origo isOfType:@[kOrigoTypePreschoolClass, kOrigoTypeSchoolClass]]) {
            if ([[OState s].currentMember isMale]) {
                [actionSheet addButtonWithTitle:NSLocalizedString(@"Parents of boys", @"") tag:kButtonTagGroupCoGenderParents];
            } else {
                [actionSheet addButtonWithTitle:NSLocalizedString(@"Parents of girls", @"") tag:kButtonTagGroupCoGenderParents];
            }
        }
    }
    
    if ([[_origo groups] count]) {
        if (!actionSheet.numberOfButtons) {
            if ([_origo isJuvenile]) {
                [actionSheet addButtonWithTitle:NSLocalizedString(@"All parents", @"") tag:kButtonTagGroupParents];
            } else {
                [actionSheet addButtonWithTitle:NSLocalizedString(@"Everybody", @"") tag:kButtonTagGroupAll];
            }
        }
        
        for (NSString *group in [_origo groups]) {
            if ([_origo isJuvenile]) {
                [actionSheet addButtonWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Parents in %@", @""), group] tag:kButtonTagGroupCoGroup];
            } else {
                [actionSheet addButtonWithTitle:group tag:kButtonTagGroupCoGroup];
            }
        }
    }
    
    if (actionSheet.numberOfButtons == 1) {
        actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagGroups];
    }
    
    if (!actionSheet.numberOfButtons) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Select all", @"") tag:kButtonTagGroupAll];
    } else {
        actionSheet.title = NSLocalizedString(@"Select recipients", @"");
    }
    
    [actionSheet show];
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
    [mailComposer setMessageBody:NSLocalizedString(@"Sent from Origo - http://origoapp.com", @"") isHTML:NO];
    
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
        
        if (![self targetIs:kTargetAllContacts] && [[_origo textRecipients] count] > 1) {
            [self.navigationItem addRightBarButtonItem:[UIBarButtonItem groupsButtonWithTarget:self]];
        }
    } else if ([self targetIs:kTargetEmail]) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem sendEmailButtonWithTarget:self];
        
        if (![self targetIs:kTargetAllContacts] && [[_origo emailRecipients] count] > 1) {
            [self.navigationItem addRightBarButtonItem:[UIBarButtonItem groupsButtonWithTarget:self]];
        }
    }
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    if ([self targetIs:kTargetAllContacts]) {
        if ([[[OMeta m].user favourites] count]) {
            _titleSubsegments = [self titleSubsegmentsWithTitles:@[NSLocalizedString(@"Favourites", @""), NSLocalizedString(@"Others", @"")]];
            
            if ([self aspectIs:kAspectFavourites]) {
                _titleSubsegments.selectedSegmentIndex = kTitleSubsegmentFavourites;
            } else if ([self aspectIs:kAspectNonFavourites]) {
                _titleSubsegments.selectedSegmentIndex = kTitleSubsegmentOthers;
            }
            
            _titleSubsegment = _titleSubsegments.selectedSegmentIndex;
        }
    } else if ([_origo isCommunity] || [_origo isJuvenile]) {
        NSString *allLabel = @"";
        NSString *groupedLabel = @"";
        
        if ([_origo isCommunity]) {
            allLabel = NSLocalizedString(_origo.type, kStringPrefixMembersTitle);
            groupedLabel = NSLocalizedString(@"Households", @"");
        } else if ([_origo isJuvenile]) {
            if ([[_origo organisers] count]) {
                allLabel = [NSString stringWithFormat:NSLocalizedString(@"Parents and %@", @""), [NSLocalizedString(_origo.type, kStringPrefixOrganisersTitle) stringByLowercasingFirstLetter]];
                groupedLabel = NSLocalizedString(@"Parents, grouped", @"");
            } else {
                allLabel = NSLocalizedString(@"Parents", @"");
                groupedLabel = NSLocalizedString(@"Grouped", @"");
            }
        }
        
        _titleSubsegments = [self titleSubsegmentsWithTitles:@[allLabel, groupedLabel]];
        _recipientCandidatesByMemberId = [NSMutableDictionary dictionary];
    }
}


- (void)loadData
{
    if ([self targetIs:kTargetAllContacts]) {
        if (_titleSubsegment == kTitleSubsegmentFavourites) {
            [self setData:[[OMeta m].user favourites] sectionIndexLabelKey:kPropertyKeyName];
        } else if (_titleSubsegment == kTitleSubsegmentOthers) {
            [self setData:[[OMeta m].user nonFavourites] sectionIndexLabelKey:kPropertyKeyName];
        }
    } else {
        if (_titleSubsegment == kTitleSubsegmentAll) {
            [self setData:[_origo recipientCandidates] sectionIndexLabelKey:kPropertyKeyName];
        } else if (_titleSubsegment == kTitleSubsegmentGrouped) {
            if ([_origo isCommunity]) {
                [self setData:[OUtil singleMemberPerPrimaryResidenceFromMembers:[_origo members] includeUser:NO] sectionIndexLabelKey:kPropertyKeyName];
            } else {
                [self setData:[_origo regulars] sectionIndexLabelKey:kPropertyKeyName];
            }
        }
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self targetIs:kTargetEmail] && !cell.checkedStateAccessoryViews) {
        UILabel *toLabel = [OLabel genericLabelWithText:NSLocalizedString(@"To", @"")];
        UILabel *ccLabel = [OLabel genericLabelWithText:NSLocalizedString(@"Cc", @"")];
        
        cell.checkedStateAccessoryViews = @[[NSNull null], toLabel, ccLabel];
    }
    
    if (_titleSubsegment == kTitleSubsegmentAll || [self targetIs:kTargetAllContacts]) {
        id<OMember> recipientCandidate = [self dataAtIndexPath:indexPath];
        
        if ([self targetIs:kTargetText]) {
            cell.checked = [_toRecipients containsObject:recipientCandidate];
        } else if ([self targetIs:kTargetEmail]) {
            if ([_toRecipients containsObject:recipientCandidate]) {
                cell.checkedState = kCellCheckedStateTo;
            } else if ([_ccRecipients containsObject:recipientCandidate]) {
                cell.checkedState = kCellCheckedStateCc;
            }
        }
        
        if ([self targetIs:kTargetAllContacts] && _titleSubsegment == kTitleSubsegmentOthers) {
            [cell loadMember:recipientCandidate inOrigo:nil excludeRoles:YES excludeRelations:YES];
        } else {
            [cell loadMember:recipientCandidate inOrigo:_origo];
        }
        
        if ([self targetIs:kTargetText]) {
            cell.selectable = [recipientCandidate.mobilePhone hasValue];
        } else if ([self targetIs:kTargetEmail]) {
            cell.selectable = [recipientCandidate.email hasValue];
        }
    } else if (_titleSubsegment == kTitleSubsegmentGrouped) {
        id<OMember> member = [self dataAtIndexPath:indexPath];
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
            BOOL includesAll = [recipientCandidates count] > 0;
            
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
            BOOL includesAllAsTo = [recipientCandidates count] > 0;
            BOOL includesAllAsCc = [recipientCandidates count] > 0;
            
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
        
        cell.selectable = [recipientCandidates count] > 0;
        
        if (cell.selectable) {
            _recipientCandidatesByMemberId[member.entityId] = recipientCandidates;
        }
        
        if ([elders count] == 1) {
            [cell loadImageForMember:elders[0]];
        } else {
            [cell loadImageForMembers:elders];
        }
    }
    
    if (!cell.selectable) {
        cell.textLabel.textColor = [UIColor tonedDownTextColour];
    }
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.selected = NO;
    
    if ([self targetIs:kTargetText]) {
        if (_titleSubsegment == kTitleSubsegmentAll || [self targetIs:kTargetAllContacts]) {
            cell.checked = !cell.checked;
            
            id<OMember> candidateInCell = [self dataAtIndexPath:indexPath];
            
            if (cell.checked) {
                [self addCandidates:@[candidateInCell] toRecipients:_toRecipients];
            } else {
                [_toRecipients removeObject:candidateInCell];
            }
        } else if (_titleSubsegment == kTitleSubsegmentGrouped) {
            cell.checked = cell.partiallyChecked ? YES : !cell.checked;
            
            id<OEntity> member = [self dataAtIndexPath:indexPath];
            
            if (cell.checked) {
                [self addCandidates:_recipientCandidatesByMemberId[member.entityId] toRecipients:_toRecipients];
            } else {
                [_toRecipients removeObjectsInArray:_recipientCandidatesByMemberId[member.entityId]];
            }
        }
    } else if ([self targetIs:kTargetEmail]) {
        [cell bumpCheckedState];

        if (_titleSubsegment == kTitleSubsegmentAll || [self targetIs:kTargetAllContacts]) {
            id<OMember> recipientCandidate = [self dataAtIndexPath:indexPath];
            
            if (cell.checkedState == kCellCheckedStateTo) {
                [self addCandidates:@[recipientCandidate] toRecipients:_toRecipients];
            } else if (cell.checkedState == kCellCheckedStateCc) {
                [_toRecipients removeObject:recipientCandidate];
                [self addCandidates:@[recipientCandidate] toRecipients:_ccRecipients];
            } else if (cell.checkedState == kCellCheckedStateNone) {
                [_ccRecipients removeObject:recipientCandidate];
            }
        } else if (_titleSubsegment == kTitleSubsegmentGrouped) {
            id<OEntity> member = [self dataAtIndexPath:indexPath];
            NSArray *recipientCandidates = _recipientCandidatesByMemberId[member.entityId];
            
            if (cell.checkedState == kCellCheckedStateTo) {
                [self addCandidates:recipientCandidates toRecipients:_toRecipients];
            } else if (cell.checkedState == kCellCheckedStateCc) {
                [_toRecipients removeObjectsInArray:recipientCandidates];
                [self addCandidates:recipientCandidates toRecipients:_ccRecipients];
            } else if (cell.checkedState == kCellCheckedStateNone) {
                [_ccRecipients removeObjectsInArray:recipientCandidates];
            }
        }
    }
    
    [self inferTitleAndSubtitle];

    if ([_toRecipients count] || [_ccRecipients count]) {
        if ([self.navigationItem.rightBarButtonItems count] > 1) {
            self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItem];
        }
    } else {
        if ([self.navigationItem.rightBarButtonItems count] == 1) {
            [self.navigationItem addRightBarButtonItem:[UIBarButtonItem groupsButtonWithTarget:self]];
        }
    }
    
    self.navigationItem.rightBarButtonItem.enabled = [_toRecipients count] > 0;
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case kActionSheetTagGroups:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
                NSMutableArray *recipientCandidates = nil;
                
                if ([self targetIs:kTargetText]) {
                    recipientCandidates = [[_origo textRecipients] mutableCopy];
                } else if ([self targetIs:kTargetEmail]) {
                    recipientCandidates = [[_origo emailRecipients] mutableCopy];
                }
                
                if (buttonTag == kButtonTagGroupAll) {
                    _toRecipients = recipientCandidates;
                } else if (buttonTag == kButtonTagGroupMembers) {
                    _toRecipients = recipientCandidates;
                    
                    for (id<OMember> organiser in [_origo organisers]) {
                        [_toRecipients removeObject:organiser];
                    }
                } else if (buttonTag == kButtonTagGroupOrganisers) {
                    NSArray *organisers = [_origo organisers];
                    
                    for (id<OMember> recipientCandidate in recipientCandidates) {
                        if ([organisers containsObject:recipientCandidate]) {
                            [_toRecipients addObject:recipientCandidate];
                        }
                    }
                } else if (buttonTag == kButtonTagGroupParents) {
                    _toRecipients = recipientCandidates;
                    
                    for (id<OMember> organiser in [_origo organisers]) {
                        [_toRecipients removeObject:organiser];
                    }
                } else if (buttonTag == kButtonTagGroupCoGenderParents) {
                    BOOL isMale = [[OState s].currentMember isMale];
                    
                    for (id<OMember> member in [_origo regulars]) {
                        if ([member isMale] == isMale) {
                            for (id<OMember> guardian in [member guardians]) {
                                if ([recipientCandidates containsObject:guardian]) {
                                    [_toRecipients addObject:guardian];
                                }
                            }
                        }
                    }
                } else if (buttonTag == kButtonTagGroupCoGroup) {
                    NSArray *groups = [_origo groups];
                    NSString *group = groups[[groups count] - (actionSheet.numberOfButtons - buttonIndex - 1)];
                    
                    for (id<OMember> member in [_origo membersOfGroup:group]) {
                        if ([_origo isJuvenile]) {
                            for (id<OMember> guardian in [member guardians]) {
                                if ([recipientCandidates containsObject:guardian]) {
                                    [_toRecipients addObject:guardian];
                                }
                            }
                        } else {
                            if ([recipientCandidates containsObject:member]) {
                                [_toRecipients addObject:member];
                            }
                        }
                    }
                }
                
                _toRecipients = [[_toRecipients sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
                
                [self inferTitleAndSubtitle];
                [self reloadSections];
                
                self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItem];
                self.navigationItem.rightBarButtonItem.enabled = YES;
            }
            
            break;
            
        default:
            break;
    }
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
