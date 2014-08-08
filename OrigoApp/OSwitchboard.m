//
//  OSwitchboard.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OSwitchboard.h"

static NSString * const kProtocolTel = @"tel://";

static NSInteger const kServiceTypeText = 0;
static NSInteger const kServiceTypeCall = 1;
static NSInteger const kServiceTypeEmail = 2;

static NSInteger const kRecipientTagOrigo = 0;
static NSInteger const kRecipientTagMember = 1;
static NSInteger const kRecipientTagContact = 2;
static NSInteger const kRecipientTagParent = 3;
static NSInteger const kRecipientTagParents = 4;
static NSInteger const kRecipientTagGuardians = 5;
static NSInteger const kRecipientTagAllMembers = 6;
static NSInteger const kRecipientTagAllContacts = 7;
static NSInteger const kRecipientTagAllGuardians = 8;


@interface OSwitchboard () <UIActionSheetDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate> {
@private
    id<OOrigo> _origo;
    id<OMember> _member;
    
    NSInteger _requestType;
    NSMutableArray *_recipientTagsByServiceType;
    NSMutableArray *_recipientCandidatesByServiceType;
    NSArray *_recipientCandidates;
    
    UIViewController *_presentingViewController;
}

@end


@implementation OSwitchboard

#pragma mark - Auxiliary methods

- (void)reset
{
    _origo = nil;
    _member = nil;
    
    _recipientCandidatesByServiceType = [NSMutableArray array];
    _recipientCandidatesByServiceType[kServiceTypeText] = [NSMutableArray array];
    _recipientCandidatesByServiceType[kServiceTypeCall] = [NSMutableArray array];
    _recipientCandidatesByServiceType[kServiceTypeEmail] = [NSMutableArray array];
    
    _recipientTagsByServiceType = [NSMutableArray array];
    _recipientTagsByServiceType[kServiceTypeText] = [NSMutableArray array];
    _recipientTagsByServiceType[kServiceTypeCall] = [NSMutableArray array];
    _recipientTagsByServiceType[kServiceTypeEmail] = [NSMutableArray array];
}


#pragma mark - Action sheets

- (void)presentRecipientCandidateSheet
{
    NSArray *recipientTags = _recipientTagsByServiceType[_requestType];
    NSString *prompt = nil;
    NSInteger candidateCount = 0;
    
    if (_requestType == kServiceTypeText) {
        prompt = NSLocalizedString(@"Who do you want to text?", @"");
    } else if (_requestType == kServiceTypeCall) {
        prompt = NSLocalizedString(@"Who do you want to call?", @"");
    } else if (_requestType == kServiceTypeEmail) {
        prompt = NSLocalizedString(@"Who do you want to email?", @"");
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:0];
    
    for (NSArray *recipients in _recipientCandidates) {
        NSInteger recipientTag = [recipientTags[candidateCount] integerValue];
        
        if (recipientTag == kRecipientTagOrigo) {
            id<OOrigo> origo = recipients[0];
            
            if ([origo isOfType:kOrigoTypeResidence]) {
                if ([_origo hasAddress]) {
                    [actionSheet addButtonWithTitle:[origo shortAddress]];
                } else {
                    [actionSheet addButtonWithTitle:NSLocalizedString(@"Home number", @"")];
                }
            } else {
                [actionSheet addButtonWithTitle:origo.name];
            }
        } else if (recipientTag == kRecipientTagMember) {
            [actionSheet addButtonWithTitle:[recipients[0] givenName]];
        } else if (recipientTag == kRecipientTagContact) {
            [actionSheet addButtonWithTitle:[recipients[0] givenNameWithContactRolesForOrigo:_origo]];
        } else if (recipientTag == kRecipientTagParent) {
            if ([[OState s] aspectIs:kAspectHousehold]) {
                [actionSheet addButtonWithTitle:[recipients[0] givenName]];
            } else {
                [actionSheet addButtonWithTitle:[recipients[0] givenNameWithParentTitle]];
            }
        } else if (recipientTag == kRecipientTagParents) {
            [actionSheet addButtonWithTitle:[[OLanguage possessiveClauseWithPossessor:_member noun:_parent_] stringByCapitalisingFirstLetter]];
        } else if (recipientTag == kRecipientTagGuardians) {
            [actionSheet addButtonWithTitle:[OUtil commaSeparatedListOfItems:recipients conjoinLastItem:YES]];
        } else if (recipientTag == kRecipientTagAllMembers) {
            [actionSheet addButtonWithTitle:NSLocalizedString(_origo.type, kStringPrefixAllMembersTitle)];
        } else if (recipientTag == kRecipientTagAllContacts) {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"All contacts", @"")];
        } else if (recipientTag == kRecipientTagAllGuardians) {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"All guardians", @"")];
        }
        
        candidateCount++;
    }
    
    [actionSheet show];
}


