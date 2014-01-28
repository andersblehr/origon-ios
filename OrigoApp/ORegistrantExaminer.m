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

static NSInteger const kActionSheetTagGender = 0;
static NSInteger const kButtonTagFemale = 0;

static NSInteger const kActionSheetTagBothParents = 1;
static NSInteger const kActionSheetTagParent = 2;
static NSInteger const kActionSheetTagAllOffspring = 3;
static NSInteger const kActionSheetTagOffspring = 4;

static NSInteger const kButtonTagYes = 0;
static NSInteger const kButtonTagNo = 3;


@implementation ORegistrantExaminer

#pragma mark - Auxiliary methods

- (NSInteger)parentCandidateStatusForMember:(OMember *)member
{
    return [member isMale] ? kParentCandidateStatusFather : kParentCandidateStatusMother;
}


- (void)assembleCandidates
{
    NSMutableArray *candidates = [NSMutableArray array];
    
    for (OMembership *residency in [_residence residencies]) {
        if (_isMinor) {
            if ([residency.member.dateOfBirth yearsBeforeDate:_dateOfBirth] >= kAgeOfConsent) {
                [candidates addObject:residency.member];
                _parentCandidateStatus ^= [self parentCandidateStatusForMember:residency.member];
            }
            
            if ([candidates count] > 2) {
                _parentCandidateStatus = kParentCandidateStatusUndetermined;
            }
        } else if ([residency.member isJuvenile] && ![residency.member hasParentWithGender:_gender]) {
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
    return [gender isEqualToString:kGenderMale] ? _father_ : _mother_;
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
    NSString *prompt = [OLanguage questionWithSubject:subject verb:_be_ argument:[OStrings stringForKey:_isMinor ? strQuestionArgumentGenderMinor : strQuestionArgumentGender]];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagGender];
    [actionSheet addButtonWithTitle:[OStrings stringForKey:_isMinor ? strTermGirl : strTermWoman] tag:kButtonTagFemale];
    [actionSheet addButtonWithTitle:[OStrings stringForKey:_isMinor ? strTermBoy : strTermMan]];
    
    [actionSheet show];
}


- (void)presentBothParentCandidatesSheet
{
    NSString *prompt = [OLanguage questionWithSubject:_candidates verb:_be_ argument:[OLanguage possessiveClauseWithPossessor:_givenName noun:_parent_]];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagBothParents];
    [actionSheet addButtonWithTitle:[OStrings stringForKey:strTermYes] tag:kButtonTagYes];
    [actionSheet addButtonWithTitle:[OLanguage predicateClauseWithSubject:_candidates[0] predicate:[self candidate:_candidates[0] parentLabelWithOffspringGender:_gender]]];
    [actionSheet addButtonWithTitle:[OLanguage predicateClauseWithSubject:_candidates[1] predicate:[self candidate:_candidates[1] parentLabelWithOffspringGender:_gender]]];
    [actionSheet addButtonWithTitle:[OStrings stringForKey:strTermNo] tag:kButtonTagNo];
    
    [actionSheet show];
}


- (void)presentAllOffspringCandidatesSheet
{
    NSString *parentNoun = [self parentNounForGender:_gender];
    NSString *prompt = [OLanguage questionWithSubject:_givenName verb:_be_ argument:[OLanguage possessiveClauseWithPossessor:_candidates noun:parentNoun]];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagAllOffspring];
    [actionSheet addButtonWithTitle:[OStrings stringForKey:strTermYes] tag:kButtonTagYes];
    
    if ([_candidates count] == 2) {
        [actionSheet addButtonWithTitle:[[OLanguage possessiveClauseWithPossessor:_candidates[0] noun:parentNoun] stringByCapitalisingFirstLetter]];
        [actionSheet addButtonWithTitle:[[OLanguage possessiveClauseWithPossessor:_candidates[1] noun:parentNoun] stringByCapitalisingFirstLetter]];
    } else {
        [actionSheet addButtonWithTitle:[OStrings stringForKey:strButtonParentToSome]];
    }
    
    [actionSheet addButtonWithTitle:[OStrings stringForKey:strTermNo] tag:kButtonTagNo];
    
    [actionSheet show];
}


- (void)presentCandidateSheetForParentCandidate:(OMember *)candidate
{
    NSString *prompt = [OLanguage questionWithSubject:candidate verb:_be_ argument:[OLanguage possessiveClauseWithPossessor:_givenName noun:[self parentNounForGender:candidate.gender]]];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagParent];
    [actionSheet addButtonWithTitle:[OStrings stringForKey:strTermYes] tag:kButtonTagYes];
    [actionSheet addButtonWithTitle:[OStrings stringForKey:strTermNo] tag:kButtonTagNo];
    
    [actionSheet show];
}


- (void)presentCandidateSheetForOffspringCandidate:(OMember *)candidate
{
    NSString *prompt = [OLanguage questionWithSubject:_givenName verb:_be_ argument:[OLanguage possessiveClauseWithPossessor:candidate noun:[self parentNounForGender:_gender]]];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagOffspring];
    [actionSheet addButtonWithTitle:[OStrings stringForKey:strTermYes] tag:kButtonTagYes];
    [actionSheet addButtonWithTitle:[OStrings stringForKey:strTermNo] tag:kButtonTagNo];
    
    [actionSheet show];
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
        if ([[OMeta m].user isJuvenile]) {
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
    _examinedCandidates = [NSMutableSet set];
    _registrantOffspring = [NSMutableArray array];
    _registrantId = [[OState s] targetIs:kTargetUser] ? [OMeta m].userId : [OCrypto generateUUID];
    _gender = nil;
    _motherId = nil;
    _fatherId = nil;
    
    [self performExamination];
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex < actionSheet.cancelButtonIndex) {
        NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
        
        switch (actionSheet.tag) {
            case kActionSheetTagGender:
                _gender = (buttonTag == kButtonTagFemale) ? kGenderFemale : kGenderMale;
                
                if (_dateOfBirth) {
                    [self assembleCandidates];
                }
                
                break;
                
            case kActionSheetTagBothParents:
                [_examinedCandidates addObjectsFromArray:_candidates];
                
                if (buttonTag == kButtonTagYes) {
                    _fatherId = [[_candidates[0] isMale] ? _candidates[0] : _candidates[1] entityId];
                    _motherId = [[_candidates[0] isMale] ? _candidates[1] : _candidates[0] entityId];
                } else if (buttonTag != kButtonTagNo) {
                    if ([_candidates[buttonTag - 1] isMale]) {
                        _fatherId = [_candidates[buttonTag - 1] entityId];
                    } else {
                        _motherId = [_candidates[buttonTag - 1] entityId];
                    }
                }
                
                break;
                
            case kActionSheetTagAllOffspring:
                if (buttonTag == kButtonTagYes) {
                    [_examinedCandidates addObjectsFromArray:_candidates];
                    [_registrantOffspring addObjectsFromArray:_candidates];
                } else if (buttonTag != kButtonTagNo) {
                    if ([_candidates count] == 2) {
                        [_examinedCandidates addObjectsFromArray:_candidates];
                        [_registrantOffspring addObject:_candidates[buttonTag - 1]];
                    }
                } else {
                    [_examinedCandidates addObjectsFromArray:_candidates];
                }
                
                break;
                
            case kActionSheetTagParent:
                if (buttonTag == kButtonTagYes) {
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
                
            case kActionSheetTagOffspring:
                if (buttonTag == kButtonTagYes) {
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
