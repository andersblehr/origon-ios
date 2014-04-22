//
//  OMemberViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OMemberViewController.h"

static NSInteger const kSectionKeyMember = 0;
static NSInteger const kSectionKeyGuardian = 1;
static NSInteger const kSectionKeyAddress = 2;

static NSInteger const kActionSheetTagAction = 0;
static NSInteger const kButtonTagActionAddAddress = 0;
static NSInteger const kButtonTagActionChangePassword = 1;
static NSInteger const kButtonTagActionEdit = 2;
static NSInteger const kButtonTagActionEditRelations = 3;
static NSInteger const kButtonTagActionCorrectGender = 4;

static NSInteger const kActionSheetTagResidence = 1;
static NSInteger const kButtonTagResidenceNewAddress = 10;

static NSInteger const kActionSheetTagSource = 2;
static NSInteger const kButtonTagSourceAddressBook = 0;
static NSInteger const kButtonTagSourceOrigo = 1;

static NSInteger const kActionSheetTagAddressBookEntry = 3;
static NSInteger const kButtonTagAddressBookEntryAllValues = 10;
static NSInteger const kButtonTagAddressBookEntryNoValue = 11;

static NSInteger const kAlertTagEmailChange = 0;
static NSInteger const kButtonTagContinue = 1;


@implementation OMemberViewController

#pragma mark - Auxiliary methods

- (void)resetInputState
{
    [self.detailCell clearInputFields];
    
    if ([self hasSectionWithKey:kSectionKeyAddress]) {
        _candidateResidences = [NSArray array];
        
        [self reloadSectionWithKey:kSectionKeyAddress];
        [self setFooterText:[self textForFooterInSectionWithKey:kSectionKeyMember] forSectionWithKey:kSectionKeyMember];
    }
}


- (BOOL)isRegisteringJuvenileElder
{
    return [self actionIs:kActionRegister] && [self targetIs:kTargetElder];
}


#pragma mark - Input validation

- (BOOL)isEligibleMember:(id)registrant
{
    BOOL isValid = YES;
    
    if ([_origo hasMember:registrant]) {
        OInputField *identifierField = _emailField.value ? _emailField : _mobilePhoneField;
        
        identifierField.value = [NSString string];
        [identifierField becomeFirstResponder];
        
        [OAlert showAlertWithTitle:NSLocalizedString(@"Already member", @"") text:[NSString stringWithFormat:NSLocalizedString(@"%@ is already a member of %@.", @""), [_member facade].name, [_origo facade].name]];
        
        isValid = NO;
    } else {
        [self presentMember:registrant];
    }
    
    return isValid;
}


- (BOOL)inputFieldHasValidValue:(OInputField *)inputField
{
    BOOL hasValidValue = [inputField hasValidValue];
    
    if (hasValidValue && [self actionIs:kActionRegister] && ![self targetIs:kTargetUser]) {
        id registrant = [[OMeta m].context entityOfClass:[OMember class] withValue:inputField.value forKey:inputField.key];
        
        if (registrant) {
            hasValidValue = [self isEligibleMember:registrant];
        }
    }
    
    return hasValidValue;
}


- (BOOL)inputMatchesRegisteredMember:(id)candidate
{
    BOOL inputMatches = [OUtil name:_nameField.value matchesName:[candidate facade].name];
    
    if (inputMatches && !_dateOfBirthField.isHidden) {
        inputMatches = [_dateOfBirthField.value isEqual:[candidate facade].dateOfBirth];
    }
    
    if (inputMatches && _mobilePhoneField.value) {
        inputMatches = [[OPhoneNumberFormatter formatPhoneNumber:_mobilePhoneField.value canonicalise:YES] isEqualToString:[OPhoneNumberFormatter formatPhoneNumber:[candidate facade].mobilePhone canonicalise:YES]];
    }
    
    if (inputMatches && _emailField.value) {
        inputMatches = [_emailField.value isEqualToString:[candidate facade].email];
    }
    
    return inputMatches;
}


#pragma mark - Member lookup & presentation

- (void)lookupMemberOnDevice
{
    if (_emailField.value || _mobilePhoneField.value) {
        OMember *member = nil;
        
        if (_emailField.value) {
            member = [[OMeta m].context entityOfClass:[OMember class] withValue:_emailField.value forKey:kPropertyKeyEmail];
        }
        
        if (!member && _mobilePhoneField.value) {
            member = [[OMeta m].context entityOfClass:[OMember class] withValue:_mobilePhoneField.value forKey:kPropertyKeyMobilePhone];
            
            if (member && member.email) {
                member = nil;
            }
        }
        
        if (member) {
            [self presentMember:member];
        }
    }
}


