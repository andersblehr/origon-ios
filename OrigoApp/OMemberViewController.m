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
#import "UITableView+OrigoExtensions.h"

#import "OEntityObservingDelegate.h"

#import "OAlert.h"
#import "OLogging.h"
#import "OMeta.h"
#import "OServerConnection.h"
#import "OState.h"
#import "OStrings.h"
#import "OTableViewCell.h"
#import "OTextField.h"

#import "OMember+OrigoExtensions.h"
#import "OMemberResidency+OrigoExtensions.h"
#import "OMembership+OrigoExtensions.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"

#import "OAuthViewController.h"
#import "OMemberListViewController.h"
#import "OOrigoViewController.h"
#import "OTabBarController.h"

static NSString * const kModalSegueToAuthView = @"modalFromMemberToAuthView";
static NSString * const kModalSegue1ToOrigoView = @"modal1FromMemberToOrigoView";
static NSString * const kModalSegue2ToOrigoView = @"modal2FromMemberToOrigoView";
static NSString * const kPushSegueToMemberListView = @"pushFromMemberToMemberListView";

static NSInteger const kMemberSection = 0;
static NSInteger const kAddressSection = 1;

static NSInteger const kGenderSheetTag = 0;
static NSInteger const kGenderSheetButtonFemale = 0;
static NSInteger const kGenderSheetButtonCancel = 2;

static NSInteger const kAddressReuseSheetTag = 1;

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
    BOOL emailIsEligible = [_emailField holdsValidEmail];
    
    if (emailIsEligible && self.state.actionIsRegister && !self.state.aspectIsSelf) {
        NSString *email = [_emailField finalText];
        
        _candidate = [[OMeta m].context memberEntityWithEmail:email];
        
        if (_candidate) {
            if ([_origo hasMember:_candidate]) {
                _emailField.text = @"";
                [_emailField becomeFirstResponder];
                
                NSString *alertTitle = [OStrings stringForKey:strAlertTitleMemberExists];
                NSString *alertMessage = [NSString stringWithFormat:[OStrings stringForKey:strAlertTextMemberExists], _candidate.name, email, _origo.name];
                [OAlert showAlertWithTitle:alertTitle message:alertMessage];
                
                _candidate = nil;
                emailIsEligible = NO;
            } else {
                _mobilePhoneField.text = _candidate.mobilePhone;
                _dateOfBirthField.date = _candidate.dateOfBirth;
                _dateOfBirthField.text = [_candidate.dateOfBirth localisedDateString];
                _gender = _candidate.gender;
                
                if (_candidate.activeSince) {
                    self.detailCell.editing = NO;
                }
            }
        }
    }
    
    return emailIsEligible;
}


- (void)registerMember
{
    if (!_member) {
        if (_candidate) {
            _member = _candidate;
        } else {
            _member = [[OMeta m].context insertMemberEntityWithEmail:[_emailField finalText]];
        }
    }
    
    if (!_membership) {
        if ([_origo isResidence]) {
            _membership = [_origo addResident:_member];
        } else {
            _membership = [_origo addMember:_member];
        }
    }
    
    [self updateMember];
}


- (void)updateMember
{
    _member.name = [_nameField finalText];
    _member.dateOfBirth = [_dateOfBirthField date];
    _member.mobilePhone = [_mobilePhoneField finalText];
    _member.email = [_emailField finalText];
    
    if (self.state.actionIsRegister) {
        _member.givenName = [NSString givenNameFromFullName:_member.name];
        _member.gender = _gender;
        
        if (self.state.aspectIsSelf && ![_origo hasAddress]) {
            [self performSegueWithIdentifier:kModalSegue1ToOrigoView sender:self];
        } else {
            if (self.state.aspectIsSelf && [_origo hasAddress]) {
                _member.activeSince = [NSDate date];
            }
            
            [self.dismisser dismissModalViewControllerWithIdentitifier:kMemberViewControllerId];
        }
    }
}


#pragma mark - Action sheets

