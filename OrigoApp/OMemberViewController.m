//
//  OMemberViewController.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OMemberViewController.h"

#import "NSDate+OrigoExtensions.h"
#import "NSManagedObjectContext+OrigoExtensions.h"
#import "NSString+OrigoExtensions.h"
#import "UIBarButtonItem+OrigoExtensions.h"

#import "OAlert.h"
#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextField.h"
#import "OUtil.h"

#import "OMember+OrigoExtensions.h"
#import "OMembership.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"

static NSString * const kSegueToMemberListView = @"segueFromMemberToMemberListView";

static NSInteger const kMemberSectionKey = 0;
static NSInteger const kAddressSectionKey = 1;

static NSInteger const kGenderSheetTag = 0;
static NSInteger const kGenderSheetButtonFemale = 0;
static NSInteger const kGenderSheetButtonCancel = 2;

static NSInteger const kResidenceSheetTag = 1;

static NSInteger const kExistingResidenceSheetTag = 2;
static NSInteger const kExistingResidenceButtonInviteToHousehold = 0;
static NSInteger const kExistingResidenceButtonMergeHouseholds = 1;
static NSInteger const kExistingResidenceButtonCancel = 2;

static NSInteger const kEmailChangeAlertTag = 3;
static NSInteger const kEmailChangeButtonContinue = 1;


@implementation OMemberViewController

#pragma mark - Auxiliary methods

- (BOOL)emailIsEligible
{
    BOOL emailIsEligible = [self.detailCell hasValidValueForKey:kPropertyKeyEmail];
    
    if (emailIsEligible && [self actionIs:kActionRegister] && ![self targetIs:kTargetUser]) {
        NSString *email = [_emailField textValue];
        
        _candidate = [[OMeta m].context memberEntityWithEmail:email];
        
        if (_candidate) {
            if ([_origo hasMember:_candidate]) {
                _emailField.text = @"";
                [_emailField becomeFirstResponder];
                
                NSString *alertTitle = [OStrings stringForKey:strAlertTitleMemberExists];
                NSString *alertMessage = [NSString stringWithFormat:[OStrings stringForKey:strAlertTextMemberExists], _candidate.name, email, _origo.name];
                [OAlert showAlertWithTitle:alertTitle text:alertMessage];
                
                _candidate = nil;
                emailIsEligible = NO;
            } else {
                _mobilePhoneField.text = _candidate.mobilePhone;
                _dateOfBirthField.date = _candidate.dateOfBirth;
                _dateOfBirthField.text = [_candidate.dateOfBirth localisedDateString];
                _gender = _candidate.gender;
                
                if ([_candidate isActive]) {
                    self.detailCell.editing = NO;
                }
            }
        }
    }
    
    return emailIsEligible;
}


- (void)persistMember
{
    [self.detailCell writeEntity];
    
    if ([self actionIs:kActionRegister]) {
        if ([self targetIs:kTargetUser] && ![_origo hasValueForKey:kPropertyKeyAddress]) {
            [self presentModalViewWithIdentifier:kViewIdOrigo data:_membership dismisser:self.dismisser];
        } else {
            [self.dismisser dismissModalViewController];
        }
    }
}


#pragma mark - Alerts & action sheets

- (void)promptForGender
{
    NSString *sheetQuestion = nil;
    NSString *femaleLabel = nil;
    NSString *maleLabel = nil;
    
    if ([_dateOfBirthField.date isBirthDateOfMinor]) {
        if ([self targetIs:kTargetUser]) {
            sheetQuestion = [OStrings stringForKey:strSheetTitleGenderSelfMinor];
        } else {
            sheetQuestion = [NSString stringWithFormat:[OStrings stringForKey:strSheetTitleGenderMinor], [OUtil givenNameFromFullName:[_nameField textValue]]];
        }
        
        femaleLabel = [OStrings stringForKey:strTermFemaleMinor];
        maleLabel = [OStrings stringForKey:strTermMaleMinor];
    } else {
        if ([self targetIs:kTargetUser]) {
            sheetQuestion = [OStrings stringForKey:strSheetTitleGenderSelf];
        } else {
            sheetQuestion = [NSString stringWithFormat:[OStrings stringForKey:strSheetTitleGenderMember], [OUtil givenNameFromFullName:[_nameField textValue]]];
        }
        
        femaleLabel = [OStrings stringForKey:strTermFemale];
        maleLabel = [OStrings stringForKey:strTermMale];
    }
    
    UIActionSheet *genderSheet = [[UIActionSheet alloc] initWithTitle:sheetQuestion delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonCancel] destructiveButtonTitle:nil otherButtonTitles:femaleLabel, maleLabel, nil];
    genderSheet.tag = kGenderSheetTag;
    
    [genderSheet showInView:self.view];
}


