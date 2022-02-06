//
//  OMemberExaminer.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

static NSInteger const kParentCandidateStatusUndetermined = 0x00;
static NSInteger const kParentCandidateStatusMother = 0x01;
static NSInteger const kParentCandidateStatusFather = 0x02;
static NSInteger const kParentCandidateStatusBoth = 0x03;

static OMemberExaminer *_instance = nil;


@interface OMemberExaminer () {
@private
    id<OMember> _member;
    id<OOrigo> _residence;
    id<OMember> _currentCandidate;
    
    NSInteger _parentCandidateStatus;
    NSArray *_candidates;
    NSMutableSet *_examinedCandidates;
    NSMutableArray *_registrantOffspring;
    
    id<OMemberExaminerDelegate> _delegate;
}

@end


@implementation OMemberExaminer

#pragma mark - Auxiliary methods

- (NSInteger)parentCandidateStatusForMember:(id<OMember>)member
{
    return [member isMale] ? kParentCandidateStatusFather : kParentCandidateStatusMother;
}


- (NSArray *)assembleCandidates
{
    NSMutableArray *candidates = [NSMutableArray array];
    
    for (id<OMember> resident in [_residence residents]) {
        if ([_member isJuvenile]) {
            if ([resident.dateOfBirth yearsBeforeDate:[_member dateOfBirth]] >= kAgeOfConsent) {
                [candidates addObject:resident];
                _parentCandidateStatus ^= [self parentCandidateStatusForMember:resident];
            }
            
            if (candidates.count > 2) {
                _parentCandidateStatus = kParentCandidateStatusUndetermined;
            }
        } else if ([resident isJuvenile] && ![resident hasParentWithGender:_member.gender]) {
            BOOL isParentCandidate = YES;
            
            if ([_member dateOfBirth] && resident.dateOfBirth) {
                isParentCandidate = [[_member dateOfBirth] yearsBeforeDate:resident.dateOfBirth] >= kAgeOfConsent;
            }
            
            if (isParentCandidate) {
                [candidates addObject:resident];
            }
        }
    }

    return [candidates sortedArrayUsingSelector:@selector(subjectiveCompare:)];
}


- (NSString *)parentNounForGender:(NSString *)gender
{
    return [gender isEqualToString:kGenderMale] ? _father_ : _mother_;
}


#pragma mark - Action sheets

- (void)presentGenderSheet
{
    BOOL isJuvenile = [_member isJuvenile];
    
    NSString *maleGender = [OLanguage genderTermForGender:kGenderMale isJuvenile:isJuvenile];
    NSString *femaleGender = [OLanguage genderTermForGender:kGenderFemale isJuvenile:isJuvenile];
    NSString *prompt = nil;
    
    if ([_member isUser]) {
        prompt = [NSString stringWithFormat:OLocalizedString(@"Are you a %@ or a %@?", @""), femaleGender, maleGender];
    } else {
        prompt = [NSString stringWithFormat:OLocalizedString(@"Is %@ a %@ or a %@?", @""), [_member givenName], femaleGender, maleGender];
    }
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt];
    [actionSheet addButtonWithTitle:[femaleGender stringByCapitalisingFirstLetter] action:^{
        [self->_member setGender:kGenderFemale];
    }];
    [actionSheet addButtonWithTitle:[maleGender stringByCapitalisingFirstLetter] action:^{
        [self->_member setGender:kGenderMale];
    }];
    
    [actionSheet showWithCancelAction:^{
        [self finishExaminationDidCancel:YES];
    }];
}


