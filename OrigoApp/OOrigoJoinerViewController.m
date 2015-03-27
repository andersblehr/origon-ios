//
//  OOrigoJoinerViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 19/03/15.
//  Copyright (c) 2015 Rhelba Source. All rights reserved.
//

#import "OOrigoJoinerViewController.h"

static NSInteger const kSectionKeyMain = 0;

static NSInteger const kActionSheetTagJoinCode = 0;
static NSInteger const kButtonTagJoinCodeEdit = 0;
static NSInteger const kButtonTagJoinCodeDelete = 1;

static NSInteger const kActionSheetTagJoin = 1;

static NSInteger const kAlertTagJoinConfirmation = 0;
static NSInteger const kAlertTagJoinAsOrganiser = 1;

@interface OOrigoJoinerViewController () <OTableViewController, UIActionSheetDelegate, UIAlertViewDelegate> {
@private
    id<OOrigo> _origo;
    id<OMember> _member;
    
    OTableViewCell *_joinCell;
    OTableViewCell *_joinCodeCell;
    NSString *_joinCode;
    NSString *_internalJoinCode;
    NSString *_organiserRole;
}

@end


@implementation OOrigoJoinerViewController

#pragma mark - Auxiliary methods

- (NSString *)infoText
{
    NSString *footerText = nil;
    
    if ([_origo isJuvenile]) {
        footerText = [NSString stringWithFormat:NSLocalizedString(@"The join code can be shared with other %@ users whose children should be included in this list. They can then use the code to join their children to the list themselves by tapping the join button (circled plus sign) in the start view.", @""), [OMeta m].appName];
    } else {
        footerText = [NSString stringWithFormat:NSLocalizedString(@"The join code can be shared with other %@ users who should be included in this list. They can then use the code to join the list themselves by tapping the join button (circled plus sign) in the start view.", @""), [OMeta m].appName];
    }
    
    return footerText;
}


- (void)showJoinCodeSetAlertAndReplicate
{
    [OAlert showAlertWithTitle:NSLocalizedString(@"The code has been set", @"") text:[NSString stringWithFormat:NSLocalizedString(@"The join code for %@ is '%@'. You may now share it with other %@ users who should be in the list.", @""), _origo.name, _origo.joinCode, [OMeta m].appName]];
    
    [[OMeta m].replicator replicateIfNeeded];
}


#pragma mark - Selector implementations

- (void)fetchOrigo
{
    OInputField *joinCodeField = [_joinCodeCell inlineField];
    
    _joinCode = joinCodeField.value;
    _internalJoinCode = [_joinCode stringByLowercasingAndRemovingWhitespace];
    
    if (_joinCode) {
        id<OMembership> existingMembership = nil;
        id<OOrigo> origo = nil;
        
        for (id<OMembership> membership in [_member allMembershipsIncludeHidden:YES]) {
            if ([membership.origo.internalJoinCode isEqualToString:_internalJoinCode]) {
                existingMembership = membership;
                origo = membership.origo;
                
                joinCodeField.value = origo.joinCode;
                _joinCode = origo.joinCode;
            }
        }
        
        if (existingMembership) {
            if ([existingMembership isActive]) {
                if ([_member isUser]) {
                    [OAlert showAlertWithTitle:NSLocalizedString(@"Already a member", @"") text:[NSString stringWithFormat:NSLocalizedString(@"%@ has join code '%@'. You are already a member of %@.", @""), origo.name, _joinCode, origo.name]];
                } else {
                    [OAlert showAlertWithTitle:NSLocalizedString(@"Already a member", @"") text:[NSString stringWithFormat:NSLocalizedString(@"%@ has join code '%@'. %@ is already a member of %@.", @""), origo.name, _joinCode, [_member givenName], origo.name]];
                }
            } else if ([existingMembership isRequested]) {
                if ([_member isUser]) {
                    [OAlert showAlertWithTitle:NSLocalizedString(@"Join request sent", @"") text:[NSString stringWithFormat:NSLocalizedString(@"%@ has join code '%@'. You have already sent a request to join %@. You will get access as soon as the request has been approved.", @""), origo.name, _joinCode, origo.name]];
                } else {
                    [OAlert showAlertWithTitle:NSLocalizedString(@"Join request sent", @"") text:[NSString stringWithFormat:NSLocalizedString(@"%@ has join code '%@'. You have already sent a request to join %@ to %@. You will get access as soon as the request has been approved.", @""), origo.name, _joinCode, [_member givenName], origo.name]];
                }
            } else if ([existingMembership isDeclined]) {
                if ([_member isUser]) {
                    [OAlert showAlertWithTitle:NSLocalizedString(@"Join request denied", @"") text:[NSString stringWithFormat:NSLocalizedString(@"%@ has join code '%@'. You have already sent a request to join %@. The request was denied. You can delete or resend the request under Settings.", @""), origo.name, _joinCode, origo.name]];
                } else {
                    [OAlert showAlertWithTitle:NSLocalizedString(@"Join request denied", @"") text:[NSString stringWithFormat:NSLocalizedString(@"%@ has join code '%@'. You have already sent a request to join %@ to %@. The request was denied. You can delete or resend the request under Settings.", @""), origo.name, _joinCode, [_member givenName], origo.name]];
                }
            }
            
            [self editInlineInCell:_joinCodeCell];
        } else {
            [[OConnection connectionWithDelegate:self] lookupOrigoWithJoinCode:_joinCode];
        }
    }
}


