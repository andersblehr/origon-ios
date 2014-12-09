//
//  OMemberViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OMemberViewController.h"

static NSInteger const kSectionKeyRoles = 1;
static NSInteger const kSectionKeyGuardians = 2;
static NSInteger const kSectionKeyAddresses = 3;

static NSInteger const kActionSheetTagEdit = 0;
static NSInteger const kButtonTagEdit = 0;
static NSInteger const kButtonTagEditAddAddress = 1;
static NSInteger const kButtonTagEditAddGuardian = 2;

static NSInteger const kActionSheetTagResidence = 1;
static NSInteger const kButtonTagResidenceNewAddress = 10;

static NSInteger const kActionSheetTagCoHabitants = 2;
static NSInteger const kButtonTagCoHabitantsAll = 0;
static NSInteger const kButtonTagCoHabitantsMinors = 1;
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

static NSInteger const kAlertTagEmailChange = 2;
static NSInteger const kButtonIndexContinue = 1;


@interface OMemberViewController () <OTableViewController, OInputCellDelegate, OMemberExaminerDelegate, OConnectionDelegate, UIActionSheetDelegate, UIAlertViewDelegate, ABPeoplePickerNavigationControllerDelegate> {
@private
    id<OMember> _member;
    id<OOrigo> _origo;
    id<OMembership> _membership;
    id<OMembership> _roleMembership;
    
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
    OTableViewCell *_roleCell;
    
    BOOL _didPerformLocalLookup;
}

@end


@implementation OMemberViewController

#pragma mark - Auxiliary methods

- (NSString *)nameKey
{
    return [self targetIs:kTargetJuvenile] ? kPropertyKeyName : kMappedKeyFullName;
}


