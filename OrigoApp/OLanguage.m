//
//  OLanguage.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OLanguage.h"

NSInteger const nominative = 0;
NSInteger const accusative = 1;
NSInteger const dative = 2;
NSInteger const disjunctive = 3;

NSInteger const singularIndefinite = 0;
NSInteger const singularDefinite = 1;
NSInteger const pluralIndefinite = 2;
NSInteger const pluralDefinite = 3;
NSInteger const possessive2 = 4;
NSInteger const possessive3 = 5;

NSInteger const singular1 = 0;
NSInteger const singular2 = 1;
NSInteger const singular3 = 2;
NSInteger const plural1 = 3;
NSInteger const plural2 = 4;
NSInteger const plural3 = 5;

NSString * const _be_  = @"verbBe";

NSString * const _origo_ = @"nounOrigo";
NSString * const _father_ = @"nounFather";
NSString * const _mother_ = @"nounMother";
NSString * const _parent_ = @"nounParent";
NSString * const _contact_ = @"nounContact";
NSString * const _address_ = @"nounAddress";

NSString * const _I_   = @"pronounI";
NSString * const _you_ = @"pronounYou";
NSString * const _he_  = @"pronounHe";
NSString * const _she_ = @"pronounShe";

static NSString * const kPartOfSpeechVerbs = @"verb";
static NSString * const kPartOfSpeechNouns = @"noun";
static NSString * const kPartOfSpeechPronouns = @"pronoun";

static NSString * const strQuestionTemplate = @"strQuestionTemplate";

static NSString * const kSubjectPlaceholder = @"{subject}";
static NSString * const kVerbPlaceholder = @"{verb}";
static NSString * const kArgumentPlaceholder = @"{argument}";
static NSString * const kPredicateClauseFormat = @"%@ %@ %@";

static OLanguage *language = nil;


@interface OLanguage ()

@property (strong, nonatomic) NSDictionary *verbs;
@property (strong, nonatomic) NSDictionary *nouns;
@property (strong, nonatomic) NSDictionary *pronouns;

@end


@implementation OLanguage

#pragma mark - Auxiliary methods

- (NSDictionary *)loadPartOfSpeech:(NSString *)partOfSpeech
{
    NSMutableDictionary *formsDictionary = [[NSMutableDictionary alloc] init];
    NSString *words = [OStrings stringForKey:[partOfSpeech stringByAppendingString:@"s"]];
    
    for (NSString *word in [words componentsSeparatedByString:kListSeparator]) {
        NSString *wordKey = [partOfSpeech stringByAppendingCapitalisedString:word];
        
        formsDictionary[wordKey] = [[OStrings stringForKey:wordKey] componentsSeparatedByString:kListSeparator];
    }
    
    return formsDictionary;
}


+ (NSString *)subjectStringWithSubject:(id)subject isQuestion:(BOOL)isQuestion
{
    NSString *subjectString = nil;
    
    if ([subject isKindOfClass:NSString.class]) {
        subjectString = subject;
    } else if ([subject isKindOfClass:OMember.class]) {
        if ([subject isUser]) {
            if (isQuestion) {
                subjectString = [OLanguage pronouns][_you_][nominative];
            } else {
                subjectString = [OLanguage pronouns][_I_][nominative];
            }
        } else {
            subjectString = [subject givenName];
        }
    } else if ([subject isKindOfClass:NSArray.class]) {
        subjectString = [OLanguage plainLanguageListOfItems:subject];
    }
    
    return subjectString;
}


+ (NSString *)verbStringWithVerb:(NSString *)verbKey subject:(id)subject isQuestion:(BOOL)isQuestion
{
    NSArray *verb = [OLanguage verbs][verbKey];
    NSString *verbString = nil;
    
    if ([subject isKindOfClass:NSString.class]) {
        verbString = verb[singular3];
    } else if ([subject isKindOfClass:OMember.class]) {
        if ([subject isUser]) {
            verbString = isQuestion ? verb[singular2] : verb[singular1];
        } else {
            verbString = verb[singular3];
        }
    } else if ([subject isKindOfClass:NSArray.class]) {
        verbString = [subject containsObject:[OMeta m].user] ? verb[plural2] : verb[plural3];
    }
    
    return verbString;
}


