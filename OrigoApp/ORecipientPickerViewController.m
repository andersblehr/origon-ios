//
//  ORecipientPickerViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 11/12/14.
//  Copyright (c) 2014 Rhelba Source. All rights reserved.
//

#import "ORecipientPickerViewController.h"

static NSInteger const kTitleSubsegmentAll = 0;
static NSInteger const kTitleSubsegmentFavourites = 1;
static NSInteger const kTitleSubsegmentGrouped = 1;

static NSInteger const kCellCheckedStateNone = 0;
static NSInteger const kCellCheckedStateTo = 1;
static NSInteger const kCellCheckedStateCc = 2;


@interface ORecipientPickerViewController () <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate> {
@private
    id<OOrigo> _origo;
    
    UISegmentedControl *_titleSubsegments;
    NSInteger _selectedTitleSubsegment;
    
    NSMutableDictionary *_recipientCandidatesByPivotId;
    NSMutableArray *_toRecipients;
    NSMutableArray *_ccRecipients;
}

@end


@implementation ORecipientPickerViewController

#pragma mark - Auxiliary methods

- (void)toggleSendButton:(BOOL)on
{
    if (on) {
        if ([self targetIs:kTargetText]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem sendTextButtonWithTarget:self];
        } else if ([self targetIs:kTargetEmail]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem sendEmailButtonWithTarget:self];
        }
        
        self.navigationItem.rightBarButtonItem.enabled = [_toRecipients count] > 0;
    } else {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem textButtonWithTitle:NSLocalizedString(@"Select all", @"") target:self action:@selector(selectAll)];
    }
}


