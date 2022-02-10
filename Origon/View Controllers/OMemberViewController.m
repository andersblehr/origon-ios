//
//  OMemberViewController.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OMemberViewController.h"

static NSInteger const kSectionKeyRoles = 1;
static NSInteger const kSectionKeyGuardians = 2;
static NSInteger const kSectionKeyAddresses = 3;

static CGFloat const kPopUpAlpha = 0.9f;
static CGFloat const kPopUpCornerRadius = 5.f;


@interface OMemberViewController () <OTableViewController, OInputCellDelegate, OMemberExaminerDelegate, CNContactPickerDelegate> {
@private
    id<OMember> _member;
    id<OOrigo> _origo;
    id<OMembership> _membership;
    id<OMembership> _roleMembership;
    
    OInputField *_nameField;
    OInputField *_dateOfBirthField;
    OInputField *_mobilePhoneField;
    OInputField *_emailField;

    NSMutableArray *_contactAddresses;
    NSMutableArray *_contactHomeNumbers;
    NSInteger _contactHomeNumberCount;
    
    NSMutableDictionary *_cachedResidencesById;
    NSArray *_cachedResidences;
    NSArray *_cachedCandidates;
    
    NSInteger _recipientType;
    NSArray *_recipientCandidates;
    
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


- (void)enableOrDisableButtons
{
    [self.navigationItem barButtonItemWithTag:kBarButtonItemTagFavourite].enabled = self.isOnline;
    [self.navigationItem barButtonItemWithTag:kBarButtonItemTagEdit].enabled = self.isOnline;
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
    NSInteger numberOfCoHabitants = [primaryResidence residents].count;
    NSInteger numberOfResidences = [_member residences].count;
    
    if ([primaryResidence hasAddress] && numberOfResidences == 1 && numberOfCoHabitants > 1) {
        [self presentCoHabitantsSheet];
    } else if (![primaryResidence hasAddress]) {
        if ([primaryResidence elders].count == 1) {
            [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:primaryResidence];
        } else {
            [self presentCoHabitantsSheet];
        }
    } else {
        [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:kOrigoTypeResidence];
    }
}


- (void)showIsFavouritePopUp:(BOOL)isFavourite
{
    UIImage *image = [[UIImage imageNamed:kIconFileFavouriteNo] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImage *highlightedImage = [[UIImage imageNamed:kIconFileFavouriteYes] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image highlightedImage:highlightedImage];
    imageView.tintColor = [UIColor whiteColor];
    imageView.highlighted = isFavourite;
    
    NSString *text = isFavourite ? OLocalizedString(@"Favourite", @"") : OLocalizedString(@"Not favourite", @"");
    
    CGSize textSize = [text sizeWithFont:[UIFont titleFont] maxWidth:CGFLOAT_MAX];
    CGFloat padding = 2.f * kDefaultCellPadding;
    CGFloat popUpWidth = MAX(imageView.image.size.width, textSize.width) + padding;
    CGFloat popUpHeight = imageView.image.size.height + textSize.height + padding;
    CGFloat popUpX = ([OMeta screenSize].width - popUpWidth) / 2.f;
    CGFloat popUpY = ([OMeta screenSize].height - popUpHeight) / 2.f;
    
    UIView *popUpView = [[UIView alloc] initWithFrame:CGRectMake(popUpX, popUpY, popUpWidth, popUpHeight)];
    popUpView.backgroundColor = [UIColor blackColor];
    popUpView.alpha = kPopUpAlpha;
    popUpView.layer.cornerRadius = kPopUpCornerRadius;
    
    CGRect imageViewFrame = imageView.frame;
    imageViewFrame.origin.x = (popUpWidth - imageView.image.size.width) / 2.f;
    imageViewFrame.origin.y = padding / 3.f;
    imageView.frame = imageViewFrame;
    
    CGFloat labelX = (popUpWidth - textSize.width) / 2.f;
    CGFloat labelY = imageView.image.size.height + 2.f * padding / 3.f;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(labelX, labelY, textSize.width, textSize.height)];
    label.font = [UIFont titleFont];
    label.text = text;
    label.textColor = [UIColor whiteColor];
    
    [popUpView addSubview:imageView];
    [popUpView addSubview:label];
    [self.view.window addSubview:popUpView];
    self.view.window.userInteractionEnabled = NO;
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void) {
        self.view.window.userInteractionEnabled = YES;
        [popUpView removeFromSuperview];
    });
}


#pragma mark - Input validation

- (BOOL)reflectIfEligibleMember:(id<OMember>)member
{
    BOOL isEligible = ![_origo hasMember:member] || ([self targetIs:kTargetOrganiser] && ![[_origo organisers] containsObject:member]);
    
    if (isEligible) {
        [self reflectMember:member];
    } else {
        [_nameField becomeFirstResponder];
        
        [OAlert showAlertWithTitle:@"" message:[NSString stringWithFormat:OLocalizedString(@"%@ is already in %@.", @""), [member givenName], [_origo displayName]]];
    }
    
    return isEligible;
}


- (BOOL)isUniqueEmail:(NSString *)email
{
    BOOL isUniqueEmail = YES;
    
    if (![_member.email hasValue] || ![email isEqualToString:_member.email]) {
        id<OMember> existingMember = [[OMeta m].context memberWithEmail:_emailField.value];
        
        if (existingMember) {
            isUniqueEmail = [self actionIs:kActionRegister] && [existingMember.name fuzzyMatches:_nameField.value] && [self reflectIfEligibleMember:existingMember];
        }
        
        if (!isUniqueEmail) {
            [OAlert showAlertWithTitle:OLocalizedString(@"Address in use", @"") message:[NSString stringWithFormat:OLocalizedString(@"The email address %@ is already in use.", @""), _emailField.value]];
            
            [_emailField becomeFirstResponder];
        }
    }
    
    return isUniqueEmail;
}


