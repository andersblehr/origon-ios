//
//  OMemberViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
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
static NSInteger const kButtonTagNewAddress = 100;

static NSInteger const kActionSheetTagLookupType = 2;
static NSInteger const kButtonTagLookUpContact = 0;
static NSInteger const kButtonTagLookUpMember = 1;

static NSInteger const kActionSheetTagMultiValue = 3;
static NSInteger const kButtonTagDifferentValue = 10;

static NSInteger const kAlertTagEmailChange = 0;
static NSInteger const kButtonTagContinue = 1;


@implementation OMemberViewController

#pragma mark - Auxiliary methods

- (BOOL)isRegisteringJuvenileElder
{
    return [self actionIs:kActionRegister] && [self targetIs:kTargetElder];
}


- (void)lookUpContact
{
    ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
    peoplePicker.peoplePickerDelegate = self;
    
    [self presentViewController:peoplePicker animated:YES completion:NULL];
}


- (void)setNameFieldFromPersonRecord:(ABRecordRef)personRecord
{
    NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(personRecord, kABPersonFirstNameProperty);
    NSString *middleName = (__bridge_transfer NSString *)ABRecordCopyValue(personRecord, kABPersonMiddleNameProperty);
    NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(personRecord, kABPersonLastNameProperty);
    
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


- (void)setMobilePhoneFieldFromPersonRecord:(ABRecordRef)personRecord
{
    NSMutableArray *mobilePhoneNumbers = [NSMutableArray array];
    ABMultiValueRef phoneMultiValues = ABRecordCopyValue(personRecord, kABPersonPhoneProperty);
    NSString *label = nil;
    
    for (CFIndex i = 0; i < ABMultiValueGetCount(phoneMultiValues); i++) {
        label = (__bridge_transfer NSString *)ABMultiValueCopyLabelAtIndex(phoneMultiValues, i);
        
        BOOL isMobilePhone = [label isEqualToString:(NSString *)kABPersonPhoneMobileLabel];
        BOOL is_iPhone = [label isEqualToString:(NSString *)kABPersonPhoneIPhoneLabel];
        
        if (isMobilePhone || is_iPhone) {
            [mobilePhoneNumbers addObject:(__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phoneMultiValues, i)];
        }
    }
    
    _mobilePhoneField.value = [mobilePhoneNumbers count] ? mobilePhoneNumbers : nil;
    
    CFRelease(phoneMultiValues);
}


- (void)setEmailFieldFromPersonRecord:(ABRecordRef)personRecord
{
    NSMutableArray *emailAddresses = [NSMutableArray array];
    ABMultiValueRef emailMultiValues = ABRecordCopyValue(personRecord, kABPersonEmailProperty);
    
    for (CFIndex i = 0; i < ABMultiValueGetCount(emailMultiValues); i++) {
        NSString *emailAddress = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(emailMultiValues, i);
        
        if ([OValidator valueIsEmailAddress:emailAddress]) {
            [emailAddresses addObject:emailAddress];
        }
    }
    
    _emailField.value = [emailAddresses count] ? emailAddresses : nil;
    
    CFRelease(emailMultiValues);
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
        inputMatches = [[[OMeta m].phoneNumberFormatter canonicalisePhoneNumber:_mobilePhoneField.value] isEqualToString:[[OMeta m].phoneNumberFormatter canonicalisePhoneNumber:dictionary[kPropertyKeyMobilePhone]]];
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
        if ([self targetIs:kTargetUser]) {
            if (![_origo.address hasValue]) {
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo data:_membership meta:kOrigoTypeResidence];
            } else {
                [self.dismisser dismissModalViewController:self reload:YES];
            }
        } else /* if (![self targetIs:kTargetHousehold]) */ {
            [self.dismisser dismissModalViewController:self reload:YES]; // TODO: Work in progress
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


- (void)presentActionSheetForMultiValueField:(OInputField *)multiValueField;
{
    NSString *promptFormat = nil;
    NSString *differentValueButtonTitle = nil;
    
    if (multiValueField == _mobilePhoneField) {
        promptFormat = NSLocalizedString(@"%@ is registered with more than one mobile phone number. Which number do you want to provide?", @"");
        differentValueButtonTitle = NSLocalizedString(@"A different number", @"");
    } else if (multiValueField == _emailField) {
        promptFormat = NSLocalizedString(@"%@ is registered with more than one email address. Which address do you want to provide?", @"");
        differentValueButtonTitle = NSLocalizedString(@"A different address", @"");
    }
    
    [multiValueField becomeFirstResponder];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:promptFormat, _nameField.value] delegate:self tag:kActionSheetTagMultiValue];
    
    for (int i = 0; i < [multiValueField.value count]; i++) {
        [actionSheet addButtonWithTitle:multiValueField.value[i]];
    }
    
    [actionSheet addButtonWithTitle:differentValueButtonTitle tag:kButtonTagDifferentValue];
    
    [actionSheet show];
}


