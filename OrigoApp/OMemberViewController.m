//
//  OMemberViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OMemberViewController.h"

static NSInteger const kSectionKeyMember = 0;
static NSInteger const kSectionKeyRoles = 1;
static NSInteger const kSectionKeyGuardians = 2;
static NSInteger const kSectionKeyAddresses = 3;

static NSInteger const kActionSheetTagEdit = 0;
static NSInteger const kButtonTagEditChangePassword = 0;
static NSInteger const kButtonTagEdit = 1;
static NSInteger const kButtonTagEditRelations = 2;
static NSInteger const kButtonTagEditAddAddress = 3;
static NSInteger const kButtonTagEditAddGuardian = 4;
static NSInteger const kButtonTagEditCorrectGender = 5;

static NSInteger const kActionSheetTagResidence = 1;
static NSInteger const kButtonTagResidenceNewAddress = 10;

static NSInteger const kActionSheetTagCoHabitants = 2;
static NSInteger const kButtonTagCoHabitantsAll = 0;
static NSInteger const kButtonTagCoHabitantsWards = 1;
static NSInteger const kButtonTagCoHabitantsNone = 2;

static NSInteger const kActionSheetTagSource = 3;
static NSInteger const kButtonTagSourceAddressBook = 0;
static NSInteger const kButtonTagSourceGroups = 1;

static NSInteger const kActionSheetTagAddressBookEntry = 4;
static NSInteger const kButtonTagAddressBookEntryAllValues = 10;
static NSInteger const kButtonTagAddressBookEntryNoValue = 11;

static NSInteger const kActionSheetTagGuardianAddressYesNo = 5;
static NSInteger const kButtonTagGuardianAddressYes = 0;

static NSInteger const kActionSheetTagGuardianAddress = 6;
static NSInteger const kActionSheetTagEditRole = 7;

static NSInteger const kAlertTagUnknownChild = 0;
static NSInteger const kButtonIndexOK = 1;

static NSInteger const kAlertTagToggleGender = 1;
static NSInteger const kButtonIndexYes = 1;

static NSInteger const kAlertTagEmailChange = 2;
static NSInteger const kButtonIndexContinue = 1;


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
    
    NSMutableDictionary *_cachedResidencesById;
    NSArray *_cachedResidences;
    NSArray *_cachedCandidates;
    NSString *_role;
    
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
    [self.inputCell clearInputFields];
    
    if ([self hasSectionWithKey:kSectionKeyAddresses]) {
        [self reloadSectionWithKey:kSectionKeyAddresses];
    }
    
    _didPerformLocalLookup = NO;
}


#pragma mark - Input validation