- (void)promptForResidence:(NSSet *)housemateResidences
{
    _candidateResidences = [housemateResidences sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:kPropertyKeyAddress ascending:YES]]];
    
    UIActionSheet *residenceSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    for (OOrigo *residence in _candidateResidences) {
        [residenceSheet addButtonWithTitle:[residence.address lines][0]];
    }
    
    [residenceSheet addButtonWithTitle:[OStrings stringForKey:strButtonNewAddress]];
    [residenceSheet addButtonWithTitle:[OStrings stringForKey:strButtonCancel]];
    residenceSheet.cancelButtonIndex = [housemateResidences count] + 1;
    residenceSheet.tag = kResidenceSheetTag;
    
    [residenceSheet showInView:self.view];
}


- (void)promptForExistingResidenceAction
{
    NSString *sheetQuestion = [NSString stringWithFormat:[OStrings stringForKey:strSheetTitleExistingResidence], _candidate.name, _candidate.givenName];
    
    UIActionSheet *existingResidenceSheet = [[UIActionSheet alloc] initWithTitle:sheetQuestion delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonCancel] destructiveButtonTitle:nil otherButtonTitles:[OStrings stringForKey:strButtonInviteToHousehold], [OStrings stringForKey:strButtonMergeHouseholds], nil];
    existingResidenceSheet.tag = kExistingResidenceSheetTag;
    
    [existingResidenceSheet showInView:self.view];
}


- (void)promptForUserEmailChangeConfirmation
{
    UIAlertView *emailChangeAlert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleUserEmailChange] message:[NSString stringWithFormat:[OStrings stringForKey:strAlertTextUserEmailChange], _member.email, [_emailField textValue]] delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonCancel] otherButtonTitles:[OStrings stringForKey:strButtonContinue], nil];
    emailChangeAlert.tag = kEmailChangeAlertTag;
    
    [emailChangeAlert show];
}


- (void)promptForMemberEmailChangeConfirmation
{
    // TODO
}


#pragma mark - Selector implementations

- (void)addResidence
{
    NSSet *housemateResidences = [_member housemateResidences];
    
    if ([housemateResidences count]) {
        [self promptForResidence:housemateResidences];
    } else {
        [self presentModalViewWithIdentifier:kViewIdOrigo data:_member meta:kOrigoTypeResidence];
    }
}


