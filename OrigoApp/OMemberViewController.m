//
//  OMemberViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OMemberViewController.h"

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


@interface OMemberViewController () <OTableViewController, OTableViewInputDelegate, OMemberExaminerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, ABPeoplePickerNavigationControllerDelegate, OConnectionDelegate> {
@private
    id<OMember> _member;
    id<OOrigo> _origo;
    id<OMembership> _membership;
    id<OMember> _guardian;
    
    OInputField *_nameField;
    OInputField *_dateOfBirthField;
    OInputField *_mobilePhoneField;
    OInputField *_emailField;
    
    NSMutableArray *_addressBookAddresses;
    NSMutableArray *_addressBookHomeNumbers;
    NSMutableArray *_addressBookMappings;
    NSArray *_candidateResidences;
    NSArray *_JSONData;
    
    BOOL _didPerformLocalLookup;
}

@end


@implementation OMemberViewController

#pragma mark - Auxiliary methods

- (void)resetInputState
{
    [_member useInstance:nil];
    
    self.detailCell.editable = YES;
    [self.detailCell clearInputFields];
    
    if ([self hasSectionWithKey:kSectionKeyAddress]) {
        [self reloadSectionWithKey:kSectionKeyAddress];
    }
    
    _didPerformLocalLookup = NO;
    _JSONData = nil;
}


#pragma mark - Input validation