- (void)promptForGender
{
    NSString *sheetQuestion = nil;
    NSString *femaleLabel = nil;
    NSString *maleLabel = nil;
    
    if ([_dateOfBirthField.date isBirthDateOfMinor]) {
        if (self.state.aspectIsSelf) {
            sheetQuestion = [OStrings stringForKey:strSheetTitleGenderSelfMinor];
        } else {
            sheetQuestion = [NSString stringWithFormat:[OStrings stringForKey:strSheetTitleGenderMinor], [NSString givenNameFromFullName:[_nameField finalText]]];
        }
        
        femaleLabel = [OStrings stringForKey:strTermFemaleMinor];
        maleLabel = [OStrings stringForKey:strTermMaleMinor];
    } else {
        if (self.state.aspectIsSelf) {
            sheetQuestion = [OStrings stringForKey:strSheetTitleGenderSelf];
        } else {
            sheetQuestion = [NSString stringWithFormat:[OStrings stringForKey:strSheetTitleGenderMember], [NSString givenNameFromFullName:[_nameField finalText]]];
        }
        
        femaleLabel = [OStrings stringForKey:strTermFemale];
        maleLabel = [OStrings stringForKey:strTermMale];
    }
    
    UIActionSheet *genderSheet = [[UIActionSheet alloc] initWithTitle:sheetQuestion delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonCancel] destructiveButtonTitle:nil otherButtonTitles:femaleLabel, maleLabel, nil];
    genderSheet.tag = kGenderSheetTag;
    
    [genderSheet showInView:self.view];
}


- (void)promptForAddressReuse:(NSSet *)housemateResidences
{
    _candidateResidences = [housemateResidences sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:kKeyPathAddress ascending:YES]]];
    
    UIActionSheet *residenceSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    for (OOrigo *residence in _candidateResidences) {
        [residenceSheet addButtonWithTitle:[residence.address lines][0]];
    }
    
    [residenceSheet addButtonWithTitle:[OStrings stringForKey:strButtonNewAddress]];
    [residenceSheet addButtonWithTitle:[OStrings stringForKey:strButtonCancel]];
    residenceSheet.cancelButtonIndex = [housemateResidences count] + 1;
    residenceSheet.tag = kAddressReuseSheetTag;
    
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
    UIAlertView *emailChangeAlert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleUserEmailChange] message:[NSString stringWithFormat:[OStrings stringForKey:strAlertTextUserEmailChange], _member.email, [_emailField finalText]] delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonCancel] otherButtonTitles:[OStrings stringForKey:strButtonContinue], nil];
    emailChangeAlert.tag = kEmailChangeAlertTag;
    
    [emailChangeAlert show];
}


- (void)promptForMemberEmailChangeConfirmation
{
    
}


#pragma mark - Selector implementations

- (void)didCancelEditing
{
    if (self.state.actionIsRegister) {
        [self.dismisser dismissModalViewControllerWithIdentitifier:kMemberViewControllerId needsReloadData:NO];
    } else if (self.state.actionIsEdit) {
        _dateOfBirthField.text = [_member.dateOfBirth localisedDateString];
        _mobilePhoneField.text = _member.mobilePhone;
        _emailField.text = _member.email;
        
        [self toggleEditMode];
    }
}


- (void)didFinishEditing
{
    BOOL inputIsValid = ([_nameField holdsValidName] && [_dateOfBirthField holdsValidDate]);
    
    if (inputIsValid) {
        if (self.state.aspectIsSelf || ![_dateOfBirthField.date isBirthDateOfMinor]) {
            inputIsValid = inputIsValid && [self emailIsEligible];
            inputIsValid = inputIsValid && [_mobilePhoneField holdsValidPhoneNumber];
        } else if ([_dateOfBirthField.date isBirthDateOfMinor]) {
            if ([[_emailField finalText] length] > 0) {
                inputIsValid = inputIsValid && [_emailField holdsValidEmail];
            }
        }
    }
    
    if (inputIsValid) {
        if (self.state.actionIsRegister) {
            [self.view endEditing:YES];
            
            if (_candidate) {
                if ([_origo isResidence] && [_candidate.residencies count]) {
                    [self promptForExistingResidenceAction];
                } else {
                    [self registerMember];
                }
            } else {
                if (!_gender) {
                    [self promptForGender];
                } else {
                    [self updateMember];
                }
            }
        } else if (self.state.actionIsEdit) {
            if ([_member hasEmail] && ![[_emailField finalText] isEqualToString:_member.email]) {
                if (self.state.aspectIsSelf) {
                    [self promptForUserEmailChangeConfirmation];
                } else {
                    [self promptForMemberEmailChangeConfirmation];
                }
            } else {
                [self updateMember];
                [self toggleEditMode];
            }
        }
    } else {
        [self.detailCell shakeCellVibrateDevice:NO];
    }
}


