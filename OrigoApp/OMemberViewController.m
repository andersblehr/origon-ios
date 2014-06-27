//
//  OMemberViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OMemberViewController.h"

static NSInteger const kSectionKeyMember = 0;
static NSInteger const kSectionKeyGuardians = 1;
static NSInteger const kSectionKeyAddresses = 2;

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

static NSInteger const kActionSheetTagGuardianAddressYesNo = 4;
static NSInteger const kButtonTagYes = 0;

static NSInteger const kActionSheetTagGuardianAddress = 5;

static NSInteger const kAlertTagUnknownChild = 0;
static NSInteger const kButtonTagOK = 1;

static NSInteger const kAlertTagEmailChange = 1;
static NSInteger const kButtonTagContinue = 1;


@interface OMemberViewController () <OTableViewController, OInputCellDelegate, OMemberExaminerDelegate, OConnectionDelegate, UIActionSheetDelegate, UIAlertViewDelegate, ABPeoplePickerNavigationControllerDelegate> {
@private
    id<OMember> _member;
    id<OOrigo> _origo;
    id<OMembership> _membership;
    
    OInputField *_nameField;
    OInputField *_dateOfBirthField;
    OInputField *_mobilePhoneField;
    OInputField *_emailField;

    NSMutableArray *_addressBookAddresses;
    NSMutableArray *_addressBookHomeNumbers;
    NSMutableArray *_addressBookMappings;
    
    NSArray *_cachedResidences;
    NSMutableDictionary *_cachedResidencesById;
    
    BOOL _didPerformLocalLookup;
}

@end


@implementation OMemberViewController

#pragma mark - Auxiliary methods

- (NSString *)nameKey
{
    return [self targetIs:kTargetJuvenile] ? kMappedKeyGivenName : kMappedKeyFullName;
}


- (void)resetInputState
{
    [_member useInstance:nil];
    
    self.target = _member;
    self.inputCell.editable = YES;
    [self.inputCell clearInputFields];
    
    if ([self hasSectionWithKey:kSectionKeyAddresses]) {
        [self reloadSectionWithKey:kSectionKeyAddresses];
    }
    
    _didPerformLocalLookup = NO;
}


#pragma mark - Input validation

- (BOOL)reflectIfEligibleMember:(id<OMember>)member
{
    BOOL isEligible = ![_origo hasMember:member];
    
    if (isEligible) {
        [self reflectMember:member];
    } else {
        [_nameField becomeFirstResponder];
        
        [OAlert showAlertWithTitle:nil text:[NSString stringWithFormat:NSLocalizedString(@"%@ is already in %@.", @""), [member publicName], _origo.name]];
    }
    
    return isEligible;
}


- (BOOL)identifierFieldHasUniqueValue:(OInputField *)identifierField
{
    BOOL hasUniqueValue = [identifierField hasValidValue];
    
    if (hasUniqueValue && [self actionIs:kActionRegister] && ![self targetIs:kTargetUser]) {
        id<OMember> registrant = [[OMeta m].context entityOfClass:[OMember class] withValue:identifierField.value forKey:identifierField.key];
        
        if (registrant) {
            hasUniqueValue = [registrant.name fuzzyMatches:_nameField.value];
            
            if (hasUniqueValue) {
                hasUniqueValue = [self reflectIfEligibleMember:registrant];
            } else {
                [identifierField becomeFirstResponder];
                
                if ([OValidator isEmailValue:identifierField.value]) {
                    [OAlert showAlertWithTitle:nil text:[NSString stringWithFormat:NSLocalizedString(@"The email address %@ is already in use.", @""), identifierField.value]];
                } else {
                    [OAlert showAlertWithTitle:nil text:[NSString stringWithFormat:NSLocalizedString(@"The mobile number %@ is already in use.", @""), identifierField.value]];
                }
            }
        }
    }
    
    return hasUniqueValue;
}