- (void)presentMember:(id)member
{
    _nameField.value = [member facade].name;

    NSString *mobilePhone = [member facade].mobilePhone;
    NSString *email = [member facade].email;
    
    if (mobilePhone) {
        _mobilePhoneField.value = mobilePhone;
    }
    
    if (email && !_emailField.value) {
        _emailField.value = email;
    }
    
    _member = member;
}


#pragma mark - Examine and persist new member

- (void)examineMember
{
    [self.detailCell writeEntityInstantiate:NO];
    
    [[OMemberExaminer examinerForResidence:_origo delegate:self] examineMember:_member];
}


- (void)persistMember
{
    [self.detailCell writeEntityInstantiate:YES];
    
    if ([self actionIs:kActionRegister]) {
        OOrigo *residence = [_member residence];
        
        if ([residence hasAddress]) {
            if ([_member isUser] && ![_member isActive]) {
                [_member makeActive];
            }
            
            [self.dismisser dismissModalViewController:self reload:YES];
        } else {
            [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:residence];
        }
    }
}


#pragma mark - Action sheets & alerts

- (void)presentCandidateResidencesSheet:(NSSet *)residences
{
    _candidateResidences = [residences sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:kPropertyKeyAddress ascending:YES]]];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagResidence];
    
    for (OOrigo *residence in _candidateResidences) {
        [actionSheet addButtonWithTitle:[residence shortAddress]];
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"New address", @"") tag:kButtonTagResidenceNewAddress];
    
    [actionSheet show];
}


- (void)presentActionSheetForMultiValueField:(OInputField *)multiValueField
{
    NSString *promptFormat = nil;
    
    if (multiValueField == _mobilePhoneField) {
        promptFormat = NSLocalizedString(@"%@ has more than one mobile phone number. Which number do you want to provide?", @"");
    } else if (multiValueField == _emailField) {
        promptFormat = NSLocalizedString(@"%@ has more than one email address. Which address do you want to provide?", @"");
    }
    
    [multiValueField becomeFirstResponder];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:promptFormat, [OUtil givenNameFromFullName:_nameField.value]] delegate:self tag:kActionSheetTagAddressBookEntry];
    
    for (NSInteger i = 0; i < [multiValueField.value count]; i++) {
        [actionSheet addButtonWithTitle:multiValueField.value[i]];
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"None of them", @"") tag:kButtonTagAddressBookEntryNoValue];
    
    [actionSheet show];
}


- (void)presentActionSheetForMultipleAddresses
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:NSLocalizedString(@"%@ has more than one home address. Which address do you want to provide?", @""), [OUtil givenNameFromFullName:_nameField.value]] delegate:self tag:kActionSheetTagAddressBookEntry];
    
    for (NSInteger i = 0; i < [_addressBookAddresses count]; i++) {
        [actionSheet addButtonWithTitle:[_addressBookAddresses[i] shortAddress]];
    }
    
    NSString *allTitle = nil;
    NSString *noneTitle = nil;
    
    if ([_addressBookAddresses count] == 2) {
        allTitle = NSLocalizedString(@"Both", @"");
        noneTitle = NSLocalizedString(@"Neither", @"");
    } else {
        allTitle = NSLocalizedString(@"All of them", @"");
        noneTitle = NSLocalizedString(@"None of them", @"");
    }
    
    [actionSheet addButtonWithTitle:allTitle tag:kButtonTagAddressBookEntryAllValues];
    [actionSheet addButtonWithTitle:noneTitle tag:kButtonTagAddressBookEntryNoValue];
    
    [actionSheet show];
}


