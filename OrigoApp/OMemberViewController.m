//
//  OMemberViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OMemberViewController.h"

static NSString * const kSegueToOrigoView = @"segueFromMemberToOrigoView";

static NSInteger const kSectionKeyMember = 0;
static NSInteger const kSectionKeyGuardian = 1;
static NSInteger const kSectionKeyAddress = 2;

static NSInteger const kActionSheetTagActionSheet = 0;
static NSInteger const kButtonTagAddAddress = 0;
static NSInteger const kButtonTagChangePassword = 1;
static NSInteger const kButtonTagEdit = 2;
static NSInteger const kButtonTagEditRelations = 3;
static NSInteger const kButtonTagCorrectGender = 4;

static NSInteger const kActionSheetTagResidence = 1;
static NSInteger const kButtonTagNewAddress = 10;

static NSInteger const kActionSheetTagPickSource = 2;
static NSInteger const kButtonTagPickFromAddressBook = 0;
static NSInteger const kButtonTagPickFromOrigo = 1;

static NSInteger const kActionSheetTagMultiValue = 3;
static NSInteger const kButtonTagNoValue = 10;

static NSInteger const kAlertTagEmailChange = 0;
static NSInteger const kButtonTagContinue = 1;


@implementation OMemberViewController

#pragma mark - Auxiliary methods

- (BOOL)isRegisteringJuvenileElder
{
    return [self actionIs:kActionRegister] && [self targetIs:kTargetElder];
}


- (void)resetInputState
{
    [self.detailCell clearInputFields];
    
    if ([self hasSectionWithKey:kSectionKeyAddress]) {
        [_candidateAddresses removeAllObjects];
        
        [self reloadSectionWithKey:kSectionKeyAddress];
        [self setFooterText:[self textForFooterInSectionWithKey:kSectionKeyMember] forSectionWithKey:kSectionKeyMember];
    }
}


- (void)pickFromAddressBook
{
    ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
    peoplePicker.peoplePickerDelegate = self;
    
    [self presentViewController:peoplePicker animated:YES completion:NULL];
}


- (void)setNameFromAddressBookPerson:(ABRecordRef)person
{
    NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *middleName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
    NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
    
    NSString *fullName = [OMeta m].shouldUseEasternNameOrder ? lastName : firstName;
    
    if (fullName) {
        NSString *nextName = [OMeta m].shouldUseEasternNameOrder ? firstName : middleName;
        
        if (nextName) {
            fullName = [fullName stringByAppendingString:nextName separator:kSeparatorSpace];
        }
        
        nextName = [OMeta m].shouldUseEasternNameOrder ? middleName : lastName;
        
        if (nextName) {
            fullName = [fullName stringByAppendingString:nextName separator:kSeparatorSpace];
        }
    }
    
    _nameField.value = fullName;
}


- (void)setPhoneNumbersFromAddressBookPerson:(ABRecordRef)person
{
    NSMutableArray *mobilePhoneNumbers = [NSMutableArray array];
    ABMultiValueRef multiValues = ABRecordCopyValue(person, kABPersonPhoneProperty);
    
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
                [_candidateHomeNumbers addObject:phoneNumber];
            }
        }
    }
    
    _mobilePhoneField.value = [mobilePhoneNumbers count] ? mobilePhoneNumbers : nil;
    
    CFRelease(multiValues);
}


- (void)setEmailFromAddressBookPerson:(ABRecordRef)person
{
    NSMutableArray *emailAddresses = [NSMutableArray array];
    ABMultiValueRef emailMultiValues = ABRecordCopyValue(person, kABPersonEmailProperty);
    
    for (CFIndex i = 0; i < ABMultiValueGetCount(emailMultiValues); i++) {
        NSString *emailAddress = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(emailMultiValues, i);
        
        if ([OValidator valueIsEmailAddress:emailAddress]) {
            [emailAddresses addObject:emailAddress];
        }
    }
    
    _emailField.value = [emailAddresses count] ? emailAddresses : nil;
    
    CFRelease(emailMultiValues);
}