- (BOOL)inputMatchesMemberWithDictionary:(NSDictionary *)dictionary
{
    NSString *name = dictionary[kPropertyKeyName];
    NSDate *dateOfBirth = [NSDate dateFromSerialisedDate:dictionary[kPropertyKeyDateOfBirth]];
    NSString *mobilePhone = dictionary[kPropertyKeyMobilePhone];
    NSString *email = dictionary[kPropertyKeyEmail];
    
    BOOL inputMatches = [_nameField.value fuzzyMatches:name];
    
    if (inputMatches && _dateOfBirthField) {
        inputMatches = [_dateOfBirthField.value isEqual:dateOfBirth];
    }
    
    if (inputMatches && _mobilePhoneField.value) {
        inputMatches = [[OPhoneNumberFormatter formatPhoneNumber:_mobilePhoneField.value canonicalise:YES] isEqualToString:[OPhoneNumberFormatter formatPhoneNumber:mobilePhone canonicalise:YES]];
    }
    
    if (inputMatches && _emailField.value) {
        inputMatches = [_emailField.value isEqualToString:email];
    }
    
    return inputMatches;
}


#pragma mark - Lookup & presentation

- (void)performLocalLookup
{
    id<OMember> actualMember = nil;
    
    if (_emailField.value) {
        actualMember = [[OMeta m].context entityOfClass:[OMember class] withValue:_emailField.value forKey:kPropertyKeyEmail];
    }
    
    if (!actualMember && _mobilePhoneField.value) {
        actualMember = [[OMeta m].context entityOfClass:[OMember class] withValue:_mobilePhoneField.value forKey:kPropertyKeyMobilePhone];
        
        if (actualMember && actualMember.email) {
            actualMember = nil;
        }
    }
    
    if (actualMember) {
        if ([self targetIs:kTargetGuardian]) {
            [self expireCoGuardianIfAlreadyHousemateOfGuardian:actualMember];
        }
        
        [self reflectMember:actualMember];
    }
    
    _didPerformLocalLookup = YES;
}


- (void)expireCoGuardianIfAlreadyHousemateOfGuardian:(id<OMember>)guardian
{
    id<OMember> ward = [self.entity ancestorConformingToProtocol:@protocol(OMember)];
    id<OMember> coGuardian = [[ward guardians] anyObject];
    
    if (coGuardian && ![coGuardian instance]) {
        for (id<OMember> housemate in [guardian housemates]) {
            if (![housemate isJuvenile] && [housemate.name fuzzyMatches:coGuardian.name]) {
                [coGuardian expire];
            }
        }
    }
}


- (void)reflectMember:(id<OMember>)member
{
    _nameField.value = member.name;
    _mobilePhoneField.value = member.mobilePhone;
    _emailField.value = member.email;
    
    if ([member instance] || (member != _member)) {
        if ([member instance]) {
            [_member useInstance:[member instance]];
        } else {
            [_member reflectEntity:member];
        }
        
        [self endEditing];
    } else {
        OInputField *invalidInputField = [self.inputCell nextInvalidInputField];
        
        if (invalidInputField) {
            [invalidInputField becomeFirstResponder];
        } else {
            [_emailField becomeFirstResponder];
        }
    }
    
    [self reloadSectionWithKey:kSectionKeyAddresses];
}


#pragma mark - Examine and persist new member

- (void)examineJuvenile
{
    id<OMember> member = nil;
    
    NSArray *guardians = [[_member guardians] allObjects];
    NSMutableArray *activeGuardians = [NSMutableArray array];
    NSMutableArray *inactiveGuardians = [NSMutableArray array];
    
    for (id<OMember> guardian in guardians) {
        if ([guardian isActive]) {
            [activeGuardians addObject:guardian];
        } else {
            [inactiveGuardians addObject:guardian];
        }
        
        for (id<OMember> ward in [guardian wards]) {
            if (!member && (ward != _member)) {
                if ([_nameField.value fuzzyMatches:[ward givenName]]) {
                    member = ward;
                }
            }
        }
    }
    
    BOOL hasActiveGuardians = [activeGuardians count] > 0;
    
    if (member) {
        for (id<OMembership> residency in [_member residencies]) {
            [residency expire];
        }
        
        if ([self reflectIfEligibleMember:member]) {
            [self persistMember];
        }
    } else if (hasActiveGuardians && ([activeGuardians count] == [guardians count])) {
        if ([activeGuardians count] == 1) {
            [OAlert showAlertWithTitle:NSLocalizedString(@"Unknown child", @"") text:[NSString stringWithFormat:NSLocalizedString(@"%@ has not registered a child called %@.", @""), [activeGuardians[0] givenName], _nameField.value]];
        } else {
            [OAlert showAlertWithTitle:NSLocalizedString(@"Unknown child", @"") text:[NSString stringWithFormat:NSLocalizedString(@"Neither %@ nor %@ has registered a child called %@.", @""), [activeGuardians[0] givenName], [activeGuardians[1] givenName], _nameField.value]];
            
        }
        
        [self.inputCell resumeFirstResponder];
    } else if (hasActiveGuardians && ![[guardians[0] housemates] containsObject:guardians[0]]) {
        for (id<OMembership> residency in [_member residencies]) {
            if ([residency.origo hasMember:activeGuardians[0]]) {
                [residency expire];
            }
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:NSLocalizedString(@"%@ has not registered a child called %@. %@ will only be added to %@'s household.", @""), [activeGuardians[0] givenName], _nameField.value, _nameField.value, [inactiveGuardians[0] givenName]] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
        alert.tag = kAlertTagUnknownChild;
    } else {
        [self examineMember];
    }
}