- (void)presentActionSheetForMappingHomeNumbers
{
    static NSInteger originalHomeNumberCount = 0;

    if (!originalHomeNumberCount) {
        originalHomeNumberCount = [_addressBookHomeNumbers count];
    }
    
    NSString *givenName = [OUtil givenNameFromFullName:_nameField.value];
    NSString *prompt = nil;
    
    if ([_candidateResidences count] == 1) {
        _homeNumberMappings = _addressBookHomeNumbers;
        
        if ([_candidateResidences[0] hasAddress]) {
            prompt = [NSString stringWithFormat:NSLocalizedString(@"%@ has more than one home phone number. Which number is valid for %@?", @""), givenName, [_candidateResidences[0] shortAddress]];
        } else {
            prompt = [NSString stringWithFormat:NSLocalizedString(@"%@ has more than one home phone number. Which number do you want to provide?", @""), givenName];
        }
    } else {
        _homeNumberMappings = [NSMutableArray array];
        
        for (id residence in _candidateResidences) {
            if (![residence facade].telephone) {
                [_homeNumberMappings addObject:residence];
            }
        }
        
        if (originalHomeNumberCount == 1) {
            prompt = [NSString stringWithFormat:NSLocalizedString(@"%@ has only one home phone number, %@. Which address has this number?", @""), givenName, _addressBookHomeNumbers[0]];
        } else if ([_addressBookHomeNumbers count] == originalHomeNumberCount) {
            prompt = [NSString stringWithFormat:NSLocalizedString(@"%@ has more than one home phone number. Which address has the number %@?", @""), givenName, _addressBookHomeNumbers[0]];
        } else {
            if (([_addressBookHomeNumbers count] == 1) && ([_homeNumberMappings count] == 1)) {
                prompt = [NSString stringWithFormat:NSLocalizedString(@"Does %@ have home phone number %@?", @""), [_homeNumberMappings[0] shortAddress], _addressBookHomeNumbers[0]];
            } else {
                prompt = [NSString stringWithFormat:NSLocalizedString(@"Which address has home phone number %@?", @""), _addressBookHomeNumbers[0]];
            }
        }
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagAddressBookEntry];
    
    if (([_addressBookHomeNumbers count] == 1) && ([_homeNumberMappings count] == 1)) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Yes", @"")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"No", @"") tag:kButtonTagAddressBookEntryNoValue];
    } else {
        for (NSInteger i = 0; i < [_homeNumberMappings count]; i++) {
            if ([_homeNumberMappings[0] isKindOfClass:[NSString class]]) {
                [actionSheet addButtonWithTitle:_homeNumberMappings[i]];
            } else {
                [actionSheet addButtonWithTitle:[_homeNumberMappings[i] shortAddress]];
            }
        }
        
        [actionSheet addButtonWithTitle:NSLocalizedString(@"None of them", @"") tag:kButtonTagAddressBookEntryNoValue];
    }
    
    [actionSheet show];
}


- (void)presentUserEmailChangeAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"New email address", @"") message:[NSString stringWithFormat:NSLocalizedString(@"You are about to change your email address from %@ to %@ ...", @""), [_member facade].email, _emailField.value] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"Continue", @""), nil];
    alert.tag = kAlertTagEmailChange;
    
    [alert show];
}


- (void)presentMemberEmailChangeAlert
{
    // TODO
}


#pragma mark - Adress book entry processing

- (BOOL)addressBookEntryNeedsProcessing
{
    BOOL needsProcessing = NO;
    
    needsProcessing = needsProcessing || [_mobilePhoneField hasMultiValue];
    needsProcessing = needsProcessing || [_emailField hasMultiValue];
    needsProcessing = needsProcessing || [_addressBookAddresses count];
    needsProcessing = needsProcessing || [_addressBookHomeNumbers count];
    
    return needsProcessing;
}


- (void)processAddressBookEntry
{
    if ([_mobilePhoneField hasMultiValue]) {
        [self presentActionSheetForMultiValueField:_mobilePhoneField];
    } else if ([_emailField hasMultiValue]) {
        [self presentActionSheetForMultiValueField:_emailField];
    } else if ([_addressBookAddresses count]) {
        [self presentActionSheetForMultipleAddresses];
    } else if ([_addressBookHomeNumbers count]) {
        [self presentActionSheetForMappingHomeNumbers];
    }
}


- (void)presentAddressBookEntry
{
    if ([_candidateResidences count]) {
        [self reloadSectionWithKey:kSectionKeyAddress];
        [self setFooterText:[self textForFooterInSectionWithKey:kSectionKeyMember] forSectionWithKey:kSectionKeyMember];
    }
    
    OInputField *invalidInputField = [self.detailCell nextInvalidInputField];
    
    if (invalidInputField) {
        [invalidInputField becomeFirstResponder];
    } else {
        [_emailField becomeFirstResponder];
    }
}


#pragma mark - Retrieving address book entry

- (void)pickFromAddressBook
{
    ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
    peoplePicker.peoplePickerDelegate = self;
    
    [self presentViewController:peoplePicker animated:YES completion:NULL];
}


- (void)setNameFromAddressBookEntry:(ABRecordRef)entry
{
    NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(entry, kABPersonFirstNameProperty);
    NSString *middleName = (__bridge_transfer NSString *)ABRecordCopyValue(entry, kABPersonMiddleNameProperty);
    NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(entry, kABPersonLastNameProperty);
    
    NSString *fullName = [OMeta usingEasternNameOrder] ? lastName : firstName;
    
    if (fullName) {
        NSString *nextName = [OMeta usingEasternNameOrder] ? firstName : middleName;
        
        if (nextName) {
            fullName = [fullName stringByAppendingString:nextName separator:kSeparatorSpace];
        }
        
        nextName = [OMeta usingEasternNameOrder] ? middleName : lastName;
        
        if (nextName) {
            fullName = [fullName stringByAppendingString:nextName separator:kSeparatorSpace];
        }
    }
    
    _nameField.value = fullName;
}