- (void)presentBothParentCandidatesSheet
{
    NSString *prompt = [OLanguage questionWithSubject:_candidates verb:_be_ argument:[OLanguage possessiveClauseWithPossessor:[_member givenName] noun:_parent_]];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt];
    [actionSheet addButtonWithTitle:OLocalizedString(@"Yes", @"") action:^{
        [self->_examinedCandidates addObjectsFromArray:self->_candidates];
        id<OMember> father = [self->_candidates[0] isMale] ? self->_candidates[0] : self->_candidates[1];
        id<OMember> mother = [self->_candidates[0] isMale] ? self->_candidates[1] : self->_candidates[0];
        [self->_member setFatherId:father.entityId];
        [self->_member setMotherId:mother.entityId];
        [self performExamination];
    }];
    [actionSheet addButtonWithTitle:[OLanguage predicateClauseWithSubject:_candidates[0] predicate:[OLanguage labelForParentWithGender:[_candidates[0] gender] relativeToOffspringWithGender:_member.gender]] action:^{
        [self->_examinedCandidates addObjectsFromArray:self->_candidates];
        if ([self->_candidates[0] isMale]) {
            [self->_member setFatherId:[self->_candidates[0] entityId]];
        } else {
            [self->_member setMotherId:[self->_candidates[0] entityId]];
        }
        [self performExamination];
    }];
    [actionSheet addButtonWithTitle:[OLanguage predicateClauseWithSubject:_candidates[1] predicate:[OLanguage labelForParentWithGender:[_candidates[1] gender] relativeToOffspringWithGender:_member.gender]] action:^{
        [self->_examinedCandidates addObjectsFromArray:self->_candidates];
        if ([self->_candidates[1] isMale]) {
            [self->_member setFatherId:[self->_candidates[1] entityId]];
        } else {
            [self->_member setMotherId:[self->_candidates[1] entityId]];
        }
        [self performExamination];
    }];
    [actionSheet addButtonWithTitle:OLocalizedString(@"No", @"") action:^{
        [self->_examinedCandidates addObjectsFromArray:self->_candidates];
        [self performExamination];
    }];
    
    [actionSheet showWithCancelAction:^{
        [self finishExaminationDidCancel:YES];
    }];
}


- (void)presentAllOffspringCandidatesSheet
{
    NSString *parentNoun = [self parentNounForGender:_member.gender];
    NSString *prompt = [OLanguage questionWithSubject:_member verb:_be_ argument:[OLanguage possessiveClauseWithPossessor:_candidates noun:parentNoun]];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt];
    [actionSheet addButtonWithTitle:OLocalizedString(@"Yes", @"") action:^{
        [self->_examinedCandidates addObjectsFromArray:self->_candidates];
        [self->_registrantOffspring addObjectsFromArray:self->_candidates];
        [self performExamination];
    }];
    
    if (_candidates.count == 2) {
        [actionSheet addButtonWithTitle:[[OLanguage possessiveClauseWithPossessor:_candidates[0] noun:parentNoun] stringByCapitalisingFirstLetter] action:^{
            [self->_examinedCandidates addObjectsFromArray:self->_candidates];
            [self->_registrantOffspring addObject:self->_candidates[0]];
            [self performExamination];
        }];
        [actionSheet addButtonWithTitle:[[OLanguage possessiveClauseWithPossessor:_candidates[1] noun:parentNoun] stringByCapitalisingFirstLetter] action:^{
            [self->_examinedCandidates addObjectsFromArray:self->_candidates];
            [self->_registrantOffspring addObject:self->_candidates[1]];
            [self performExamination];
        }];
    } else if (_candidates.count > 2) {
        [actionSheet addButtonWithTitle:OLocalizedString(@"To some of them", @"") action:^{
            [self->_examinedCandidates addObjectsFromArray:self->_candidates];
            [self performExamination];
        }]; // TODO
    }
    
    [actionSheet addButtonWithTitle:OLocalizedString(@"No", @"") action:^{
        [self->_examinedCandidates addObjectsFromArray:self->_candidates];
        [self performExamination];
    }];
    
    [actionSheet showWithCancelAction:^{
        [self finishExaminationDidCancel:YES];
    }];
}


- (void)presentCandidateSheetForParentCandidate:(id<OMember>)parentCandidate
{
    NSString *prompt = [OLanguage questionWithSubject:parentCandidate verb:_be_ argument:[OLanguage possessiveClauseWithPossessor:[_member givenName] noun:[self parentNounForGender:parentCandidate.gender]]];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt];
    [actionSheet addButtonWithTitle:OLocalizedString(@"Yes", @"") action:^{
        if ([self->_currentCandidate isMale]) {
            [self->_member setFatherId:self->_currentCandidate.entityId];
        } else {
            [self->_member setMotherId:self->_currentCandidate.entityId];
        }

        for (id<OMember> candidate in self->_candidates) {
            if ([candidate isMale] == [self->_currentCandidate isMale]) {
                [self->_examinedCandidates addObject:candidate];
            }
        }

        [self performExamination];
    }];
    [actionSheet addButtonWithTitle:OLocalizedString(@"No", @"") action:^{
        [self->_examinedCandidates addObject:self->_currentCandidate];
        [self performExamination];
    }];
    
    [actionSheet showWithCancelAction:^{
        [self finishExaminationDidCancel:YES];
    }];
}