- (void)setAddressesFromAddressBookPerson:(ABRecordRef)person
{
    ABMultiValueRef multiValues = ABRecordCopyValue(person, kABPersonAddressProperty);
    
    for (CFIndex i = 0; i < ABMultiValueGetCount(multiValues); i++) {
        NSString *label = (__bridge_transfer NSString *)ABMultiValueCopyLabelAtIndex(multiValues, i);
        
        if ([label isEqualToString:(NSString *)kABHomeLabel]) {
            [_candidateAddresses addObject:[[OOrigoProxy alloc] initWithAddressBookDictionary:ABMultiValueCopyValueAtIndex(multiValues, i)]];
        }
    }
    
    CFRelease(multiValues);
}


- (BOOL)candidateIsEligible
{
    BOOL candidateIsEligible = YES;
    
    if ([_origo hasMember:_candidate]) {
        OInputField *identifierField = _emailField.value ? _emailField : _mobilePhoneField;
        
        identifierField.value = [NSString string];
        [identifierField becomeFirstResponder];
        
        [OAlert showAlertWithTitle:NSLocalizedString(@"Already member", @"") text:[NSString stringWithFormat:NSLocalizedString(@"%@ is already a member of %@.", @""), _candidate.name, [_origo displayName]]];
        
        _candidate = nil;
        candidateIsEligible = NO;
    } else {
        _nameField.value = _candidate.name;
        _mobilePhoneField.value = _candidate.mobilePhone;
        _emailField.value = _candidate.email;
    }
    
    return candidateIsEligible;
}


- (BOOL)valueIsEligableForInputField:(OInputField *)inputField
{
    BOOL valueIsEligible = [inputField hasValidValue];
    
    if (valueIsEligible && [self actionIs:kActionRegister] && ![self targetIs:kTargetUser]) {
        _candidate = [[OMeta m].context entityOfClass:[OMember class] withValue:inputField.value forKey:inputField.key];
        
        if (_candidate) {
            valueIsEligible = [self candidateIsEligible];
        }
    }
    
    return valueIsEligible;
}


- (OMember *)lookupMemberOnDevice
{
    OMember *member = nil;

    if (_emailField.value || _mobilePhoneField.value) {
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
            [self populateWithName:member.name mobilePhone:member.mobilePhone email:member.email];
        }
    }

    return member;
}


- (BOOL)inputMatchesCandicateWithDictionary:(NSDictionary *)dictionary
{
    BOOL inputMatches = [OUtil name:_nameField.value matchesName:dictionary[kPropertyKeyName]];
    
    if (inputMatches && !_dateOfBirthField.isHidden) {
        inputMatches = [_dateOfBirthField.value isEqual:[NSDate dateWithDeserialisedDate:dictionary[kPropertyKeyDateOfBirth]]];
    }
    
    if (inputMatches && _mobilePhoneField.value) {
        inputMatches = [[OPhoneNumberFormatter formatPhoneNumber:_mobilePhoneField.value canonicalise:YES] isEqualToString:[OPhoneNumberFormatter formatPhoneNumber:dictionary[kPropertyKeyMobilePhone] canonicalise:YES]];
    }
    
    if (inputMatches && _emailField.value) {
        inputMatches = [_emailField.value isEqualToString:dictionary[kPropertyKeyEmail]];
    }
    
    return inputMatches;
}


- (void)populateWithName:(NSString *)name mobilePhone:(NSString *)mobilePhone email:(NSString *)email
{
    _nameField.value = name;
    
    if (mobilePhone) {
        _mobilePhoneField.value = mobilePhone;
    }
    
    if (email && !_emailField.value) {
        _emailField.value = email;
    }
}


- (void)examineMember
{
    _examiner = [[ORegistrantExaminer alloc] initWithOrigo:_origo];
    
    if (_candidate) {
        [_examiner examineRegistrant:_candidate];
    } else if (_candidateDictionary) {
        [_examiner examineRegistrantWithName:_candidateDictionary[kPropertyKeyName] gender:_candidateDictionary[kPropertyKeyGender]];
    } else if ([_dateOfBirthField isHidden]) {
        [_examiner examineRegistrantWithName:_nameField.value];
    } else {
        [_examiner examineRegistrantWithName:_nameField.value dateOfBirth:_dateOfBirthField.value];
    }
}