- (void)presentUserEmailChangeAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"New email address", @"") message:[NSString stringWithFormat:NSLocalizedString(@"You are about to change your email address from %@ to %@ ...", @""), _member.email, _emailField.value] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"Continue", @""), nil];
    alert.tag = kAlertTagEmailChange;
    
    [alert show];
}


- (void)presentMemberEmailChangeAlert
{
    // TODO
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
    
    if ([[OState s].pivotMember hasPeersNotInOrigo:_origo]) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagLookupType];
        
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Retrieve from Contacts", @"")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Retrieve from Origo", @"")];
        
        [actionSheet show];
    } else {
        [self lookUpContact];
    }
}


#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    _nameField = [self.detailCell inputFieldForKey:kPropertyKeyName];
    _dateOfBirthField = [self.detailCell inputFieldForKey:kPropertyKeyDateOfBirth];
    _mobilePhoneField = [self.detailCell inputFieldForKey:kPropertyKeyMobilePhone];
    _emailField = [self.detailCell inputFieldForKey:kPropertyKeyEmail];
    
    if ([self actionIs:kActionRegister] && [_origo isJuvenile] && !self.meta && !self.wasHidden) {
        [self presentModalViewControllerWithIdentifier:kIdentifierMember data:_origo meta:kTargetGuardian];
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
            [self prepareForPushSegue:segue data:_membership];
            [segue.destinationViewController setDismisser:self.dismisser];
        } else {
            [self prepareForPushSegue:segue];
        }
    }
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialiseState
{
    if ([self.data isKindOfClass:[OMember class]]) {
        _member = self.data;
    } else if ([self.data isKindOfClass:[OMembership class]]) {
        _membership = self.data;
        _member = _membership.member;
        _origo = _membership.origo;
    } else if ([self.data isKindOfClass:[OOrigo class]]) {
        _origo = self.data;
    }
    
    self.state.target = _member ? _member : (self.meta ? self.meta : _origo);
    
    if ([self targetIs:kTargetUser]) {
        self.title = NSLocalizedString(@"About me", @"");
    } else if ([self targetIs:kTargetGuardian]) {
        self.title = [[OLanguage nouns][_guardian_][singularIndefinite] capitalizedString];
    } else if ([self targetIs:kTargetContact]) {
        self.title = NSLocalizedString(_origo.type, kKeyPrefixContactTitle);
    } else if ([self targetIs:kTargetParentContact]) {
        self.title = NSLocalizedString(@"Parent contact", @"");
    } else if (_member) {
        self.title = [_member isHousemateOfUser] ? [_member givenName] : _member.name;
    } else {
        self.title = NSLocalizedString(_origo.type, kKeyPrefixNewMemberTitle);
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
    id memberDataSource = _member ? _member : kRegistrationCell;
    
    [self setData:memberDataSource forSectionWithKey:kSectionKeyMember];
    
    if ([self actionIs:kActionDisplay]) {
        if ([_member isJuvenile]) {
            [self setData:[_member guardians] forSectionWithKey:kSectionKeyGuardian];
        }
        
        [self setData:[_member residencies] forSectionWithKey:kSectionKeyAddress];
    }
}


- (NSArray *)toolbarButtons
{
    return [_member isUser] ? nil : [[OMeta m].switchboard toolbarButtonsForMember:_member];
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasFooter = [self actionIs:kActionRegister];
    
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
        if ([[_member residencies] count] == 1) {
            text = [OLanguage nouns][_address_][singularIndefinite];
        } else if ([[_member residencies] count] > 1) {
            text = [OLanguage nouns][_address_][pluralIndefinite];
        }
    }
    
    return [text capitalizedString];
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = NSLocalizedString(@"A notification will be sent to the email address you provide.", @"");
    
    if ([_origo isJuvenile] && [self targetIs:kTargetGuardian]) {
        text = [NSString stringWithFormat:@"%@\n\n%@", NSLocalizedString(@"Before you can register a minor, you must register his or her parents/guardians.", @""), text];
    }
    
    return text;
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyGuardian) {
        OMemberViewController *memberViewController = [self.storyboard instantiateViewControllerWithIdentifier:kIdentifierMember];
        memberViewController.data = [self dataAtIndexPath:indexPath];
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
        if ([_member.email isEqualToString:_emailField.value]) {
            [self persistMember];
        } else {
            UIAlertView *failedEmailChangeAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Activation failed", @"") message:[NSString stringWithFormat:NSLocalizedString(@"The email address %@ could not be activated ...", @""), _emailField.value] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [failedEmailChangeAlert show];
            
            [self toggleEditMode];
            [_emailField becomeFirstResponder];
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

        if ([[_member residencies] count] == 1) {
            cell.detailTextLabel.text = [guardian shortDetails];
        } else {
            cell.detailTextLabel.text = [guardian shortAddress];
        }
        
        if ([_member hasParent:guardian] && ![_member guardiansAreParents]) {
            cell.detailTextLabel.text = [[[guardian parentNoun][singularIndefinite] capitalizedString] stringByAppendingString:cell.detailTextLabel.text separator:kSeparatorComma];
        }
    } else if (sectionKey == kSectionKeyAddress) {
        OOrigo *residence = [[self dataAtIndexPath:indexPath] origo];
        
        cell.textLabel.text = [residence shortAddress];
        cell.imageView.image = [UIImage imageNamed:kIconFileHousehold];
        
        if ([residence.telephone hasValue]) {
            cell.detailTextLabel.text = [[OMeta m].phoneNumberFormatter canonicalisePhoneNumber:residence.telephone];
        }
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
        if ([_member.email hasValue] && ![_emailField.value isEqualToString:_member.email]) {
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
        inputValue = _member.dateOfBirth ? nil : @([_origo isJuvenile]);
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
            if (buttonIndex == actionSheet.cancelButtonIndex) {
                [self performSelectorOnMainThread:@selector(didCancelEditing) withObject:nil waitUntilDone:NO];
            } else {
                OInputField *multiValueField = [_mobilePhoneField hasMultiValue] ? _mobilePhoneField : _emailField;
                
                if (buttonTag != kButtonTagDifferentValue) {
                    multiValueField.value = multiValueField.value[buttonIndex];
                } else {
                    multiValueField.value = nil;
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
                    [self presentModalViewControllerWithIdentifier:kIdentifierOrigo data:_member meta:kOrigoTypeResidence];
                }
            }
            
            break;
            
        case kActionSheetTagResidence:
            if (buttonTag == kButtonTagNewAddress) {
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo data:_member meta:kOrigoTypeResidence];
            } else if (buttonIndex < actionSheet.cancelButtonIndex) {
                [_candidateResidences[buttonIndex] addMember:_member];
                [self reloadSections];
            }
            
            break;
            
        case kActionSheetTagLookupType:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                [self.detailCell clearInputFields];
                
                if (buttonTag == kButtonTagLookUpContact) {
                    [self lookUpContact];
                } else if (buttonTag == kButtonTagLookUpMember) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker data:_origo meta:self.meta ? self.meta : kTargetMember];
                }
            } else {
                [self.detailCell resumeFirstResponder];
            }
            
            break;
            
        case kActionSheetTagMultiValue:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                if ([_emailField hasMultiValue]) {
                    [self presentActionSheetForMultiValueField:_emailField];
                } else {
                    if ([self.detailCell hasInvalidInputField]) {
                        [[self.detailCell nextInvalidInputField] becomeFirstResponder];
                    } else {
                        [self endEditing];
                    }
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
                [self presentModalViewControllerWithIdentifier:kIdentifierAuth data:_emailField.value];
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
    self.detailCell.editable = YES;
    
    [self setNameFieldFromPersonRecord:person];
    [self setMobilePhoneFieldFromPersonRecord:person];
    [self setEmailFieldFromPersonRecord:person];
    
    [self dismissViewControllerAnimated:YES completion:^{
        if ([_mobilePhoneField hasMultiValue]) {
            [self presentActionSheetForMultiValueField:_mobilePhoneField];
        } else if ([_emailField hasMultiValue]) {
            [self presentActionSheetForMultiValueField:_emailField];
        } else if (![self.detailCell hasInvalidInputField]) {
            [self endEditing];
        }
    }];
    
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