- (BOOL)inputMatchesMemberWithDictionary:(NSDictionary *)dictionary
{
    NSString *name = dictionary[kPropertyKeyName];
    NSDate *dateOfBirth = [NSDate dateFromSerialisedDate:dictionary[kPropertyKeyDateOfBirth]];
    //NSString *mobilePhone = dictionary[kPropertyKeyMobilePhone];
    NSString *email = dictionary[kPropertyKeyEmail];
    
    BOOL inputMatches = [_nameField.value fuzzyMatches:name];
    
    if (inputMatches && _dateOfBirthField) {
        inputMatches = [_dateOfBirthField.value isEqual:dateOfBirth];
    }
  
// TODO: Commented out to simplify member registration for 1.0.1. Comment back in if too loose.

//    if (inputMatches && [mobilePhone hasValue] && ![OMeta deviceIsSimulator]) {
//        inputMatches = _mobilePhoneField.value ? [[[OPhoneNumberFormatter formatterForNumber:_mobilePhoneField.value] completelyFormattedNumberCanonicalised:YES] isEqualToString:[[OPhoneNumberFormatter formatterForNumber:mobilePhone] completelyFormattedNumberCanonicalised:YES]] : NO;
//    }
    
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
        actualMember = [[OMeta m].context memberWithEmail:_emailField.value];
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
    } else if (activeResidences.count) {
        [OAlert showAlertWithTitle:OLocalizedString(@"Unknown child", @"") message:[NSString stringWithFormat:OLocalizedString(@"No child named %@ has been registered by %@.", @""), _nameField.value, [OUtil commaSeparatedListOfMembers:activeGuardians conjoin:YES subjective:YES]]];
        
        if (allResidences.count > activeResidences.count) {
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
            
            if ([ward residences].count && ![_member residences].count) {
                BOOL addingToResidence = [self.entity.ancestor conformsToProtocol:@protocol(OOrigo)];
                
                if ([ward hasAddress] && !addingToResidence) {
                    _cachedResidences = [ward addresses];
                    
                    [self presentGuardianCoHabitantsSheet];
                } else {
                    [[ward primaryResidence] addMember:_member];
                    [self.dismisser dismissModalViewController:self];
                }
            } else if (![_member hasAddress] && [_member userCanEdit]) {
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
                    [_member pinnedFriendList];
                }
                
                [self.dismisser dismissModalViewController:self];
            }
        }
    }
}


#pragma mark - Action sheets

- (void)presentHousemateResidencesSheet
{
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil];
    
    for (id<OOrigo> residence in _cachedResidences) {
        [actionSheet addButtonWithTitle:[residence shortAddress] action:^{
            [residence addMember:self->_member];
            [self reloadSections];
        }];
    }
    
    [actionSheet addButtonWithTitle:OLocalizedString(@"Other address", @"") action:^{
        [self registerNewResidence];
    }];
    
    [actionSheet show];
}


- (void)presentCoHabitantsSheet
{
    void (^registerMemberCoHabitants)(NSArray *, BOOL) = ^(NSArray *coHabitants, BOOL minorsOnly) {
        id<OOrigo> primaryResidence = [self->_member primaryResidence];
        if (minorsOnly || [primaryResidence hasAddress]) {
            if (minorsOnly && ![primaryResidence hasAddress]) {
                [[[primaryResidence membershipForMember:self->_member] proxy] expire];
            }
            primaryResidence = [OOrigoProxy residenceProxyUseDefaultName:![self->_member isUser]];
            [primaryResidence addMember:self->_member];
            for (id<OMember> coHabitant in coHabitants) {
                [primaryResidence addMember:coHabitant];
            }
        }
        [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:primaryResidence];
    };
    
    NSArray *residentGroups = [OUtil sortedGroupsOfResidents:[[_member primaryResidence] residents] excluding:_member];
    OActionSheet *actionSheet = nil;
    
    if (residentGroups.count == 1) {
        NSString *prompt = nil;
        
        if ([residentGroups[0] count] == 1) {
            prompt = [NSString stringWithFormat:OLocalizedString(@"[sg] Should %@ also be registered at this address?", @""), [residentGroups[0][0] givenName]];
        } else {
            prompt = [NSString stringWithFormat:OLocalizedString(@"[pl] Should %@ also be registered at this address?", @""), [OUtil commaSeparatedListOfMembers:residentGroups[0] conjoin:YES subjective:YES]];
        }
        
        actionSheet = [[OActionSheet alloc] initWithPrompt:prompt];
        [actionSheet addButtonWithTitle:OLocalizedString(@"Yes", @"") action:^{
            registerMemberCoHabitants(residentGroups[0], NO);
        }];
        [actionSheet addButtonWithTitle:OLocalizedString(@"No", @"") action:nil];
    } else {
        actionSheet = [[OActionSheet alloc] initWithPrompt:OLocalizedString(@"Who else should be registered at this address?", @"")];
        [actionSheet addButtonWithTitle:[[OUtil commaSeparatedListOfMembers:residentGroups[0] conjoin:YES subjective:YES] stringByCapitalisingFirstLetter] action:^{
            registerMemberCoHabitants(residentGroups[0], NO);
        }];
        [actionSheet addButtonWithTitle:[[OUtil commaSeparatedListOfMembers:residentGroups[1] conjoin:YES subjective:YES] stringByCapitalisingFirstLetter] action:^{
            registerMemberCoHabitants(residentGroups[1], YES);
        }];
        
        if ([_member hasAddress]) {
            if ([residentGroups[0] containsObject:[OMeta m].user]) {
                [actionSheet addButtonWithTitle:OLocalizedString(@"None of you", @"") action:nil];
            } else {
                [actionSheet addButtonWithTitle:OLocalizedString(@"None of them [persons]", @"") action:nil];
            }
        }
    }
    
    [actionSheet show];
}


- (void)presentGuardianCoHabitantsSheet
{
    OActionSheet *actionSheet = nil;
    
    if (_cachedResidences.count == 1) {
        NSString *guardians = [OUtil commaSeparatedListOfMembers:[_cachedResidences[0] elders] conjoin:YES subjective:YES];
        
        actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:OLocalizedString(@"Does %@ live with %@?", @""), [_member givenName], guardians]];
        [actionSheet addButtonWithTitle:OLocalizedString(@"Yes", @"") action:^{
            [self->_cachedResidences[0] addMember:self->_member];
            [self.dismisser dismissModalViewController:self];
        }];
        [actionSheet addButtonWithTitle:OLocalizedString(@"No", @"") action:^{
            [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:[self->_member primaryResidence]];
        }];
    } else {
        void (^addMemberToResidence)(id<OOrigo>) = ^(id<OOrigo> residence) {
            [self.inputCell resumeFirstResponder];
            [residence addMember:self->_member];
            [self.dismisser dismissModalViewController:self];
        };

        NSString *guardians1 = [OUtil commaSeparatedListOfMembers:[_cachedResidences[0] elders] conjoin:YES subjective:YES];
        NSString *guardians2 = [OUtil commaSeparatedListOfMembers:[_cachedResidences[1] elders] conjoin:YES subjective:YES];
        
        actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:OLocalizedString(@"Does %@ live with %@ or %@?", @""), [_member givenName], guardians1, guardians2]];
        [actionSheet addButtonWithTitle:guardians1 action:^{
            addMemberToResidence(self->_cachedResidences[0]);
        }];
        [actionSheet addButtonWithTitle:guardians2 action:^{
            addMemberToResidence(self->_cachedResidences[1]);
        }];
    }
    
    [actionSheet show];
}