- (void)persistMember
{
    [self.detailCell writeEntity];
    
    if ([self actionIs:kActionRegister]) {
        OOrigo *residence = [_member residence];
        
        if ([residence.address hasValue]) {
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
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"New address", @"") tag:kButtonTagNewAddress];
    
    [actionSheet show];
}


- (void)presentActionSheetForMultiValueField:(OInputField *)multiValueField
{
    NSString *promptFormat = nil;
    
    if (multiValueField == _mobilePhoneField) {
        promptFormat = NSLocalizedString(@"%@ is registered with more than one mobile phone number. Which number do you want to provide?", @"");
    } else if (multiValueField == _emailField) {
        promptFormat = NSLocalizedString(@"%@ is registered with more than one email address. Which address do you want to provide?", @"");
    }
    
    [multiValueField becomeFirstResponder];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:promptFormat, [OUtil givenNameFromFullName:_nameField.value]] delegate:self tag:kActionSheetTagMultiValue];
    
    for (NSInteger i = 0; i < [multiValueField.value count]; i++) {
        [actionSheet addButtonWithTitle:multiValueField.value[i]];
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"None of them", @"") tag:kButtonTagNoValue];
    
    [actionSheet show];
}


- (void)presentActionSheetForMultipleAddresses
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:NSLocalizedString(@"%@ is registered with more than one home address. Which address do you want to provide?", @""), [OUtil givenNameFromFullName:_nameField.value]] delegate:self tag:kActionSheetTagMultiValue];
    
    for (NSInteger i = 0; i < [_candidateAddresses count]; i++) {
        [actionSheet addButtonWithTitle:[_candidateAddresses[i] shortAddress]];
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"None of them", @"") tag:kButtonTagNoValue];
    
    [actionSheet show];
}


- (void)presentActionSheetForMultipleHomePhoneNumbers
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:NSLocalizedString(@"%@ is registered with more than one home phone number. Which number do you want to provide?", @""), [OUtil givenNameFromFullName:_nameField.value], [_candidateAddresses[0] shortAddress]] delegate:self tag:kActionSheetTagMultiValue];
    
    for (NSInteger i = 0; i < [_candidateHomeNumbers count]; i++) {
        [actionSheet addButtonWithTitle:_candidateHomeNumbers[i]];
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"None of them", @"") tag:kButtonTagNoValue];
    
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


#pragma mark - Adress book data handling

- (BOOL)hasAddressBookMultiValues
{
    BOOL hasMultiValues = NO;
    
    hasMultiValues = hasMultiValues || [_mobilePhoneField hasMultiValue];
    hasMultiValues = hasMultiValues || [_emailField hasMultiValue];
    hasMultiValues = hasMultiValues || ([_candidateAddresses count] > 1);
    hasMultiValues = hasMultiValues || ([_candidateHomeNumbers count] > 1);
    
    return hasMultiValues;
}


- (void)processAddressBookMultiValues
{
    if ([_mobilePhoneField hasMultiValue]) {
        [self presentActionSheetForMultiValueField:_mobilePhoneField];
    } else if ([_emailField hasMultiValue]) {
        [self presentActionSheetForMultiValueField:_emailField];
    } else if ([_candidateAddresses count] > 1) {
        [self presentActionSheetForMultipleAddresses];
    } else if ([_candidateHomeNumbers count] > 1) {
        [self presentActionSheetForMultipleHomePhoneNumbers];
    }
}