- (BOOL)isEligibleMember:(id<OMember>)member
{
    BOOL isValid = YES;
    
    if ([_origo hasMember:member]) {
        OInputField *identifierField = _emailField.value ? _emailField : _mobilePhoneField;
        
        identifierField.value = [NSString string];
        [identifierField becomeFirstResponder];
        
        [OAlert showAlertWithTitle:NSLocalizedString(@"Already member", @"") text:[NSString stringWithFormat:NSLocalizedString(@"%@ is already a member of %@.", @""), _member.name, _origo.name]];
        
        isValid = NO;
    } else {
        [self presentMember:member];
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


- (BOOL)inputMatchesRegisteredMember:(id<OMember>)member
{
    BOOL inputMatches = [OUtil fullName:_nameField.value fuzzyMatchesFullName:member.name];
    
    if (inputMatches && !_dateOfBirthField.isHidden) {
        inputMatches = [_dateOfBirthField.value isEqual:member.dateOfBirth];
    }
    
    if (inputMatches && _mobilePhoneField.value) {
        inputMatches = [[OPhoneNumberFormatter formatPhoneNumber:_mobilePhoneField.value canonicalise:YES] isEqualToString:[OPhoneNumberFormatter formatPhoneNumber:member.mobilePhone canonicalise:YES]];
    }
    
    if (inputMatches && _emailField.value) {
        inputMatches = [_emailField.value isEqualToString:member.email];
    }
    
    return inputMatches;
}


#pragma mark - Lookup & presentation

- (void)performLocalLookup
{
    id<OMember> member = nil;
    
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
    
    _didPerformLocalLookup = YES;
}


- (void)presentMember:(id<OMember>)member
{
    if ([member isCommitted]) {
        [_member useInstance:[member instance]];
        [self endEditing];
    }
    
    _nameField.value = member.name;
    _mobilePhoneField.value = member.mobilePhone;
    _emailField.value = member.email;
    
    [self reloadSectionWithKey:kSectionKeyAddress];
    
    OInputField *invalidInputField = [self.detailCell nextInvalidInputField];
    
    if (invalidInputField) {
        [invalidInputField becomeFirstResponder];
    } else {
        [_emailField becomeFirstResponder];
    }
}


#pragma mark - Examine and persist new member

- (void)examineMember
{
    [self.detailCell writeInput];
    
    [[OMemberExaminer examinerForResidence:_origo delegate:self] examineMember:_member];
}


- (void)persistMember
{
    [self.detailCell writeInput];
    
    if ([self actionIs:kActionRegister]) {
        _membership = [_origo addMember:_member];
        id<OOrigo> residence = [_member residence];
        
        if ([residence hasAddress] && ![self aspectIs:kAspectJuvenile]) {
            if ([_member isUser] && [_member isCommitted] && ![_member isActive]) {
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
    
    for (id<OOrigo> residence in _candidateResidences) {
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
    
    if (![self aspectIs:kAspectJuvenile]) {
        [actionSheet addButtonWithTitle:allTitle tag:kButtonTagAddressBookEntryAllValues];
    }
    
    [actionSheet addButtonWithTitle:noneTitle tag:kButtonTagAddressBookEntryNoValue];
    
    [actionSheet show];
}


- (void)presentActionSheetForMappingHomeNumbers
{
    static NSInteger homeNumberCount = 0;

    if (!homeNumberCount) {
        homeNumberCount = [_addressBookHomeNumbers count];
    }
    
    NSString *givenName = [OUtil givenNameFromFullName:_nameField.value];
    NSString *prompt = nil;
    
    if ([[_member residences] count] == 1) {
        _addressBookMappings = _addressBookHomeNumbers;
        id<OOrigo> residence = [_member residence];
        
        if ([residence hasAddress]) {
            prompt = [NSString stringWithFormat:NSLocalizedString(@"%@ has more than one home phone number. Which number is valid for %@?", @""), givenName, [residence shortAddress]];
        } else {
            prompt = [NSString stringWithFormat:NSLocalizedString(@"%@ has more than one home phone number. Which number do you want to provide?", @""), givenName];
        }
    } else {
        _addressBookMappings = [NSMutableArray array];
        
        for (id<OOrigo> residence in [_member residences]) {
            if (!residence.telephone) {
                [_addressBookMappings addObject:residence];
            }
        }
        
        if (homeNumberCount == 1) {
            prompt = [NSString stringWithFormat:NSLocalizedString(@"%@ has only one home phone number, %@. Which address has this number?", @""), givenName, _addressBookHomeNumbers[0]];
        } else if ([_addressBookHomeNumbers count] == homeNumberCount) {
            prompt = [NSString stringWithFormat:NSLocalizedString(@"%@ has more than one home phone number. Which address has the number %@?", @""), givenName, _addressBookHomeNumbers[0]];
        } else {
            if (([_addressBookHomeNumbers count] == 1) && ([_addressBookMappings count] == 1)) {
                prompt = [NSString stringWithFormat:NSLocalizedString(@"Is %@ the phone number for %@?", @""), _addressBookHomeNumbers[0], [_addressBookMappings[0] shortAddress]];
            } else {
                prompt = [NSString stringWithFormat:NSLocalizedString(@"Which address has the number %@?", @""), _addressBookHomeNumbers[0]];
            }
        }
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagAddressBookEntry];
    
    if (([_addressBookHomeNumbers count] == 1) && ([_addressBookMappings count] == 1)) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Yes", @"")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"No", @"") tag:kButtonTagAddressBookEntryNoValue];
    } else {
        for (NSInteger i = 0; i < [_addressBookMappings count]; i++) {
            if ([_addressBookMappings[0] isKindOfClass:[NSString class]]) {
                [actionSheet addButtonWithTitle:_addressBookMappings[i]];
            } else {
                [actionSheet addButtonWithTitle:[_addressBookMappings[i] shortAddress]];
            }
        }
        
        [actionSheet addButtonWithTitle:NSLocalizedString(@"None of them", @"") tag:kButtonTagAddressBookEntryNoValue];
    }
    
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


#pragma mark - Adress book entry processing

- (void)refineAddressBookContactInfo
{
    if ([_mobilePhoneField hasMultiValue]) {
        [self presentActionSheetForMultiValueField:_mobilePhoneField];
    } else if ([_emailField hasMultiValue]) {
        [self presentActionSheetForMultiValueField:_emailField];
    }
}


- (void)refineAddressBookAddressInfo
{
    if ([_addressBookAddresses count]) {
        [self presentActionSheetForMultipleAddresses];
    } else if ([_addressBookHomeNumbers count]) {
        [self presentActionSheetForMappingHomeNumbers];
    }
}


#pragma mark - Retrieving address book data

- (void)pickFromAddressBook
{
    ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
    peoplePicker.peoplePickerDelegate = self;
    
    [self presentViewController:peoplePicker animated:YES completion:NULL];
}


- (void)retrieveNameFromAddressBookPersonRecord:(ABRecordRef)person
{
    NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *middleName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
    NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
    
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
    _member.name = _nameField.value;
}


- (void)retrievePhoneNumbersFromAddressBookPersonRecord:(ABRecordRef)person
{
    _addressBookHomeNumbers = [NSMutableArray array];
    
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
                [_addressBookHomeNumbers addObject:phoneNumber];
            }
        }
    }
    
    CFRelease(multiValues);

    if ([mobilePhoneNumbers count]) {
        _mobilePhoneField.value = mobilePhoneNumbers;
        
        if (![_mobilePhoneField hasMultiValue]) {
            _member.mobilePhone = _mobilePhoneField.value;
        }
    }
}


- (void)retrieveEmailAddressesFromAddressBookPersonRecord:(ABRecordRef)person
{
    NSMutableArray *emailAddresses = [NSMutableArray array];
    ABMultiValueRef multiValues = ABRecordCopyValue(person, kABPersonEmailProperty);
    
    for (CFIndex i = 0; i < ABMultiValueGetCount(multiValues); i++) {
        NSString *emailAddress = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(multiValues, i);
        
        if ([OValidator valueIsEmailAddress:emailAddress]) {
            [emailAddresses addObject:emailAddress];
        }
    }
    
    CFRelease(multiValues);
    
    if ([emailAddresses count]) {
        _emailField.value = emailAddresses;
        
        if (![_emailField hasMultiValue]) {
            _member.email = _emailField.value;
        }
    }
}


- (void)retrieveAddressesFromAddressBookPersonRecord:(ABRecordRef)person
{
    _addressBookAddresses = [NSMutableArray array];
    
    ABMultiValueRef multiValues = ABRecordCopyValue(person, kABPersonAddressProperty);
    
    for (CFIndex i = 0; i < ABMultiValueGetCount(multiValues); i++) {
        NSString *label = (__bridge_transfer NSString *)ABMultiValueCopyLabelAtIndex(multiValues, i);
        
        if ([label isEqualToString:(NSString *)kABHomeLabel]) {
            [_addressBookAddresses addObject:[OOrigoProxy proxyFromAddressBookAddress:ABMultiValueCopyValueAtIndex(multiValues, i)]];
        }
    }
    
    CFRelease(multiValues);
    
    if ([_addressBookAddresses count] == 1) {
        [_addressBookAddresses[0] addMember:_member];
        [_addressBookAddresses removeAllObjects];
    }
    
    if ([_addressBookHomeNumbers count]) {
        if (![_addressBookAddresses count] && ![_member hasAddress]) {
            if ([_addressBookHomeNumbers count] == 1) {
                [[OOrigoProxy proxyWithType:kOrigoTypeResidence] addMember:_member];
            }
        }
        
        if (([[_member residences] count] == 1) && ([_addressBookHomeNumbers count] == 1)) {
            [_member residence].telephone = _addressBookHomeNumbers[0];
            [_addressBookHomeNumbers removeAllObjects];
        }
    }
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


- (void)performLookupAction
{
    [self.view endEditing:YES];
    
    id<OMember> pivotMember = [self.entity ancestorConformingToProtocol:@protocol(OMember)];
    
    if ([[pivotMember peersNotInOrigo:_origo] count] > 0) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagSource];
        
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Retrieve from Contacts", @"")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Retrieve from other groups", @"")];
        
        [actionSheet show];
    } else {
        [self resetInputState];
        [self pickFromAddressBook];
    }
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self actionIs:kActionRegister] && [self targetIs:kTargetJuvenile] && _guardian) {
        [[_guardian residence] addMember:_member];
        
        [self reloadSections];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    //if (!_nameField) {
        _nameField = [self.detailCell inputFieldForKey:kPropertyKeyName];
        _dateOfBirthField = [self.detailCell inputFieldForKey:kPropertyKeyDateOfBirth];
        _mobilePhoneField = [self.detailCell inputFieldForKey:kPropertyKeyMobilePhone];
        _emailField = [self.detailCell inputFieldForKey:kPropertyKeyEmail];
    //}
    
    if ([self actionIs:kActionRegister] && [self targetIs:kTargetJuvenile]) {
        if (_guardian) {
            [_nameField becomeFirstResponder];
        } else {
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


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    _member = [self.entity proxy];
    _origo = [self.entity ancestorConformingToProtocol:@protocol(OOrigo)];
    _membership = [_origo membershipForMember:_member];
    
    if ([self targetIs:kTargetUser]) {
        self.title = NSLocalizedString(@"About me", @"");
    } else if ([self targetIs:kTargetGuardian]) {
        self.title = [[OLanguage nouns][_guardian_][singularIndefinite] capitalizedString];
    } else if ([self targetIs:kTargetContact]) {
        self.title = NSLocalizedString(_origo.type, kStringPrefixContactTitle);
    } else if ([self targetIs:kTargetParentContact]) {
        self.title = NSLocalizedString(@"Parent contact", @"");
    } else if ([_member isCommitted]) {
        NSString *givenName = [_member givenName];
        
        self.title = [_member isHousemateOfUser] ? givenName : _member.name;
        self.navigationItem.backBarButtonItem = [UIBarButtonItem buttonWithTitle:givenName];
    } else {
        self.title = NSLocalizedString(_origo.type, kStringPrefixNewMemberTitle);
    }
    
    if ([self actionIs:kActionRegister]) {
        if (![self targetIs:kTargetUser] && ![self targetIs:kTargetJuvenile]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem lookupButton];
        }
    } else if ([self actionIs:kActionDisplay]) {
        if (self.canEdit) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem actionButton];
        }
    }
    
    self.requiresSynchronousServerCalls = YES;
}


