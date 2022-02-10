//
//  OOrigoJoinerViewController.m
//  Origon
//
//  Created by Anders Blehr on 19/03/15.
//  Copyright (c) 2015 Rhelba Source. All rights reserved.
//

#import "OOrigoJoinerViewController.h"

static NSInteger const kSectionKeyMain = 0;

@interface OOrigoJoinerViewController () <OTableViewController> {
@private
    id<OOrigo> _origo;
    id<OMember> _member;
    
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
        footerText = OLocalizedString(@"The join code can be shared with the parents of children you wish to include in this list. They can then join their children to the list themselves by tapping the join button (circled plus sign) in the start view and entering the join code.", @"");
    } else {
        footerText = OLocalizedString(@"The join code can be shared with those you wish to include in this list. They can then join the list themselves by tapping the join button (circled plus sign) in the start view and entering the join code.", @"");
    }
    
    return footerText;
}


- (void)showJoinCodeSetAlertAndReplicate
{
    [OAlert showAlertWithTitle:OLocalizedString(@"The code has been set", @"") message:[NSString stringWithFormat:OLocalizedString(@"The join code for %@ is '%@'. You may now share it with those you wish to include in the list.", @""), _origo.name, _origo.joinCode]];
    
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
            if ([[membership.origo internalJoinCode] isEqualToString:_internalJoinCode]) {
                existingMembership = membership;
                origo = membership.origo;
                
                joinCodeField.value = origo.joinCode;
                _joinCode = origo.joinCode;
            }
        }
        
        if ([existingMembership isAssociate]) {
            _origo = origo;
            self.navigationItem.rightBarButtonItem = nil;
            
            [self reloadSections];
        } else if (existingMembership) {
            if ([existingMembership isActive]) {
                if ([_member isUser]) {
                    [OAlert showAlertWithTitle:OLocalizedString(@"Already a member", @"") message:[NSString stringWithFormat:OLocalizedString(@"%@ has join code '%@'. You are already a member of %@.", @""), origo.name, _joinCode, origo.name]];
                } else {
                    [OAlert showAlertWithTitle:OLocalizedString(@"Already a member", @"") message:[NSString stringWithFormat:OLocalizedString(@"%@ has join code '%@'. %@ is already a member of %@.", @""), origo.name, _joinCode, [_member givenName], origo.name]];
                }
            } else if ([existingMembership isRequested]) {
                if ([_member isUser]) {
                    [OAlert showAlertWithTitle:OLocalizedString(@"Awaiting approval", @"") message:[NSString stringWithFormat:OLocalizedString(@"%@ has join code '%@'. You have already sent a request to join %@. You will get access as soon as the request has been approved.", @""), origo.name, _joinCode, origo.name]];
                } else {
                    [OAlert showAlertWithTitle:OLocalizedString(@"Awaiting approval", @"") message:[NSString stringWithFormat:OLocalizedString(@"%@ has join code '%@'. You have already sent a request to join %@ to %@. You will get access as soon as the request has been approved.", @""), origo.name, _joinCode, [_member givenName], origo.name]];
                }
            } else if ([existingMembership isDeclined]) {
                if ([_member isUser]) {
                    [OAlert showAlertWithTitle:OLocalizedString(@"Join request declined", @"") message:[NSString stringWithFormat:OLocalizedString(@"%@ has join code '%@'. You have already sent a request to join %@. The request was declined. You can delete or resend the request in the start view.", @""), origo.name, _joinCode, origo.name]];
                } else {
                    [OAlert showAlertWithTitle:OLocalizedString(@"Join request denied", @"") message:[NSString stringWithFormat:OLocalizedString(@"%@ has join code '%@'. You have already sent a request to join %@ to %@. The request was declined. You can delete or resend the request in the start view.", @""), origo.name, _joinCode, [_member givenName], origo.name]];
                }
            }
            
            [self editInlineInCell:_joinCodeCell];
        } else {
            [[OConnection connectionWithDelegate:self] lookupOrigoWithJoinCode:_joinCode];
        }
    }
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    if ([self targetIs:kTargetJoinCode]) {
        _origo = self.state.currentOrigo;
        
        self.title = OLocalizedString(kPropertyKeyJoinCode, kStringPrefixLabel);
    } else if ([self targetIs:kTargetOrigo]) {
        _member = self.state.currentMember;
        
        self.title = OLocalizedString(@"Join list", @"");
        self.navigationItem.leftBarButtonItem = [UIBarButtonItem cancelButtonWithTarget:self];
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem doneButtonWithTitle:OLocalizedString(@"Done", @"") target:self action:@selector(fetchOrigo)];
    }
    
    self.requiresSynchronousServerCalls = YES;
}