- (void)examineMember
{
    [self.inputCell writeInput];
    
    [[OMemberExaminer examinerForResidence:_origo delegate:self] examineMember:_member];
}


- (void)persistMember
{
    [self.inputCell writeInput];
    
    if ([self actionIs:kActionRegister]) {
        if ([self targetIs:kTargetGuardian] && [self aspectIs:kAspectJuvenile]) {
            id<OMember> ward = [self.entity ancestorConformingToProtocol:@protocol(OMember)];
            
            if ([[ward residences] count]) {
                if ([ward hasAddress]) {
                    [self presentGuardianAddressSheetForWard:ward];
                } else {
                    [[ward residence] addMember:_member];
                    [self.dismisser dismissModalViewController:self];
                }
            } else if (![_member hasAddress]) {
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:[_member residence]];
            } else {
                [self.dismisser dismissModalViewController:self];
            }
        } else {
            _membership = [_origo addMember:_member];
            
            if (![_member hasAddress]) {
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:[_member residence]];
            } else {
                if ([_member isUser] && ![_member isActive]) {
                    [_member makeActive];
                }
                
                [self.dismisser dismissModalViewController:self];
            }
        }
    }
}


#pragma mark - Action sheets & alerts

- (void)presentHousemateResidencesSheet
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagResidence];
    
    for (id<OOrigo> residence in _cachedResidences) {
        [actionSheet addButtonWithTitle:[residence shortAddress]];
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"New address", @"") tag:kButtonTagResidenceNewAddress];
    
    [actionSheet show];
}


- (void)presentMultiValueSheetForInputField:(OInputField *)inputField
{
    NSString *promptFormat = nil;
    
    if (inputField == _mobilePhoneField) {
        promptFormat = NSLocalizedString(@"%@ has more than one mobile phone number. Which number do you want to provide?", @"");
    } else if (inputField == _emailField) {
        promptFormat = NSLocalizedString(@"%@ has more than one email address. Which address do you want to provide?", @"");
    }
    
    [inputField becomeFirstResponder];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:promptFormat, [_nameField.value givenName]] delegate:self tag:kActionSheetTagAddressBookEntry];
    
    for (NSInteger i = 0; i < [inputField.value count]; i++) {
        [actionSheet addButtonWithTitle:inputField.value[i]];
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"None of them", @"") tag:kButtonTagAddressBookEntryNoValue];
    
    [actionSheet show];
}


- (void)presentMultipleAddressesSheet
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:NSLocalizedString(@"%@ has more than one home address. Which address do you want to provide?", @""), [_nameField.value givenName]] delegate:self tag:kActionSheetTagAddressBookEntry];
    
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