- (void)presentMultiValueSheetForInputField:(OInputField *)inputField
                                     prompt:(NSString *)prompt
                              onValueSelect:(void (^)(NSString *))selectValue
{
    [inputField becomeFirstResponder];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt];
    
    for (id inputFieldValue in inputField.value) {
        [actionSheet addButtonWithTitle:inputFieldValue action:^{
            inputField.value = inputFieldValue;
            selectValue(inputFieldValue);
            [self finaliseOrRefineAddressBookInfo];
        }];
    }
    [actionSheet addButtonWithTitle:OLocalizedString(@"None of them", @"") action:^{
        [self finaliseOrRefineAddressBookInfo];
    }];
    [actionSheet show];
}


- (void)presentMultipleAddressesSheet
{
    OActionSheet *actionSheet =
            [[OActionSheet alloc] initWithPrompt:
                    [NSString stringWithFormat:OLocalizedString(@"%@ has more than one home address. Which address do you want to provide?", @""),
                            [_nameField.value givenName]]];
    
    for (id<OOrigo> selectableAddress in _contactAddresses) {
        [actionSheet addButtonWithTitle:[selectableAddress shortAddress] action:^{
            [selectableAddress addMember:self->_member];
            for (id<OOrigo> address in self->_contactAddresses) {
                if (address != selectableAddress) {
                    [address expire];
                }
            }
            [self->_contactAddresses removeAllObjects];
            [self finaliseOrRefineAddressBookInfo];
        }];
    }
    
    if (![self aspectIs:kAspectJuvenile]) {
        [actionSheet addButtonWithTitle:OLocalizedString(@"All of them", @"") action:^{
            for (id<OOrigo> address in self->_contactAddresses) {
                [address addMember:self->_member];
            }
            [self->_contactAddresses removeAllObjects];
            [self finaliseOrRefineAddressBookInfo];
        }];
    }
    
    [actionSheet addButtonWithTitle:OLocalizedString(@"None of them", @"") action:^{
        [self->_contactAddresses removeAllObjects];
        [self finaliseOrRefineAddressBookInfo];
    }];
    
    [actionSheet show];
}


- (void)presentHomeNumberConfirmationSheetForResidence:(id<OOrigo>)residence {
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:[NSString stringWithFormat:
            OLocalizedString(@"Is %@ the phone number for %@?", @""),
            _contactHomeNumbers[0],
            [residence shortAddress]]];
    [actionSheet addButtonWithTitle:OLocalizedString(@"Yes", @"") action:^{
        residence.telephone = self->_contactHomeNumbers[0];
        [self->_contactHomeNumbers removeAllObjects];
        [self finaliseOrRefineAddressBookInfo];
    }];
    [actionSheet addButtonWithTitle:OLocalizedString(@"No", @"") action:^{
        [self->_contactHomeNumbers removeAllObjects];
        [self finaliseOrRefineAddressBookInfo];
    }];
    [actionSheet show];
}


- (void)presentHomeNumberSelectionSheetForResidence:(id<OOrigo>)residence {
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:
            [residence hasAddress]
                    ? [NSString stringWithFormat:OLocalizedString(@"%@ has more than one home phone number. Which number is valid for %@?", @""),
                              [_nameField.value givenName],
                              [residence shortAddress]]
                    : [NSString stringWithFormat:OLocalizedString(@"%@ has more than one home phone number. Which number do you want to provide?", @""),
                              [_nameField.value givenName]]];
    for (NSString *homeNumber in _contactHomeNumbers) {
        [actionSheet addButtonWithTitle:homeNumber action:^{
            residence.telephone = homeNumber;
            [self->_contactHomeNumbers removeAllObjects];
            [self finaliseOrRefineAddressBookInfo];
        }];
    }
    [actionSheet addButtonWithTitle:OLocalizedString(@"None of them", @"") action:^{
        [self->_contactHomeNumbers removeAllObjects];
        [self finaliseOrRefineAddressBookInfo];
    }];
    [actionSheet show];
}


- (void)presentHomeNumberResidenceSelectionSheet:(NSMutableArray *)residences {
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:
            _contactHomeNumberCount == 1 || _contactHomeNumbers.count == _contactHomeNumberCount
                    ? [NSString stringWithFormat:_contactHomeNumberCount == 1
                                    ? OLocalizedString(@"%@ has only one home phone number, %@. Which address has this number?", @"")
                                    : OLocalizedString(@"%@ has more than one home phone number. Which address has the number %@?", @""),
                                                 [_nameField.value givenName],
                                                 _contactHomeNumbers[0]]
                    : [NSString stringWithFormat:OLocalizedString(@"Which address has phone number %@?", @""),
                                                 _contactHomeNumbers[0]]];
    for (OOrigo *residence in residences) {
        [actionSheet addButtonWithTitle:[residence shortAddress] action:^{
            residence.telephone = self->_contactHomeNumbers[0];
            [residences removeObject:residence];
            [self->_contactHomeNumbers removeObjectAtIndex:0];
            if (residences.count && self->_contactHomeNumbers.count) {
                [self refineAddressBookAddressInfo];
            }
        }];
    }
    [actionSheet addButtonWithTitle:OLocalizedString(@"None of them", @"") action:^{
        [self->_contactHomeNumbers removeObjectAtIndex:0];
        [self finaliseOrRefineAddressBookInfo];
    }];
    [actionSheet show];
}


- (void)presentHomeNumberMappingSheet
{
    NSMutableArray *residencesLackingHomeNumber = [NSMutableArray array];
    for (id<OOrigo> residence in [_member residences]) {
        if (!residence.telephone) {
            [residencesLackingHomeNumber addObject:residence];
        }
    }
    
    if (_contactHomeNumbers.count == 1 && residencesLackingHomeNumber.count == 1) {
        [self presentHomeNumberConfirmationSheetForResidence:residencesLackingHomeNumber[0]];
    } else if ([_member residences].count == 1) {
        [self presentHomeNumberSelectionSheetForResidence:[_member primaryResidence]];
    } else {
        [self presentHomeNumberResidenceSelectionSheet:residencesLackingHomeNumber];
    }
}