#pragma mark - Singleton instantiation & initialisation

+ (id)allocWithZone:(NSZone *)zone
{
    return [OLanguage language];
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


- (id)init
{
    self = [super init];
    
    if (self) {
        _verbs = [self loadPartOfSpeech:kPartOfSpeechVerbs];
        _nouns = [self loadPartOfSpeech:kPartOfSpeechNouns];
        _pronouns = [self loadPartOfSpeech:kPartOfSpeechPronouns];
    }
    
    return self;
}


+ (OLanguage *)language
{
    if (!language) {
        language = [[super allocWithZone:nil] init];
    }
    
    return language;
}


#pragma mark - Parts of speech dictionaries

+ (NSDictionary *)verbs
{
    return [OLanguage language].verbs;
}


+ (NSDictionary *)nouns
{
    return [OLanguage language].nouns;
}


+ (NSDictionary *)pronouns
{
    return [OLanguage language].pronouns;
}


#pragma mark - Simple sentence construction

+ (NSString *)predicateClauseWithSubject:(id)subject predicate:(NSString *)predicate
{
    NSString *subjectString = [self subjectStringWithSubject:subject isQuestion:NO];
    NSString *verbString = [self verbStringWithVerb:_be_ subject:subject isQuestion:NO];
    
    return [[NSString stringWithFormat:kPredicateClauseFormat, subjectString, verbString, predicate] stringByCapitalisingFirstLetter];
}


+ (NSString *)possessiveClauseWithPossessor:(id)possessor noun:(NSString *)nounKey
{
    NSString *possessiveClause = nil;
    NSArray *noun = [OLanguage nouns][nounKey];
    
    if ([possessor isKindOfClass:NSString.class]) {
        possessiveClause = [NSString stringWithFormat:noun[possessive3], possessor];
    } else if ([possessor isKindOfClass:OMember.class]) {
        if ([possessor isUser]) {
            possessiveClause = noun[possessive2];
        } else {
            possessiveClause = [NSString stringWithFormat:noun[possessive3], [possessor givenName]];
        }
    } else if ([possessor isKindOfClass:NSArray.class]) {
        possessiveClause = [NSString stringWithFormat:noun[possessive3], [OLanguage plainLanguageListOfItems:possessor]];
    }
    
    return possessiveClause;
}


+ (NSString *)questionWithSubject:(id)subject verb:(NSString *)verb argument:(NSString *)argument
{
    NSString *subjectString = [self subjectStringWithSubject:subject isQuestion:YES];
    NSString *verbString = [self verbStringWithVerb:verb subject:subject isQuestion:YES];
    
    NSString *question = [OStrings stringForKey:strQuestionTemplate];
    question = [question stringByReplacingSubstring:kSubjectPlaceholder withString:subjectString];
    question = [question stringByReplacingSubstring:kVerbPlaceholder withString:verbString];
    question = [question stringByReplacingSubstring:kArgumentPlaceholder withString:argument];
    
    return [question stringByCapitalisingFirstLetter];
}


+ (NSString *)plainLanguageListOfItems:(NSArray *)items
{
    NSMutableArray *stringItems = nil;
    
    if ([items[0] isKindOfClass:NSString.class]) {
        stringItems = [NSArray arrayWithArray:items];
    } else if ([items[0] isKindOfClass:OMember.class]) {
        stringItems = [[NSMutableArray alloc] init];
        
        for (OMember *member in items) {
            [stringItems addObject:[member appellation]];
        }
    }

    NSMutableString *plainLanguageListing = nil;
    
    for (NSString *stringItem in stringItems) {
        if (!plainLanguageListing) {
            plainLanguageListing = [NSMutableString stringWithString:stringItem];
        } else if ([stringItems lastObject] == stringItem) {
            [plainLanguageListing appendString:[OStrings stringForKey:strSeparatorAnd]];
            [plainLanguageListing appendString:stringItem];
        } else {
            [plainLanguageListing appendString:kSeparatorComma];
            [plainLanguageListing appendString:stringItem];
        }
    }
    
    return plainLanguageListing;
}

@end