- (void)presentHomeNumberMappingSheet
{
    static NSInteger homeNumberCount = 0;

    if (!homeNumberCount) {
        homeNumberCount = [_addressBookHomeNumbers count];
    }
    
    NSString *givenName = [_nameField.value givenName];
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


- (void)presentGuardianAddressSheetForWard:(id<OMember>)ward
{
    _cachedResidences = [NSArray array];
    
    for (id<OOrigo> residence in [ward residences]) {
        if ([residence hasAddress]) {
            _cachedResidences = [_cachedResidences arrayByAddingObject:residence];
        }
    }
    
    OActionSheet *actionSheet = nil;
    
    if ([_cachedResidences count] == 1) {
        NSString *guardians = [OUtil commaSeparatedListOfItems:[_cachedResidences[0] elders] conjoinLastItem:YES];

        actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:NSLocalizedString(@"Does %@ live with %@?", @""), [_member givenName], guardians] delegate:self tag:kActionSheetTagGuardianAddressYesNo];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Yes", @"")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"No", @"")];
    } else {
        NSString *guardians1 = [OUtil commaSeparatedListOfItems:[_cachedResidences[0] elders] conjoinLastItem:YES];
        NSString *guardians2 = [OUtil commaSeparatedListOfItems:[_cachedResidences[1] elders] conjoinLastItem:YES];
        
        actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:NSLocalizedString(@"Does %@ live with %@ or %@?", @""), [_member givenName], guardians1, guardians2] delegate:self tag:kActionSheetTagGuardianAddress];
        [actionSheet addButtonWithTitle:guardians1];
        [actionSheet addButtonWithTitle:guardians2];
    }
    
    [actionSheet show];
}


- (void)presentAlertForNumberOfUmatchedResidences:(NSInteger)numberOfUnmatchedResidences
{
    NSString *title = nil;
    NSString *text = nil;
    
    if (numberOfUnmatchedResidences == 1) {
        title = NSLocalizedString(@"Unknown address", @"");
    } else {
        title = NSLocalizedString(@"Unknown addresses", @"");
    }
    
    if (numberOfUnmatchedResidences < [[_member residences] count]) {
        if (numberOfUnmatchedResidences == 1) {
            text = NSLocalizedString(@"One of the addresses you provided did not match our records and was not saved.", @"");
        } else {
            text = NSLocalizedString(@"Some of the addresses you provided did not match our records and were not saved.", @"");
        }
    } else if (numberOfUnmatchedResidences == 1) {
        text = NSLocalizedString(@"The address you provided did not match our records and was not saved.", @"");
    } else {
        text = NSLocalizedString(@"The addresses you provided did not match our records and were not saved.", @"");
    }
    
    [OAlert showAlertWithTitle:title text:text];
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
        [self presentMultiValueSheetForInputField:_mobilePhoneField];
    } else if ([_emailField hasMultiValue]) {
        [self presentMultiValueSheetForInputField:_emailField];
    }
}


- (void)refineAddressBookAddressInfo
{
    if ([_addressBookAddresses count]) {
        [self presentMultipleAddressesSheet];
    } else if ([_addressBookHomeNumbers count]) {
        if ([[_member residences] count]) {
            [self presentHomeNumberMappingSheet];
        } else {
            [_addressBookHomeNumbers removeAllObjects];
        }
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
        
        if ([OValidator isEmailValue:emailAddress]) {
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
    
    if ([[OUtil eligibleCandidatesForOrigo:_origo isElder:[self targetIs:kTargetElder]] count]) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagSource];
        
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Retrieve from Contacts", @"")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Retrieve from other groups", @"")];
        
        [actionSheet show];
    } else {
        [self resetInputState];
        [self pickFromAddressBook];
    }
}


- (void)addItem
{
    [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetGuardian];
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self actionIs:kActionRegister] && [[_member guardians] count]) {
        [self reloadSections];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    if ([self actionIs:kActionRegister] && [self targetIs:kTargetJuvenile]) {
        if ([[_member guardians] count]) {
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
        
        self.title = [_member isHousemateOfUser] ? givenName : [_member publicName];
        self.navigationItem.backBarButtonItem = [UIBarButtonItem buttonWithTitle:givenName];
    } else {
        self.title = NSLocalizedString(_origo.type, kStringPrefixNewMemberTitle);
    }
    
    if ([self actionIs:kActionRegister]) {
        if ([self targetIs:kTargetJuvenile]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
        } else if (![self targetIs:kTargetUser]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem lookupButtonWithTarget:self];
        }
    } else if ([self actionIs:kActionDisplay]) {
        if ([_member isManagedByUser]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem actionButtonWithTarget:self];
        }
    }
    
    self.requiresSynchronousServerCalls = YES;
}