- (void)presentRecipientsSheet
{
    if (_recipientCandidates.count == 1) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil];
        [actionSheet addButtonWithTitle:[_recipientCandidates[0] recipientLabelForRecipientType:_recipientType] action:^{
            if (self->_recipientType == kRecipientTypeText) {
                [self sendTextToRecipients:self->_recipientCandidates[0]];
            } else if (self->_recipientType == kRecipientTypeCall) {
                [self callRecipient:self->_recipientCandidates[0]];
            } else if (self->_recipientType == kRecipientTypeEmail) {
                [self sendEmailToRecipients:self->_recipientCandidates[0]];
            }
        }];
        [actionSheet show];
    } else {
        if (_recipientType == kRecipientTypeText) {
            [self presentRecipientsSheetWithPrompt:OLocalizedString(@"Who do you want to text?", @"")
                                          onSelect:^(id recipient) {
                                              [self sendTextToRecipients:recipient];
                                          }];
        } else if (_recipientType == kRecipientTypeCall) {
            [self presentRecipientsSheetWithPrompt:OLocalizedString(@"Who do you want to call?", @"")
                                          onSelect:^(id recipient) {
                                              [self callRecipient:recipient];
                                          }];
        } else if (_recipientType == kRecipientTypeEmail) {
            [self presentRecipientsSheetWithPrompt:OLocalizedString(@"Who do you want to email?", @"")
                                          onSelect:^(id recipient) {
                                              [self sendEmailToRecipients:recipient];
                                          }];
        }
    }
}


- (void)presentRecipientsSheetWithPrompt:(NSString *)prompt onSelect:(void (^)(id))selectRecipient {
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt];
    for (id recipientCandidate in _recipientCandidates) {
        [actionSheet addButtonWithTitle:[recipientCandidate recipientLabel] action:^{
            selectRecipient(recipientCandidate);
        }];
    }
    [actionSheet show];
}


#pragma mark - Alerts

- (void)presentAlertForNumberOfUnmatchedResidences:(NSInteger)numberOfUnmatchedResidences
{
    NSString *title = nil;
    NSString *message = nil;
    
    if (numberOfUnmatchedResidences == 1) {
        title = OLocalizedString(@"Unknown address", @"");
    } else {
        title = OLocalizedString(@"Unknown addresses", @"");
    }
    
    if (numberOfUnmatchedResidences < [_member residences].count) {
        if (numberOfUnmatchedResidences == 1) {
            message = OLocalizedString(@"One of the addresses you provided did not match our records and was not saved.", @"");
        } else {
            message = OLocalizedString(@"Some of the addresses you provided did not match our records and were not saved.", @"");
        }
    } else if (numberOfUnmatchedResidences == 1) {
        message = OLocalizedString(@"The address you provided did not match our records and was not saved.", @"");
    } else {
        message = OLocalizedString(@"The addresses you provided did not match our records and were not saved.", @"");
    }
    
    [OAlert showAlertWithTitle:title message:message];
}


- (void)presentEmailChangeAlert
{
    if (self.isOnline) {
        [OAlert showAlertWithTitle:OLocalizedString(@"New email address", @"")
                           message:[_member isUser]
                                   ? [NSString stringWithFormat:OLocalizedString(@"You are about to change your email address from %@ to %@ ...", @""),
                                             _member.email,
                                             _emailField.value]
                                   : [NSString stringWithFormat:OLocalizedString(@"You are about to change %@'s email address from %@ to %@ ...", @""),
                                             [_member givenName],
                                             _member.email,
                                             _emailField.value]
                     okButtonTitle:OLocalizedString(@"Continue", @"")
                              onOk:^{
                                  [[OConnection connectionWithDelegate:self] lookupMemberWithEmail:self->_emailField.value];
                              }
                          onCancel:^{ [self->_emailField becomeFirstResponder]; }];
    } else {
        [OAlert showAlertWithTitle:OLocalizedString(@"No internet connection", @"")
                           message:[_member isUser]
                                   ? OLocalizedString(@"You need a working internet connection to change your email address.", @"")
                                   : [NSString stringWithFormat:OLocalizedString(@"You need a working internet connection to change %@'s email address.", @""),
                                             [_member givenName]]];
    }
}


#pragma mark - Adress book entry processing

- (void)refineAddressBookContactInfo
{
    if ([_mobilePhoneField hasMultiValue]) {
        [self presentMultiValueSheetForInputField:_mobilePhoneField
                                           prompt:[NSString stringWithFormat:
                                                   OLocalizedString(@"%@ has more than one mobile phone number. Which number do you want to provide?", @""),
                                                   [_nameField.value givenName]]
                                    onValueSelect:^(NSString *selectedValue) {
                                        self->_mobilePhoneField.value = selectedValue;
                                    }];
    } else if ([_emailField hasMultiValue]) {
        [self presentMultiValueSheetForInputField:_emailField
                                           prompt:[NSString stringWithFormat:
                                                   OLocalizedString(@"%@ has more than one email address. Which address do you want to provide?", @""),
                                                   [_nameField.value givenName]]
                                    onValueSelect:^(NSString *selectedValue) {
                                        self->_emailField.value = selectedValue;
                                    }];
    }
}


- (void)refineAddressBookAddressInfo
{
    if (_contactAddresses.count) {
        [self presentMultipleAddressesSheet];
    } else if (_contactHomeNumbers.count) {
        if ([_member residences].count) {
            [self presentHomeNumberMappingSheet];
        } else {
            [_contactHomeNumbers removeAllObjects];
        }
    }
}


- (void)finaliseOrRefineAddressBookInfo {
    if (![_member instance]) {
        if ([_emailField hasMultiValue]) {
            [self refineAddressBookContactInfo];
        } else if (!_didPerformLocalLookup) {
            [self performLocalLookup];
            if ([_member instance] && _contactAddresses.count) {
                for (id<OOrigo> address in _contactAddresses) {
                    [address expire];
                }
            } else {
                [self refineAddressBookAddressInfo];
            }
        } else if (_contactHomeNumbers.count) {
            [self refineAddressBookAddressInfo];
        }
    }
    if (!_contactHomeNumbers.count && !_contactAddresses.count) {
        [self reflectMember:_member];
    }
}


#pragma mark - Retrieving address book data

- (void)pickFromAddressBook
{
    [self resetInputState];
    
    CNContactPickerViewController *contactPicker = [[CNContactPickerViewController alloc] init];
    contactPicker.delegate = self;
    
    [self presentViewController:contactPicker animated:YES completion:nil];
}