- (void)loadData
{
    [self setDataForDetailSection];
    
    if ([_member isJuvenile]) {
        [self setData:[_member guardians] forSectionWithKey:kSectionKeyGuardian];
    }
    
    [self setData:[_member residences] forSectionWithKey:kSectionKeyAddress];
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyGuardian) {
        id<OMember> guardian = [self dataAtIndexPath:indexPath];
        
        cell.imageView.image = [OUtil smallImageForMember:guardian];
        cell.textLabel.text = guardian.name;
        cell.destinationId = kIdentifierMember;
        
        if ([[_member residences] count] == 1) {
            cell.detailTextLabel.text = [OUtil contactInfoForMember:guardian];
        } else {
            cell.detailTextLabel.text = [[guardian residence] shortAddress];
        }
        
        if ([_member hasParent:guardian] && ![_member guardiansAreParents]) {
            cell.detailTextLabel.text = [[[guardian parentNoun][singularIndefinite] capitalizedString] stringByAppendingString:cell.detailTextLabel.text separator:kSeparatorComma];
        }
    } else if (sectionKey == kSectionKeyAddress) {
        id<OOrigo> residence = [self dataAtIndexPath:indexPath];
        
        cell.imageView.image = [UIImage imageNamed:kIconFileHousehold];
        cell.textLabel.text = [residence shortAddress];
        cell.detailTextLabel.text = [OPhoneNumberFormatter formatPhoneNumber:residence.telephone canonicalise:YES];
        
        [cell setDestinationId:kIdentifierOrigo selectableDuringInput:YES];
    }
}