#pragma mark - OTableViewController conformance

- (void)loadState
{
    if ([self targetIs:kTargetJoinCode]) {
        _origo = self.state.currentOrigo;
        
        self.title = NSLocalizedString(kPropertyKeyJoinCode, kStringPrefixLabel);
    } else if ([self targetIs:kTargetOrigo]) {
        _member = self.state.currentMember;
        
        self.title = NSLocalizedString(@"Join list", @"");
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTitle:NSLocalizedString(@"Done", @"") target:self action:@selector(fetchOrigo)];
    }
    
    self.requiresSynchronousServerCalls = YES;
}


- (void)loadData
{
    if ([self targetIs:kTargetJoinCode]) {
        [self setData:@[kPropertyKeyJoinCode] forSectionWithKey:kSectionKeyMain];
    } else if ([self targetIs:kTargetOrigo]) {
        if (_origo) {
            [self setData:@[kActionKeyJoinOrigo] forSectionWithKey:kSectionKeyMain];
        } else {
            [self setData:@[kPropertyKeyJoinCode] forSectionWithKey:kSectionKeyMain];
        }
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    OInputField *joinCodeField = nil;
    
    if ([cell isInlineCell]) {
        _joinCodeCell = cell;
        joinCodeField = [_joinCodeCell inlineField];
        joinCodeField.placeholder = NSLocalizedString(kPropertyKeyJoinCode, kStringPrefixLabel);
    }
    
    if ([self targetIs:kTargetJoinCode] || !_origo) {
        if ([self targetIs:kTargetJoinCode]) {
            if ([_origo userIsAdmin]) {
                if ([_origo.joinCode hasValue]) {
                    joinCodeField.value = _origo.joinCode;
                } else {
                    [self editInlineInCell:_joinCodeCell];
                }
            } else if ([_origo.joinCode hasValue]) {
                cell.textLabel.text = _origo.joinCode;
                cell.selectable = NO;
            }
        } else if (!_origo) {
            [self editInlineInCell:_joinCodeCell];
        }
    } else if (_origo) {
        cell.textLabel.text = _origo.name;
        cell.detailTextLabel.text = NSLocalizedString(_origo.type, kStringPrefixOrigoTitle);
        [cell loadImageWithName:kIconFileAddToOrigo tintColour:[UIColor globalTintColour]];
    }
}


- (UITableViewCellStyle)listCellStyleForSectionWithKey:(NSInteger)sectionKey
{
    UITableViewCellStyle style = kTableViewCellStyleDefault;
    
    if ([self targetIs:kTargetJoinCode] || !_origo) {
        style = kTableViewCellStyleInline;
    }
    
    return style;
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self targetIs:kTargetJoinCode]) {
        if ([_origo userIsAdmin]) {
            OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagJoinCode];
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit join code", @"") tag:kButtonTagJoinCodeEdit];
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete join code", @"") tag:kButtonTagJoinCodeDelete];
            
            [actionSheet show];
        }
    } else if ([self targetIs:kTargetOrigo]) {
        _joinCell = cell;
        
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagJoin];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Send join request", @"")];
        
        [actionSheet show];
    }
}