- (BOOL)reflectIfEligibleMember:(id<OMember>)member
{
    BOOL isEligible = ![_origo hasMember:member] || ([_origo isJuvenile] && ![_member isJuvenile]);
    
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
        inputMatches = [[OPhoneNumberFormatter formatterForNumber:_mobilePhoneField.value].flattenedNumber isEqualToString:[OPhoneNumberFormatter formatterForNumber:mobilePhone].flattenedNumber];
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
    id<OMember> coGuardian = [[NSSet setWithArray:[ward guardians]] anyObject];
    
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
        
        if (![self aspectIs:kAspectHousehold]) {
            [self endEditing];
        }
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
    
    NSArray *guardians = [_member guardians];
    NSMutableArray *inactiveGuardians = [NSMutableArray array];
    NSMutableArray *activeGuardians = [NSMutableArray array];
    NSMutableSet *activeResidences = [NSMutableSet set];
    NSMutableSet *allResidences = [NSMutableSet set];
    
    for (id<OMember> guardian in guardians) {
        NSArray *residences = [guardian residences];
        [allResidences addObjectsFromArray:residences];
        
        if ([guardian isActive]) {
            [activeGuardians addObject:guardian];
            [activeResidences addObjectsFromArray:residences];
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
    
    if (member) {
        for (id<OMembership> residency in [_member residencies]) {
            [residency expire];
        }
        
        if ([self reflectIfEligibleMember:member]) {
            [self persistMember];
        }
    } else if ([activeResidences count]) {
        [OAlert showAlertWithTitle:NSLocalizedString(@"Unknown child", @"") text:[NSString stringWithFormat:NSLocalizedString(@"No child named %@ has been registered by %@.", @""), _nameField.value, [OUtil commaSeparatedListOfItems:activeGuardians conjoinLastItem:YES]]];
        
        if ([allResidences count] > [activeResidences count]) {
            for (id<OOrigo> activeResidence in activeResidences) {
                [[activeResidence membershipForMember:_member] expire];
            }
            
            [self reloadSections];
        }
        
        [self.inputCell resumeFirstResponder];
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
            
            if ([[ward residences] count] && ![[_member residences] count]) {
                BOOL addingToResidence = [self.entity.ancestor conformsToProtocol:@protocol(OOrigo)];
                
                if ([ward hasAddress] && !addingToResidence) {
                    [self presentGuardianAddressSheetForWard:ward];
                } else {
                    [[ward residence] addMember:_member];
                    [self.dismisser dismissModalViewController:self];
                }
            } else if (![_member instance] && ![_member hasAddress]) {
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:[_member residence]];
            } else {
                [self.dismisser dismissModalViewController:self];
            }
        } else {
            _membership = [_origo addMember:_member];
            
            if (_role) {
                [_membership addAffiliation:_role ofType:kAffiliationTypeOrganiserRole];
            }
            
            BOOL needsRegisterResidence = ![_member hasAddress];
            
            if ([self targetIs:kTargetOrganiser] || ([_member isJuvenile] && ![_member isUser])) {
                needsRegisterResidence = NO;
            }
            
            if (needsRegisterResidence) {
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


#pragma mark - Action sheets

- (void)presentHousemateResidencesSheet
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagResidence];
    
    for (id<OOrigo> residence in _cachedResidences) {
        [actionSheet addButtonWithTitle:[residence shortAddress]];
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"New address", @"") tag:kButtonTagResidenceNewAddress];
    
    [actionSheet show];
}


- (void)presentCoHabitantsSheet
{
    id<OOrigo> residence = [_member residence];
    
    _cachedCandidates = [OUtil sortedGroupsOfResidents:[residence residents] excluding:_member];
    
    OActionSheet *actionSheet = nil;
    
    if ([_cachedCandidates count] == 1) {
        actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:NSLocalizedString(@"Should %@ be registered at the same address?", @""), [OUtil commaSeparatedListOfItems:_cachedCandidates[kButtonTagCoHabitantsAll] conjoinLastItem:YES]] delegate:self tag:kActionSheetTagCoHabitants];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Yes", @"") tag:kButtonTagCoHabitantsAll];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"No", @"") tag:kButtonTagCoHabitantsNone];
    } else {
        actionSheet = [[OActionSheet alloc] initWithPrompt:NSLocalizedString(@"Who else should be registered at the same address?", @"") delegate:self tag:kActionSheetTagCoHabitants];
        [actionSheet addButtonWithTitle:[OUtil commaSeparatedListOfItems:_cachedCandidates[kButtonTagCoHabitantsAll] conjoinLastItem:YES] tag:kButtonTagCoHabitantsAll];
        [actionSheet addButtonWithTitle:[OUtil commaSeparatedListOfItems:_cachedCandidates[kButtonTagCoHabitantsWards] conjoinLastItem:YES] tag:kButtonTagCoHabitantsWards];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"None of them", @"") tag:kButtonTagCoHabitantsNone];
    }
    
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


#pragma mark - Alerts

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