- (void)signOut
{
    [[OMeta m] userDidSignOut];
    
    [self.dismisser dismissModalViewController];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    if ([self targetIs:kTargetUser]) {
        self.title = [OStrings stringForKey:strViewTitleAboutMe];
    } else if (_member) {
        self.title = _member.givenName;
    } else if ([self actionIs:kActionRegister]) {
        if ([_origo isOfType:kOrigoTypeResidence]) {
            self.title = [OStrings stringForKey:strViewTitleNewHouseholdMember];
        } else {
            self.title = [OStrings stringForKey:strViewTitleNewMember];
        }
    }
    
    if ([self actionIs:kActionDisplay]) {
        if ([self canEdit]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem addButtonWithTarget:self];
            self.navigationItem.rightBarButtonItem.action = @selector(addResidence);
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _nameField = [self.detailCell textFieldForKey:kPropertyKeyName];
    _dateOfBirthField = [self.detailCell textFieldForKey:kPropertyKeyDateOfBirth];
    _mobilePhoneField = [self.detailCell textFieldForKey:kPropertyKeyMobilePhone];
    _emailField = [self.detailCell textFieldForKey:kPropertyKeyEmail];
    _gender = _member.gender;
}


#pragma mark - OTableViewController overrides

- (BOOL)canEdit
{
    BOOL isUserAndTeenOrOlder = ([_member isUser] && [_member isTeenOrOlder]);
    BOOL isWardOfUser = [[[OMeta m].user wards] containsObject:_member];
    BOOL userIsAdminOrCreator = ([_origo userIsAdmin] || [_origo userIsCreator]);
    
    return (isUserAndTeenOrOlder || isWardOfUser || (![_member isActive] && userIsAdminOrCreator));
}


- (BOOL)cancelRegistrationImpliesSignOut
{
    return [self targetIs:kTargetUser];
}


#pragma mark - UIViewController overrides

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueToMemberListView]) {
        if ([self actionIs:kActionRegister]) {
            [self prepareForPushSegue:segue data:_membership];
            [segue.destinationViewController setDismisser:self.dismisser];
        } else {
            [self prepareForPushSegue:segue];
        }
    }
}


#pragma mark - OTableViewControllerInstance conformance

- (void)initialise
{
    if ([self.data isKindOfClass:OMembership.class]) {
        _membership = self.data;
        _member = _membership.member;
        _origo = _membership.origo;
    } else if ([self.data isKindOfClass:OOrigo.class]) {
        _origo = self.data;
    }
    
    self.target = _member ? _member : _origo;
}


- (void)populateDataSource
{
    id memberDataSource = _member ? _member : kCustomCell;
    
    [self setData:memberDataSource forSectionWithKey:kMemberSectionKey];
    
    if ([self actionIs:kActionDisplay]) {
        [self setData:[_member residencies] forSectionWithKey:kAddressSectionKey];
    }
}


- (BOOL)hasFooterForSectionWithKey:(NSInteger)sectionKey
{
    return ([super hasFooterForSectionWithKey:sectionKey] && [self canEdit]);
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kAddressSectionKey) {
        if ([[_member residencies] count] == 1) {
            text = [OStrings stringForKey:strTermAddress];
        } else {
            text = [OStrings stringForKey:strHeaderAddresses];
        }
    }
    
    return text;
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    return [OStrings stringForKey:strFooterMember];
}


- (void)didSelectCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:kSegueToMemberListView sender:self];
}


- (BOOL)inputIsValid
{
    BOOL inputIsValid = YES;
    
    inputIsValid = inputIsValid && [self.detailCell hasValidValueForKey:kPropertyKeyName];
    inputIsValid = inputIsValid && [self.detailCell hasValidValueForKey:kPropertyKeyDateOfBirth];
    
    if (inputIsValid) {
        if ([self targetIs:kTargetUser] || ![_dateOfBirthField.date isBirthDateOfMinor]) {
            inputIsValid = [self emailIsEligible] && [self.detailCell hasValidValueForKey:kPropertyKeyMobilePhone];
        } else if ([_dateOfBirthField.date isBirthDateOfMinor]) {
            if ([self.detailCell hasValueForKey:kPropertyKeyEmail]) {
                inputIsValid = [self.detailCell hasValidValueForKey:kPropertyKeyEmail];
            }
        }
    }
    
    return  inputIsValid;
}


- (void)processInput
{
    if ([self actionIs:kActionRegister]) {
        if (_candidate) {
            if ([_origo isOfType:kOrigoTypeResidence] && [_candidate.residencies count]) {
                [self promptForExistingResidenceAction];
            } else {
                [self persistMember];
            }
        } else {
            if (!_gender) {
                [self promptForGender];
            } else {
                [self persistMember];
            }
        }
    } else if ([self actionIs:kActionEdit]) {
        if ([_member hasValueForKey:kPropertyKeyEmail] && ![[_emailField textValue] isEqualToString:_member.email]) {
            if ([self targetIs:kTargetUser]) {
                [self promptForUserEmailChangeConfirmation];
            } else {
                [self promptForMemberEmailChangeConfirmation];
            }
        } else {
            [self persistMember];
            [self toggleEditMode];
        }
    }
}