- (void)inferTitleAndSubtitle
{
    NSString *title = nil;
    NSString *subtitle = nil;
    
    if ([_toRecipients count]) {
        title = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"To", @""), [OUtil commaSeparatedListOfMembers:_toRecipients conjoin:NO subjective:YES]];
    } else if ([self targetIs:kTargetText]) {
        title = NSLocalizedString(@"Send text", @"");
    } else if ([self targetIs:kTargetEmail]) {
        title = NSLocalizedString(@"Send email", @"");
    }
    
    if ([self targetIs:kTargetEmail] && [_ccRecipients count]) {
        subtitle = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Cc", @""), [OUtil commaSeparatedListOfMembers:_ccRecipients conjoin:NO subjective:YES]];
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

- (void)selectAll
{
    if ([self targetIs:kTargetText]) {
        _toRecipients = [[_origo textRecipients] mutableCopy];
    } else if ([self targetIs:kTargetEmail]) {
        _toRecipients = [[_origo emailRecipients] mutableCopy];
    }
    
    if (_selectedTitleSubsegment == kTitleSubsegmentGrouped) {
        for (id<OMember> organiser in [_origo organisers]) {
            [_toRecipients removeObject:organiser];
        }
    }
    
    [self inferTitleAndSubtitle];
    [self toggleSendButton:YES];
    [self reloadSections];
}


- (void)didSelectTitleSegment
{
    _selectedTitleSubsegment = _titleSubsegments.selectedSegmentIndex;
    
    self.rowAnimation = UITableViewRowAnimationFade;
    [self reloadSections];
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
    
    self.usesSectionIndexTitles = YES;
    
    if ([self targetIs:kTargetText]) {
        self.title = NSLocalizedString(@"Send text", @"");
    } else if ([self targetIs:kTargetEmail]) {
        _ccRecipients = [NSMutableArray array];
        
        self.title = NSLocalizedString(@"Send email", @"");
    }
    
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
    
    [self toggleSendButton:[self aspectIs:kAspectGlobal]];
    
    if ([self aspectIs:kAspectGlobal]) {
        _titleSubsegments = [self titleSubsegmentsWithTitles:@[NSLocalizedString(@"All", @""), NSLocalizedString(@"Favourites", @"")]];
    } else if ([_origo isOfType:kOrigoTypeCommunity] || [_origo isJuvenile]) {
        NSString *allLabel = nil;
        NSString *groupedLabel = nil;
        
        if ([_origo isOfType:kOrigoTypeCommunity]) {
            allLabel = NSLocalizedString(_origo.type, kStringPrefixMembersTitle);
            groupedLabel = NSLocalizedString(@"Households", @"");
        } else if ([_origo isJuvenile]) {
            if ([[_origo organisers] count]) {
                allLabel = [NSString stringWithFormat:NSLocalizedString(@"Parents and %@", @""), [NSLocalizedString(_origo.type, kStringPrefixOrganisersTitle) stringByLowercasingFirstLetter]];
            } else {
                allLabel = NSLocalizedString(@"Parents", @"");
            }
            
            groupedLabel = NSLocalizedString(@"Parents, grouped", @"");
        }
        
        _titleSubsegments = [self titleSubsegmentsWithTitles:@[allLabel, groupedLabel]];
        _recipientCandidatesByPivotId = [NSMutableDictionary dictionary];
    }
}


- (void)loadData
{
    if ([self aspectIs:kAspectGlobal]) {
        if (_selectedTitleSubsegment == kTitleSubsegmentAll) {
            [self setData:[self.state eligibleCandidates] sectionIndexLabelKey:kPropertyKeyName];
        } else if (_selectedTitleSubsegment == kTitleSubsegmentFavourites) {
            [self setData:[[OMeta m].user favourites] sectionIndexLabelKey:kPropertyKeyName];
        }
    } else {
        if (_selectedTitleSubsegment == kTitleSubsegmentAll) {
            [self setData:[_origo recipientCandidates] sectionIndexLabelKey:kPropertyKeyName];
        } else if (_selectedTitleSubsegment == kTitleSubsegmentGrouped) {
            if ([_origo isOfType:kOrigoTypeCommunity]) {
                [self setData:[_origo memberResidences] sectionIndexLabelKey:kPropertyKeyAddress];
            } else {
                [self setData:[_origo regulars] sectionIndexLabelKey:kPropertyKeyName];
            }
        }
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self targetIs:kTargetEmail] && !cell.checkedStateAccessoryViews) {
        UILabel *noLabel = [OLabel genericLabelWithText:@""];
        UILabel *toLabel = [OLabel genericLabelWithText:NSLocalizedString(@"To", @"")];
        UILabel *ccLabel = [OLabel genericLabelWithText:NSLocalizedString(@"Cc", @"")];
        
        cell.checkedStateAccessoryViews = @[noLabel, toLabel, ccLabel];
    }
    
    if (_selectedTitleSubsegment == kTitleSubsegmentAll || [self aspectIs:kAspectGlobal]) {
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
        
        if (_selectedTitleSubsegment == kTitleSubsegmentAll && [self aspectIs:kAspectGlobal]) {
            [cell loadMember:recipientCandidate inOrigo:nil excludeRoles:YES excludeRelations:YES];
        } else {
            [cell loadMember:recipientCandidate inOrigo:_origo];
        }
        
        if ([self targetIs:kTargetText]) {
            cell.selectable = [recipientCandidate.mobilePhone hasValue];
        } else if ([self targetIs:kTargetEmail]) {
            cell.selectable = [recipientCandidate.email hasValue];
        }
    } else if (_selectedTitleSubsegment == kTitleSubsegmentGrouped) {
        BOOL isCommunity = [_origo isOfType:kOrigoTypeCommunity];
        
        id pivot = [self dataAtIndexPath:indexPath];
        
        NSArray *elders = isCommunity ? [pivot elders] : [pivot parentsOrGuardians];
        NSMutableArray *recipientCandidatesForGroup = [NSMutableArray array];
        NSMutableArray *nonRecipientCandidatesForGroup = [NSMutableArray array];
        
        for (id<OMember> elder in elders) {
            if (![elder isUser]) {
                BOOL isRecipientCandidate = NO;
                
                if ([self targetIs:kTargetText]) {
                    isRecipientCandidate = [elder.mobilePhone hasValue];
                } else if ([self targetIs:kTargetEmail]) {
                    isRecipientCandidate = [elder.email hasValue];
                }
                
                if (isRecipientCandidate) {
                    [recipientCandidatesForGroup addObject:elder];
                } else {
                    [nonRecipientCandidatesForGroup addObject:elder];
                }
            }
        }
        
        if ([self targetIs:kTargetText]) {
            BOOL includesSome = NO;
            BOOL includesAll = [recipientCandidatesForGroup count] > 0;
            
            for (id<OMember> recipientCandidate in recipientCandidatesForGroup) {
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
            BOOL includesAllAsTo = [recipientCandidatesForGroup count] > 0;
            BOOL includesAllAsCc = [recipientCandidatesForGroup count] > 0;
            
            for (id<OMember> recipientCandidate in recipientCandidatesForGroup) {
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
        
        if ([_origo isOfType:kOrigoTypeCommunity]) {
            cell.textLabel.text = [pivot shortAddress];
            
            if ([nonRecipientCandidatesForGroup count]) {
                if ([recipientCandidatesForGroup count]) {
                    cell.detailTextLabel.text = [OUtil commaSeparatedListOfMembers:recipientCandidatesForGroup withRolesInOrigo:_origo];
                } else {
                    cell.detailTextLabel.text = [OUtil commaSeparatedListOfMembers:nonRecipientCandidatesForGroup withRolesInOrigo:_origo];
                }
            } else {
                cell.detailTextLabel.text = [OUtil commaSeparatedListOfMembers:recipientCandidatesForGroup withRolesInOrigo:_origo];
            }
        } else {
            if ([nonRecipientCandidatesForGroup count]) {
                if ([recipientCandidatesForGroup count]) {
                    cell.textLabel.text = [OUtil commaSeparatedListOfMembers:recipientCandidatesForGroup conjoin:NO];
                } else {
                    cell.textLabel.text = [OUtil commaSeparatedListOfMembers:nonRecipientCandidatesForGroup conjoin:NO];
                }
            } else if ([pivot isWardOfUser]) {
                cell.textLabel.text = [OUtil commaSeparatedListOfMembers:recipientCandidatesForGroup conjoin:NO];
            } else {
                cell.textLabel.text = [pivot guardianInfo];
            }
            
            cell.detailTextLabel.text = [pivot displayNameInOrigo:_origo];
            cell.detailTextLabel.textColor = [UIColor tonedDownTextColour];
        }
        
        cell.selectable = [recipientCandidatesForGroup count] > 0;
        
        NSArray *countableElders = nil;
        
        if (cell.selectable) {
            countableElders = recipientCandidatesForGroup;
            _recipientCandidatesByPivotId[[pivot entityId]] = recipientCandidatesForGroup;
        } else {
            countableElders = elders;
        }
        
        if ([countableElders count] > 1) {
            [cell loadTonedDownIconWithFileName:kIconFileRoleHolders];
        } else {
            [cell loadImageForMember:countableElders[0]];
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
        if (_selectedTitleSubsegment == kTitleSubsegmentAll || [self aspectIs:kAspectGlobal]) {
            cell.checked = !cell.checked;
            
            id<OMember> candidateInCell = [self dataAtIndexPath:indexPath];
            
            if (cell.checked) {
                [self addCandidates:@[candidateInCell] toRecipients:_toRecipients];
            } else {
                [_toRecipients removeObject:candidateInCell];
            }
        } else if (_selectedTitleSubsegment == kTitleSubsegmentGrouped) {
            cell.checked = cell.partiallyChecked ? YES : !cell.checked;
            
            id<OEntity> pivot = [self dataAtIndexPath:indexPath];
            
            if (cell.checked) {
                [self addCandidates:_recipientCandidatesByPivotId[pivot.entityId] toRecipients:_toRecipients];
            } else {
                [_toRecipients removeObjectsInArray:_recipientCandidatesByPivotId[pivot.entityId]];
            }
        }
    } else if ([self targetIs:kTargetEmail]) {
        [cell bumpCheckedState];

        if (_selectedTitleSubsegment == kTitleSubsegmentAll || [self aspectIs:kAspectGlobal]) {
            id<OMember> recipientCandidate = [self dataAtIndexPath:indexPath];
            
            if (cell.checkedState == kCellCheckedStateTo) {
                [self addCandidates:@[recipientCandidate] toRecipients:_toRecipients];
            } else if (cell.checkedState == kCellCheckedStateCc) {
                [_toRecipients removeObject:recipientCandidate];
                [self addCandidates:@[recipientCandidate] toRecipients:_ccRecipients];
            } else if (cell.checkedState == kCellCheckedStateNone) {
                [_ccRecipients removeObject:recipientCandidate];
            }
        } else if (_selectedTitleSubsegment == kTitleSubsegmentGrouped) {
            id<OEntity> groupPivot = [self dataAtIndexPath:indexPath];
            NSArray *recipientCandidates = _recipientCandidatesByPivotId[groupPivot.entityId];
            
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
    
    if (![_toRecipients count] && ![_ccRecipients count]) {
        [self toggleSendButton:NO];
    } else {
        [self toggleSendButton:YES];
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
