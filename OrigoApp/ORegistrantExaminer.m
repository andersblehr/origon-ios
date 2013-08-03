//
//  ORegistrantExaminer.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "ORegistrantExaminer.h"

static NSInteger const kParentCandidateStatusUndetermined = 0x00;
static NSInteger const kParentCandidateStatusMother = 0x01;
static NSInteger const kParentCandidateStatusFather = 0x02;
static NSInteger const kParentCandidateStatusBoth = 0x03;

static NSInteger const kGenderSheetTag = 0;
static NSInteger const kGenderSheetButtonFemale = 0;

static NSInteger const kBothParentCandidatesSheetTag = 1;
static NSInteger const kBothParentCandidatesButtonYes = 0;
static NSInteger const kBothParentCandidatesButtonNo = 3;

static NSInteger const kAllOffspringCandidatesSheetTag = 2;
static NSInteger const kAllOffspringCandidatesButtonYes = 0;
static NSInteger const kAllOffspringCandidatesButtonSome = 1;

static NSInteger const kParentCandidateSheetTag = 3;
static NSInteger const kParentCandidateButtonYes = 0;

static NSInteger const kOffspringCandidateSheetTag = 4;
static NSInteger const kOffspringCandidateButtonYes = 0;


@implementation ORegistrantExaminer

#pragma mark - Auxiliary methods

- (NSInteger)parentCandidateStatusForMember:(OMember *)member
{
    return [member isMale] ? kParentCandidateStatusFather : kParentCandidateStatusMother;
}


- (void)assembleCandidates
{
    NSMutableArray *candidates = [[NSMutableArray alloc] init];
    
    for (OMembership *residency in [_residence residencies]) {
        if (_isMinor) {
            if ([residency.member.dateOfBirth yearsBeforeDate:_dateOfBirth] >= kAgeOfConsent) {
                [candidates addObject:residency.member];
                _parentCandidateStatus ^= [self parentCandidateStatusForMember:residency.member];
            }
            
            if ([candidates count] > 2) {
                _parentCandidateStatus = kParentCandidateStatusUndetermined;
            }
        } else if ([residency.member isMinor] && ![residency.member hasParentWithGender:_gender]) {
            if ([_dateOfBirth yearsBeforeDate:residency.member.dateOfBirth] >= kAgeOfConsent) {
                [candidates addObject:residency.member];
            }
        }
    }

    if ([candidates count]) {
        _candidates = [candidates sortedArrayUsingSelector:@selector(appellationCompare:)];
    }
}


- (NSString *)parentNounForGender:(NSString *)gender
{
    return [gender isEqualToString:kGenderMale] ? father : mother;
}


- (NSString *)candidate:(OMember *)parent parentLabelWithOffspringGender:(NSString *)gender
{
    NSString *stringKey = nil;
    
    if ([parent isMale]) {
        stringKey = [gender isEqualToString:kGenderMale] ? strTermHisFather : strTermHerFather;
    } else {
        stringKey = [gender isEqualToString:kGenderMale] ? strTermHisMother : strTermHerMother;
    }
    
    return [OStrings stringForKey:stringKey];
}


#pragma mark - Action sheets

- (void)presentGenderSheet
{
    id subject = [[OState s] targetIs:kTargetUser] ? [OMeta m].user : _givenName;
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[OLanguage questionWithSubject:subject verb:be argument:[OStrings stringForKey:_isMinor ? strQuestionArgumentGenderMinor : strQuestionArgumentGender]] delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonCancel] destructiveButtonTitle:nil otherButtonTitles:[OStrings stringForKey:_isMinor ? strTermGirl : strTermWoman], [OStrings stringForKey:_isMinor ? strTermBoy : strTermMan], nil];
    sheet.tag = kGenderSheetTag;
    
    [sheet showInView:[OState s].viewController.view];
}


- (void)presentBothParentCandidatesSheet
{
    NSString *question = [OLanguage questionWithSubject:_candidates verb:be argument:[OLanguage possessiveClauseWithPossessor:_givenName noun:parents]];
    
    NSString *buttonCandidate0 = [OLanguage predicateClauseWithSubject:_candidates[0] predicate:[self candidate:_candidates[0] parentLabelWithOffspringGender:_gender]];
    NSString *buttonCandidate1 = [OLanguage predicateClauseWithSubject:_candidates[1] predicate:[self candidate:_candidates[1] parentLabelWithOffspringGender:_gender]];
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:question delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonCancel] destructiveButtonTitle:nil otherButtonTitles:[OStrings stringForKey:strTermYes], buttonCandidate0, buttonCandidate1, [OStrings stringForKey:strTermNo], nil];
    sheet.tag = kBothParentCandidatesSheetTag;
    
    [sheet showInView:[OState s].viewController.view];
}