#pragma mark - OTableViewInputDelegate conformance

- (id)targetEntity
{
    if (_candidate) {
        _member = _candidate;
    } else {
        _member = [[OMeta m].context insertMemberEntity];
    }
    
    if (!_membership) {
        _membership = [_origo addMember:_member];
    }
    
    return _member;
}


- (NSDictionary *)additionalInputValues
{
    NSMutableDictionary *additionalValues = [[NSMutableDictionary alloc] init];
    
    additionalValues[kPropertyKeyGender] = _gender;
    additionalValues[kPropertyKeyGivenName] = [OUtil givenNameFromFullName:_member.name];
    
    return additionalValues;
}


#pragma mark - OTableViewListCellDelegate conformance

- (void)populateListCell:(OTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.text = [[[self dataAtIndexPath:indexPath] origo].address lines][0];
    cell.imageView.image = [UIImage imageNamed:kIconFileHousehold];
}


#pragma mark - OModalViewControllerDelegate conformance

- (void)dismissModalViewControllerWithIdentifier:(NSString *)identifier
{
    if ([identifier isEqualToString:kViewIdAuth]) {
        [super dismissModalViewControllerWithIdentifier:identifier needsReloadData:NO];
        
        if ([_member.email isEqualToString:[_emailField textValue]]) {
            [OMeta m].userEmail = _member.email;
            [self persistMember];
        } else {
            UIAlertView *failedEmailChangeAlert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleEmailChangeFailed] message:[NSString stringWithFormat:[OStrings stringForKey:strAlertTextEmailChangeFailed], [_emailField textValue]] delegate:nil cancelButtonTitle:[OStrings stringForKey:strButtonOK] otherButtonTitles:nil];
            [failedEmailChangeAlert show];
            
            [self toggleEditMode];
            [_emailField becomeFirstResponder];
        }
    } else if ([identifier isEqualToString:kViewIdOrigo]) {
        [self.dismisser dismissModalViewController];
    } else if ([identifier isEqualToString:kViewIdMemberList]) {
        [super dismissModalViewControllerWithIdentifier:identifier];
    }
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case kGenderSheetTag:
            if (buttonIndex != kGenderSheetButtonCancel) {
                _gender = (buttonIndex == kGenderSheetButtonFemale) ? kGenderFemale : kGenderMale;
                [self persistMember];
            } else {
                [self resumeFirstResponder];
            }
            
            break;
            
        case kResidenceSheetTag:
            if (buttonIndex == actionSheet.numberOfButtons - 2) {
                [self presentModalViewWithIdentifier:kViewIdOrigo data:_member meta:kOrigoTypeResidence];
            } else if (buttonIndex < actionSheet.numberOfButtons - 2) {
                [_candidateResidences[buttonIndex] addMember:_member];
                [self reloadSectionsIfNeeded];
            }
            
            break;
            
        case kExistingResidenceSheetTag:
            if (buttonIndex == kExistingResidenceButtonInviteToHousehold) {
                [self persistMember];
            } else if (buttonIndex == kExistingResidenceButtonMergeHouseholds) {
                // TODO
            } else if (buttonIndex == kExistingResidenceButtonCancel) {
                [self resumeFirstResponder];
            }
            
            break;
            
        default:
            break;
    }
}


#pragma mark - UIAlertViewDelegate conformance

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case kEmailChangeAlertTag:
            if (buttonIndex == kEmailChangeButtonContinue) {
                [self toggleEditMode];
                [self presentModalViewWithIdentifier:kViewIdAuth data:[_emailField textValue]];
            } else {
                [_emailField becomeFirstResponder];
            }
            
            break;
            
        default:
            break;
    }
}

@end