- (NSArray *)toolbarButtons
{
    NSArray *toolbarButtons = nil;
    
    if ([_member isCommitted] && ![_member isUser]) {
        toolbarButtons = [[OMeta m].switchboard toolbarButtonsForMember:_member];
    }
    
    return toolbarButtons;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasFooter = [self isBottomSectionKey:sectionKey] && [self actionIs:kActionRegister];
    
    hasFooter = hasFooter && ![self targetIs:kTargetUser];
    hasFooter = hasFooter && ![self targetIs:kTargetJuvenile];
    
    return hasFooter;
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kSectionKeyGuardian) {
        NSSet *guardians = [_member guardians];
        
        if ([guardians count] == 1) {
            id<OMember> guardian = [guardians anyObject];
            
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
        if ([[_member residences] count] == 1) {
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
        
        if ([self targetIs:kTargetGuardian]) {
            text = [NSString stringWithFormat:@"%@\n\n%@", NSLocalizedString(@"Before you can register a minor, you must register his or her parents/guardians.", @""), text];
        }
    }
    
    return text;
}


- (BOOL)canDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDelete = NO;
    
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyAddress) {
        canDelete = ([self tableView:self.tableView numberOfRowsInSection:indexPath.section] > 1);
    }
    
    return canDelete;
}


- (BOOL)canCompareObjectsInSectionWithKey:(NSInteger)sectionKey
{
    return (sectionKey == kSectionKeyGuardian);
}


- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2
{
    NSComparisonResult result = NSOrderedSame;
    
    id<OMember> guardian1 = object1;
    id<OMember> guardian2 = object2;
    
    if ([_member hasParent:guardian1] && ![_member hasParent:guardian2]) {
        result = NSOrderedAscending;
    } else if (![_member hasParent:guardian1] && [_member hasParent:guardian2]) {
        result = NSOrderedDescending;
    } else {
        NSString *address1 = [[guardian1 residence] shortAddress];
        NSString *address2 = [[guardian2 residence] shortAddress];
        
        if ([address1 isEqualToString:address2]) {
            result = [guardian1.name localizedCompare:guardian2.name];
        } else {
            result = [address1 localizedCompare:address2];
        }
    }
    
    return result;
}


- (NSString *)sortKeyForSectionWithKey:(NSInteger)sectionKey
{
    NSString *sortKey = nil;
    
    if (sectionKey == kSectionKeyAddress) {
        sortKey = [OUtil sortKeyWithPropertyKey:kPropertyKeyAddress relationshipKey:kRelationshipKeyOrigo];
    }
    
    return sortKey;
}


- (BOOL)shouldRelayDismissalOfModalViewController:(id<OTableViewController>)viewController
{
    return [viewController.identifier isEqualToString:kIdentifierOrigo];
}


- (void)willDismissModalViewController:(id<OTableViewController>)viewController
{
    if ([viewController.identifier isEqualToString:kIdentifierMember]) {
        if ([self targetIs:kTargetJuvenile] && viewController.returnData) {
            _guardian = viewController.returnData;
        }
    } else if ([viewController.identifier isEqualToString:kIdentifierAuth]) {
        if ([_member.email isEqualToString:_emailField.value]) {
            [self persistMember];
        } else {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Activation failed", @"") message:[NSString stringWithFormat:NSLocalizedString(@"The email address %@ could not be activated ...", @""), _emailField.value] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil] show];
            
            self.nextInputField = _emailField;
            [self toggleEditMode];
        }
    }
}


- (void)didDismissModalViewController:(id<OTableViewController>)viewController
{
    if (viewController.returnData) {
        if ([viewController.identifier isEqualToString:kIdentifierValuePicker]) {
            if ([self isEligibleMember:viewController.returnData]) {
                if ([self aspectIs:kAspectHousehold]) {
                    [[self.detailCell nextInvalidInputField] becomeFirstResponder];
                } else {
                    [self endEditing];
                }
            }
        } else if ([viewController.identifier isEqualToString:kIdentifierMember]) {
            // TODO
        }
    } else if ([self actionIs:kActionRegister]) {
        [self.detailCell resumeFirstResponder];
    }
}


#pragma mark - OTableViewInputDelegate conformance

- (BOOL)isReceivingInput
{
    return [self actionIs:kActionInput];
}