- (void)presentToggleGenderAlert
{
    NSString *message = nil;
    NSString *alternateGender = [OUtil genderTermForGender:[_member isMale] ? kGenderFemale : kGenderMale isJuvenile:[_member isJuvenile]];
    
    if ([_member isUser]) {
        message = [NSString stringWithFormat:NSLocalizedString(@"Are you a %@?", @""), alternateGender];
    } else {
        message = [NSString stringWithFormat:NSLocalizedString(@"Is %@ a %@?", @""), [_member givenName], alternateGender];
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:NSLocalizedString(@"No", @"") otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
    alert.tag = kAlertTagToggleGender;
    
    [alert show];
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
    [self resetInputState];
    
    ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
    peoplePicker.peoplePickerDelegate = self;
    
    [self presentViewController:peoplePicker animated:YES completion:NULL];
}


- (void)retrieveNameFromAddressBookPersonRecord:(ABRecordRef)person
{
    NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonFirstNameProperty);
    NSString *middleName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonMiddleNameProperty);
    NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
    
    NSString *fullName = [OMeta usesEasternNameOrder] ? lastName : firstName;
    
    if (fullName) {
        NSString *nextName = [OMeta usesEasternNameOrder] ? firstName : middleName;
        
        if (nextName) {
            fullName = [fullName stringByAppendingString:nextName separator:kSeparatorSpace];
        }
        
        nextName = [OMeta usesEasternNameOrder] ? middleName : lastName;
        
        if (nextName) {
            fullName = [fullName stringByAppendingString:nextName separator:kSeparatorSpace];
        }
    }
    
    _nameField.value = fullName;
    _member.name = _nameField.value;
}