- (void)setAddressesFromAddressBookEntry:(ABRecordRef)entry
{
    ABMultiValueRef multiValues = ABRecordCopyValue(entry, kABPersonAddressProperty);
    
    for (CFIndex i = 0; i < ABMultiValueGetCount(multiValues); i++) {
        NSString *label = (__bridge_transfer NSString *)ABMultiValueCopyLabelAtIndex(multiValues, i);
        
        if ([label isEqualToString:(NSString *)kABHomeLabel]) {
            [_addressBookAddresses addObject:[OOrigoProxy proxyFromAddressBookEntry:ABMultiValueCopyValueAtIndex(multiValues, i)]];
        }
    }
    
    CFRelease(multiValues);
    
    if ([_addressBookAddresses count] == 1) {
        _candidateResidences = @[_addressBookAddresses[0]];
        [_addressBookAddresses removeAllObjects];
    }
}


- (void)setPhoneNumbersFromAddressBookEntry:(ABRecordRef)entry
{
    NSMutableArray *mobilePhoneNumbers = [NSMutableArray array];
    ABMultiValueRef multiValues = ABRecordCopyValue(entry, kABPersonPhoneProperty);
    
    for (CFIndex i = 0; i < ABMultiValueGetCount(multiValues); i++) {
        NSString *label = (__bridge_transfer NSString *)ABMultiValueCopyLabelAtIndex(multiValues, i);
        
        BOOL isMobilePhone = [label isEqualToString:(NSString *)kABPersonPhoneMobileLabel];
        BOOL is_iPhone = [label isEqualToString:(NSString *)kABPersonPhoneIPhoneLabel];
        BOOL isHomePhone = [label isEqualToString:(NSString *)kABHomeLabel];
        
        if (isMobilePhone || is_iPhone || isHomePhone) {
            NSString *phoneNumber = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(multiValues, i);
            
            if (isMobilePhone || is_iPhone) {
                [mobilePhoneNumbers addObject:phoneNumber];
            } else {
                [_addressBookHomeNumbers addObject:phoneNumber];
            }
        }
    }
    
    CFRelease(multiValues);
    
    if ([_addressBookHomeNumbers count]) {
        if (![_addressBookAddresses count] && ![_candidateResidences count]) {
            if ([_addressBookHomeNumbers count] == 1) {
                _candidateResidences = @[[OOrigoProxy proxyWithType:kOrigoTypeResidence]];
            }
        }
        
        if ([_addressBookHomeNumbers count] == [_candidateResidences count]) {
            [_candidateResidences[0] facade].telephone = _addressBookHomeNumbers[0];
            [_addressBookHomeNumbers removeAllObjects];
        }
    }
    
    _mobilePhoneField.value = [mobilePhoneNumbers count] ? mobilePhoneNumbers : nil;
}


- (void)setEmailFromAddressBookEntry:(ABRecordRef)entry
{
    NSMutableArray *emailAddresses = [NSMutableArray array];
    ABMultiValueRef multiValues = ABRecordCopyValue(entry, kABPersonEmailProperty);
    
    for (CFIndex i = 0; i < ABMultiValueGetCount(multiValues); i++) {
        NSString *emailAddress = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(multiValues, i);
        
        if ([OValidator valueIsEmailAddress:emailAddress]) {
            [emailAddresses addObject:emailAddress];
        }
    }
    
    CFRelease(multiValues);
    
    _emailField.value = [emailAddresses count] ? emailAddresses : nil;
}


#pragma mark - Selector implementations

- (void)presentActionSheet
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagAction];
    
    if ([_member isUser]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Change password", @"") tag:kButtonTagActionChangePassword];
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit", @"") tag:kButtonTagActionEdit];
    
    if ([_member isWardOfUser]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit relations", @"") tag:kButtonTagActionEditRelations];
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Add an address", @"") tag:kButtonTagActionAddAddress];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Correct gender", @"") tag:kButtonTagActionCorrectGender];
    
    [actionSheet show];
}


- (void)performLookup
{
    [self.view endEditing:YES];
    
    if ([[[OState s].pivotMember peersNotInOrigo:_origo] count] > 0) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagSource];
        
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Retrieve from Contacts", @"")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Retrieve from Origo", @"")];
        
        [actionSheet show];
    } else {
        [self resetInputState];
        [self pickFromAddressBook];
    }
}