- (void)cancelEditingListCellIfNeeded
{
    if (_roleCell && !_roleCell.selectable) {
        OInputField *roleField = [_roleCell editableListCellField];
        [roleField resignFirstResponder];
        roleField.editable = NO;
        roleField.value = _role;
        
        _roleCell.selectable = YES;
    }
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


- (void)registerNewResidence
{
    id<OOrigo> primaryResidence = [_member primaryResidence];
    NSInteger numberOfCoHabitants = [[primaryResidence residents] count];
    NSInteger numberOfResidences = [[_member residences] count];
    
    if ([primaryResidence hasAddress] && numberOfResidences == 1 && numberOfCoHabitants > 1) {
        [self presentCoHabitantsSheet];
    } else if (![primaryResidence hasAddress]) {
        if ([[primaryResidence elders] count] == 1) {
            [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:primaryResidence];
        } else {
            [self presentCoHabitantsSheet];
        }
    } else {
        [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:kOrigoTypeResidence];
    }
}


#pragma mark - Input validation

- (BOOL)reflectIfEligibleMember:(id<OMember>)member
{
    BOOL isEligible = ![_origo hasMember:member] || ([_origo isJuvenile] && ![_member isJuvenile]);
    
    if (isEligible) {
        [self reflectMember:member];
    } else {
        [_nameField becomeFirstResponder];
        
        [OAlert showAlertWithTitle:@"" text:[NSString stringWithFormat:NSLocalizedString(@"%@ is already in %@.", @""), [member givenName], _origo.name]];
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
                    [OAlert showAlertWithTitle:@"" text:[NSString stringWithFormat:NSLocalizedString(@"The email address %@ is already in use.", @""), identifierField.value]];
                } else {
                    [OAlert showAlertWithTitle:@"" text:[NSString stringWithFormat:NSLocalizedString(@"The mobile number %@ is already in use.", @""), identifierField.value]];
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
    
    if ([member instance] || member != _member) {
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
            if (!member && ward != _member) {
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
        [OAlert showAlertWithTitle:NSLocalizedString(@"Unknown child", @"") text:[NSString stringWithFormat:NSLocalizedString(@"No child named %@ has been registered by %@.", @""), _nameField.value, [OUtil commaSeparatedListOfMembers:activeGuardians conjoin:YES subjective:YES]]];
        
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
                    _cachedResidences = [ward addresses];
                    
                    [self presentGuardianCoHabitantsSheet];
                } else {
                    [[ward primaryResidence] addMember:_member];
                    [self.dismisser dismissModalViewController:self];
                }
            } else if (![_member hasAddress] && [_member isManagedByUser]) {
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:[_member primaryResidence]];
            } else {
                [self.dismisser dismissModalViewController:self];
            }
        } else {
            _membership = [_origo addMember:_member];
            
            if (_role) {
                [_membership addAffiliation:_role ofType:kAffiliationTypeOrganiserRole];
            }
            
            BOOL needsRegisterPrimaryResidence = ![_member hasAddress];
            
            if ([self targetIs:kTargetOrganiser] || ([_member isJuvenile] && ![_member isUser])) {
                needsRegisterPrimaryResidence = NO;
            }
            
            if (needsRegisterPrimaryResidence) {
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:[_member primaryResidence]];
            } else {
                if ([_member isUser] && ![_member isActive]) {
                    [_member makeActive];
                } else if ([_member isWardOfUser]) {
                    [_member defaultFriendList];
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
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Other address", @"") tag:kButtonTagResidenceNewAddress];
    
    [actionSheet show];
}


- (void)presentCoHabitantsSheet
{
    _cachedCandidates = [OUtil sortedGroupsOfResidents:[[_member primaryResidence] residents] excluding:_member];
    
    OActionSheet *actionSheet = nil;
    
    if ([_cachedCandidates count] == 1) {
        actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:NSLocalizedString(@"Should %@ also be registered at this address?", @""), [OUtil commaSeparatedListOfMembers:_cachedCandidates[kButtonTagCoHabitantsAll] conjoin:YES subjective:YES]] delegate:self tag:kActionSheetTagCoHabitants];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Yes", @"") tag:kButtonTagCoHabitantsAll];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"No", @"") tag:kButtonTagCoHabitantsNone];
    } else {
        actionSheet = [[OActionSheet alloc] initWithPrompt:NSLocalizedString(@"Who else should be registered at this address?", @"") delegate:self tag:kActionSheetTagCoHabitants];
        [actionSheet addButtonWithTitle:[[OUtil commaSeparatedListOfMembers:_cachedCandidates[kButtonTagCoHabitantsAll] conjoin:YES subjective:YES] stringByCapitalisingFirstLetter] tag:kButtonTagCoHabitantsAll];
        [actionSheet addButtonWithTitle:[[OUtil commaSeparatedListOfMembers:_cachedCandidates[kButtonTagCoHabitantsMinors] conjoin:YES subjective:YES] stringByCapitalisingFirstLetter] tag:kButtonTagCoHabitantsMinors];
        
        if ([_member hasAddress]) {
            if ([_cachedCandidates[kButtonTagCoHabitantsAll] containsObject:[OMeta m].user]) {
                [actionSheet addButtonWithTitle:NSLocalizedString(@"None of you", @"") tag:kButtonTagCoHabitantsNone];
            } else {
                [actionSheet addButtonWithTitle:NSLocalizedString(@"None of them", @"") tag:kButtonTagCoHabitantsNone];
            }
        }
    }
    
    [actionSheet show];
}