- (void)loadData
{
    [self setDataForInputSection];
    
    if ([_member isJuvenile]) {
        [self setData:[_member guardians] forSectionWithKey:kSectionKeyGuardians];
    }
    
    if (![_member isUser] || [[OMeta m] userIsAllSet]) {
        NSMutableArray *addresses = [NSMutableArray array];
        
        for (id<OOrigo> residence in [_member residences]) {
            if ([residence hasAddress]) {
                [addresses addObject:residence];
            }
        }
        
        [self setData:addresses forSectionWithKey:kSectionKeyAddresses];
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyGuardians) {
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
    } else if (sectionKey == kSectionKeyAddresses) {
        id<OOrigo> residence = [self dataAtIndexPath:indexPath];
        
        cell.imageView.image = [UIImage imageNamed:kIconFileHousehold];
        cell.textLabel.text = [residence shortAddress];
        cell.detailTextLabel.text = [OPhoneNumberFormatter formatPhoneNumber:residence.telephone canonicalise:YES];
        
        [cell setDestinationId:kIdentifierOrigo selectableDuringInput:![self targetIs:kTargetJuvenile]];
    }
}


- (NSArray *)toolbarButtons
{
    NSArray *toolbarButtons = nil;
    
    if ([_member isCommitted] && ![_member isUser]) {
        toolbarButtons = [[OMeta m].switchboard toolbarButtonsForMember:_member presenter:self];
    }
    
    return toolbarButtons;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasFooter = NO;
    
    if ([self actionIs:kActionRegister]) {
        if ([self isBottomSectionKey:sectionKey]) {
            hasFooter = ![_member isUser] && ![_member isJuvenile];
        } else if (sectionKey == kSectionKeyMember) {
            hasFooter = [_member isJuvenile];
        }
    }
    
    return hasFooter;
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kSectionKeyGuardians) {
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
    } else if (sectionKey == kSectionKeyAddresses) {
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
    
    if ([self isBottomSectionKey:sectionKey]) {
        text = NSLocalizedString(@"A notification will be sent to the email address you provide.", @"");
        
        if ([self targetIs:kTargetGuardian]) {
            text = [NSString stringWithFormat:@"%@\n\n%@", NSLocalizedString(@"Before you can register a minor, you must register his or her guardians.", @""), text];
        }
    } else if (sectionKey == kSectionKeyMember) {
        text = NSLocalizedString(@"Tap [+] to add another guardian.", @"");
    }
    
    return text;
}


- (void)willDisplayInputCell:(OTableViewCell *)cell
{
    _nameField = [cell inputFieldForKey:[self nameKey]];
    _dateOfBirthField = [cell inputFieldForKey:kPropertyKeyDateOfBirth];
    _mobilePhoneField = [cell inputFieldForKey:kPropertyKeyMobilePhone];
    _emailField = [cell inputFieldForKey:kPropertyKeyEmail];
}


- (BOOL)canDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDelete = NO;
    
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyAddresses) {
        canDelete = [self tableView:self.tableView numberOfRowsInSection:indexPath.section] > 1;
    }
    
    return canDelete;
}


- (BOOL)canCompareObjectsInSectionWithKey:(NSInteger)sectionKey
{
    return sectionKey == kSectionKeyGuardians;
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
    
    if (sectionKey == kSectionKeyAddresses) {
        sortKey = [OUtil sortKeyWithPropertyKey:kPropertyKeyAddress relationshipKey:kRelationshipKeyOrigo];
    }
    
    return sortKey;
}


- (BOOL)shouldRelayDismissalOfModalViewController:(OTableViewController *)viewController
{
    BOOL shouldRelay = NO;
    
    if ([viewController.identifier isEqualToString:kIdentifierOrigo]) {
        shouldRelay = YES;
    } else if ([viewController.identifier isEqualToString:kIdentifierMember]) {
        if ([_member isJuvenile]) {
            shouldRelay = [[_member guardians] count] ? NO : viewController.didCancel;
        }
    }
    
    return shouldRelay;
}


