//
//  OMemberExaminer.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OMemberExaminer.h"

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

static OMemberExaminer *_instance = nil;


@implementation OMemberExaminer

#pragma mark - Auxiliary methods

- (NSInteger)parentCandidateStatusForMember:(id<OMember>)member
{
    return [member isMale] ? kParentCandidateStatusFather : kParentCandidateStatusMother;
}


- (void)assembleCandidates
{
    NSMutableArray *candidates = [NSMutableArray array];
    
    for (id<OMember> resident in [_residence residents]) {
        if ([_member isJuvenile]) {
            if ([resident.dateOfBirth yearsBeforeDate:[_member dateOfBirth]] >= kAgeOfConsent) {
                [candidates addObject:resident];
                _parentCandidateStatus ^= [self parentCandidateStatusForMember:resident];
            }
            
            if ([candidates count] > 2) {
                _parentCandidateStatus = kParentCandidateStatusUndetermined;
            }
        } else if ([resident isJuvenile] && ![resident hasParentWithGender:[_member gender]]) {
            BOOL isParentCandidate = YES;
            
            if ([_member dateOfBirth] && resident.dateOfBirth) {
                isParentCandidate = ([[_member dateOfBirth] yearsBeforeDate:resident.dateOfBirth] >= kAgeOfConsent);
            }
            
            if (isParentCandidate) {
                [candidates addObject:resident];
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


- (NSString *)candidate:(id<OMember>)candidate parentLabelWithOffspringGender:(NSString *)gender
{
    NSString *parentLabel = nil;
    
    if ([candidate isMale]) {
        parentLabel = [gender isEqualToString:kGenderMale] ? NSLocalizedString(@"his father", @"") : NSLocalizedString(@"her father", @"");
    } else {
        parentLabel = [gender isEqualToString:kGenderMale] ? NSLocalizedString(@"his mother", @"") : NSLocalizedString(@"her mother", @"");
    }
    
    return parentLabel;
}


#pragma mark - Action sheets

- (void)presentGenderSheet
{
    id subject = nil;
    
    if ([[OState s] targetIs:kTargetUser]) {
        subject = [OMeta m].user;
    } else {
        subject = [_member givenName];
    }
    
    NSString *prompt = [OLanguage questionWithSubject:subject verb:_be_ argument:[_member isJuvenile] ? NSLocalizedString(@"a girl or a boy", @"") : NSLocalizedString(@"a woman or a man", @"")];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagGender];
    [actionSheet addButtonWithTitle:[_member isJuvenile] ? NSLocalizedString(@"Girl", @"") : NSLocalizedString(@"Woman", @"") tag:kButtonTagFemale];
    [actionSheet addButtonWithTitle:[_member isJuvenile] ? NSLocalizedString(@"Boy", @"") : NSLocalizedString(@"Man", @"")];
    
    [actionSheet show];
}


- (void)presentBothParentCandidatesSheet
{
    NSString *prompt = [OLanguage questionWithSubject:_candidates verb:_be_ argument:[OLanguage possessiveClauseWithPossessor:[_member givenName] noun:_parent_]];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagBothParents];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Yes", @"") tag:kButtonTagYes];
    [actionSheet addButtonWithTitle:[OLanguage predicateClauseWithSubject:_candidates[0] predicate:[self candidate:_candidates[0] parentLabelWithOffspringGender:[_member gender]]]];
    [actionSheet addButtonWithTitle:[OLanguage predicateClauseWithSubject:_candidates[1] predicate:[self candidate:_candidates[1] parentLabelWithOffspringGender:[_member gender]]]];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"No", @"") tag:kButtonTagNo];
    
    [actionSheet show];
}