- (void)presentAllOffspringCandidatesSheet
{
    NSString *noun = [self parentNounForGender:_gender];
    NSString *question = [OLanguage questionWithSubject:_givenName verb:be argument:[OLanguage possessiveClauseWithPossessor:_candidates noun:noun]];
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:question delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    [sheet addButtonWithTitle:[OStrings stringForKey:strTermYes]];
    
    if ([_candidates count] == 2) {
        [sheet addButtonWithTitle:[[OLanguage possessiveClauseWithPossessor:_candidates[0] noun:noun]stringByCapitalisingFirstLetter]];
        [sheet addButtonWithTitle:[[OLanguage possessiveClauseWithPossessor:_candidates[1] noun:noun] stringByCapitalisingFirstLetter]];
    } else if ([_candidates count] > 2) {
        [sheet addButtonWithTitle:[OStrings stringForKey:strButtonParentToSome]];
    }
    
    [sheet addButtonWithTitle:[OStrings stringForKey:strTermNo]];
    [sheet addButtonWithTitle:[OStrings stringForKey:strButtonCancel]];
    sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
    sheet.tag = kAllOffspringCandidatesSheetTag;
    
    [sheet showInView:[OState s].viewController.view];
}


- (void)presentCandidateSheetForParentCandidate:(OMember *)candidate
{
    NSString *question = [OLanguage questionWithSubject:candidate verb:be argument:[OLanguage possessiveClauseWithPossessor:_givenName noun:[self parentNounForGender:candidate.gender]]];
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:question delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonCancel] destructiveButtonTitle:nil otherButtonTitles:[OStrings stringForKey:strTermYes], [OStrings stringForKey:strTermNo], nil];
    sheet.tag = kParentCandidateSheetTag;
    
    [sheet showInView:[OState s].viewController.view];
}


- (void)presentCandidateSheetForOffspringCandidate:(OMember *)candidate
{
    NSString *question = [OLanguage questionWithSubject:_givenName verb:be argument:[OLanguage possessiveClauseWithPossessor:candidate noun:[self parentNounForGender:_gender]]];
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:question delegate:self cancelButtonTitle:[OStrings stringForKey:strButtonCancel] destructiveButtonTitle:nil otherButtonTitles:[OStrings stringForKey:strTermYes], [OStrings stringForKey:strTermNo], nil];
    sheet.tag = kOffspringCandidateSheetTag;
    
    [sheet showInView:[OState s].viewController.view];
}


#pragma mark - Examination loop

- (OMember *)nextCandidate
{
    OMember *nextCandidate = nil;
    
    for (OMember *candidate in _candidates) {
        if (!nextCandidate && ![_examinedCandidates containsObject:candidate]) {
            nextCandidate = candidate;
        }
    }
    
    return nextCandidate;
}


- (void)finishExamination
{
    if ([_registrantOffspring count]) {
        for (OMember *offspring in _registrantOffspring) {
            if ([_gender isEqualToString:kGenderMale]) {
                offspring.fatherId = _registrantId;
            } else {
                offspring.motherId = _registrantId;
            }
        }
    }
    
    [_delegate examinerDidFinishExamination];
}


- (void)presentNextCandidateSheet
{
    _currentCandidate = [self nextCandidate];
    
    if (_currentCandidate) {
        if (_isMinor) {
            [self presentCandidateSheetForParentCandidate:_currentCandidate];
        } else {
            [self presentCandidateSheetForOffspringCandidate:_currentCandidate];
        }
    } else {
        [self finishExamination];
    }
}


- (void)performInitialExamination
{
    if (_isMinor) {
        if (_parentCandidateStatus == kParentCandidateStatusBoth) {
            [self presentBothParentCandidatesSheet];
        } else {
            [self presentNextCandidateSheet];
        }
    } else {
        if ([[OMeta m].user isMinor]) {
            [self presentNextCandidateSheet];
        } else {
            [self presentAllOffspringCandidatesSheet];
        }
    }
}


- (void)performExamination
{
    if (!_gender) {
        [self presentGenderSheet];
    } else if (_candidates) {
        if (![_examinedCandidates count]) {
            [self performInitialExamination];
        } else {
            [self presentNextCandidateSheet];
        }
    } else {
        [self finishExamination];
    }
}


#pragma mark - Initialisation