- (void)presentAddressBookValues
{
    for (NSInteger i = 0; i < [_candidateAddresses count]; i++) {
        [_candidateAddresses[i] facade].telephone = _candidateHomeNumbers[i];
    }
    
    if ([_candidateAddresses count]) {
        [self reloadSectionWithKey:kSectionKeyAddress];
        [self setFooterText:[self textForFooterInSectionWithKey:kSectionKeyMember] forSectionWithKey:kSectionKeyMember];
    }
    
    if ([self.detailCell hasInvalidInputField]) {
        [[self.detailCell nextInvalidInputField] becomeFirstResponder];
    } else {
        [_emailField becomeFirstResponder];
    }
}


#pragma mark - Selector implementations

- (void)presentActionSheet
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagActionSheet];
    
    if ([_member isUser]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Change password", @"") tag:kButtonTagChangePassword];
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit", @"") tag:kButtonTagEdit];
    
    if ([_member isWardOfUser]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit relations", @"") tag:kButtonTagEditRelations];
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Add an address", @"") tag:kButtonTagAddAddress];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Correct gender", @"") tag:kButtonTagCorrectGender];
    
    [actionSheet show];
}


- (void)performLookup
{
    [self.view endEditing:YES];
    
    if ([[[OState s].pivotMember peersNotInOrigo:_origo] count] > 0) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagPickSource];
        
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
    _nameField = [self.detailCell inputFieldForKey:kPropertyKeyName];
    _dateOfBirthField = [self.detailCell inputFieldForKey:kPropertyKeyDateOfBirth];
    _mobilePhoneField = [self.detailCell inputFieldForKey:kPropertyKeyMobilePhone];
    _emailField = [self.detailCell inputFieldForKey:kPropertyKeyEmail];
    
    if ([self actionIs:kActionRegister] && [_origo isJuvenile] && ![self targetIs:kTargetGuardian]) {
        [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetGuardian];
    }
    
    [super viewDidAppear:animated];
}


#pragma mark - OTableViewController custom accessors

- (BOOL)canEdit
{
    return [_member isManagedByUser];
}


#pragma mark - UIViewController overrides

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToOrigoView]) {
        if ([self actionIs:kActionRegister]) {
            [self prepareForPushSegue:segue target:_candidateAddresses[0]];
        } else {
            [self prepareForPushSegue:segue];
        }
    }
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialiseState
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


