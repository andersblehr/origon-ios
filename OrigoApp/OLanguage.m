//
//  OLanguage.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OLanguage.h"

NSString * const _be_  = @"wordBe";

NSString * const _origo_ = @"wordOrigo";
NSString * const _father_ = @"wordFather";
NSString * const _mother_ = @"wordMother";
NSString * const _parent_ = @"wordParent";
NSString * const _guardian_ = @"wordGuardian";
NSString * const _contact_ = @"wordContact";
NSString * const _address_ = @"wordAddress";

NSString * const _I_   = @"wordI";
NSString * const _you_ = @"wordYou";
NSString * const _he_  = @"wordHe";
NSString * const _she_ = @"wordShe";

static NSString * const kPartOfSpeechVerbs = @"be";
static NSString * const kPartOfSpeechNouns = @"origo;father;mother;parent;guardian;contact;address";
static NSString * const kPartOfSpeechPronouns = @"I;you;he;she";

static NSString * const kPlaceholderSubject = @"{subject}";
static NSString * const kPlaceholderVerb = @"{verb}";
static NSString * const kPlaceholderArgument = @"{argument}";

static NSString * const kWordPrefix = @"word";
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
    NSMutableDictionary *formsDictionary = [NSMutableDictionary dictionary];
    
    for (NSString *word in [partOfSpeech componentsSeparatedByString:kSeparatorList]) {
        NSString *wordKey = [kWordPrefix stringByAppendingCapitalisedString:word];
        
        formsDictionary[wordKey] = [NSLocalizedString(wordKey, @"") componentsSeparatedByString:kSeparatorList];
    }
    
    return formsDictionary;
}


+ (NSString *)subjectStringWithSubject:(id)subject isQuestion:(BOOL)isQuestion
{
    NSString *subjectString = nil;
    
    if ([subject isKindOfClass:[NSString class]]) {
        subjectString = subject;
    } else if ([subject isKindOfClass:[OMember class]]) {
        if ([subject isUser]) {
            if (isQuestion) {
                subjectString = [OLanguage pronouns][_you_][nominative];
            } else {
                subjectString = [OLanguage pronouns][_I_][nominative];
            }
        } else {
            subjectString = [subject givenName];
        }
    } else if ([subject isKindOfClass:[NSArray class]]) {
        subjectString = [OUtil commaSeparatedListOfItems:subject conjoinLastItem:YES];
    }
    
    return subjectString;
}


+ (NSString *)verbStringWithVerb:(NSString *)verbKey subject:(id)subject isQuestion:(BOOL)isQuestion
{
    NSArray *verb = [OLanguage verbs][verbKey];
    NSString *verbString = nil;
    
    if ([subject isKindOfClass:[NSString class]]) {
        verbString = verb[singular3];
    } else if ([subject isKindOfClass:[OMember class]]) {
        if ([subject isUser]) {
            verbString = isQuestion ? verb[singular2] : verb[singular1];
        } else {
            verbString = verb[singular3];
        }
    } else if ([subject isKindOfClass:[NSArray class]]) {
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
    
    if ([possessor isKindOfClass:[NSString class]]) {
        possessiveClause = [NSString stringWithFormat:noun[possessive3], possessor];
    } else if ([possessor isKindOfClass:[OMember class]]) {
        if ([possessor isUser]) {
            possessiveClause = noun[possessive2];
        } else {
            possessiveClause = [NSString stringWithFormat:noun[possessive3], [possessor givenName]];
        }
    } else if ([possessor isKindOfClass:[NSArray class]]) {
        possessiveClause = [NSString stringWithFormat:noun[possessive3], [OUtil commaSeparatedListOfItems:possessor conjoinLastItem:YES]];
    }
    
    return possessiveClause;
}


+ (NSString *)questionWithSubject:(id)subject verb:(NSString *)verb argument:(NSString *)argument
{
    NSString *subjectString = [self subjectStringWithSubject:subject isQuestion:YES];
    NSString *verbString = [self verbStringWithVerb:verb subject:subject isQuestion:YES];
    
    NSString *question = NSLocalizedString(@"questionTemplate", @"");
    question = [question stringByReplacingSubstring:kPlaceholderSubject withString:subjectString];
    question = [question stringByReplacingSubstring:kPlaceholderVerb withString:verbString];
    question = [question stringByReplacingSubstring:kPlaceholderArgument withString:argument];
    
    return [question stringByCapitalisingFirstLetter];
}

@end