#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    if (!_nameField) {
        _nameField = [self.detailCell inputFieldForKey:kPropertyKeyName];
        _dateOfBirthField = [self.detailCell inputFieldForKey:kPropertyKeyDateOfBirth];
        _mobilePhoneField = [self.detailCell inputFieldForKey:kPropertyKeyMobilePhone];
        _emailField = [self.detailCell inputFieldForKey:kPropertyKeyEmail];
    }
    
    if ([self actionIs:kActionRegister]) {
        if ([_origo isJuvenile] && ![self targetIs:kTargetGuardian]) {
            [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetGuardian];
        }
    }
    
    [super viewDidAppear:animated];
}


#pragma mark - OTableViewController custom accessors

- (BOOL)canEdit
{
    return [_member isManagedByUser];
}


#pragma mark - OTableViewControllerInstance conformance

- (void)loadState
{
    _member = [self.entityProxy facade];
    _origo = [[self.entityProxy parentWithClass:[OOrigo class]] facade];
    
    if ([_origo isInstantiated] && [_member isInstantiated]) {
        _membership = [_origo membershipForMember:_member];
    }
    
    if ([self targetIs:kTargetUser]) {
        self.title = NSLocalizedString(@"About me", @"");
    } else if ([self targetIs:kTargetGuardian]) {
        self.title = [[OLanguage nouns][_guardian_][singularIndefinite] capitalizedString];
    } else if ([self targetIs:kTargetContact]) {
        self.title = NSLocalizedString([_origo facade].type, kKeyPrefixContactTitle);
    } else if ([self targetIs:kTargetParentContact]) {
        self.title = NSLocalizedString(@"Parent contact", @"");
    } else if ([_member isInstantiated]) {
        self.title = [_member isHousemateOfUser] ? [_member givenName] : [_member facade].name;
        self.navigationItem.backBarButtonItem = [UIBarButtonItem buttonWithTitle:[_member givenName]];
    } else {
        self.title = NSLocalizedString([_origo facade].type, kKeyPrefixNewMemberTitle);
    }
    
    if ([self actionIs:kActionDisplay]) {
        if (self.canEdit) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem actionButton];
        }
    } else if ([self actionIs:kActionRegister] && ![self targetIs:kTargetUser]) {
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem lookupButton];
    }
}


- (void)loadData
{
    [self setDataForDetailSection];
    
    if ([self actionIs:kActionDisplay]) {
        if ([_member isJuvenile]) {
            [self setData:[_member guardians] forSectionWithKey:kSectionKeyGuardian];
        }
        
        [self setData:[_member residences] forSectionWithKey:kSectionKeyAddress];
    } else if (_candidateResidences) {
        [self setData:_candidateResidences forSectionWithKey:kSectionKeyAddress];
    }
}


- (NSArray *)toolbarButtons
{
    NSArray *toolbarButtons = nil;
    
    if ([_member isInstantiated] && ![_member isUser]) {
        toolbarButtons = [[OMeta m].switchboard toolbarButtonsForMember:_member];
    }
    
    return toolbarButtons;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasFooter = [self actionIs:kActionRegister] && [self isLastSectionKey:sectionKey];
    
    hasFooter = hasFooter && ![self targetIs:kTargetUser];
    hasFooter = hasFooter && (![_origo isJuvenile] || [self isRegisteringJuvenileElder]);
    
    return hasFooter;
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kSectionKeyGuardian) {
        NSSet *guardians = [_member guardians];
        
        if ([guardians count] == 1) {
            OMember *guardian = [guardians anyObject];
            
            if ([_member hasParent:guardian]) {
                text = [guardian parentNoun][singularIndefinite];
            } else {
                text = [OLanguage nouns][_guardian_][singularIndefinite];
            }
        } else {
            if ([_member guardiansAreParents]) {
                text = [OLanguage nouns][_parent_][pluralIndefinite];
            } else {
                text = [OLanguage nouns][_guardian_][pluralIndefinite];
            }
        }
    } else if (sectionKey == kSectionKeyAddress) {
        if (([[_member residences] count] == 1) || ([_candidateResidences count] == 1)) {
            text = [OLanguage nouns][_address_][singularIndefinite];
        } else if (([[_member residences] count] > 1) || ([_candidateResidences count] > 1)) {
            text = [OLanguage nouns][_address_][pluralIndefinite];
        }
    }
    
    return [text capitalizedString];
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if ([self hasFooterForSectionWithKey:sectionKey]) {
        text = NSLocalizedString(@"A notification will be sent to the email address you provide.", @"");
        
        if ([_origo isJuvenile] && [self targetIs:kTargetGuardian]) {
            text = [NSString stringWithFormat:@"%@\n\n%@", NSLocalizedString(@"Before you can register a minor, you must register his or her parents/guardians.", @""), text];
        }
    }
    
    return text;
}