- (void)presentGuardianCoHabitantsSheet
{
    OActionSheet *actionSheet = nil;
    
    if ([_cachedResidences count] == 1) {
        NSString *guardians = [OUtil commaSeparatedListOfMembers:[_cachedResidences[0] elders] conjoin:YES subjective:YES];
        
        actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:NSLocalizedString(@"Does %@ live with %@?", @""), [_member givenName], guardians] delegate:self tag:kActionSheetTagGuardianAddressYesNo];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Yes", @"")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"No", @"")];
    } else {
        NSString *guardians1 = [OUtil commaSeparatedListOfMembers:[_cachedResidences[0] elders] conjoin:YES subjective:YES];
        NSString *guardians2 = [OUtil commaSeparatedListOfMembers:[_cachedResidences[1] elders] conjoin:YES subjective:YES];
        
        actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:NSLocalizedString(@"Does %@ live with %@ or %@?", @""), [_member givenName], guardians1, guardians2] delegate:self tag:kActionSheetTagGuardianAddress];
        [actionSheet addButtonWithTitle:guardians1];
        [actionSheet addButtonWithTitle:guardians2];
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
        id<OOrigo> primaryResidence = [_member primaryResidence];
        
        if ([primaryResidence hasAddress]) {
            prompt = [NSString stringWithFormat:NSLocalizedString(@"%@ has more than one home phone number. Which number is valid for %@?", @""), givenName, [primaryResidence shortAddress]];
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
            if ([_addressBookHomeNumbers count] == 1 && [_addressBookMappings count] == 1) {
                prompt = [NSString stringWithFormat:NSLocalizedString(@"Is %@ the phone number for %@?", @""), _addressBookHomeNumbers[0], [_addressBookMappings[0] shortAddress]];
            } else {
                prompt = [NSString stringWithFormat:NSLocalizedString(@"Which address has the number %@?", @""), _addressBookHomeNumbers[0]];
            }
        }
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagAddressBookEntry];
    
    if ([_addressBookHomeNumbers count] == 1 && [_addressBookMappings count] == 1) {
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
    
    NSString *name = firstName;
    
    if (middleName) {
        name = name ? [name stringByAppendingString:middleName separator:kSeparatorSpace] : middleName;
    }
    
    if (lastName) {
        name = name ? [name stringByAppendingString:lastName separator:kSeparatorSpace] : lastName;
    }
    
    _nameField.value = name;
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
            
            if ([[_member residences] count] == 1 && [_addressBookHomeNumbers count] == 1) {
                [_member primaryResidence].telephone = _addressBookHomeNumbers[0];
                [_addressBookHomeNumbers removeAllObjects];
            }
        }
    }
}


#pragma mark - Selector implementations

- (void)toggleFavouriteStatus
{
    BOOL isFavourite = [_member isFavourite];
    id<OOrigo> stash = [[OMeta m].user stash];
    
    if (isFavourite) {
        [[stash membershipForMember:_member] expire];
    } else {
        [stash addMember:_member];
    }
    
    isFavourite = !isFavourite;
    
    NSMutableArray *rightBarButtonItems = [self.navigationItem.rightBarButtonItems mutableCopy];
    NSInteger toggleIndex = [rightBarButtonItems indexOfObject:[self.navigationItem rightBarButtonItemWithTag:kBarButtonTagFavourite]];
    
    [rightBarButtonItems replaceObjectAtIndex:toggleIndex withObject:[UIBarButtonItem favouriteButtonWithTarget:self isFavourite:isFavourite]];
    
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
}


- (void)performEditAction
{
    [self cancelEditingListCellIfNeeded];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagEdit];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit", @"") tag:kButtonTagEdit];
    
    if (![_member isJuvenile] || [_member isWardOfUser]) {
        if ([_member hasAddress]) {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Register an address", @"") tag:kButtonTagEditAddAddress];
        } else {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Register address", @"") tag:kButtonTagEditAddAddress];
        }
    } else {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Register guardian", @"") tag:kButtonTagEditAddGuardian];
    }
    
    [actionSheet show];
}


- (void)performInfoAction
{
    [self cancelEditingListCellIfNeeded];
    [self presentModalViewControllerWithIdentifier:kIdentifierInfo target:_member];
}