- (BOOL)hasHeaderForSectionWithKey:(NSInteger)sectionKey
{
    return [self targetIs:kTargetOrigo] && _origo;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return YES;
}


- (id)headerContentForSectionWithKey:(NSInteger)sectionKey
{
    NSString *headerContent = nil;
    
    if ([_member isUser]) {
        headerContent = [NSLocalizedString(@"Send join request", @"") stringByAppendingString:kSeparatorColon];
    } else {
        headerContent = [NSString stringWithFormat:NSLocalizedString(@"Send join request for %@:", @""), [_member givenName]];
    }
    
    return headerContent;
}


- (id)footerContentForSectionWithKey:(NSInteger)sectionKey
{
    NSString *footerContent = nil;
    
    if ([self targetIs:kTargetJoinCode] || !_origo) {
        if ([self targetIs:kTargetJoinCode]) {
            footerContent = [self infoText];
        } else {
            if ([_member isUser]) {
                footerContent = NSLocalizedString(@"Please enter the join code for the list you want to join.", @"");
            } else {
                footerContent = [NSString stringWithFormat:NSLocalizedString(@"Please enter the join code for the list that %@ should be joined to.", @""), [_member givenName]];
            }
        }
    } else if ([self targetIs:kTargetOrigo]) {
        footerContent = [NSString stringWithFormat:NSLocalizedString(@"You will get access to %@ as soon as the request has been approved.", @""), _origo.name];
    }
    
    return footerContent;
}


- (NSString *)emptyTableViewFooterText
{
    NSString *footerText = nil;
    
    if ([self targetIs:kTargetJoinCode]) {
        footerText = [[self infoText] stringByAppendingString:[NSString stringWithFormat:NSLocalizedString(@"You may ask an administrator to create a join code for %@.", @""), _origo.name] separator:kSeparatorParagraph];
    }
    
    return footerText;
}


- (void)didFinishEditingInlineField:(OInputField *)inlineField
{
    if ([self targetIs:kTargetJoinCode]) {
        if (self.didCancel) {
            inlineField.value = _origo.joinCode;
            
            if (![_origo.joinCode hasValue]) {
                [self.navigationController popViewControllerAnimated:YES];
            }
        } else {
            _joinCode = inlineField.value;
            _internalJoinCode = [_joinCode stringByLowercasingAndRemovingWhitespace];
            
            if ([_internalJoinCode isEqualToString:_origo.internalJoinCode]) {
                _origo.joinCode = _joinCode;
                
                [self showJoinCodeSetAlertAndReplicate];
            } else {
                [[OConnection connectionWithDelegate:self] lookupOrigoWithJoinCode:_joinCode];
            }
        }
    } else if ([self targetIs:kTargetOrigo]) {
        [self fetchOrigo];
    }
}


#pragma mark - OConnectionDelegate conformance