#pragma mark - Selector implementations

- (void)processTextRequest
{
    _requestType = kServiceTypeText;
    _recipientCandidates = _recipientCandidatesByServiceType[kServiceTypeText];
    
    [self processServiceRequest];
}


- (void)processCallRequest
{
    _requestType = kServiceTypeCall;
    _recipientCandidates = _recipientCandidatesByServiceType[kServiceTypeCall];
    
    [self processServiceRequest];
}


- (void)processEmailRequest
{
    _requestType = kServiceTypeEmail;
    _recipientCandidates = _recipientCandidatesByServiceType[kServiceTypeEmail];
    
    [self processServiceRequest];
}


#pragma mark - Assembling recipient candidates

- (void)addRecipients:(NSArray *)recipients forServiceType:(NSInteger)serviceType tag:(NSInteger)tag
{
    NSMutableArray *recipientCandidates = _recipientCandidatesByServiceType[serviceType];
    
    BOOL isListed = NO;
    
    if ([recipients count] == 1) {
        for (NSArray *recipientList in recipientCandidates) {
            if (!isListed && [recipientList containsObject:recipients[0]]) {
                isListed = [recipientList count] == 1;
            }
        }
    }
    
    if (!isListed) {
        [_recipientTagsByServiceType[serviceType] addObject:@(tag)];
        [recipientCandidates addObject:recipients];
    }
}


- (void)addRecipientCandidates:(NSArray *)candidates skipUser:(BOOL)skipUser tag:(NSInteger)tag
{
    NSMutableArray *emailRecipients = [NSMutableArray array];
    NSMutableArray *phoneRecipients = [NSMutableArray array];
    
    if (tag == kRecipientTagOrigo) {
        if ([[candidates[0] telephone] hasValue]) {
            [phoneRecipients addObject:candidates[0]];
        }
    } else {
        if (![candidates containsObject:[OMeta m].user] || !skipUser) {
            for (id<OMember> candidate in candidates) {
                if (![candidate isUser]) {
                    if ([candidate.email hasValue]) {
                        [emailRecipients addObject:candidate];
                    }
                    
                    if ([candidate.mobilePhone hasValue]) {
                        [phoneRecipients addObject:candidate];
                    }
                }
            }
        }
    }
    
    if ([emailRecipients count]) {
        [self addRecipients:emailRecipients forServiceType:kServiceTypeEmail tag:tag];
    }
    
    if ([phoneRecipients count]) {
        if (tag != kRecipientTagOrigo) {
            [self addRecipients:phoneRecipients forServiceType:kServiceTypeText tag:tag];
        }
        
        if (([phoneRecipients count] == 1) && (tag != kRecipientTagAllMembers)) {
            [self addRecipients:phoneRecipients forServiceType:kServiceTypeCall tag:tag];
        } else if (_member && ([phoneRecipients count] == 2) && (tag != kRecipientTagParents)) {
            if ([_member hasParent:phoneRecipients[0]]) {
                [self addRecipients:@[phoneRecipients[1]] forServiceType:kServiceTypeCall tag:tag];
            } else if ([_member hasParent:phoneRecipients[1]]) {
                [self addRecipients:@[phoneRecipients[0]] forServiceType:kServiceTypeCall tag:tag];
            }
        }
    }
}


