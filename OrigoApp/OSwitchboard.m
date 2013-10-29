//
//  OSwitchboard.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OSwitchboard.h"

static NSInteger const kServiceRequestEmail = 0;
static NSInteger const kServiceRequestText = 1;
static NSInteger const kServiceRequestPhoneCall = 2;


@implementation OSwitchboard

#pragma mark - Auxiliary methods

- (BOOL)candidate:(OMember *)candidate canHandleServiceRequest:(NSInteger)serviceRequest
{
    BOOL canHandleServiceRequest = NO;
    
    if (serviceRequest == kServiceRequestEmail) {
        canHandleServiceRequest = [candidate.email hasValue];
    } else {
        canHandleServiceRequest = [candidate.mobilePhone hasValue];
    }
    
    return canHandleServiceRequest;
}


- (void)addRecipientCandidates:(id)candidates skipIfContainsUser:(BOOL)skipIfContainsUser
{
    NSMutableArray *emailRecipients = [NSMutableArray array];
    NSMutableArray *phoneRecipients = [NSMutableArray array];
    
    for (OMember *candidate in candidates) {
        if (![candidate isUser]) {
            if ([self candidate:candidate canHandleServiceRequest:kServiceRequestEmail]) {
                [emailRecipients addObject:candidate];
            }
            
            if ([self candidate:candidate canHandleServiceRequest:kServiceRequestPhoneCall]) {
                [phoneRecipients addObject:candidate];
            }
        } else if (skipIfContainsUser) {
            [emailRecipients removeAllObjects];
            [phoneRecipients removeAllObjects];
            
            break;
        }
    }
    
    if ([emailRecipients count]) {
        [_emailRecipientCandidates addObject:emailRecipients];
    }
    
    if ([phoneRecipients count]) {
        [_textRecipientCandidates addObject:phoneRecipients];
        
        if ([phoneRecipients count] == 1) {
            [_callRecipientCandidates addObject:phoneRecipients];
        } else if ([phoneRecipients count] == 2) {
            if (![_member hasParent:phoneRecipients[0]]) {
                [_callRecipientCandidates addObject:@[phoneRecipients[0]]];
            } else if (![_member hasParent:phoneRecipients[1]]) {
                [_callRecipientCandidates addObject:@[phoneRecipients[1]]];
            }
        }
    }
}


- (void)assembleRecipientCandidatesWithEntity:(id)entity
{
    _emailRecipientCandidates = [NSMutableArray array];
    _textRecipientCandidates = [NSMutableArray array];
    _callRecipientCandidates = [NSMutableArray array];
    
    if ([entity isKindOfClass:[OOrigo class]]) {
        [self addRecipientCandidates:[entity fullMemberships] skipIfContainsUser:NO];
    } else if ([entity isKindOfClass:[OMember class]]) {
        _member = entity;
        
        [self addRecipientCandidates:@[_member] skipIfContainsUser:YES];

        if ([_member isMinor]) {
            if ([[_member parents] count]) {
                NSMutableArray *parents = [NSMutableArray array];
                
                for (OMember *parent in [_member parents]) {
                    [parents insertObject:parent atIndex:[parent isUser] ? [parents count] : 0];
                }
                
                if ([parents count] == 2) {
                    [self addRecipientCandidates:parents skipIfContainsUser:YES];
                }
                
                for (OMember *parent in parents) {
                    [self addRecipientCandidates:@[parent] skipIfContainsUser:YES];
                }
                
                for (OMember *parent in parents) {
                    OMember *partner = [parent partner];
                    
                    if (partner) {
                        [self addRecipientCandidates:@[parent, partner] skipIfContainsUser:NO];
                    }
                }
            } else {
                for (OMembership *residency in [_member residencies]) {
                    NSSet *elders = [residency.origo elders];
                    
                    [self addRecipientCandidates:elders skipIfContainsUser:YES];
                    
                    for (OMember *elder in elders) {
                        [self addRecipientCandidates:@[elder] skipIfContainsUser:YES];
                    }
                }
            }
            
            if ([[_member guardians] count] > 2) {
                [self addRecipientCandidates:[_member guardians] skipIfContainsUser:NO];
            }
        }
        
        for (OMembership *residency in [_member residencies]) {
            if ([residency.origo.telephone hasValue]) {
                [_callRecipientCandidates addObject:@[residency.origo]];
            }
        }
    }
}


- (void)processServiceRequest
{
    if ([_recipientCandidates count] == 1) {
        [self performServiceRequestWithRecipients:_recipientCandidates[0]];
    } else {
        [self presentRecipientCandidateSheet];
    }
}


#pragma mark - Action sheets