- (void)retrievePhoneNumbersFromAddressBookPersonRecord:(ABRecordRef)person
{
    ABMultiValueRef multiValues = ABRecordCopyValue(person, kABPersonPhoneProperty);
    CFIndex multiValueCount = ABMultiValueGetCount(multiValues);
    
    if (multiValueCount) {
        _addressBookHomeNumbers = [NSMutableArray array];
        
        NSMutableArray *mobilePhoneNumbers = [NSMutableArray array];
        
        for (CFIndex i = 0; i < multiValueCount; i++) {
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
}


- (void)retrieveEmailAddressesFromAddressBookPersonRecord:(ABRecordRef)person
{
    ABMultiValueRef multiValues = ABRecordCopyValue(person, kABPersonEmailProperty);
    CFIndex multiValueCount = ABMultiValueGetCount(multiValues);
    
    if (multiValueCount) {
        NSMutableArray *emailAddresses = [NSMutableArray array];
        
        for (CFIndex i = 0; i < multiValueCount; i++) {
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
}


- (void)retrieveAddressesFromAddressBookPersonRecord:(ABRecordRef)person
{
    ABMultiValueRef multiValues = ABRecordCopyValue(person, kABPersonAddressProperty);
    CFIndex multiValueCount = ABMultiValueGetCount(multiValues);
    
    if (multiValueCount) {
        _addressBookAddresses = [NSMutableArray array];
        
        for (CFIndex i = 0; i < multiValueCount; i++) {
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
}


#pragma mark - Selector implementations

- (void)performEditAction
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagEdit];
    
    if ([_member isUser]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Change password", @"") tag:kButtonTagEditChangePassword];
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit", @"") tag:kButtonTagEdit];
    
    if ([_member isWardOfUser]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit relations", @"") tag:kButtonTagEditRelations];
    }
    
    if (![_member isJuvenile] || [_member isWardOfUser]) {
        if ([_member hasAddress]) {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Add an address", @"") tag:kButtonTagEditAddAddress];
        } else {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Register address", @"") tag:kButtonTagEditAddAddress];
        }
    } else {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Register guardian", @"") tag:kButtonTagEditAddGuardian];
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Correct gender", @"") tag:kButtonTagEditCorrectGender];
    
    [actionSheet show];
}


- (void)performInfoAction
{
    
}


- (void)performLookupAction
{
    [self.view endEditing:YES];
    
    _cachedCandidates = [self.state eligibleCandidates];

    if ([_cachedCandidates count]) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagSource];
        
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Retrieve from Contacts", @"") tag:kButtonTagSourceAddressBook];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Retrieve from other groups", @"") tag:kButtonTagSourceGroups];
        
        [actionSheet show];
    } else {
        [self pickFromAddressBook];
    }
}


- (void)performAddAction
{
    [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetGuardian];
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self actionIs:kActionRegister]) {
        if ([[_member guardians] count]) {
            [self reloadSections];
        }
        
        if (self.wasHidden) {
            [[self.inputCell nextInvalidInputField] becomeFirstResponder];
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    if ([self actionIs:kActionRegister] && [self targetIs:kTargetJuvenile]) {
        if ([[_member guardians] count]) {
            [_nameField becomeFirstResponder];
        } else if (!self.wasHidden) {
            [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetGuardian];
        }
    }
    
    [super viewDidAppear:animated];
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    _member = [self.entity proxy];
    _origo = self.state.currentOrigo;
    _membership = [_origo membershipForMember:_member];
    
    if ([self actionIs:kActionRegister]) {
        if ([self targetIs:kTargetUser]) {
            self.title = NSLocalizedString(@"About me", @"");
        } else if ([self targetIs:kTargetGuardian]) {
            self.title = [[OLanguage nouns][_guardian_][singularIndefinite] capitalizedString];
        } else if ([self targetIs:kTargetOrganiser]) {
            [self setEditableTitle:nil placeholder:NSLocalizedString(_origo.type, kStringPrefixOrganiserRoleTitle)];
        } else {
            self.title = NSLocalizedString(_origo.type, kStringPrefixNewMemberTitle);
        }
        
        if ([self targetIs:kTargetJuvenile]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
        } else if (![self targetIs:kTargetUser]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem lookupButtonWithTarget:self];
        }
    } else if ([self actionIs:kActionDisplay]) {
        self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:[_member givenName]];
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem infoButtonWithTarget:self];
        
        if ([_member isManagedByUser]) {
            [self.navigationItem addRightBarButtonItem:[UIBarButtonItem editButtonWithTarget:self]];
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
        [self setData:[_member addresses] forSectionWithKey:kSectionKeyAddresses];
        [self setData:[_membership roles] forSectionWithKey:kSectionKeyRoles];
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyGuardians) {
        id<OMember> guardian = [self dataAtIndexPath:indexPath];
        
        cell.textLabel.text = guardian.name;
        cell.destinationId = kIdentifierMember;
        [OUtil setImageForMember:guardian inTableViewCell:cell];
        
        NSString *details = nil;
        
        if ([[_member residences] count] > 1) {
            details = [[guardian residence] shortAddress];
        }
        
        if ([_member hasParent:guardian] && ![_member guardiansAreParents]) {
            if (details) {
                details = [[[guardian parentNoun][singularIndefinite] capitalizedString] stringByAppendingString:details separator:kSeparatorComma];
            } else {
                details = [[guardian parentNoun][singularIndefinite] capitalizedString];
            }
        }
        
        cell.detailTextLabel.text = details;
    } else if (sectionKey == kSectionKeyAddresses) {
        id<OOrigo> residence = [self dataAtIndexPath:indexPath];
        
        cell.imageView.image = [UIImage imageNamed:kIconFileHousehold];
        cell.textLabel.text = [residence shortAddress];
        cell.detailTextLabel.text = [[OPhoneNumberFormatter formatterForNumber:residence.telephone] completelyFormattedNumberCanonicalised:YES];
        
        [cell setDestinationId:kIdentifierOrigo selectableDuringInput:![self targetIs:kTargetJuvenile]];
    } else if (sectionKey == kSectionKeyRoles) {
        cell.textLabel.text = [self dataAtIndexPath:indexPath];
        cell.selectable = [_origo userCanEdit];
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
    
    if ([self actionIs:kActionRegister] && ![_member isUser]) {
        if ([self isBottomSectionKey:sectionKey]) {
            hasFooter = ![_member isJuvenile];
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
        NSArray *guardians = [_member guardians];
        
        if ([guardians count] == 1) {
            id<OMember> guardian = guardians[0];
            
            if ([_member hasParent:guardian]) {
                text = [guardian parentNoun][singularIndefinite];
            } else {
                text = [OLanguage nouns][_guardian_][singularIndefinite];
            }
        } else if ([guardians count] == 2) {
            text = [OLanguage nouns][_parent_][pluralIndefinite];
        } else {
            text = [OLanguage nouns][_guardian_][pluralIndefinite];
        }
    } else if (sectionKey == kSectionKeyAddresses) {
        if ([[_member residences] count] == 1) {
            text = [OLanguage nouns][_address_][singularIndefinite];
        } else if ([[_member residences] count] > 1) {
            text = [OLanguage nouns][_address_][pluralIndefinite];
        }
    } else if (sectionKey == kSectionKeyRoles) {
        if ([[[_origo membershipForMember:_member] roles] count] > 1) {
            text = [NSString stringWithFormat:NSLocalizedString(@"Responsibility in %@", @""), _origo.name];
        } else {
            text = [NSString stringWithFormat:NSLocalizedString(@"Responsibilities in %@", @""), _origo.name];
        }
    }
    
    return [text stringByCapitalisingFirstLetter];
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if ([self isBottomSectionKey:sectionKey]) {
        text = NSLocalizedString(@"A notification will be sent to the email address you provide.", @"");
        
        if ([self targetIs:kTargetGuardian]) {
            id<OEntity> ancestor = [self.entity ancestor];
            
            if ([ancestor conformsToProtocol:@protocol(OMember)] && ![ancestor isCommitted]) {
                text = [NSLocalizedString(@"Before you can register a minor, you must register his or her guardian(s).", @"") stringByAppendingString:text separator:kSeparatorSpace];
            }
        }
    } else if (sectionKey == kSectionKeyMember) {
        text = NSLocalizedString(@"Tap [+] to add another guardian.", @"");
    }
    
    return text;
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
        
        if (!address1 || !address2 || [address1 isEqualToString:address2]) {
            result = [guardian1.name localizedCaseInsensitiveCompare:guardian2.name];
        } else {
            result = [address1 localizedCaseInsensitiveCompare:address2];
        }
    }
    
    return result;
}


- (void)willDisplayInputCell:(OTableViewCell *)inputCell
{
    _nameField = [inputCell inputFieldForKey:[self nameKey]];
    _dateOfBirthField = [inputCell inputFieldForKey:kPropertyKeyDateOfBirth];
    _mobilePhoneField = [inputCell inputFieldForKey:kPropertyKeyMobilePhone];
    _emailField = [inputCell inputFieldForKey:kPropertyKeyEmail];
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyRoles) {
        _role = [self dataAtIndexPath:indexPath];
        
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagEditRole];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit responsibility", @"")];
        [actionSheet show];
    }
}