- (BOOL)canDeleteRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDelete = NO;
    
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyAddress) {
        canDelete = ([self tableView:self.tableView numberOfRowsInSection:indexPath.section] > 1);
    }
    
    return canDelete;
}


- (BOOL)shouldRelayDismissalOfModalViewController:(OTableViewController *)viewController
{
    BOOL shouldRelayDismissal = NO;
    
    if ([viewController.identifier isEqualToString:kIdentifierMember]) {
        shouldRelayDismissal = !viewController.returnData;
    } else if ([viewController.identifier isEqualToString:kIdentifierOrigo]) {
        shouldRelayDismissal = YES;
    }
    
    return shouldRelayDismissal;
}


- (void)willDismissModalViewController:(OTableViewController *)viewController
{
    if ([viewController.identifier isEqualToString:kIdentifierAuth]) {
        if ([[_member facade].email isEqualToString:_emailField.value]) {
            [self persistMember];
        } else {
            UIAlertView *failedEmailChangeAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Activation failed", @"") message:[NSString stringWithFormat:NSLocalizedString(@"The email address %@ could not be activated ...", @""), _emailField.value] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [failedEmailChangeAlert show];
            
            self.nextInputField = _emailField;
            [self toggleEditMode];
        }
    }
}


- (void)didDismissModalViewController:(OTableViewController *)viewController
{
    if (viewController.returnData) {
        if ([viewController.identifier isEqualToString:kIdentifierValuePicker]) {
            if (![self aspectIsHousehold] && [self isEligibleMember:viewController.returnData]) {
                [self endEditing];
            }
        } else if ([viewController.identifier isEqualToString:kIdentifierMember]) {
            // TODO
        }
    }
}


- (BOOL)serverRequestsAreSynchronous
{
    return YES;
}


#pragma mark - OTableViewListDelegate conformance

- (NSString *)sortKeyForSectionWithKey:(NSInteger)sectionKey
{
    NSString *sortKey = nil;
    
    if (sectionKey == kSectionKeyAddress) {
        sortKey = [OUtil sortKeyWithPropertyKey:kPropertyKeyAddress relationshipKey:kRelationshipKeyOrigo];
    }
    
    return sortKey;
}


- (BOOL)willCompareObjectsInSectionWithKey:(NSInteger)sectionKey
{
    return (sectionKey == kSectionKeyGuardian);
}


- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2
{
    NSComparisonResult result = NSOrderedSame;
    
    OMember *guardian1 = (OMember *)object1;
    OMember *guardian2 = (OMember *)object2;
    
    if ([_member hasParent:guardian1] && ![_member hasParent:guardian2]) {
        result = NSOrderedAscending;
    } else if (![_member hasParent:guardian1] && [_member hasParent:guardian2]) {
        result = NSOrderedDescending;
    } else {
        NSString *address1 = [guardian1 shortAddress];
        NSString *address2 = [guardian2 shortAddress];
        
        if ([address1 isEqualToString:address2]) {
            result = [guardian1.name localizedCompare:guardian2.name];
        } else {
            result = [address1 localizedCompare:address2];
        }
    }
    
    return result;
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyGuardian) {
        OMember *guardian = [self dataAtIndexPath:indexPath];
        
        cell.imageView.image = [guardian smallImage];
        cell.textLabel.text = guardian.name;
        cell.destinationId = kIdentifierMember;

        if ([[_member residences] count] == 1) {
            cell.detailTextLabel.text = [guardian shortDetails];
        } else {
            cell.detailTextLabel.text = [guardian shortAddress];
        }
        
        if ([_member hasParent:guardian] && ![_member guardiansAreParents]) {
            cell.detailTextLabel.text = [[[guardian parentNoun][singularIndefinite] capitalizedString] stringByAppendingString:cell.detailTextLabel.text separator:kSeparatorComma];
        }
    } else if (sectionKey == kSectionKeyAddress) {
        id residence = [self dataAtIndexPath:indexPath];
        
        cell.imageView.image = [UIImage imageNamed:kIconFileHousehold];
        cell.textLabel.text = [residence shortAddress];
        cell.detailTextLabel.text = [OPhoneNumberFormatter formatPhoneNumber:[residence facade].telephone canonicalise:YES];
        
        [cell setDestinationId:kIdentifierOrigo selectableDuringInput:YES];
    }
}