- (void)willDismissModalViewController:(OTableViewController *)viewController
{
    if ([viewController.identifier isEqualToString:kIdentifierMember]) {
        if ([self targetIs:kTargetJuvenile] && !viewController.didCancel) {
            id<OOrigo> guardianResidence = [viewController.returnData residence];
            
            if (![guardianResidence hasMember:_member]) {
                [guardianResidence addMember:_member];
            }
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


- (void)didDismissModalViewController:(OTableViewController *)viewController
{
    if (!viewController.didCancel) {
        if ([viewController.identifier isEqualToString:kIdentifierValuePicker]) {
            if ([self reflectIfEligibleMember:viewController.returnData]) {
                if ([self aspectIs:kAspectHousehold]) {
                    [[self.inputCell nextInvalidInputField] becomeFirstResponder];
                } else {
                    [self endEditing];
                }
            }
        }
    } else if ([self actionIs:kActionRegister]) {
        [self.inputCell resumeFirstResponder];
    }
}


#pragma mark - OInputCellDelegate conformance

- (OInputCellBlueprint *)inputCellBlueprint
{
    OInputCellBlueprint *blueprint = [[OInputCellBlueprint alloc] init];
    blueprint.titleKey = [self nameKey];
    blueprint.detailKeys = @[kPropertyKeyDateOfBirth, kPropertyKeyMobilePhone, kPropertyKeyEmail];
    blueprint.hasPhoto = _member.photo || ([self aspectIs:kAspectHousehold] && [_member isManagedByUser]);
    
    return blueprint;
}


- (BOOL)isReceivingInput
{
    return [self actionIs:kActionInput];
}


- (BOOL)inputIsValid
{
    BOOL isValid = [_nameField hasValidValue];
    
    if (!isValid && [self targetIs:kTargetJuvenile]) {
        isValid = [_nameField.value hasValue];
    }
    
    if (isValid && [self aspectIs:kAspectHousehold]) {
        isValid = [_dateOfBirthField hasValidValue];
        
        if ([_member instance] && ![_member isUser]) {
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
            isValid = [self identifierFieldHasUniqueValue:_mobilePhoneField];
        }
    }
    
    if (isValid && _emailField.value) {
        isValid = [self identifierFieldHasUniqueValue:_emailField];
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
            } else if ([self targetIs:kTargetJuvenile]) {
                [self examineJuvenile];
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
    BOOL isDisplayable = [key isEqualToString:[self nameKey]] || [self aspectIs:kAspectHousehold];
    
    if (!isDisplayable && [@[kPropertyKeyMobilePhone, kPropertyKeyEmail] containsObject:key]) {
        isDisplayable = ![self targetIs:kTargetJuvenile];
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


- (void)didCommitEntity:(id)entity
{
    _member = entity;
    
    if ([_cachedResidencesById count] && ![_member isActive]) {
        for (id<OOrigo> residence in [_member residences]) {
            id<OOrigo> cachedResidence = _cachedResidencesById[residence.entityId];
            
            if (!residence.telephone && cachedResidence.telephone) {
                residence.telephone = cachedResidence.telephone;
            }
        }
    }
}


#pragma mark - OMemberExaminerDelegate conformance

- (void)examinerDidFinishExamination
{
    [self persistMember];
}


- (void)examinerDidCancelExamination
{
    [self.inputCell resumeFirstResponder];
}


#pragma mark - OConnectionDelegate conformance

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    [super didCompleteWithResponse:response data:data];
    
    if (response.statusCode == kHTTPStatusOK) {
        NSString *identifier = _emailField.value ? _emailField.value : _mobilePhoneField.value;
        NSString *identifierKey = _emailField.value ? kPropertyKeyEmail : kPropertyKeyMobilePhone;
        
        id actualMember = nil;
        
        for (NSDictionary *entityDictionary in data) {
            if ([[entityDictionary allKeys] containsObject:identifierKey]) {
                if ([entityDictionary[identifierKey] isEqualToString:identifier]) {
                    if ([self inputMatchesMemberWithDictionary:entityDictionary]) {
                        actualMember = [OMemberProxy proxyForEntityWithDictionary:entityDictionary];
                    }
                    
                    break;
                }
            }
        }
        
        if (actualMember) {
            [OEntityProxy cacheProxiesForEntitiesWithDictionaries:data];
            
            if ([self targetIs:kTargetGuardian]) {
                [self expireCoGuardianIfAlreadyHousemateOfGuardian:actualMember];
            }
            
            _cachedResidencesById = [NSMutableDictionary dictionary];
            
            if ([_member hasAddress] && [actualMember hasAddress]) {
                NSMutableArray *residences = [[_member residences] mutableCopy];
                NSMutableArray *unmatchedResidences = [residences mutableCopy];
                
                for (id<OOrigo> actualResidence in [actualMember residences]) {
                    for (id<OOrigo> residence in residences) {
                        if ([unmatchedResidences containsObject:residence]) {
                            if ([actualResidence.address fuzzyMatches:residence.address]) {
                                [unmatchedResidences removeObject:residence];
                                _cachedResidencesById[actualResidence.entityId] = residence;
                            }
                        }
                    }
                }
                
                if ([unmatchedResidences count]) {
                    [self presentAlertForNumberOfUmatchedResidences:[unmatchedResidences count]];
                }
            }
            
            [self reflectMember:actualMember];
            [self persistMember];
        } else {
            [OAlert showAlertWithTitle:NSLocalizedString(@"Incorrect details", @"") text:NSLocalizedString(@"The details you have provided do not match our records ...", @"")];
            
            [self.inputCell resumeFirstResponder];
        }
    } else if (response.statusCode == kHTTPStatusNotFound) {
        [self examineMember];
    }
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
                    [self reflectMember:_member];
                }
            }
            
            break;
            
        case kActionSheetTagGuardianAddressYesNo:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                if (buttonTag == kButtonTagYes) {
                    [_cachedResidences[0] addMember:_member];
                    [self.dismisser dismissModalViewController:self];
                }
            } else {
                [self.inputCell resumeFirstResponder];
            }
            
            break;
            
        case kActionSheetTagGuardianAddress:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                [_cachedResidences[buttonIndex] addMember:_member];
                [self.dismisser dismissModalViewController:self];
            } else {
                [self.inputCell resumeFirstResponder];
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
                _cachedResidences = [_member housemateResidences];
                
                if ([_cachedResidences count]) {
                    [self presentHousemateResidencesSheet];
                } else {
                    [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:kOrigoTypeResidence];
                }
            }
            
            break;
            
        case kActionSheetTagResidence:
            if (buttonTag == kButtonTagResidenceNewAddress) {
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:kOrigoTypeResidence];
            } else if (buttonIndex != actionSheet.cancelButtonIndex) {
                [_cachedResidences[buttonIndex] addMember:_member];
                [self reloadSections];
            }
            
            break;
            
        case kActionSheetTagSource:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                if (buttonTag == kButtonTagSourceAddressBook) {
                    [self pickFromAddressBook];
                } else if (buttonTag == kButtonTagSourceOrigo) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:self.target meta:_origo];
                }
            } else {
                [self.inputCell resumeFirstResponder];
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
            
        case kActionSheetTagGuardianAddressYesNo:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                if (buttonTag != kButtonTagYes) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:[_member residence]];
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
        
        case kAlertTagUnknownChild:
            if (buttonIndex == kButtonTagOK) {
                [self examineMember];
            } else {
                [self.inputCell resumeFirstResponder];
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
    
    if (![_mobilePhoneField hasMultiValue] && ![_emailField hasMultiValue]) {
        [self performLocalLookup];
    }
    
    if ([_member instance]) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    } else {
        [self retrieveAddressesFromAddressBookPersonRecord:person];
        
        if ([_mobilePhoneField hasMultiValue] || [_emailField hasMultiValue]) {
            [self dismissViewControllerAnimated:YES completion:^{
                [self refineAddressBookContactInfo];
            }];
        } else {
            if ([_addressBookAddresses count] || [_addressBookHomeNumbers count]) {
                [self dismissViewControllerAnimated:YES completion:^{
                    [self refineAddressBookAddressInfo];
                }];
            } else {
                [self reflectMember:_member];
                [self dismissViewControllerAnimated:YES completion:NULL];
            }
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
        [self.inputCell resumeFirstResponder];
    }];
}

@end