- (void)addResidence
{
    NSSet *housemateResidences = [_member housemateResidences];
    
    if ([housemateResidences count] > 0) {
        [self promptForAddressReuse:housemateResidences];
    } else {
        [self performSegueWithIdentifier:kModalSegue2ToOrigoView sender:self];
    }
}


- (void)signOut
{
    [[OMeta m] userDidSignOut];
    self.detailCell.entity = nil;
    
    [self.dismisser dismissModalViewControllerWithIdentitifier:kMemberViewControllerId];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.state.aspectIsSelf) {
        self.title = [OStrings stringForKey:strViewTitleAboutMe];
    } else if (_member) {
        self.title = _member.givenName;
    } else if (self.state.actionIsRegister) {
        if ([_origo isResidence]) {
            self.title = [OStrings stringForKey:strViewTitleNewHouseholdMember];
        } else {
            self.title = [OStrings stringForKey:strViewTitleNewMember];
        }
    }
    
    if (self.state.actionIsDisplay) {
        if ([self canEdit]) {
            self.navigationItem.rightBarButtonItem = [UIBarButtonItem addButtonWithTarget:self];
            self.navigationItem.rightBarButtonItem.action = @selector(addResidence);
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _nameField = [self.detailCell textFieldForKeyPath:kKeyPathName];
    _dateOfBirthField = [self.detailCell textFieldForKeyPath:kKeyPathDateOfBirth];
    _mobilePhoneField = [self.detailCell textFieldForKeyPath:kKeyPathMobilePhone];
    _emailField = [self.detailCell textFieldForKeyPath:kKeyPathEmail];
    _gender = _member.gender;
    
    OLogState;
}


#pragma mark - OTableViewController overrides

- (BOOL)canEdit
{
    BOOL memberIsUserAndTeen = ([_member isUser] && [_member isTeenOrOlder]);
    BOOL memberIsWardOfUser = [[[OMeta m].user wards] containsObject:_member];
    BOOL membershipIsInactiveAndUserIsAdmin = ([_origo userIsAdmin] && ![_membership.isActive boolValue]);
    
    return (memberIsUserAndTeen || memberIsWardOfUser || membershipIsInactiveAndUserIsAdmin);
}


- (UIBarButtonItem *)cancelRegistrationButton
{
    UIBarButtonItem *cancelButton = [UIBarButtonItem cancelButtonWithTarget:self];
    
    if (self.state.aspectIsSelf) {
        cancelButton = [UIBarButtonItem signOutButtonWithTarget:self];
    }
    
    return cancelButton;
}


#pragma mark - UIViewController overrides

- (BOOL)hidesBottomBarWhenPushed
{
    return YES;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kModalSegueToAuthView]) {
        [self prepareForModalSegue:segue data:[_emailField finalText]];
    } else if ([segue.identifier isEqualToString:kModalSegue1ToOrigoView]) {
        [self prepareForModalSegue:segue data:_membership];
    } else if ([segue.identifier isEqualToString:kModalSegue2ToOrigoView]) {
        [self prepareForModalSegue:segue data:_member meta:kOrigoTypeResidence];
    } else if ([segue.identifier isEqualToString:kPushSegueToMemberListView]) {
        if (self.state.actionIsRegister) {
            [self prepareForPushSegue:segue data:_membership];
            [segue.destinationViewController setDismisser:self.dismisser];
        } else {
            [self prepareForPushSegue:segue];
        }
    }
}


#pragma mark - OTableViewControllerDelegate conformance