- (void)assembleOrigoRecipientCandidates
{
    if ([_origo.telephone hasValue]) {
        [self addRecipientCandidates:@[_origo] skipUser:NO tag:kRecipientTagOrigo];
    }
    
    if ([_origo isJuvenile]) {
        [self addRecipientCandidates:[_origo guardians] skipUser:NO tag:kRecipientTagAllGuardians];
        
        if ([_origo userIsOrganiser]) {
            [self addRecipientCandidates:[_origo members] skipUser:NO tag:kRecipientTagAllMembers];
        }
        
        if ([_origo hasOrganisers]) {
            [self addRecipientCandidates:[_origo organisers] skipUser:NO tag:kRecipientTagAllContacts];
        }
    }
    
    if ([_origo isOfType:kOrigoTypeResidence]) {
        for (id<OMember> member in [_origo members]) {
            [self addRecipientCandidates:@[member] skipUser:YES tag:kRecipientTagMember];
        }
    } else {
        for (id<OMember> organiser in [_origo organisers]) {
            [self addRecipientCandidates:@[organiser] skipUser:YES tag:kRecipientTagContact];
        }
        
        for (id<OMember> parentContact in [_origo parentContacts]) {
            [self addRecipientCandidates:@[parentContact] skipUser:YES tag:kRecipientTagContact];
        }
    }
    
    if (![_origo isJuvenile]) {
        [self addRecipientCandidates:[_origo members] skipUser:NO tag:kRecipientTagAllMembers];
    }
}


- (void)assembleMemberRecipientCandidates
{
    if ([_member isJuvenile]) {
        if ([[_member parents] count]) {
            NSMutableArray *parents = [NSMutableArray array];
            
            for (id<OMember> parent in [_member parents]) {
                [parents insertObject:parent atIndex:[parent isUser] ? [parents count] : 0];
            }
            
            if ([parents count] == 2) {
                [self addRecipientCandidates:parents skipUser:YES tag:kRecipientTagParents];
            }
            
            for (id<OMember> parent in parents) {
                [self addRecipientCandidates:@[parent] skipUser:YES tag:kRecipientTagParent];
            }
            
            for (id<OMember> parent in parents) {
                id<OMember> partner = [parent partner];
                
                if (partner) {
                    [self addRecipientCandidates:@[parent, partner] skipUser:NO tag:kRecipientTagGuardians];
                }
            }
        } else {
            for (id<OOrigo> residence in [_member residences]) {
                NSArray *elders = [residence elders];
                
                [self addRecipientCandidates:elders skipUser:YES tag:kRecipientTagGuardians];
                
                for (id<OMember> elder in elders) {
                    [self addRecipientCandidates:@[elder] skipUser:YES tag:kRecipientTagMember];
                }
            }
        }
        
        if ([[_member guardians] count] > 2) {
            [self addRecipientCandidates:[_member guardians] skipUser:NO tag:kRecipientTagAllGuardians];
        }
    }
    
    [self addRecipientCandidates:@[_member] skipUser:YES tag:kRecipientTagMember];
    
    for (id<OOrigo> residence in [_member residences]) {
        if ([residence.telephone hasValue]) {
            [self addRecipientCandidates:@[residence] skipUser:NO tag:kRecipientTagOrigo];
        }
    }
}


#pragma mark - Configuring buttons

- (BOOL)hasTextButton
{
    BOOL hasTextRecipients = [_recipientCandidatesByServiceType[kServiceTypeText] count];
    BOOL canSendText = [MFMessageComposeViewController canSendText];
    
    return hasTextRecipients && (canSendText || [OMeta deviceIsSimulator]);
}


- (BOOL)hasCallButton
{
    BOOL hasCallRecipients = [_recipientCandidatesByServiceType[kServiceTypeCall] count];
    BOOL canPlacePhoneCall = NO;
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:kProtocolTel]]) {
        canPlacePhoneCall = [_carrier.mobileNetworkCode hasValue];
    }
    
    return hasCallRecipients && (canPlacePhoneCall || [OMeta deviceIsSimulator]);
}


- (BOOL)hasEmailButton
{
    BOOL hasEmailRecipients = [_recipientCandidatesByServiceType[kServiceTypeEmail] count];
    
    return hasEmailRecipients && [MFMailComposeViewController canSendMail];
}