#pragma mark - OTableViewInputDelegate conformance

- (BOOL)inputIsValid
{
    if (![_member isUser]) {
        [self lookupMemberOnDevice];
    }
    
    BOOL isValid = [_nameField hasValidValue];
    
    if (isValid && [self aspectIsHousehold]) {
        isValid = [_dateOfBirthField hasValidValue];
        
        if ([_member isInstantiated] && ![_member isUser]) {
            isValid = [_dateOfBirthField.value isEqual:[_member facade].dateOfBirth];
            
            if (!isValid) {
                [_dateOfBirthField becomeFirstResponder];
            }
        }
    }
    
    if (isValid && _mobilePhoneField.value) {
        if (_emailField.value) {
            isValid = [_mobilePhoneField hasValidValue];
        } else {
            isValid = [self inputFieldHasValidValue:_mobilePhoneField];
        }
    }
    
    if (isValid && _emailField.value) {
        isValid = [self inputFieldHasValidValue:_emailField];
    }
    
    if (isValid && ([_member isUser] || ![_dateOfBirthField.value isBirthDateOfMinor])) {
        if ([self aspectIsHousehold]) {
            isValid = [_mobilePhoneField hasValidValue] && [_emailField hasValidValue];
        } else {
            isValid = _emailField.value || [_mobilePhoneField hasValidValue];
        }
    }
    
    return isValid;
}


- (void)processInput
{
    if ([self actionIs:kActionRegister]) {
        if ([_member isInstantiated] && ![_member isUser]) {
            if ([_origo isOfType:kOrigoTypeResidence]) {
                [self examineMember];
            } else {
                [self persistMember];
            }
        } else {
            if (![_member isUser] && (_emailField.value || _mobilePhoneField.value)) {
                [[OConnection connectionWithDelegate:self] lookupMemberWithIdentifier:_emailField.value ? _emailField.value : _mobilePhoneField.value];
            } else {
                [self examineMember];
            }
        }
    } else if ([self actionIs:kActionEdit]) {
        NSString *email = [_member facade].email;
        
        if ([email hasValue] && ![_emailField.value isEqualToString:email]) {
            if ([_member isUser]) {
                [self presentUserEmailChangeAlert];
            } else {
                [self presentMemberEmailChangeAlert];
            }
        } else {
            [self persistMember];
            [self toggleEditMode];
        }
    }
}


- (void)didInstantiateEntity:(id)entity
{
    _member = entity;
    
    for (id residence in _candidateResidences) {
        [[residence instantiate] addMember:_member];
    }
    
    if (!_membership) {
        _membership = [_origo addMember:_member];
    }
}


- (BOOL)canEditInputFieldWithKey:(NSString *)key
{
    BOOL canEdit = YES;
    
    if ([key isEqualToString:kPropertyKeyEmail]) {
        canEdit = ![self actionIs:kActionRegister] || ![self targetIs:kTargetUser];
    }
    
    return canEdit;
}


#pragma mark - OMemberExaminerDelegate conformance

- (void)examinerDidFinishExamination
{
    if (self.returnData) {
        [[OMeta m].context saveServerReplicas:self.returnData];
    }
    
    [self persistMember];
}


- (void)examinerDidCancelExamination
{
    [self.detailCell resumeFirstResponder];
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
    
    switch (actionSheet.tag) {
        case kActionSheetTagAction:
            if (buttonTag == kButtonTagActionEdit) {
                [self toggleEditMode];
            }
            
            break;
            
        case kActionSheetTagAddressBookEntry:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                if ([_mobilePhoneField hasMultiValue]) {
                    if (buttonTag != kButtonTagAddressBookEntryNoValue) {
                        _mobilePhoneField.value = _mobilePhoneField.value[buttonIndex];
                    } else {
                        _mobilePhoneField.value = nil;
                    }
                } else if ([_emailField hasMultiValue]) {
                    if (buttonTag != kButtonTagAddressBookEntryNoValue) {
                        _emailField.value = _emailField.value[buttonIndex];
                    } else {
                        _emailField.value = nil;
                    }
                } else if ([_addressBookAddresses count]) {
                    if (buttonTag == kButtonTagAddressBookEntryAllValues) {
                        _candidateResidences = [NSArray arrayWithArray:_addressBookAddresses];
                    } else if (buttonTag != kButtonTagAddressBookEntryNoValue) {
                        _candidateResidences = @[_addressBookAddresses[buttonIndex]];
                    }
                    
                    [_addressBookAddresses removeAllObjects];
                } else if ([_addressBookHomeNumbers count]) {
                    if ([_homeNumberMappings[0] isKindOfClass:[NSString class]]) {
                        if (buttonTag != kButtonTagAddressBookEntryNoValue) {
                            NSString *selectedNumber = _homeNumberMappings[buttonIndex];
                            [_candidateResidences[0] facade].telephone = selectedNumber;
                        }
                        
                        [_addressBookHomeNumbers removeAllObjects];
                    } else {
                        if (buttonTag != kButtonTagAddressBookEntryNoValue) {
                            id selectedAddress = _homeNumberMappings[buttonIndex];
                            [selectedAddress facade].telephone = _addressBookHomeNumbers[0];
                        }
                        
                        [_addressBookHomeNumbers removeObjectAtIndex:0];
                    }
                }
                
                if (![self addressBookEntryNeedsProcessing]) {
                    [self presentAddressBookEntry];
                }
            }
            
            break;
            
        default:
            break;
    }
}