- (id)initWithResidence:(OOrigo *)residence
{
    self = [super init];
    
    if (self) {
        _residence = residence;
        _delegate = (id<ORegistrantExaminerDelegate>)[OState s].viewController;
    }
    
    return self;
}


#pragma mark - Examining registrants

- (void)examineRegistrant:(OMember *)registrant
{
    _gender = registrant.gender;
    
    [self examineRegistrantWithName:registrant.name dateOfBirth:registrant.dateOfBirth];
}


- (void)examineRegistrantWithName:(NSString *)name dateOfBirth:(NSDate *)dateOfBirth
{
    _dateOfBirth = dateOfBirth;
    
    [self examineRegistrantWithName:name isMinor:[dateOfBirth isBirthDateOfMinor]];
}


- (void)examineRegistrantWithName:(NSString *)name isGuardian:(BOOL)isGuardian
{
    if (isGuardian) {
        _dateOfBirth = [NSDate defaultDate];
    }
    
    [self examineRegistrantWithName:name isMinor:NO];
}


- (void)examineRegistrantWithName:(NSString *)name isMinor:(BOOL)isMinor
{
    _isMinor = isMinor;
    _givenName = [OUtil givenNameFromFullName:name];
    _parentCandidateStatus = kParentCandidateStatusUndetermined;
    _candidates = nil;
    _examinedCandidates = [[NSMutableSet alloc] init];
    _registrantOffspring = [[NSMutableArray alloc] init];
    _registrantId = [[OState s] targetIs:kTargetUser] ? [OMeta m].userId : [OCrypto generateUUID];
    _gender = nil;
    _motherId = nil;
    _fatherId = nil;
    
    [self performExamination];
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        switch (actionSheet.tag) {
            case kGenderSheetTag:
                _gender = (buttonIndex == kGenderSheetButtonFemale) ? kGenderFemale : kGenderMale;
                
                if (_dateOfBirth) {
                    [self assembleCandidates];
                }
                
                break;
                
            case kBothParentCandidatesSheetTag:
                [_examinedCandidates addObjectsFromArray:_candidates];
                
                if (buttonIndex == kBothParentCandidatesButtonYes) {
                    _fatherId = [[_candidates[0] isMale] ? _candidates[0] : _candidates[1] entityId];
                    _motherId = [[_candidates[0] isMale] ? _candidates[1] : _candidates[0] entityId];
                } else if (buttonIndex < kBothParentCandidatesButtonNo) {
                    if ([_candidates[buttonIndex - 1] isMale]) {
                        _fatherId = [_candidates[buttonIndex - 1] entityId];
                    } else {
                        _motherId = [_candidates[buttonIndex - 1] entityId];
                    }
                }
                
                break;
                
            case kAllOffspringCandidatesSheetTag:
                if (buttonIndex == kAllOffspringCandidatesButtonYes) {
                    [_examinedCandidates addObjectsFromArray:_candidates];
                    [_registrantOffspring addObjectsFromArray:_candidates];
                } else if (buttonIndex < actionSheet.numberOfButtons - 2) {
                    if ([_candidates count] == 2) {
                        [_examinedCandidates addObjectsFromArray:_candidates];
                        
                        if (buttonIndex == kAllOffspringCandidatesButtonSome) {
                            [_registrantOffspring addObject:_candidates[0]];
                        } else {
                            [_registrantOffspring addObject:_candidates[1]];
                        }
                    }
                } else {
                    [_examinedCandidates addObjectsFromArray:_candidates];
                }
                
                break;
                
            case kParentCandidateSheetTag:
                if (buttonIndex == kParentCandidateButtonYes) {
                    _fatherId = [_currentCandidate isMale] ? _currentCandidate.entityId : nil;
                    _motherId = [_currentCandidate isMale] ? nil : _currentCandidate.entityId;
                    
                    for (OMember *candidate in _candidates) {
                        if ([candidate isMale] == [_currentCandidate isMale]) {
                            [_examinedCandidates addObject:candidate];
                        }
                    }
                } else {
                    [_examinedCandidates addObject:_currentCandidate];
                }
                
                break;
                
            case kOffspringCandidateSheetTag:
                if (buttonIndex == kOffspringCandidateButtonYes) {
                    [_registrantOffspring addObject:_currentCandidate];
                }
                
                [_examinedCandidates addObject:_currentCandidate];
                
                break;
                
            default:
                
                break;
        }
        
        [self performExamination];
    } else {
        [_delegate examinerDidCancelExamination];
    }
}

@end