- (NSArray *)toolbarButtons
{
    BOOL hasTextButton = [self hasTextButton];
    BOOL hasCallButton = [self hasCallButton];
    BOOL hasEmailButton = [self hasEmailButton];
    
    NSMutableArray *toolbarButtons = [NSMutableArray array];
    
    if (hasTextButton || hasCallButton || hasEmailButton) {
        [toolbarButtons addObject:[UIBarButtonItem flexibleSpace]];
        
        if (hasTextButton) {
            [toolbarButtons addObject:[UIBarButtonItem sendTextButtonWithTarget:self]];
            [toolbarButtons addObject:[UIBarButtonItem flexibleSpace]];
        }
        
        if (hasCallButton) {
            [toolbarButtons addObject:[UIBarButtonItem phoneCallButtonWithTarget:self]];
            [toolbarButtons addObject:[UIBarButtonItem flexibleSpace]];
        }
        
        if (hasEmailButton) {
            [toolbarButtons addObject:[UIBarButtonItem sendEmailButtonWithTarget:self]];
            [toolbarButtons addObject:[UIBarButtonItem flexibleSpace]];
        }
    }
    
    return [toolbarButtons count] ? toolbarButtons : nil;
}


#pragma mark - Performing service requests

- (void)sendEmailToRecipients:(NSArray *)recipients
{
    NSMutableArray *recipientEmailAddresses = [NSMutableArray array];
    
    for (id<OMember> recipient in recipients) {
        [recipientEmailAddresses addObject:recipient.email];
    }
    
    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
    mailComposer.mailComposeDelegate = self;
    [mailComposer setToRecipients:recipientEmailAddresses];
    [mailComposer setMessageBody:NSLocalizedString(@"Sent from Origo - http://origoapp.com", @"") isHTML:NO];

    [_presentingViewController presentViewController:mailComposer animated:YES completion:NULL];
}


- (void)sendTextToRecipients:(NSArray *)recipients
{
    NSMutableArray *recipientMobileNumbers = [NSMutableArray array];
    
    for (id<OMember> recipient in recipients) {
        [recipientMobileNumbers addObject:recipient.mobilePhone];
    }
    
    MFMessageComposeViewController *messageComposer = [[MFMessageComposeViewController alloc] init];
    messageComposer.messageComposeDelegate = self;
    messageComposer.recipients = recipientMobileNumbers;
    
    [_presentingViewController presentViewController:messageComposer animated:YES completion:NULL];
}


- (void)placePhoneCallToRecipient:(id)recipient
{
    NSString *phoneNumber = nil;
    
    if ([recipient conformsToProtocol:@protocol(OMember)]) {
        phoneNumber = [[recipient mobilePhone] callablePhoneNumber];
    } else if ([recipient conformsToProtocol:@protocol(OOrigo)]) {
        phoneNumber = [[recipient telephone] callablePhoneNumber];
    }
    
    NSURL *phoneURL = [NSURL URLWithString:[kProtocolTel stringByAppendingString:phoneNumber]];
    
    if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
        [[UIApplication sharedApplication] openURL:phoneURL];
    } else {
        [OAlert showAlertWithTitle:NSLocalizedString(@"Cannot place call", @"") text:[NSString stringWithFormat:NSLocalizedString(@"Cannot place call to %@. It may not be a valid phone number.", @""), phoneNumber]];
    }
}


- (void)performServiceRequestWithRecipients:(NSArray *)recipients
{
    if (_requestType == kServiceTypeEmail) {
        [self sendEmailToRecipients:recipients];
    } else if (_requestType == kServiceTypeText) {
        [self sendTextToRecipients:recipients];
    } else if (_requestType == kServiceTypeCall) {
        [self placePhoneCallToRecipient:recipients[0]];
    }
}


- (void)processServiceRequest
{
    if (_member && [_recipientCandidates count] == 1) {
        [self performServiceRequestWithRecipients:_recipientCandidates[0]];
    } else {
        [self presentRecipientCandidateSheet];
    }
}


#pragma mark - Initialisation

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _carrier = [[[CTTelephonyNetworkInfo alloc] init] subscriberCellularProvider];
    }
    
    return self;
}


#pragma mark - Applicable toolbar items

- (NSArray *)toolbarButtonsForOrigo:(id<OOrigo>)origo presenter:(UIViewController *)presenter
{
    [self reset];
    
    _origo = origo;
    _presentingViewController = presenter;
    
    [self assembleOrigoRecipientCandidates];
    
    return [self toolbarButtons];
}


- (NSArray *)toolbarButtonsForMember:(id<OMember>)member presenter:(UIViewController *)presenter
{
    [self reset];
    
    _member = member;
    _presentingViewController = presenter;
    
    [self assembleMemberRecipientCandidates];
    
    return [self toolbarButtons];
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
    [_presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - MFMessageComposeViewControllerDelegate conformance

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [_presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end