- (void)connection:(OConnection *)connection didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    [super connection:connection didCompleteWithResponse:response data:data];
    
    if ([self targetIs:kTargetJoinCode]) {
        if (response.statusCode == kHTTPStatusNotFound) {
            _origo.joinCode = _joinCode;
            _origo.internalJoinCode = _internalJoinCode;
            
            [self showJoinCodeSetAlertAndReplicate];
        } else {
            [OAlert showAlertWithTitle:NSLocalizedString(@"The code is in use", @"") text:[NSString stringWithFormat:NSLocalizedString(@"The join code '%@' is already in use. Please try to make the code more specific, for instance by including a location and/or a year.", @""), _joinCode]];
            
            [self editInlineInCell:_joinCodeCell];
        }
    } else if ([self targetIs:kTargetOrigo]) {
        if (response.statusCode == kHTTPStatusOK) {
            _origo = [OOrigoProxy proxyForEntityWithDictionary:data];
            
            [_joinCodeCell inlineField].value = _origo.joinCode;
            
            if ([_member isJuvenile] && ![_origo isJuvenile]) {
                NSString *message = nil;
                
                if ([_member isUser]) {
                    message = [NSString stringWithFormat:NSLocalizedString(@"You are a minor. The list with join code '%@' is primarily for adults. Are you sure you want to join?", @""), _origo.joinCode];
                } else {
                    message = [NSString stringWithFormat:NSLocalizedString(@"%@ is a minor. The list with join code '%@' is primarily for adults. Are you sure you want to continue?", @""), [_member givenName], _origo.joinCode];
                }
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Primarily for adults", @"") message:message delegate:self cancelButtonTitle:NSLocalizedString(@"No", @"") otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
                alert.tag = kAlertTagJoinConfirmation;
                
                [alert show];
            } else if (![_member isJuvenile] && [_origo isJuvenile]) {
                if ([_origo isOrganised]) {
                    NSString *origoTitle = [NSLocalizedString(_origo.type, kStringPrefixOrigoTitle) stringByLowercasingFirstLetter];
                    NSString *organiserTitle = [NSLocalizedString(_origo.type, kStringPrefixOrganiserTitle) stringByLowercasingFirstLetter];
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Join as %@", @""), organiserTitle] message:[NSString stringWithFormat:NSLocalizedString(@"The list with join code '%@' represents a %@. Do you want to join as %@?", @""), _origo.joinCode, origoTitle, organiserTitle] delegate:self cancelButtonTitle:NSLocalizedString(@"No", @"") otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
                    alert.tag = kAlertTagJoinAsOrganiser;
                    
                    [alert show];
                } else {
                    [OAlert showAlertWithTitle:NSLocalizedString(@"For minors", @"") text:[NSString stringWithFormat:NSLocalizedString(@"The list with join code '%@' is for minors. You cannot join this list.", @""), _origo.joinCode]];
                }
            } else if ([_origo isCommunity] && [[[_member primaryResidence] elders] count] > 1) {
                NSMutableArray *coResidents = [[[_member primaryResidence] elders] mutableCopy];
                [coResidents removeObject:[OMeta m].user];
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Community list", @"") message:[NSString stringWithFormat:NSLocalizedString(@"The list with join code '%@' is a community list which consists of whole households. %@ will also be included in the join request.", @""), _origo.joinCode, [OUtil commaSeparatedListOfMembers:coResidents conjoin:YES subjective:YES]] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"Continue", @""), nil];
                alert.tag = kAlertTagJoinConfirmation;
                
                [alert show];
            } else {
                [self reloadSections];
                
                self.navigationItem.rightBarButtonItem = nil;
            }
        } else if (response.statusCode == kHTTPStatusNotFound) {
            [OAlert showAlertWithTitle:NSLocalizedString(@"Unknown join code", @"") text:[NSString stringWithFormat:NSLocalizedString(@"The join code '%@' is unknown. Please check your spelling.", @""), _joinCode]];
            
            [self editInlineInCell:_joinCodeCell];
        }
    }
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
    
    switch (actionSheet.tag) {
        case kActionSheetTagJoinCode:
            _joinCodeCell.selected = NO;
            
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                if (buttonTag == kButtonTagJoinCodeDelete) {
                    _origo.joinCode = nil;
                    [_joinCodeCell inlineField].value = nil;
                    
                    [[OMeta m].replicator replicate];
                }
                
                [self editInlineInCell:_joinCodeCell];
            }
            
            break;
            
        case kActionSheetTagJoin:
            _joinCell.selected = NO;
            
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                [_origo instantiate];
                
                id<OMembership> membership = [_origo addMember:_member];
                
                if (_organiserRole) {
                    [membership addAffiliation:_organiserRole ofType:kAffiliationTypeOrganiserRole];
                }
                
                [self.dismisser dismissModalViewController:self];
            }
            
        default:
            break;
    }
}


#pragma mark - UIAlertViewDelegate conformace

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertTagJoinAsOrganiser:
            if (buttonIndex != alertView.cancelButtonIndex) {
                _organiserRole = NSLocalizedString(_origo.type, kStringPrefixOrganiserTitle);
            }
            
        case kAlertTagJoinConfirmation:
            if (buttonIndex != alertView.cancelButtonIndex) {
                [self reloadSections];
                
                self.navigationItem.rightBarButtonItem = nil;
            } else {
                [self editInlineInCell:_joinCodeCell];
            }
            
            break;
            
        default:
            break;
    }
}

@end