- (void)performLookupAction
{
    [self.view endEditing:YES];
    
    _cachedCandidates = [self.state eligibleCandidates];

    if ([_cachedCandidates count]) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagSource];
        
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Retrieve from Contacts", @"") tag:kButtonTagSourceAddressBook];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Retrieve from other list", @"") tag:kButtonTagSourceGroups];
        
        [actionSheet show];
    } else {
        [self pickFromAddressBook];
    }
}


- (void)performAddAction
{
    [self cancelEditingListCellIfNeeded];
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
    
    if (!_origo && [_member isUser]) {
        _origo = [_member primaryResidence];
    }
    
    _membership = [_origo membershipForMember:_member];
    _roleMembership = self.state.baseOrigo ? [self.state.baseOrigo membershipForMember:_member] : _membership;
    
    if ([self actionIs:kActionRegister]) {
        if ([self targetIs:kTargetUser]) {
            self.title = NSLocalizedString(@"About you", @"");
        } else if ([self targetIs:kTargetGuardian]) {
            self.title = [[OLanguage nouns][_guardian_][singularIndefinite] capitalizedString];
        } else if ([self targetIs:kTargetOrganiser]) {
            [self editableTitle:nil withPlaceholder:NSLocalizedString(_origo.type, kStringPrefixOrganiserRoleTitle)];
        } else if ([_origo isOfType:kOrigoTypeList]) {
            if ([_member isJuvenile]) {
                self.title = NSLocalizedString(@"New friend", @"");
            } else {
                self.title = NSLocalizedString(@"New contact", @"");
            }
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
        
        if (![_member isUser] && ([_member.mobilePhone hasValue] || [_member.email hasValue])) {
            if (![_member isJuvenile] || [_member isWardOfUser] || [[OMeta m].user isJuvenile]) {
                [self.navigationItem addRightBarButtonItem:[UIBarButtonItem favouriteButtonWithTarget:self isFavourite:[_member isFavourite]]];
            }
        }
        
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
        [self setData:[_roleMembership roles] forSectionWithKey:kSectionKeyRoles];
    }
}


- (void)loadListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyGuardians) {
        id<OMember> guardian = [self dataAtIndexPath:indexPath];
        
        [cell loadMember:guardian inOrigo:_origo excludeRoles:NO excludeRelations:YES];
        
        if ([_member hasParent:guardian] && ![_member guardiansAreParents]) {
            NSString *parentLabel = [guardian parentNoun][singularIndefinite];
            
            if (cell.detailTextLabel.text) {
                cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", cell.textLabel.text, parentLabel];
            } else {
                cell.detailTextLabel.text = [parentLabel stringByCapitalisingFirstLetter];
                cell.detailTextLabel.textColor = [UIColor tonedDownTextColour];
            }
        }
        
        cell.destinationId = kIdentifierMember;
    } else if (sectionKey == kSectionKeyAddresses) {
        id<OOrigo> residence = [self dataAtIndexPath:indexPath];
        
        [cell loadImageForOrigo:residence];
        cell.textLabel.text = [residence shortAddress];
        
        if ([_member isJuvenile] && [[_member residences] count] > 1) {
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfMembers:[residence elders] conjoin:NO];
            cell.detailTextLabel.textColor = [UIColor tonedDownTextColour];
        }
        
        [cell setDestinationId:kIdentifierOrigo selectableDuringInput:![self targetIs:kTargetJuvenile]];
    } else if (sectionKey == kSectionKeyRoles) {
        if ([_origo userCanEdit]) {
            OInputField *roleField = [cell editableListCellField];
            roleField.placeholder = NSLocalizedString(@"Responsibility", @"");
            roleField.value = [self dataAtIndexPath:indexPath];
            
            cell.selectable = YES;
        } else {
            cell.textLabel.text = [self dataAtIndexPath:indexPath];
            cell.selectable = NO;
        }
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
        if ([_member isJuvenile]) {
            hasFooter = sectionKey == kSectionKeyGuardians;
        } else {
            hasFooter = [self isBottomSectionKey:sectionKey];
        }
    }
    
    return hasFooter;
}