- (void)retrieveNameFromContact:(CNContact *)contact
{
    NSString *firstName = contact.givenName;
    NSString *middleName = contact.middleName;
    NSString *lastName = contact.familyName;
    
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


- (void)retrievePhoneNumbersFromContact:(CNContact *)contact
{
    NSArray<CNLabeledValue<CNPhoneNumber *> *> *labeledPhoneNumbers = contact.phoneNumbers;
    
    if (labeledPhoneNumbers.count > 0) {
        _contactHomeNumbers = [NSMutableArray array];
        
        NSMutableArray *mobilePhoneNumbers = [NSMutableArray array];
        
        for (CNLabeledValue<CNPhoneNumber *> *labeledPhoneNumber in labeledPhoneNumbers) {
            NSString *label = labeledPhoneNumber.label;
            
            BOOL isMobilePhone = [label isEqualToString:CNLabelPhoneNumberMobile];
            BOOL is_iPhone = [label isEqualToString:CNLabelPhoneNumberiPhone];
            BOOL isHomePhone = [label isEqualToString:CNLabelPhoneNumberMain];
            
            if (isMobilePhone || is_iPhone || isHomePhone) {
                NSString *phoneNumber = labeledPhoneNumber.value.stringValue;
                
                if (isMobilePhone || is_iPhone) {
                    [mobilePhoneNumbers addObject:phoneNumber];
                } else {
                    [_contactHomeNumbers addObject:phoneNumber];
                }
            }
        }
        
        _contactHomeNumberCount = _contactHomeNumbers.count;
        
        if (mobilePhoneNumbers.count) {
            _mobilePhoneField.value = mobilePhoneNumbers;
            
            if (![_mobilePhoneField hasMultiValue]) {
                _member.mobilePhone = _mobilePhoneField.value;
            }
        }
    }
}


- (void)retrieveEmailAddressesFromContact:(CNContact *)contact
{
    NSArray<CNLabeledValue<NSString *> *> *labeledEmailAddresses = contact.emailAddresses;
    
    if (labeledEmailAddresses.count > 0) {
        NSMutableArray *emailAddresses = [NSMutableArray array];
        
        for (CNLabeledValue<NSString *> *labeledEmailAddress in labeledEmailAddresses) {
            NSString *emailAddress = labeledEmailAddress.value;
            
            if ([OValidator isEmailValue:emailAddress]) {
                [emailAddresses addObject:emailAddress];
            }
        }
        
        if (emailAddresses.count) {
            _emailField.value = emailAddresses;
            
            if (![_emailField hasMultiValue]) {
                _member.email = _emailField.value;
            }
        }
    }
}


- (void)retrieveAddressesFromContact:(CNContact *)contact
{
    NSArray<CNLabeledValue<CNPostalAddress *> *> *labeledAddresses = contact.postalAddresses;
    
    if (labeledAddresses.count > 0) {
        _contactAddresses = [NSMutableArray array];
        
        for (CNLabeledValue<CNPostalAddress *> *labeledAddress in labeledAddresses) {
            NSString *label = labeledAddress.label;
            
            if ([label isEqualToString:CNLabelHome]) {
                [_contactAddresses addObject:[OOrigoProxy residenceProxyFromAddress:labeledAddress.value]];
            }
        }
        
        if (_contactAddresses.count == 1) {
            [_contactAddresses[0] addMember:_member];
            [_contactAddresses removeAllObjects];
        }
        
        if (_contactHomeNumbers.count) {
            if (!_contactAddresses.count && ![_member hasAddress]) {
                if (_contactHomeNumbers.count == 1) {
                    [[OOrigoProxy residenceProxyUseDefaultName:YES] addMember:_member];
                }
            }
            
            if ([_member residences].count == 1 && _contactHomeNumbers.count == 1) {
                [_member primaryResidence].telephone = _contactHomeNumbers[0];
                [_contactHomeNumbers removeAllObjects];
            }
        }
    }
}


#pragma mark - Selector implementations

- (void)toggleFavouriteStatus
{
    [self cancelInlineEditingIfOngoing];
    
    BOOL isFavourite = [_member isFavourite];
    id<OOrigo> stash = [[OMeta m].user stash];
    
    if (isFavourite) {
        [[stash membershipForMember:_member] expire];
    } else {
        [stash addMember:_member];
    }
    
    isFavourite = !isFavourite;
    
    NSMutableArray *rightBarButtonItems = [self.navigationItem.rightBarButtonItems mutableCopy];
    NSUInteger toggleIndex = [rightBarButtonItems indexOfObject:[self.navigationItem barButtonItemWithTag:kBarButtonItemTagFavourite]];
    
    rightBarButtonItems[toggleIndex] = [UIBarButtonItem favouriteButtonWithTarget:self isFavourite:isFavourite];
    
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    
    [self showIsFavouritePopUp:isFavourite];
}


- (void)performEditAction
{
    [self cancelInlineEditingIfOngoing];
    
    if ([[OMeta m].user isJuvenile]) {
        [self scrollToTopAndToggleEditMode];
    } else {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil];
        [actionSheet addButtonWithTitle:OLocalizedString(@"Edit", @"") action:^{
            [self scrollToTopAndToggleEditMode];
        }];
        
        if (![_member isJuvenile] || [_member isWardOfUser]) {
            [actionSheet addButtonWithTitle:OLocalizedString([_member hasAddress] ? @"Register an address" : @"Register address", @"") action:^{
                if ([self->_member housemateResidences]) {
                    [self presentHousemateResidencesSheet];
                } else {
                    [self registerNewResidence];
                }
            }];
        } else if (![[OMeta m].user isJuvenile]) {
            [actionSheet addButtonWithTitle:OLocalizedString(@"Register guardian", @"") action:^{
                [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetGuardian];
            }];
        }
        
        [actionSheet show];
    }
}


- (void)performInfoAction
{
    [self cancelInlineEditingIfOngoing];
    [self presentModalViewControllerWithIdentifier:kIdentifierInfo target:_member];
}


- (void)performLookupAction
{
    [self.view endEditing:YES];
    
    if ([self targetIs:@[kTargetGuardian, kTargetOrganiser]]) {
        _cachedCandidates = [self.state eligibleCandidates];
    } else {
        _cachedCandidates = nil;
    }
    
    if (_cachedCandidates && _cachedCandidates.count) {
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil];
        [actionSheet addButtonWithTitle:OLocalizedString(@"Retrieve from lists", @"") action:^{
            [self resetInputState];
            [self presentModalViewControllerWithIdentifier:kIdentifierValuePicker target:kTargetMember meta:self->_cachedCandidates];
        }];
        [actionSheet addButtonWithTitle:OLocalizedString(@"Retrieve from Contacts", @"") action:^{
            [self resetInputState];
            [self pickFromAddressBook];
        }];
        
        [actionSheet showWithCancelAction:^{
            [self.inputCell resumeFirstResponder];
        }];
    } else {
        [self pickFromAddressBook];
    }
}