- (BOOL)canDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDelete = NO;
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyAddresses) {
        canDelete = [self numberOfRowsInSectionWithKey:sectionKey] > 1;
    }
    
    return canDelete;
}


- (void)willDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyAddresses) {
        if ([_origo isOfType:kOrigoTypeResidence]) {
            [[_origo membershipForMember:_member] expire];
        }
    }
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
    } else if ([viewController.identifier isEqualToString:kIdentifierValuePicker]) {
        if (!viewController.didCancel && [viewController.returnData instance]) {
            self.returnData = viewController.returnData;
            shouldRelay = YES;
        }
    }
    
    return shouldRelay;
}


- (void)willDismissModalViewController:(OTableViewController *)viewController
{
    if ([viewController.identifier isEqualToString:kIdentifierAuth]) {
        if ([_member.email isEqualToString:_emailField.value]) {
            [self persistMember];
        } else {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Activation failed", @"") message:[NSString stringWithFormat:NSLocalizedString(@"The email address %@ could not be activated ...", @""), _emailField.value] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil] show];
            
            self.nextInputField = _emailField;
            [self toggleEditMode];
        }
    } else if ([viewController.identifier isEqualToString:kIdentifierMember]) {
        if (!viewController.didCancel && [self targetIs:kTargetJuvenile]) {
            for (id<OOrigo> residence in [viewController.returnData residences]) {
                [residence addMember:_member];
            }
        }
    } else if ([viewController.identifier isEqualToString:kIdentifierValuePicker]) {
        if (!viewController.didCancel) {
            if ([viewController targetIs:kTargetMember]) {
                [self reflectMember:viewController.returnData];
            } else if ([viewController targetIs:kTargetRole]) {
                if (_role && ![viewController.title isEqualToString:_role]) {
                    _role = viewController.title;
                    
                    OTableViewController *precedingViewController = [self precedingViewController];
                    
                    if ([precedingViewController targetIs:kTargetRole]) {
                        precedingViewController.target = _role;
                        precedingViewController.title = _role;
                    }
                    
                    [self reloadSectionWithKey:kSectionKeyRoles];
                }
            }
        }
    }
}