- (BOOL)inputIsValid
{
    BOOL isValid = [_nameField hasValidValue];
    
    if (isValid && [self aspectIs:kAspectHousehold]) {
        isValid = [_dateOfBirthField hasValidValue];
        
        if ([_member isCommitted] && ![_member isUser]) {
            isValid = [_dateOfBirthField.value isEqual:_member.dateOfBirth];
            
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
    
    if (isValid && !([_dateOfBirthField.value isBirthDateOfMinor] || [_member isJuvenile])) {
        if ([self aspectIs:kAspectHousehold]) {
            isValid = [_mobilePhoneField hasValidValue] && [_emailField hasValidValue];
        } else {
            isValid = _emailField.value || [_mobilePhoneField hasValidValue];
        }
    }
    
    if (isValid && ![self targetIs:kTargetUser]) {
        [self performLocalLookup];
    }
    
    return isValid;
}


- (void)processInput
{
    if ([self actionIs:kActionRegister]) {
        if ([_member instance] && ![_member isUser]) {
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
        if ([_member.email hasValue] && ![_emailField.value isEqualToString:_member.email]) {
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


- (BOOL)isDisplayableFieldWithKey:(NSString *)key
{
    BOOL isDisplayable = [key isEqualToString:kPropertyKeyName] || [self aspectIs:kAspectHousehold];
    
    if (!isDisplayable && [@[kPropertyKeyMobilePhone, kPropertyKeyEmail] containsObject:key]) {
        isDisplayable = !([self targetIs:kTargetJuvenile] && [self actionIs:kActionInput]);
    }
    
    return isDisplayable;
}


- (BOOL)isEditableFieldWithKey:(NSString *)key
{
    BOOL isEditable = YES;
    
    if ([key isEqualToString:kPropertyKeyEmail]) {
        isEditable = !([self actionIs:kActionRegister] && [self targetIs:kTargetUser]);
    }
    
    return isEditable;
}


- (BOOL)shouldCommitEntity:(id)entity
{
    return [_member.gender hasValue] && [self.entity.ancestor isCommitted];
}


#pragma mark - OMemberExaminerDelegate conformance

- (void)examinerDidFinishExamination
{
    if (_JSONData) {
        [[OMeta m].context saveServerReplicas:_JSONData];
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
            
        case kActionSheetTagSource:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                [self resetInputState];
            }
            
            break;
            
        case kActionSheetTagAddressBookEntry:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                if ([_mobilePhoneField hasMultiValue]) {
                    if (buttonTag != kButtonTagAddressBookEntryNoValue) {
                        _mobilePhoneField.value = _mobilePhoneField.value[buttonIndex];
                        _member.mobilePhone = _mobilePhoneField.value;
                    }
                } else if ([_emailField hasMultiValue]) {
                    if (buttonTag != kButtonTagAddressBookEntryNoValue) {
                        _emailField.value = _emailField.value[buttonIndex];
                        _member.email = _emailField.value;
                    }
                } else if ([_addressBookAddresses count]) {
                    if (buttonTag == kButtonTagAddressBookEntryAllValues) {
                        for (id<OOrigo> address in _addressBookAddresses) {
                            [address addMember:_member];
                        }
                    } else if (buttonTag != kButtonTagAddressBookEntryNoValue) {
                        [_addressBookAddresses[buttonIndex] addMember:_member];
                    }
                    
                    [_addressBookAddresses removeAllObjects];
                } else if ([_addressBookHomeNumbers count]) {
                    if ([_addressBookMappings[0] isKindOfClass:[NSString class]]) {
                        if (buttonTag != kButtonTagAddressBookEntryNoValue) {
                            NSString *selectedNumber = _addressBookMappings[buttonIndex];
                            [_member residence].telephone = selectedNumber;
                        }
                        
                        [_addressBookHomeNumbers removeAllObjects];
                    } else {
                        if (buttonTag != kButtonTagAddressBookEntryNoValue) {
                            id<OOrigo> selectedAddress = _addressBookMappings[buttonIndex];
                            selectedAddress.telephone = _addressBookHomeNumbers[0];
                        }
                        
                        [_addressBookHomeNumbers removeObjectAtIndex:0];
                    }
                }
                
                if (![_addressBookAddresses count] && ![_addressBookHomeNumbers count]) {
                    [self presentMember:_member];
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
            if ((buttonIndex != actionSheet.cancelButtonIndex) && ![_member instance]) {
                if ([_emailField hasMultiValue]) {
                    [self refineAddressBookContactInfo];
                } else if (!_didPerformLocalLookup) {
                    [self performLocalLookup];
                    
                    if (![_member instance]) {
                        [self refineAddressBookAddressInfo];
                    }
                } else if ([_addressBookHomeNumbers count]) {
                    [self refineAddressBookAddressInfo];
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
    [self retrieveNameFromAddressBookPersonRecord:person];
    [self retrievePhoneNumbersFromAddressBookPersonRecord:person];
    [self retrieveEmailAddressesFromAddressBookPersonRecord:person];
    [self retrieveAddressesFromAddressBookPersonRecord:person];

    if ([_mobilePhoneField hasMultiValue] || [_emailField hasMultiValue]) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self refineAddressBookContactInfo];
        }];
    } else {
        [self performLocalLookup];
        
        if ([_member instance]) {
            [self dismissViewControllerAnimated:YES completion:NULL];
        } else if ([_addressBookAddresses count] || [_addressBookHomeNumbers count]) {
            [self dismissViewControllerAnimated:YES completion:^{
                [self refineAddressBookAddressInfo];
            }];
        } else {
            [self presentMember:_member];
            [self dismissViewControllerAnimated:YES completion:NULL];
        }
    }
    
    return NO;
}


- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    return NO;
}


- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.detailCell resumeFirstResponder];
    }];
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
                    id member = [OMemberProxy proxyForEntityWithJSONDictionary:JSONDictionary];
                    
                    if ([self inputMatchesRegisteredMember:member]) {
                        _JSONData = data;
                        
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