- (void)actionSheet:(OActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
    
    switch (actionSheet.tag) {
        case kActionSheetTagAction:
            if (buttonTag == kButtonTagActionAddAddress) {
                NSSet *housemateResidences = [_member housemateResidences];
                
                if ([housemateResidences count]) {
                    [self presentCandidateResidencesSheet:housemateResidences];
                } else {
                    [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:kOrigoTypeResidence];
                }
            }
            
            break;
            
        case kActionSheetTagResidence:
            if (buttonTag == kButtonTagResidenceNewAddress) {
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:kOrigoTypeResidence];
            } else if (buttonIndex < actionSheet.cancelButtonIndex) {
                [_candidateResidences[buttonIndex] addMember:_member];
                [self reloadSections];
            }
            
            break;
            
        case kActionSheetTagSource:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                [self resetInputState];
                
                if (buttonTag == kButtonTagSourceAddressBook) {
                    [self pickFromAddressBook];
                } else if (buttonTag == kButtonTagSourceOrigo) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:kTargetMember meta:_origo];
                }
            } else {
                [self.detailCell resumeFirstResponder];
            }
            
            break;
            
        case kActionSheetTagAddressBookEntry:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                if ([self addressBookEntryNeedsProcessing]) {
                    [self processAddressBookEntry];
                }
            }
            
            break;
            
        default:
            break;
    }
}


#pragma mark - UIAlertViewDelegate conformance

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertTagEmailChange:
            if (buttonIndex == kButtonTagContinue) {
                [self toggleEditMode];
                [self presentModalViewControllerWithIdentifier:kIdentifierAuth target:_emailField.value];
            } else {
                [_emailField becomeFirstResponder];
            }
            
            break;
            
        default:
            break;
    }
}


#pragma mark - ABPeoplePickerNavigationControllerDelegate conformance

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    _addressBookAddresses = [NSMutableArray array];
    _addressBookHomeNumbers = [NSMutableArray array];
    
    [self setNameFromAddressBookEntry:person];
    [self setAddressesFromAddressBookEntry:person];
    [self setPhoneNumbersFromAddressBookEntry:person];
    [self setEmailFromAddressBookEntry:person];

    if ([self addressBookEntryNeedsProcessing]) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self processAddressBookEntry];
        }];
    } else {
        [self presentAddressBookEntry];
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
    
    return NO;
}


- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    return NO;
}


- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - OConnectionDelegate conformance

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    [super didCompleteWithResponse:response data:data];
    
    if (response.statusCode == kHTTPStatusOK) {
        NSString *identifier = _emailField.value ? _emailField.value : _mobilePhoneField.value;
        NSString *identifierKey = _emailField.value ? kPropertyKeyEmail : kPropertyKeyMobilePhone;
        NSString *memberClassName = NSStringFromClass([OMember class]);
        
        for (NSDictionary *JSONDictionary in data) {
            if ([JSONDictionary[kJSONKeyEntityClass] isEqualToString:memberClassName]) {
                if ([JSONDictionary[identifierKey] isEqualToString:identifier]) {
                    id member = [OEntityProxy proxyForEntityWithJSONDictionary:JSONDictionary];
                    
                    if ([self inputMatchesRegisteredMember:member]) {
                        self.returnData = data;
                        
                        [self presentMember:member];
                        [self examineMember];
                    } else {
                        [OAlert showAlertWithTitle:NSLocalizedString(@"Incorrect details", @"") text:NSLocalizedString(@"The details you have provided do not match our records ...", @"")];
                        
                        [self.detailCell resumeFirstResponder];
                    }
                    
                    break;
                }
            }
        }
    } else {
        [self examineMember];
    }
}

@end