- (void)didDismissModalViewController:(OTableViewController *)viewController
{
    if ([viewController.identifier isEqualToString:kIdentifierValuePicker]) {
        if ([viewController targetIs:kTargetMember] && !viewController.didCancel) {
            if ([self reflectIfEligibleMember:viewController.returnData]) {
                if ([self aspectIs:kAspectHousehold]) {
                    [[self.inputCell nextInvalidInputField] becomeFirstResponder];
                } else {
                    [self endEditing];
                }
            }
        }
    }
}


- (void)maySetViewTitle:(NSString *)newTitle
{
    if (newTitle) {
        _role = newTitle;
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
    BOOL isValid = YES;
    
    if ([self targetIs:kTargetUser]) {
        isValid = isValid && [_nameField hasValidValue];
        isValid = isValid && [_mobilePhoneField hasValidValue];
        isValid = isValid && [self identifierFieldHasUniqueValue:_emailField];
    } else {
        if ([self targetIs:kTargetJuvenile]) {
            isValid = [_nameField.value hasValue];
        } else {
            isValid = [_nameField hasValidValue];
        }
        
        if (isValid && [self aspectIs:kAspectHousehold]) {
            isValid = [_dateOfBirthField hasValidValue];
            
            if ([_member instance]) {
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
        
        if (isValid && [self actionIs:kActionRegister]) {
            [self performLocalLookup];
        }
    }
    
    return isValid;
}


- (void)processInput
{
    if ([self actionIs:kActionRegister]) {
        if ([self targetIs:kTargetJuvenile]) {
            [self examineJuvenile];
        } else if ([_member isUser]) {
            [self examineMember];
        } else if ([_member instance]) {
            if ([_origo isOfType:kOrigoTypeResidence]) {
                [self examineMember];
            } else {
                [self persistMember];
            }
        } else {
            [[OConnection connectionWithDelegate:self] lookupMemberWithIdentifier:_emailField.value ? _emailField.value : _mobilePhoneField.value];
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
    return [_member.gender hasValue] && (!self.entity.ancestor || [self.entity.ancestor isCommitted]);
}


- (void)didCommitEntity:(id)entity
{
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
        case kActionSheetTagEdit:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                if (buttonTag == kButtonTagEdit) {
                    [self scrollToTopAndToggleEditMode];
                }
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
                if (buttonTag == kButtonTagGuardianAddressYes) {
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
            
        case kActionSheetTagEditRole:
            [self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]].selected = NO;
            
            break;
            
        default:
            break;
    }
}


- (void)actionSheet:(OActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
    
    switch (actionSheet.tag) {
        case kActionSheetTagEdit:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                if (buttonTag == kButtonTagEditAddAddress) {
                    _cachedResidences = [_member housemateResidences];
                    
                    if ([_cachedResidences count]) {
                        [self presentHousemateResidencesSheet];
                    } else if (![_member hasAddress]) {
                        if ([[_member housemates] count]) {
                            [self presentCoHabitantsSheet];
                        } else {
                            [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:[_member residence]];
                        }
                    } else {
                        [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:kOrigoTypeResidence];
                    }
                } else if (buttonTag == kButtonTagEditAddGuardian) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetGuardian];
                } else if (buttonTag == kButtonTagEditCorrectGender) {
                    [self presentToggleGenderAlert];
                }
            }
            
            break;
            
        case kActionSheetTagResidence:
            if (buttonTag == kButtonTagResidenceNewAddress) {
                if ([_member hasAddress]) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:kOrigoTypeResidence];
                } else {
                    [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:[_member residence]];
                }
            } else if (buttonIndex != actionSheet.cancelButtonIndex) {
                [_cachedResidences[buttonIndex] addMember:_member];
                [self reloadSections];
            }
            
            break;
            
        case kActionSheetTagCoHabitants:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                id<OOrigo> residence = [_member residence];
                
                if (buttonTag != kButtonTagCoHabitantsAll) {
                    residence = [OOrigoProxy proxyWithType:kOrigoTypeResidence];
                    [residence addMember:_member];
                    
                    if (buttonTag == kButtonTagCoHabitantsWards) {
                        for (id<OMember> ward in [_member wards]) {
                            [residence addMember:ward];
                        }
                    }
                }
                
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:residence];
            }
            
            break;
            
        case kActionSheetTagSource:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                if (buttonTag == kButtonTagSourceAddressBook) {
                    [self pickFromAddressBook];
                } else if (buttonTag == kButtonTagSourceGroups) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:kTargetMember meta:_cachedCandidates];
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
                if (buttonTag != kButtonTagGuardianAddressYes) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:[_member residence]];
                }
            }
            
            break;
        
        case kActionSheetTagEditRole:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                NSString *roleType = [[_origo membershipForMember:_member] typeOfAffiliation:_role];
                NSString *aspect = nil;
                
                if ([roleType isEqualToString:kAffiliationTypeMemberRole]) {
                    aspect = kAspectMemberRole;
                } else if ([roleType isEqualToString:kAffiliationTypeOrganiserRole]) {
                    aspect = kAspectOrganiserRole;
                } else if ([roleType isEqualToString:kAffiliationTypeParentRole]) {
                    aspect = kAspectParentRole;
                }
                
                [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:@{_role: aspect}];
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
        case kAlertTagToggleGender:
            if (buttonIndex == kButtonIndexYes) {
                _member.gender = [_member isMale] ? kGenderFemale : kGenderMale;
                
                NSString *message = nil;
                NSString *gender = [OUtil genderTermForGender:_member.gender isJuvenile:[_member isJuvenile]];
                
                if ([_member isUser]) {
                    message = [NSString stringWithFormat:NSLocalizedString(@"You are now registered as a %@.", @""), gender];
                } else {
                    message = [NSString stringWithFormat:NSLocalizedString(@"%@ is now registered as a %@.", @""), [_member givenName], gender];
                }
                
                [OAlert showAlertWithTitle:nil text:message];
            }
            
            break;
            
        case kAlertTagEmailChange:
            if (buttonIndex == kButtonIndexContinue) {
                [self toggleEditMode];
                [self presentModalViewControllerWithIdentifier:kIdentifierAuth target:_emailField.value];
            } else {
                [_emailField becomeFirstResponder];
            }
            
            break;
        
        case kAlertTagUnknownChild:
            if (buttonIndex == kButtonIndexOK) {
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

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person
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
}


- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.inputCell resumeFirstResponder];
    }];
}


#pragma mark - ABPeoplePickerNavigationControllerDelegate conformance (iOS 7.x)

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    [self peoplePickerNavigationController:peoplePicker didSelectPerson:person];
    
    return NO;
}

@end