- (void)presentAllOffspringCandidatesSheet
{
    NSString *parentNoun = [self parentNounForGender:[_member gender]];
    NSString *prompt = [OLanguage questionWithSubject:[_member givenName] verb:_be_ argument:[OLanguage possessiveClauseWithPossessor:_candidates noun:parentNoun]];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagAllOffspring];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Yes", @"") tag:kButtonTagYes];
    
    if ([_candidates count] == 2) {
        [actionSheet addButtonWithTitle:[[OLanguage possessiveClauseWithPossessor:_candidates[0] noun:parentNoun] stringByCapitalisingFirstLetter]];
        [actionSheet addButtonWithTitle:[[OLanguage possessiveClauseWithPossessor:_candidates[1] noun:parentNoun] stringByCapitalisingFirstLetter]];
    } else if ([_candidates count] > 2) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"To some of them", @"")]; // TODO
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"No", @"") tag:kButtonTagNo];
    
    [actionSheet show];
}


- (void)presentCandidateSheetForParentCandidate:(id<OMember>)candidate
{
    NSString *prompt = [OLanguage questionWithSubject:candidate verb:_be_ argument:[OLanguage possessiveClauseWithPossessor:[_member givenName] noun:[self parentNounForGender:candidate.gender]]];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagParent];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Yes", @"") tag:kButtonTagYes];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"No", @"") tag:kButtonTagNo];
    
    [actionSheet show];
}


- (void)presentCandidateSheetForOffspringCandidate:(id<OMember>)candidate
{
    NSString *prompt = [OLanguage questionWithSubject:[_member givenName] verb:_be_ argument:[OLanguage possessiveClauseWithPossessor:candidate noun:[self parentNounForGender:[_member gender]]]];
    
    OActionSheet *actionSheet = [[OActionSheet alloc] initWithPrompt:prompt delegate:self tag:kActionSheetTagOffspring];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Yes", @"") tag:kButtonTagYes];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"No", @"") tag:kButtonTagNo];
    
    [actionSheet show];
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
        if ([_registrantOffspring count]) {
            for (id<OMember> offspring in _registrantOffspring) {
                if ([[_member gender] isEqualToString:kGenderMale]) {
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
    if (![_member gender]) {
        [self presentGenderSheet];
    } else if (_candidates) {
        if (![_examinedCandidates count]) {
            [self performInitialExamination];
        } else {
            [self presentNextCandidateSheet];
        }
    } else {
        [self finishExaminationDidCancel:NO];
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
    
    if (_residence && ([_member dateOfBirth] || [[OState s] targetIs:kTargetGuardian])) {
        [self assembleCandidates];
    }
    
    [self performExamination];
}


#pragma mark - UIActionSheetDelegate conformance

- (void)actionSheet:(OActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex < actionSheet.cancelButtonIndex) {
        NSInteger buttonTag = [actionSheet tagForButtonIndex:buttonIndex];
        
        switch (actionSheet.tag) {
            case kActionSheetTagGender:
                [_member setGender:(buttonTag == kButtonTagFemale) ? kGenderFemale : kGenderMale];
                
                break;
                
            case kActionSheetTagBothParents:
                [_examinedCandidates addObjectsFromArray:_candidates];
                
                if (buttonTag == kButtonTagYes) {
                    id<OMember> father = [_candidates[0] isMale] ? _candidates[0] : _candidates[1];
                    id<OMember> mother = [_candidates[0] isMale] ? _candidates[1] : _candidates[0];
                    
                    [_member setFatherId:father.entityId];
                    [_member setMotherId:mother.entityId];
                } else if (buttonTag != kButtonTagNo) {
                    if ([_candidates[buttonTag - 1] isMale]) {
                        [_member setFatherId:[_candidates[buttonTag - 1] entityId]];
                    } else {
                        [_member setMotherId:[_candidates[buttonTag - 1] entityId]];
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
                    if ([_currentCandidate isMale]) {
                        [_member setFatherId:_currentCandidate.entityId];
                    } else {
                        [_member setMotherId:_currentCandidate.entityId];
                    }
                    
                    for (id<OMember> candidate in _candidates) {
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
        [self finishExaminationDidCancel:YES];
    }
}

@end