- (void)loadData
{
    if ([self targetIs:kTargetJoinCode] && ([_origo userIsAdmin] || _origo.joinCode)) {
        if (self.isOnline || _origo.joinCode) {
            [self setData:@[kPropertyKeyJoinCode] forSectionWithKey:kSectionKeyMain];
        } else {
            [self setData:@[] forSectionWithKey:kSectionKeyMain];
        }
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
        joinCodeField.placeholder = OLocalizedString(kPropertyKeyJoinCode, kStringPrefixLabel);
    }
    
    if ([self targetIs:kTargetJoinCode] || !_origo) {
        if ([self targetIs:kTargetJoinCode]) {
            if ([_origo userIsAdmin]) {
                if ([_origo.joinCode hasValue]) {
                    joinCodeField.value = _origo.joinCode;
                    cell.selectable = self.isOnline;
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
        cell.detailTextLabel.text = OLocalizedString(_origo.type, kStringPrefixOrigoTitle);
        
        if (self.isOnline) {
            [cell loadImageWithName:kIconFileJoin tintColour:[UIColor globalTintColour]];
        } else {
            [cell loadImageWithName:kIconFileJoin tintColour:[UIColor tonedDownTextColour]];
            cell.textLabel.textColor = [UIColor tonedDownTextColour];
            cell.detailTextLabel.textColor = [UIColor tonedDownTextColour];
            cell.selectable = NO;
        }
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
            OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil];
            [actionSheet addButtonWithTitle:OLocalizedString(@"Edit join code", @"") action:^{
                [self editInlineInCell:self->_joinCodeCell];
            }];
            [actionSheet addDestructiveButtonWithTitle:OLocalizedString(@"Delete join code", @"") action:^{
                self->_origo.joinCode = nil;
                [self->_joinCodeCell inlineField].value = nil;
                [[OMeta m].replicator replicate];
                [self editInlineInCell:self->_joinCodeCell];
            }];
            
            [actionSheet show];
        }
    } else if ([self targetIs:kTargetOrigo]) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil];
        [actionSheet addButtonWithTitle:OLocalizedString(@"Send join request", @"") action:^{
            if (![self->_origo instance]) {
                [self->_origo instantiate];
            }
            id<OMembership> membership = [self->_origo addMember:self->_member];
            if (self->_organiserRole) {
                [membership addAffiliation:self->_organiserRole ofType:kAffiliationTypeOrganiserRole];
            }
            [self.dismisser dismissModalViewController:self];
        }];
        
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
        headerContent = [OLocalizedString(@"Send join request", @"") stringByAppendingString:kSeparatorColon];
    } else {
        headerContent = [NSString stringWithFormat:OLocalizedString(@"Send join request for %@:", @""), [_member givenName]];
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
            if (self.isOnline) {
                if ([_member isUser]) {
                    footerContent = OLocalizedString(@"Please enter the join code for the list you want to join.", @"");
                } else {
                    footerContent = [NSString stringWithFormat:OLocalizedString(@"Please enter the join code for the list that %@ should be joined to.", @""), [_member givenName]];
                }
            } else {
                footerContent = OLocalizedString(@"You need a working internet connection to continue.", @"");
            }
        }
    } else if ([self targetIs:kTargetOrigo]) {
        if (self.isOnline) {
            footerContent = [NSString stringWithFormat:OLocalizedString(@"You will get access to %@ as soon as the request has been approved.", @""), _origo.name];
        } else {
            footerContent = OLocalizedString(@"You need a working internet connection to continue.", @"");
        }
    }
    
    return footerContent;
}