- (id)headerContentForSectionWithKey:(NSInteger)sectionKey
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
        } else if ([_member guardiansAreParents]) {
            text = [OLanguage nouns][_parent_][pluralIndefinite];
        } else {
            text = [OLanguage nouns][_guardian_][pluralIndefinite];
        }
    } else if (sectionKey == kSectionKeyAddresses) {
        NSInteger numberOfAddresses = [[_member addresses] count];
        
        if (numberOfAddresses == 1) {
            text = [OLanguage nouns][_address_][singularIndefinite];
        } else if (numberOfAddresses > 1) {
            text = [OLanguage nouns][_address_][pluralIndefinite];
        }
    } else if (sectionKey == kSectionKeyRoles) {
        if ([[[_origo membershipForMember:_member] roles] count] == 1) {
            text = [NSString stringWithFormat:NSLocalizedString(@"Responsibility in %@", @""), _roleMembership.origo.name];
        } else {
            text = [NSString stringWithFormat:NSLocalizedString(@"Responsibilities in %@", @""), _roleMembership.origo.name];
        }
    }
    
    return [text stringByCapitalisingFirstLetter];
}


- (NSString *)footerContentForSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if ([self actionIs:kActionRegister] && ![_member isUser]) {
        text = NSLocalizedString(@"A notification will be sent to the email address you provide.", @"");
        
        if ([_member isJuvenile]) {
            text = NSLocalizedString(@"Tap + to register additional guardians.", @"");
        } else {
            id ancestor = [self.entity ancestor];
            
            if ([ancestor conformsToProtocol:@protocol(OMember)] && ![[ancestor guardians] count]) {
                text = [NSLocalizedString(@"Before you can register a minor, you must register his or her guardians.", @"") stringByAppendingString:text separator:kSeparatorSpace];
            }
        }
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
        NSString *address1 = [[guardian1 primaryResidence] shortAddress];
        NSString *address2 = [[guardian2 primaryResidence] shortAddress];
        
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
    [self cancelEditingListCellIfNeeded];
    
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyRoles) {
        _role = [self dataAtIndexPath:indexPath];
        _roleCell = cell;
        
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil delegate:self tag:kActionSheetTagEditRole];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Edit responsibility", @"")];
        [actionSheet show];
    }
}


- (BOOL)canDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL canDelete = NO;
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyRoles) {
        canDelete = [self.state.baseOrigo userCanEdit];
    } else if (sectionKey == kSectionKeyAddresses) {
        canDelete = [self numberOfRowsInSectionWithKey:sectionKey] > 1;
    }
    
    return canDelete;
}