- (void)initialiseData
{
    [self setDataForDetailSection];
    
    if ([self actionIs:kActionDisplay]) {
        if ([_member isJuvenile]) {
            [self setData:[_member guardians] forSectionWithKey:kSectionKeyGuardian];
        }
        
        [self setData:[_member residences] forSectionWithKey:kSectionKeyAddress];
    } else if (_candidateAddresses) {
        [self setData:_candidateAddresses forSectionWithKey:kSectionKeyAddress];
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
        if (([[_member residences] count] == 1) || _candidateAddresses) {
            text = [OLanguage nouns][_address_][singularIndefinite];
        } else if ([[_member residences] count] > 1) {
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


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyGuardian) {
        OMemberViewController *memberViewController = [self.storyboard instantiateViewControllerWithIdentifier:kIdentifierMember];
        memberViewController.target = [self dataAtIndexPath:indexPath];
        memberViewController.observer = (OTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        
        [self.navigationController pushViewController:memberViewController animated:YES];
    } else if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyAddress) {
        [self performSegueWithIdentifier:kSegueToOrigoView sender:self];
    }
}


- (BOOL)shouldRelayDismissalOfModalViewController:(OTableViewController *)viewController
{
    BOOL shouldRelayDismissal = [viewController.identifier isEqualToString:kIdentifierOrigo];
    
    if (!shouldRelayDismissal) {
        if ([viewController.identifier isEqualToString:kIdentifierMember]) {
            shouldRelayDismissal = !viewController.returnData;
        }
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
            _candidate = viewController.returnData;
            
            if ([self candidateIsEligible] && _dateOfBirthField.isHidden) {
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


- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyGuardian) {
        OMember *guardian = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = guardian.name;
        cell.imageView.image = [guardian smallImage];

        if ([[_member residences] count] == 1) {
            cell.detailTextLabel.text = [guardian shortDetails];
        } else {
            cell.detailTextLabel.text = [guardian shortAddress];
        }
        
        if ([_member hasParent:guardian] && ![_member guardiansAreParents]) {
            cell.detailTextLabel.text = [[[guardian parentNoun][singularIndefinite] capitalizedString] stringByAppendingString:cell.detailTextLabel.text separator:kSeparatorComma];
        }
    } else if (sectionKey == kSectionKeyAddress) {
        NSString *homeNumber = nil;
        
        if ([self actionIs:kActionDisplay]) {
            OOrigo *residence = [self dataAtIndexPath:indexPath];
            
            cell.textLabel.text = [residence shortAddress];
            homeNumber = [residence.telephone hasValue] ? residence.telephone : nil;
        } else if ([self actionIs:kActionRegister] && [_candidateAddresses count]) {
            cell.textLabel.text = [_candidateAddresses[0] shortAddress];
            homeNumber = [_candidateAddresses[0] facade].telephone;
        }
        
        cell.imageView.image = [UIImage imageNamed:kIconFileHousehold];
        cell.detailTextLabel.text = [OPhoneNumberFormatter formatPhoneNumber:homeNumber canonicalise:YES];
    }
}


#pragma mark - OTableViewInputDelegate conformance

- (BOOL)inputIsValid
{
    if (!_candidate && ![self targetIs:kTargetUser]) {
        _candidate = [self lookupMemberOnDevice];
    }
    
    BOOL isValid = [_nameField hasValidValue];
    
    if (isValid && [self aspectIsHousehold]) {
        isValid = [_dateOfBirthField hasValidValue];
        
        if (_candidate) {
            isValid = [_dateOfBirthField.value isEqual:_candidate.dateOfBirth];
            
            if (!isValid) {
                [_dateOfBirthField becomeFirstResponder];
            }
        }
    }
    
    if (isValid && _mobilePhoneField.value) {
        if (_emailField.value) {
            isValid = [_mobilePhoneField hasValidValue];
        } else {
            isValid = [self valueIsEligableForInputField:_mobilePhoneField];
        }
    }
    
    if (isValid && _emailField.value) {
        isValid = [self valueIsEligableForInputField:_emailField];
    }
    
    if (isValid && ([self targetIs:kTargetUser] || ![_dateOfBirthField.value isBirthDateOfMinor])) {
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
        if (_candidate) {
            if ([_origo isOfType:kOrigoTypeResidence]) {
                [self examineMember];
            } else {
                [self persistMember];
            }
        } else {
            if (![self targetIs:kTargetUser] && (_emailField.value || _mobilePhoneField.value)) {
                [OConnection lookupMemberWithIdentifier:_emailField.value ? _emailField.value : _mobilePhoneField.value];
            } else {
                [self examineMember];
            }
        }
    } else if ([self actionIs:kActionEdit]) {
        NSString *email = [_member facade].email;
        
        if ([email hasValue] && ![_emailField.value isEqualToString:email]) {
            if ([self targetIs:kTargetUser]) {
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


- (id)inputEntity
{
    if (_candidate) {
        _member = _candidate;
    } else {
        _member = [[OMeta m].context insertMemberEntityWithId:_examiner.registrantId];
    }
    
    if (!_membership) {
        _membership = [_origo addMember:_member];
    }
    
    return _member;
}


- (id)inputValueForIndirectKey:(NSString *)key
{
    id inputValue = nil;

    if ([key isEqualToString:kPropertyKeyIsMinor]) {
        inputValue = [_member facade].dateOfBirth ? nil : @([_origo isJuvenile]);
    } else {
        if (_examiner) {
            inputValue = [_examiner valueForKey:key];
        } else {
            inputValue = [_member valueForKey:key];
        }
    }
    
    return inputValue;
}


- (BOOL)canEditInputFieldWithKey:(NSString *)key
{
    BOOL canEdit = YES;
    
    if ([key isEqualToString:kPropertyKeyEmail]) {
        canEdit = ![self actionIs:kActionRegister] || ![self targetIs:kTargetUser];
    }
    
    return canEdit;
}


#pragma mark - ORegistrantExaminerDelegate conformance

- (void)examinerDidFinishExamination
{
    if (self.returnData) {
        [[OMeta m].context saveServerReplicas:self.returnData];
        _candidate = [[OMeta m].context entityWithId:_candidateDictionary[kPropertyKeyEntityId]];
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
        case kActionSheetTagActionSheet:
            if (buttonTag == kButtonTagEdit) {
                [self toggleEditMode];
            }
            
            break;
            
        case kActionSheetTagMultiValue:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                if ([_mobilePhoneField hasMultiValue]) {
                    if (buttonTag != kButtonTagNoValue) {
                        _mobilePhoneField.value = _mobilePhoneField.value[buttonIndex];
                    } else {
                        _mobilePhoneField.value = nil;
                    }
                } else if ([_emailField hasMultiValue]) {
                    if (buttonTag != kButtonTagNoValue) {
                        _emailField.value = _emailField.value[buttonIndex];
                    } else {
                        _emailField.value = nil;
                    }
                } else if ([_candidateAddresses count] > 1) {
                    if (buttonTag != kButtonTagNoValue) {
                        [_candidateAddresses setArray:@[_candidateAddresses[buttonIndex]]];
                    } else {
                        [_candidateAddresses removeAllObjects];
                    }
                } else if ([_candidateHomeNumbers count] > 1) {
                    if (buttonTag != kButtonTagNoValue) {
                        [_candidateHomeNumbers setArray:@[_candidateHomeNumbers[buttonIndex]]];
                    } else {
                        [_candidateHomeNumbers removeAllObjects];
                    }
                }
                
                if (![self hasAddressBookMultiValues]) {
                    [self presentAddressBookValues];
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
        case kActionSheetTagActionSheet:
            if (buttonTag == kButtonTagAddAddress) {
                NSSet *housemateResidences = [_member housemateResidences];
                
                if ([housemateResidences count]) {
                    [self presentCandidateResidencesSheet:housemateResidences];
                } else {
                    [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:kOrigoTypeResidence];
                }
            }
            
            break;
            
        case kActionSheetTagResidence:
            if (buttonTag == kButtonTagNewAddress) {
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:kOrigoTypeResidence];
            } else if (buttonIndex < actionSheet.cancelButtonIndex) {
                [_candidateResidences[buttonIndex] addMember:_member];
                [self reloadSections];
            }
            
            break;
            
        case kActionSheetTagPickSource:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                [self resetInputState];
                
                if (buttonTag == kButtonTagPickFromAddressBook) {
                    [self pickFromAddressBook];
                } else if (buttonTag == kButtonTagPickFromOrigo) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:kTargetMember meta:_origo];
                }
            } else {
                [self.detailCell resumeFirstResponder];
            }
            
            break;
            
        case kActionSheetTagMultiValue:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                if ([self hasAddressBookMultiValues]) {
                    [self processAddressBookMultiValues];
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
    _candidateAddresses = [NSMutableArray array];
    _candidateHomeNumbers = [NSMutableArray array];
    
    [self setNameFromAddressBookPerson:person];
    [self setPhoneNumbersFromAddressBookPerson:person];
    [self setEmailFromAddressBookPerson:person];
    [self setAddressesFromAddressBookPerson:person];

    if ([self hasAddressBookMultiValues]) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self processAddressBookMultiValues];
        }];
    } else {
        [self presentAddressBookValues];
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
        
        for (NSDictionary *entityDictionary in data) {
            if ([entityDictionary[kJSONKeyEntityClass] isEqualToString:memberClassName]) {
                if ([entityDictionary[identifierKey] isEqualToString:identifier]) {
                    if ([self inputMatchesCandicateWithDictionary:entityDictionary]) {
                        self.returnData = data;
                        _candidateDictionary = entityDictionary;
                        
                        [self populateWithName:_candidateDictionary[kPropertyKeyName] mobilePhone:_candidateDictionary[kPropertyKeyMobilePhone] email:_candidateDictionary[kPropertyKeyEmail]];
                        
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