- (NSString *)emptyTableViewFooterText
{
    NSString *footerText = nil;
    
    if ([self targetIs:kTargetJoinCode]) {
        if ([_origo userIsAdmin] && !self.isOnline) {
            footerText = [[self infoText] stringByAppendingString:[NSString stringWithFormat:OLocalizedString(@"You need a working internet connection to create a join code for %@.", @""), _origo.name] separator:kSeparatorParagraph];
        } else {
            footerText = [[self infoText] stringByAppendingString:[NSString stringWithFormat:OLocalizedString(@"You may ask an administrator to create a join code for %@.", @""), _origo.name] separator:kSeparatorParagraph];
        }
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


- (void)onlineStatusDidChange
{
    [self reloadSectionWithKey:kSectionKeyMain];
    
    if ([self targetIs:kTargetOrigo]) {
        [self.navigationItem barButtonItemWithTag:kBarButtonItemTagDone].enabled = self.isOnline;
        [self reloadFooterForSectionWithKey:kSectionKeyMain];
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
            [OAlert showAlertWithTitle:OLocalizedString(@"Code in use", @"") message:[NSString stringWithFormat:OLocalizedString(@"The join code '%@' is already in use. Please try to make the code more specific, for instance by including a location and/or a year.", @""), _joinCode]];
            
            [self editInlineInCell:_joinCodeCell];
        }
    } else if ([self targetIs:kTargetOrigo]) {
        if (response.statusCode == kHTTPStatusOK) {
            _origo = [OOrigoProxy proxyForEntityWithDictionary:data];
            
            [_joinCodeCell inlineField].value = _origo.joinCode;
            
            if ([_member isJuvenile] && ![_origo isJuvenile]) {
                NSString *message = nil;
                
                if ([_member isUser]) {
                    if ([_member isMale]) {
                        message = [NSString stringWithFormat:OLocalizedString(@"You are a [male] minor. The list with join code '%@' is primarily for adults. Are you sure you want to join?", @""), _origo.joinCode];
                    } else {
                        message = [NSString stringWithFormat:OLocalizedString(@"You are a [female] minor. The list with join code '%@' is primarily for adults. Are you sure you want to join?", @""), _origo.joinCode];
                    }
                } else {
                    if ([_member isMale]) {
                        message = [NSString stringWithFormat:OLocalizedString(@"%@ is a [male] minor. The list with join code '%@' is primarily for adults. Are you sure you want to continue?", @""), [_member givenName], _origo.joinCode];
                    } else {
                        message = [NSString stringWithFormat:OLocalizedString(@"%@ is a [female] minor. The list with join code '%@' is primarily for adults. Are you sure you want to continue?", @""), [_member givenName], _origo.joinCode];
                    }
                }
                
                [OAlert showAlertWithTitle:OLocalizedString(@"Primarily for adults", @"")
                                   message:message
                             okButtonTitle:OLocalizedString(@"Yes", @"")
                                      onOk:^{
                                          [self reloadSections];
                                          self.navigationItem.rightBarButtonItem = nil;
                                      }
                         cancelButtonTitle:OLocalizedString(@"No", @"")
                                  onCancel:^{ [self editInlineInCell:self->_joinCodeCell]; }];
            } else if (![_member isJuvenile] && [_origo isJuvenile]) {
                if ([_origo isOrganised]) {
                    NSString *origoTitle = [OLanguage inlineNoun:OLocalizedString(_origo.type, kStringPrefixOrigoTitle)];
                    NSString *organiserTitle = [OLanguage inlineNoun:OLocalizedString(_origo.type, kStringPrefixOrganiserTitle)];
                    
                    [OAlert showAlertWithTitle:[NSString stringWithFormat:OLocalizedString(@"Join as %@?", @""),
                                                       organiserTitle]
                                       message:[NSString stringWithFormat:OLocalizedString(@"The list with join code '%@' represents a %@. Do you want to join as %@?", @""),
                                                       _origo.joinCode,
                                                       origoTitle,
                                                       organiserTitle]
                                 okButtonTitle:OLocalizedString(@"Yes", @"")
                                          onOk:^{
                        self->_organiserRole = OLocalizedString(self->_origo.type, kStringPrefixOrganiserTitle);
                                          }
                             cancelButtonTitle:OLocalizedString(@"No", @"")
                                      onCancel:nil];
                } else {
                    [OAlert showAlertWithTitle:OLocalizedString(@"For minors", @"")
                                       message:[NSString stringWithFormat:OLocalizedString(@"The list with join code '%@' is for minors. You cannot join this list.", @""),
                                                       _origo.joinCode]];
                }
            } else if ([_origo isCommunity] && [[_member primaryResidence] elders].count > 1) {
                NSMutableArray *coResidents = [[[_member primaryResidence] elders] mutableCopy];
                [coResidents removeObject:[OMeta m].user];
                
                [OAlert showAlertWithTitle:OLocalizedString(@"Community list", @"")
                                   message:[NSString stringWithFormat:OLocalizedString(@"The list with join code '%@' is a community list which consists of whole households. %@ will also be included in the join request.", @""),
                                                   _origo.joinCode,
                                                   [OUtil commaSeparatedListOfMembers:coResidents
                                                                              conjoin:YES
                                                                           subjective:YES]]
                             okButtonTitle:OLocalizedString(@"Continue", @"")
                                      onOk:^{
                                          [self reloadSections];
                                          self.navigationItem.rightBarButtonItem = nil;
                                      }
                                  onCancel:^{ [self editInlineInCell:self->_joinCodeCell]; }];
            } else {
                [self reloadSections];
                
                self.navigationItem.rightBarButtonItem = nil;
            }
        } else if (response.statusCode == kHTTPStatusNotFound) {
            [OAlert showAlertWithTitle:OLocalizedString(@"Unknown join code", @"") message:[NSString stringWithFormat:OLocalizedString(@"The join code '%@' is unknown. Please check your spelling.", @""), _joinCode]];
            
            [self editInlineInCell:_joinCodeCell];
        }
    }
}

@end