- (void)performAddAction
{
    [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetGuardian];
}


- (void)performTextAction
{
    if ([_member isJuvenile]) {
        _recipientType = kRecipientTypeText;
        _recipientCandidates = [_member textRecipients];
        
        [self presentRecipientsSheet];
    } else {
        [self sendTextToRecipients:_member];
    }
}


- (void)performCallAction
{
    _recipientCandidates = [_member callRecipients];
    
    if ([_member isJuvenile] || _recipientCandidates.count > 1) {
        _recipientType = kRecipientTypeCall;
        
        [self presentRecipientsSheet];
    } else {
        [self callRecipient:_recipientCandidates[0]];
    }
}


- (void)performEmailAction
{
    if ([_member isJuvenile]) {
        _recipientType = kRecipientTypeEmail;
        _recipientCandidates = [_member emailRecipients];
        
        [self presentRecipientsSheet];
    } else {
        [self sendEmailToRecipients:_member];
    }
}


#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self actionIs:kActionRegister]) {
        if ([_member guardians].count) {
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
        if ([_member guardians].count) {
            [_nameField becomeFirstResponder];
        } else if (!self.wasHidden) {
            [self presentModalViewControllerWithIdentifier:kIdentifierMember target:kTargetGuardian];
        }
    }
    
    [super viewDidAppear:animated];
    
    if ([self actionIs:kActionDisplay] && ![[OMeta m].user isJuvenile]) {
        if ([_member isHousemateOfUser] && ![_member hasValueForKey:kPropertyKeyDateOfBirth]) {
            [self toggleEditMode];
            [[self.inputCell nextInvalidInputField] becomeFirstResponder];
        }
    }
}


#pragma mark - OTableViewController protocol conformance

- (void)loadState
{
    _member = [self.entity proxy];
    _origo = self.state.currentOrigo;
    
    if (!_origo && [_member isUser]) {
        _origo = [_member primaryResidence];
    }
    
    if ([self actionIs:kActionRegister]) {
        if ([self targetIs:kTargetUser]) {
            self.title = OLocalizedString(@"About you", @"");
        } else if ([self targetIs:kTargetGuardian]) {
            self.title = [[OLanguage nouns][_guardian_][singularIndefinite] stringByCapitalisingFirstLetter];
        } else if ([self targetIs:kTargetOrganiser]) {
            self.titleView = [OTitleView titleViewWithTitle:nil];
            self.titleView.placeholder = OLocalizedString(_origo.type, kStringPrefixOrganiserRoleTitle);
        } else if ([_origo isPrivate]) {
            if ([_member isJuvenile]) {
                self.title = OLocalizedString(@"Friend", @"");
            } else {
                self.title = OLocalizedString(@"Contact", @"");
            }
        } else {
            self.title = OLocalizedString(_origo.type, kStringPrefixNewMemberTitle);
        }
        
        if (![self targetIs:kTargetUser]) {
            if ([self targetIs:kTargetJuvenile]) {
                self.navigationItem.rightBarButtonItem = [UIBarButtonItem plusButtonWithTarget:self];
            } else {
                self.navigationItem.rightBarButtonItem = [UIBarButtonItem lookupButtonWithTarget:self];
            }
        }
    } else if ([self actionIs:kActionDisplay]) {
        _membership = [_origo membershipForMember:_member];
        _roleMembership = self.state.baseOrigo ? [self.state.baseOrigo membershipForMember:_member] : _membership;
        
        self.navigationItem.backBarButtonItem = [UIBarButtonItem backButtonWithTitle:[_member givenName]];
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem infoButtonWithTarget:self];
        
        if (![_member isUser] && ([_member.mobilePhone hasValue] || [_member.email hasValue])) {
            if (![_member isJuvenile] || [_member isWardOfUser] || [[OMeta m].user isJuvenile]) {
                [self.navigationItem addRightBarButtonItem:[UIBarButtonItem favouriteButtonWithTarget:self isFavourite:[_member isFavourite]]];
            }
        }
        
        if ([_member userCanEdit]) {
            [self.navigationItem addRightBarButtonItem:[UIBarButtonItem editButtonWithTarget:self]];
        }
        
        [self enableOrDisableButtons];
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
            cell.detailTextLabel.text = [[guardian parentNoun][singularIndefinite] stringByCapitalisingFirstLetter];
            cell.detailTextLabel.textColor = [UIColor tonedDownTextColour];
        }
        
        cell.destinationId = kIdentifierMember;
    } else if (sectionKey == kSectionKeyAddresses) {
        id<OOrigo> residence = [self dataAtIndexPath:indexPath];
        
        [cell loadImageForOrigo:residence];
        cell.textLabel.text = [residence shortAddress];
        
        if (![residence hasAddress]) {
            cell.textLabel.textColor = [UIColor tonedDownTextColour];
        }
        
        if ([_member isJuvenile] && [_member residences].count > 1) {
            cell.detailTextLabel.text = [OUtil commaSeparatedListOfMembers:[residence elders] conjoin:NO];
            cell.detailTextLabel.textColor = [UIColor tonedDownTextColour];
        } else if ([residence hasTelephone]) {
            cell.detailTextLabel.text = [[OPhoneNumberFormatter formatterForNumber:residence.telephone] completelyFormattedNumberCanonicalised:YES];
        }
        
        [cell setDestinationId:kIdentifierOrigo selectableDuringInput:![self targetIs:kTargetJuvenile]];
    } else if (sectionKey == kSectionKeyRoles) {
        if ([_roleMembership.origo userCanEdit]) {
            OInputField *roleField = [cell inlineField];
            roleField.placeholder = OLocalizedString(@"Responsibility", @"");
            roleField.value = [self dataAtIndexPath:indexPath];
        } else {
            cell.textLabel.text = [self dataAtIndexPath:indexPath];
            cell.selectable = NO;
        }
    }
}