- (void)willDeleteCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sectionKey = [self sectionKeyForIndexPath:indexPath];
    
    if (sectionKey == kSectionKeyRoles) {
        id<OMembership> roleMembership = [self.state.baseOrigo membershipForMember:_member];
        NSString *role = [self dataAtIndexPath:indexPath];
        NSString *roleType = [roleMembership typeOfAffiliation:role];
        
        [roleMembership removeAffiliation:role ofType:roleType];
    } else if (sectionKey == kSectionKeyAddresses) {
        [[[self dataAtIndexPath:indexPath] membershipForMember:_member] expire];
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


- (void)didFinishEditingViewTitleField:(UITextField *)viewTitleField
{
    _role = viewTitleField.text;
}


- (BOOL)isEditableListCellAtIndexPath:(NSIndexPath *)indexPath
{
    return [self sectionKeyForIndexPath:indexPath] == kSectionKeyRoles && [_origo userCanEdit];
}


- (void)didFinishEditingListCellField:(OInputField *)listCellField
{
    NSString *editedRole = listCellField.value;
    
    if (![editedRole isEqualToString:_role]) {
        NSString *roleType = [_roleMembership typeOfAffiliation:_role];
        
        [_roleMembership addAffiliation:editedRole ofType:roleType];
        [_roleMembership removeAffiliation:_role ofType:roleType];
        
        _role = editedRole;
    }
    
    [listCellField resignFirstResponder];
    listCellField.editable = NO;
    
    _roleCell.selectable = YES;
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
        } else if ([_member isUser] || !(_emailField.value || _mobilePhoneField.value)) {
            if ([_member isReplicated]) {
                [self persistMember];
            } else {
                [self examineMember];
            }
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
        isEditable = ![self actionIs:kActionRegister] || ![self targetIs:kTargetUser];
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
                            [_member primaryResidence].telephone = selectedNumber;
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
            
        case kActionSheetTagGuardianAddress:
        case kActionSheetTagGuardianAddressYesNo:
            if (buttonIndex == actionSheet.cancelButtonIndex) {
                [self.inputCell resumeFirstResponder];
            }
            
            break;
            
        case kActionSheetTagEditRole:
            _roleCell.selected = NO;
            
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                _roleCell.selectable = NO;
                
                OInputField *roleField = [_roleCell editableListCellField];
                roleField.editable = YES;
                [roleField becomeFirstResponder];
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
        case kActionSheetTagEdit:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                if (buttonTag == kButtonTagEditAddAddress) {
                    _cachedResidences = [_member housemateResidences];
                    
                    if ([_cachedResidences count]) {
                        [self presentHousemateResidencesSheet];
                    } else {
                        [self registerNewResidence];
                    }
                } else if (buttonTag == kButtonTagEditAddGuardian) {
                    [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetGuardian];
                }
            }
            
            break;
            
        case kActionSheetTagResidence:
            if (buttonTag == kButtonTagResidenceNewAddress) {
                [self registerNewResidence];
            } else if (buttonIndex != actionSheet.cancelButtonIndex) {
                [_cachedResidences[buttonIndex] addMember:_member];
                [self reloadSections];
            }
            
            break;
            
        case kActionSheetTagCoHabitants:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                id<OOrigo> primaryResidence = [_member primaryResidence];
                
                if ([primaryResidence hasAddress] || buttonTag != kButtonTagCoHabitantsAll) {
                    NSArray *coHabitants = nil;
                    
                    if ([primaryResidence hasAddress]) {
                        if (buttonTag == kButtonTagCoHabitantsAll) {
                            coHabitants = [primaryResidence residents];
                        } else if (buttonTag == kButtonTagCoHabitantsMinors) {
                            coHabitants = [primaryResidence minors];
                        }
                    } else if (buttonTag == kButtonTagCoHabitantsMinors) {
                        coHabitants = [primaryResidence minors];
                        
                        if (![primaryResidence hasAddress]) {
                            [[[primaryResidence membershipForMember:_member] proxy] expire];
                        }
                    }
                    
                    primaryResidence = [OOrigoProxy proxyWithType:kOrigoTypeResidence];
                    [primaryResidence addMember:_member];
                    
                    for (id<OMember> coHabitant in coHabitants) {
                        [primaryResidence addMember:coHabitant];
                    }
                }
                
                [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:primaryResidence];
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
            if (buttonIndex != actionSheet.cancelButtonIndex && ![_member instance]) {
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
                if (buttonTag == kButtonTagGuardianAddressYes) {
                    [_cachedResidences[0] addMember:_member];
                    [self.dismisser dismissModalViewController:self];
                } else {
                    [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:[_member primaryResidence]];
                }
            }
            
            break;
            
        case kActionSheetTagGuardianAddress:
            if (buttonIndex != actionSheet.cancelButtonIndex) {
                [_cachedResidences[buttonIndex] addMember:_member];
                [self.dismisser dismissModalViewController:self];
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
            if (buttonIndex == kButtonIndexContinue) {
                [self toggleEditMode];
            }
            
            break;
        
        default:
            break;
    }
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kAlertTagEmailChange:
            if (buttonIndex == kButtonIndexContinue) {
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