- (void)presentCandidateSheetForOffspringCandidate:(id<OMember>)candidate
{
    NSString *prompt = [OLanguage questionWithSubject:[_member givenName] verb:_be_ argument:[OLanguage possessiveClauseWithPossessor:candidate noun:[self parentNounForGender:_member.gender]]];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt];
    [actionSheet addButtonWithTitle:OLocalizedString(@"Yes", @"") action:^{
        [self->_registrantOffspring addObject:self->_currentCandidate];
        [self->_examinedCandidates addObject:self->_currentCandidate];
        [self performExamination];
    }];
    [actionSheet addButtonWithTitle:OLocalizedString(@"No", @"") action:^{
        [self->_examinedCandidates addObject:self->_currentCandidate];
        [self performExamination];
    }];
    
    [actionSheet showWithCancelAction:^{
        [self finishExaminationDidCancel:YES];
    }];
}


#pragma mark - Examination loop

- (id<OMember>)nextCandidate
{
    id<OMember> nextCandidate = nil;
    
    for (id<OMember> candidate in _candidates) {
        if (!nextCandidate && ![_examinedCandidates containsObject:candidate]) {
            nextCandidate = candidate;
        }
    }
    
    return nextCandidate;
}


- (void)finishExaminationDidCancel:(BOOL)didCancel
{
    if (didCancel) {
        [_delegate examinerDidCancelExamination];
    } else {
        if (_registrantOffspring.count) {
            for (id<OMember> offspring in _registrantOffspring) {
                if ([_member.gender isEqualToString:kGenderMale]) {
                    offspring.fatherId = [_member entityId];
                } else {
                    offspring.motherId = [_member entityId];
                }
            }
        }
        
        [_delegate examinerDidFinishExamination];
    }
    
    _instance = nil;
}


- (void)presentNextCandidateSheet
{
    _currentCandidate = [self nextCandidate];
    
    if (_currentCandidate) {
        if ([_member isJuvenile]) {
            [self presentCandidateSheetForParentCandidate:_currentCandidate];
        } else {
            [self presentCandidateSheetForOffspringCandidate:_currentCandidate];
        }
    } else {
        [self finishExaminationDidCancel:NO];
    }
}


- (void)performInitialExamination
{
    if ([_member isJuvenile]) {
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
    if (!_member.gender) {
        [self presentGenderSheet];
    } else {
        if (!_candidates) {
            if (_residence && ([_member dateOfBirth] || [[OState s] targetIs:kTargetGuardian])) {
                _candidates = [self assembleCandidates];
            }
        }
        
        if (_candidates.count) {
            if (!_examinedCandidates.count) {
                [self performInitialExamination];
            } else {
                [self presentNextCandidateSheet];
            }
        } else {
            [self finishExaminationDidCancel:NO];
        }
    }
}


#pragma mark - Initialisation

- (instancetype)initWithResidence:(id<OOrigo>)residence delegate:(id)delegate
{
    self = [super init];
    
    if (self) {
        _residence = residence;
        _delegate = delegate;
    }
    
    return self;
}


#pragma mark - Factory methods

+ (instancetype)examinerForResidence:(id<OOrigo>)residence delegate:(id)delegate
{
    _instance = [[self alloc] initWithResidence:residence delegate:delegate];
    
    return _instance;
}


#pragma mark - Member examination

- (void)examineMember:(id)member
{
    _member = member;
    _parentCandidateStatus = kParentCandidateStatusUndetermined;
    _candidates = nil;
    _examinedCandidates = [NSMutableSet set];
    _registrantOffspring = [NSMutableArray array];
    
    [self performExamination];
}

@end