- (void)digestInput
{
    if ([self.data isKindOfClass:OMembership.class]) {
        _membership = self.data;
        _member = _membership.member;
        _origo = _membership.origo;
    } else if ([self.data isKindOfClass:OOrigo.class]) {
        _origo = self.data;
    }
    
    self.aspectCarrier = _member ? _member : _origo;
}


- (void)populateDataSource
{
    [self setData:_member forSectionWithKey:kMemberSection];
    
    if (self.state.actionIsDisplay) {
        [self setData:_member.residencies forSectionWithKey:kAddressSection];
    }
}


- (NSString *)textForHeaderInSectionWithKey:(NSInteger)sectionKey
{
    NSString *text = nil;
    
    if (sectionKey == kAddressSection) {
        if ([_member.residencies count] == 1) {
            text = [OStrings stringForKey:strTermAddress];
        } else {
            text = [OStrings stringForKey:strHeaderAddresses];
        }
    }
    
    return text;
}


- (NSString *)textForFooterInSectionWithKey:(NSInteger)sectionKey
{
    return nil;
}


- (void)didSelectRow:(NSInteger)row inSectionWithKey:(NSInteger)sectionKey
{
    [self performSegueWithIdentifier:kPushSegueToMemberListView sender:self];
}


#pragma mark - OModalViewControllerDelegate conformance

- (void)dismissModalViewControllerWithIdentitifier:(NSString *)identitifier
{
    if ([identitifier isEqualToString:kAuthViewControllerId]) {
        [super dismissModalViewControllerWithIdentitifier:identitifier needsReloadData:NO];
        
        if ([_member.email isEqualToString:[_emailField finalText]]) {
            [OMeta m].userEmail = _member.email;
            [self updateMember];
        } else {
            UIAlertView *failedEmailChangeAlert = [[UIAlertView alloc] initWithTitle:[OStrings stringForKey:strAlertTitleEmailChangeFailed] message:[NSString stringWithFormat:[OStrings stringForKey:strAlertTextEmailChangeFailed], [_emailField finalText]] delegate:nil cancelButtonTitle:[OStrings stringForKey:strButtonOK] otherButtonTitles:nil];
            [failedEmailChangeAlert show];
            
            [self toggleEditMode];
            [_emailField becomeFirstResponder];
        }
    } else if ([identitifier isEqualToString:kOrigoViewControllerId]) {
        [super dismissModalViewControllerWithIdentitifier:identitifier needsReloadData:NO];
        [self performSegueWithIdentifier:kPushSegueToMemberListView sender:self];
    } else if ([identitifier isEqualToString:kMemberListViewControllerId]) {
        [super dismissModalViewControllerWithIdentitifier:identitifier];
    }
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
        case kGenderSheetTag:
            if (buttonIndex != kGenderSheetButtonCancel) {
                _gender = (buttonIndex == kGenderSheetButtonFemale) ? kGenderFemale : kGenderMale;
                [self registerMember];
            } else {
                [self resumeFirstResponder];
            }
            
            break;
            
        case kAddressReuseSheetTag:
            if (buttonIndex == actionSheet.numberOfButtons - 2) {
                [self performSegueWithIdentifier:kModalSegue2ToOrigoView sender:self];
            } else if (buttonIndex < actionSheet.numberOfButtons - 2) {
                [_candidateResidences[buttonIndex] addResident:_member];
                [self reloadSectionsIfNeeded];
            }
            
            break;
            
        case kExistingResidenceSheetTag:
            if (buttonIndex == kExistingResidenceButtonInviteToHousehold) {
                [self registerMember];
            } else if (buttonIndex == kExistingResidenceButtonMergeHouseholds) {
                // TODO
            } else if (buttonIndex == kExistingResidenceButtonCancel) {
                [self resumeFirstResponder];
            }
            
            break;
            
        case kEmailChangeAlertTag:
            if (buttonIndex == kEmailChangeButtonContinue) {
                [self toggleEditMode];
                [self performSegueWithIdentifier:kModalSegueToAuthView sender:self];
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
                [self performSegueWithIdentifier:kModalSegueToAuthView sender:self];
            } else {
                [_emailField becomeFirstResponder];
            }
            
            break;
            
        default:
            break;
    }
}

@end