- (UITableViewCellStyle)listCellStyleForSectionWithKey:(NSInteger)sectionKey
{
    UITableViewCellStyle cellStyle = kTableViewCellStyleDefault;
    
    if (sectionKey == kSectionKeyRoles && ([_roleMembership.origo userCanEdit])) {
        cellStyle = kTableViewCellStyleInline;
    }
    
    return cellStyle;
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    BOOL hasFooter = NO;
    BOOL isBottomSection = [self isBottomSectionKey:sectionKey];
    
    if (![_member isUser]) {
        if ([self actionIs:kActionRegister]) {
            if ([_member isJuvenile]) {
                hasFooter = sectionKey == kSectionKeyGuardians;
            } else {
                hasFooter = isBottomSection;
            }
        } else if (![_member isJuvenile] || ([_member isActive] && [_member isTeenOrOlder])) {
            hasFooter = isBottomSection;
        }
    }
    
    return hasFooter;
}


- (id)headerContentForSectionWithKey:(NSInteger)sectionKey
{
    NSString *headerContent = nil;
    
    if (sectionKey == kSectionKeyGuardians) {
        NSArray *guardians = [_member guardians];
        
        if (guardians.count == 1) {
            id<OMember> guardian = guardians[0];
            
            if ([_member hasParent:guardian]) {
                headerContent = [guardian parentNoun][singularIndefinite];
            } else {
                headerContent = [guardian guardianNoun][singularIndefinite];
            }
        } else if ([_member guardiansAreParents]) {
            headerContent = [OLanguage nouns][_parent_][pluralIndefinite];
        } else {
            headerContent = [OLanguage nouns][_guardian_][pluralIndefinite];
        }
    } else if (sectionKey == kSectionKeyAddresses) {
        NSInteger numberOfAddresses = [_member addresses].count;
        
        if (numberOfAddresses == 1) {
            headerContent = [OLanguage nouns][_address_][singularIndefinite];
        } else if (numberOfAddresses > 1) {
            headerContent = [OLanguage nouns][_address_][pluralIndefinite];
        }
    } else if (sectionKey == kSectionKeyRoles) {
        if ([[_origo membershipForMember:_member] roles].count == 1) {
            headerContent = [NSString stringWithFormat:OLocalizedString(@"Responsibility in %@", @""), [_roleMembership.origo name]];
        } else {
            headerContent = [NSString stringWithFormat:OLocalizedString(@"Responsibilities in %@", @""), [_roleMembership.origo name]];
        }
    }
    
    return [headerContent stringByCapitalisingFirstLetter];
}


- (NSString *)footerContentForSectionWithKey:(NSInteger)sectionKey
{
    NSString *footerContent = nil;
    
    if (![_member isUser]) {
        if ([self actionIs:kActionRegister]) {
            if ([_member isJuvenile]) {
                footerContent = OLocalizedString(@"Tap + to register additional guardians.", @"");
            } else {
                if ([_origo isResidence]) {
                    footerContent = OLocalizedString(@"New household members are notified by email that their household has been added on Origon.", @"");
                } else if ([_origo isPrivate]) {
                    footerContent = OLocalizedString(@"New listings are notified by email that they have been added to a private list on Origon.", @"");
                } else {
                    footerContent = [NSString stringWithFormat:OLocalizedString(@"New list members are notified by email that they have been added to the list %@ on Origon.", @""), _origo.name];
                }
                
                id<OMember> minor = nil;
                
                if ([[self.entity ancestor] conformsToProtocol:@protocol(OMember)]) {
                    minor = [self.entity ancestor];
                }
                
                if (minor && ![minor guardians].count) {
                    if ([[OMeta m].user isJuvenile]) {
                        footerContent = [OLocalizedString(@"Before you can register a friend, you must register his or her guardians.", @"") stringByAppendingString:footerContent separator:kSeparatorParagraph];
                    } else {
                        footerContent = [OLocalizedString(@"Before you can register a minor, you must register his or her guardians.", @"") stringByAppendingString:footerContent separator:kSeparatorParagraph];
                    }
                }
            }
        } else if (![_member isJuvenile] || [_member isHousemateOfUser] || [_member isTeenOrOlder]) {
            if ([_member isActive]) {
                footerContent = [NSString stringWithFormat:OLocalizedString(@"%@ is active on %@.", @""), [_member givenName], [OMeta m].appName];
            }
        }
    }
    
    return footerContent;
}


- (BOOL)toolbarHasSendTextButton
{
    return [_member textRecipients].count > 0;
}


- (BOOL)toolbarHasCallButton
{
    return [_member callRecipients].count > 0;
}


- (BOOL)toolbarHasSendEmailButton
{
    return [_member emailRecipients].count > 0;
}


- (BOOL)canCompareObjectsInSectionWithKey:(NSInteger)sectionKey
{
    return sectionKey == kSectionKeyGuardians;
}


- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2
{
    NSComparisonResult result;
    
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
    if ([self sectionKeyForIndexPath:indexPath] == kSectionKeyRoles) {
        _role = [self dataAtIndexPath:indexPath];
        _roleCell = cell;
        
        OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:nil];
        [actionSheet addButtonWithTitle:OLocalizedString(@"Edit responsibility", @"") action:^{
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
            [self editInlineInCell:self->_roleCell];
        }];
        [actionSheet showWithCancelAction:^{
            [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
        }];
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


- (void)deleteCellAtIndexPath:(NSIndexPath *)indexPath
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
            shouldRelay = [_member guardians].count ? NO : viewController.didCancel;
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
            if (!viewController.didCancel) {
                [OAlert showAlertWithTitle:OLocalizedString(@"Activation failed", @"")
                                   message:[NSString stringWithFormat:OLocalizedString(@"The email address %@ could not be activated ...", @""),
                                                   self->_emailField.value]];
            }
            
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


- (void)didFinishEditingInlineField:(OInputField *)inlineField
{
    NSString *editedRole = inlineField.value;
    
    if (self.didCancel) {
        inlineField.value = _role;
    } else if (![editedRole isEqualToString:_role]) {
        NSString *roleType = [_roleMembership typeOfAffiliation:_role];
        
        [_roleMembership addAffiliation:editedRole ofType:roleType];
        [_roleMembership removeAffiliation:_role ofType:roleType];
        
        _role = editedRole;
    }
}


- (void)onlineStatusDidChange
{
    [self enableOrDisableButtons];
}


- (void)didToggleEditMode
{
    if ([_member isHousemateOfUser] && !self.isModal) {
        self.title = nil;
        
        if (!_member.dateOfBirth) {
            if ([self actionIs:kActionEdit]) {
                self.title = OLocalizedString(@"Complete registration", @"");
            } else if ([self actionIs:kActionDisplay]) {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    }
}


#pragma mark - OTitleViewDelegate conformance

- (void)didFinishEditingTitleView:(OTitleView *)titleView
{
    [super didFinishEditingTitleView:titleView];
    
    _role = titleView.title;
}


#pragma mark - OInputCellDelegate conformance

- (OInputCellBlueprint *)inputCellBlueprint
{
    OInputCellBlueprint *blueprint = [[OInputCellBlueprint alloc] init];
    blueprint.titleKey = [self nameKey];
    blueprint.detailKeys = @[kPropertyKeyDateOfBirth, kPropertyKeyMobilePhone, kPropertyKeyEmail];

    // LATER: Introduce photos
    // blueprint.hasPhoto = _member.photo || ([self aspectIs:kAspectHousehold] && [_member userCanEdit]);
    
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
        isValid = isValid && [_emailField hasValidValue];
    } else {
        if ([self targetIs:kTargetJuvenile]) {
            isValid = [_nameField.value hasValue];
        } else {
            isValid = [_nameField hasValidValue];
        }
        
        if (isValid && _dateOfBirthField) {
            isValid = [_dateOfBirthField hasValidValue];
        }
        
        if (isValid && _mobilePhoneField.value) {
            isValid = [_mobilePhoneField hasValidValue];
        }
        
        if (isValid) {
            if (_emailField.value) {
                isValid = [_emailField hasValidValue] && [self isUniqueEmail:_emailField.value];
            } else {
                isValid = ![_member.email hasValue];
            }
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
            if ([_origo isResidence]) {
                [self examineMember];
            } else {
                [self examinerDidFinishExamination];
            }
        } else {
            if (_emailField.value) {
                [[OConnection connectionWithDelegate:self] lookupMemberWithEmail:_emailField.value];
            } else {
                [self examineMember];
            }
        }
    } else if ([self actionIs:kActionEdit]) {
        if ([_member.email hasValue] && ![_emailField.value isEqualToString:_member.email]) {
            [self presentEmailChangeAlert];
        } else {
            [self persistMember];
            [self toggleEditMode];
        }
    }
}


- (BOOL)isDisplayableFieldWithKey:(NSString *)key
{
    BOOL isDisplayable = [key isEqualToString:[self nameKey]] || [self aspectIs:kAspectHousehold];
    
    if (!isDisplayable) {
        if ([key isEqualToString:kPropertyKeyDateOfBirth]) {
            if ([_member hasValueForKey:kPropertyKeyDateOfBirth]) {
                isDisplayable = [_member isJuvenile] || [_member isHousemateOfUser];
            }
        } else if ([[OMeta m].user isJuvenile]) {
            isDisplayable = YES;
        } else if ([self actionIs:kActionRegister]) {
            isDisplayable = ![self targetIs:kTargetJuvenile];
        } else {
            isDisplayable = [_member isTeenOrOlder];
        }
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
    if ([self actionIs:kActionRegister]) {
        self.returnData = entity;
        
        if (!_membership && ![self targetIs:kTargetGuardian]) {
            _membership = [_origo addMember:_member];
        }
        
        if (_cachedResidencesById.count && ![_member isActive]) {
            for (id<OOrigo> residence in [_member residences]) {
                id<OOrigo> cachedResidence = _cachedResidencesById[residence.entityId];
                
                if (!residence.telephone && cachedResidence.telephone) {
                    residence.telephone = cachedResidence.telephone;
                }
            }
        }
    }
}


#pragma mark - OMemberExaminerDelegate conformance

- (void)examinerDidFinishExamination
{
    if ([_origo isCommunity] && ![_member hasAddress]) {
        [self toggleEditMode];
        [self presentModalViewControllerWithIdentifier:kIdentifierOrigo target:[_member primaryResidence]];
    } else {
        [self persistMember];
    }
}


- (void)examinerDidCancelExamination
{
    [self.inputCell resumeFirstResponder];
}


#pragma mark - OConnectionDelegate conformance

- (void)connection:(OConnection *)connection didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    [super connection:connection didCompleteWithResponse:response data:data];
    
    if ([self actionIs:kActionRegister]) {
        if (response.statusCode == kHTTPStatusOK) {
            id actualMember = nil;
            
            for (NSDictionary *entityDictionary in data) {
                if ([[entityDictionary allKeys] containsObject:kPropertyKeyEmail]) {
                    if ([entityDictionary[kPropertyKeyEmail] isEqualToString:_emailField.value]) {
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
                    NSArray *residences = [_member residences];
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
                    
                    if (unmatchedResidences.count) {
                        [self presentAlertForNumberOfUnmatchedResidences:unmatchedResidences.count];
                    }
                }
                
                [self reflectMember:actualMember];
                [self examinerDidFinishExamination];
            } else {
                [OAlert showAlertWithTitle:OLocalizedString(@"Incorrect details", @"") message:OLocalizedString(@"The details you have provided do not match our records ...", @"")];
                
                [self.inputCell resumeFirstResponder];
            }
        } else if (response.statusCode == kHTTPStatusNotFound) {
            [self examineMember];
        }
    } else if ([self actionIs:kActionEdit]) {
        if (response.statusCode == kHTTPStatusOK) {
            [OAlert showAlertWithTitle:OLocalizedString(@"Address in use", @"") message:[NSString stringWithFormat:OLocalizedString(@"The email address %@ is already in use.", @""), _emailField.value]];
            
            [_emailField becomeFirstResponder];
        } else if (response.statusCode == kHTTPStatusNotFound) {
            if ([_member isUser]) {
                [self toggleEditMode];
                [self presentModalViewControllerWithIdentifier:kIdentifierAuth target:_emailField.value];
            } else {
                [self persistMember];
                [self toggleEditMode];
            }
        }
    }
}


#pragma mark - CNContactPickerDelegate conformance

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContact:(CNContact *)contact
{
    [self retrieveNameFromContact:contact];
    [self retrievePhoneNumbersFromContact:contact];
    [self retrieveEmailAddressesFromContact:contact];
    
    if (![_mobilePhoneField hasMultiValue] && ![_emailField hasMultiValue]) {
        [self performLocalLookup];
    }
    
    if ([_member instance]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self retrieveAddressesFromContact:contact];
        
        if ([_mobilePhoneField hasMultiValue] || [_emailField hasMultiValue]) {
            [self dismissViewControllerAnimated:YES completion:^{
                [self refineAddressBookContactInfo];
            }];
        } else {
            if (_contactAddresses.count || _contactHomeNumbers.count) {
                [self dismissViewControllerAnimated:YES completion:^{
                    [self refineAddressBookAddressInfo];
                }];
            } else {
                [self reflectMember:_member];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
    }
}


- (void)contactPickerDidCancel:(CNContactPickerViewController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.inputCell resumeFirstResponder];
    }];
}

@end