- (void)presentRecipientCandidateSheet
{
    NSString *prompt = nil;
    
    if (_serviceRequest == kServiceRequestEmail) {
        prompt = [OStrings stringForKey:strSheetTitleEmailRecipient];
    } else if (_serviceRequest == kServiceRequestText) {
        prompt = [OStrings stringForKey:strSheetTitleTextRecipient];
    } else if (_serviceRequest == kServiceRequestPhoneCall) {
        prompt = [OStrings stringForKey:strSheetTitlePhoneCallRecipient];
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:0];
    
    for (NSArray *recipients in _recipientCandidates) {
        if ([recipients count] == 1) {
            if ([recipients[0] isKindOfClass:[OMember class]]) {
                if ([_member isWardOfUser]) {
                    [actionSheet addButtonWithTitle:[recipients[0] givenName]];
                } else if ([_member hasParent:recipients[0]]) {
                    [actionSheet addButtonWithTitle:[recipients[0] nameWithParentTitle]];
                } else {
                    [actionSheet addButtonWithTitle:[recipients[0] name]];
                }
            } else if ([recipients[0] isKindOfClass:[OOrigo class]]) {
                [actionSheet addButtonWithTitle:[recipients[0] shortAddress]];
            }
        } else if ([recipients count] == 2) {
            if ([_member hasParent:recipients[0]] && [_member hasParent:recipients[1]]) {
                [actionSheet addButtonWithTitle:[[OLanguage possessiveClauseWithPossessor:_member noun:_parent_] stringByCapitalisingFirstLetter]];
            } else {
                [actionSheet addButtonWithTitle:[OLanguage plainLanguageListOfItems:recipients]];
            }
        } else if ([recipients count] > 2) {
            [actionSheet addButtonWithTitle:[OStrings stringForKey:strButtonAllContacts]];
        }
    }
    
    [actionSheet show];
}


#pragma mark - Selector implementations

- (void)processEmailRequest
{
    _serviceRequest = kServiceRequestEmail;
    _recipientCandidates = _emailRecipientCandidates;
    
    [self processServiceRequest];
}


- (void)processTextRequest
{
    _serviceRequest = kServiceRequestText;
    _recipientCandidates = _textRecipientCandidates;
    
    [self processServiceRequest];
}


- (void)processPhoneCallRequest
{
    _serviceRequest = kServiceRequestPhoneCall;
    _recipientCandidates = _callRecipientCandidates;
    
    [self processServiceRequest];
}


#pragma mark - Performing service requests

- (void)sendEmailToRecipients:(NSArray *)recipients
{
    NSMutableArray *recipientEmailAddresses = [NSMutableArray array];
    
    for (OMember *recipient in recipients) {
        [recipientEmailAddresses addObject:recipient.email];
    }
    
    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
    mailComposer.mailComposeDelegate = self;
    [mailComposer setToRecipients:recipientEmailAddresses];
    [mailComposer setMessageBody:[OStrings stringForKey:strFooterOrigoSignature] isHTML:NO];

    [[OState s].viewController presentViewController:mailComposer animated:YES completion:NULL];
}


- (void)sendTextToRecipients:(NSArray *)recipients
{
    NSMutableArray *recipientMobileNumbers = [NSMutableArray array];
    
    for (OMember *recipient in recipients) {
        [recipientMobileNumbers addObject:recipient.mobilePhone];
    }
    
    MFMessageComposeViewController *messageComposer = [[MFMessageComposeViewController alloc] init];
    messageComposer.messageComposeDelegate = self;
    messageComposer.recipients = recipientMobileNumbers;
    
    [[OState s].viewController presentViewController:messageComposer animated:YES completion:NULL];
}


- (void)placePhoneCallToRecipient:(id)recipient
{
    NSString *phoneNumber = nil;
    
    if ([recipient isKindOfClass:[OMember class]]) {
        phoneNumber = [recipient mobilePhone];
    } else if ([recipient isKindOfClass:[OOrigo class]]) {
        phoneNumber = [recipient telephone];
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[kProtocolTel stringByAppendingString:phoneNumber]]];
}


- (void)performServiceRequestWithRecipients:(NSArray *)recipients
{
    if (_serviceRequest == kServiceRequestEmail) {
        [self sendEmailToRecipients:recipients];
    } else if (_serviceRequest == kServiceRequestText) {
        [self sendTextToRecipients:recipients];
    } else if (_serviceRequest == kServiceRequestPhoneCall) {
        [self placePhoneCallToRecipient:recipients[0]];
    }
}


#pragma mark - Initialisation

- (id)init
{
    self = [super init];
    
    if (self) {
        _carrier = [[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider];
    }
    
    return self;
}


#pragma mark - Applicable toolbar items

- (NSArray *)toolbarButtonsWithEntity:(id)entity
{
    UIBarButtonItem *flexibleSpace = [UIBarButtonItem flexibleSpace];
    NSMutableArray *toolbarButtons = [NSMutableArray array];
    
    [self assembleRecipientCandidatesWithEntity:entity];

    if ([_emailRecipientCandidates count] || [_callRecipientCandidates count]) {
        [toolbarButtons addObject:flexibleSpace];
        
        if ([_callRecipientCandidates count]) {
            if ([MFMessageComposeViewController canSendText]) {
                [toolbarButtons addObject:[UIBarButtonItem sendTextButtonWithTarget:self]];
                [toolbarButtons addObject:flexibleSpace];
            }
            
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kProtocolTel]]) {
                NSString *mobileNetworkCode = _carrier.mobileNetworkCode;
                
                if ([mobileNetworkCode hasValue] && ![mobileNetworkCode isEqualToString:@"65535"]) {
                    [toolbarButtons addObject:[UIBarButtonItem phoneCallButtonWithTarget:self]];
                    [toolbarButtons addObject:flexibleSpace];
                }
            }
        }
        
        if ([_emailRecipientCandidates count] && [MFMailComposeViewController canSendMail]) {
            [toolbarButtons addObject:[UIBarButtonItem sendEmailButtonWithTarget:self]];
            [toolbarButtons addObject:flexibleSpace];
        }
    }
    
    return [toolbarButtons count] ? toolbarButtons : nil;
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        [self performServiceRequestWithRecipients:_recipientCandidates[buttonIndex]];
    }
}


#pragma mark - MFMailComposeViewControllerDelegate conformance

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [[OState s].viewController dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - MFMessageComposeViewControllerDelegate conformance

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [[OState s].viewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
