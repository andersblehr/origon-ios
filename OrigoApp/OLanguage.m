//
//  OLanguage.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OLanguage.h"

NSString * const _be_  = @"be";

NSString * const _address_ = @"address";
NSString * const _coach_ = @"coach";
NSString * const _contact_ = @"contact";
NSString * const _father_ = @"father";
NSString * const _group_ = @"group";
NSString * const _guardian_ = @"guardian";
NSString * const _household_ = @"household";
NSString * const _lecturer_ = @"lecturer";
NSString * const _mother_ = @"mother";
NSString * const _parent_ = @"parent";
NSString * const _parentContact_ = @"parentContact";
NSString * const _preschoolTeacher_ = @"preschoolTeacher";
NSString * const _teacher_ = @"teacher";

NSString * const _he_  = @"he";
NSString * const _I_   = @"I";
NSString * const _she_ = @"she";
NSString * const _you_ = @"you";

static NSString * const kPartOfSpeechVerbs = @"be";
static NSString * const kPartOfSpeechNouns = @"address;coach;contact;father;group;guardian;household;lecturer;mother;parent;parentContact;preschoolTeacher;teacher";
static NSString * const kPartOfSpeechPronouns = @"he;I;she;you";

static NSString * const kPlaceholderSubject = @"{subject}";
static NSString * const kPlaceholderVerb = @"{verb}";
static NSString * const kPlaceholderArgument = @"{argument}";
static NSString * const kPredicateClauseFormat = @"%@ %@ %@";


@interface OLanguage ()

@property (strong, nonatomic) NSDictionary *verbs;
@property (strong, nonatomic) NSDictionary *nouns;
@property (strong, nonatomic) NSDictionary *pronouns;

@end


@implementation OLanguage

#pragma mark - Auxiliary methods

- (NSDictionary *)loadPartOfSpeech:(NSString *)partOfSpeech
{
    NSMutableDictionary *forms = [NSMutableDictionary dictionary];
    
    for (NSString *word in [partOfSpeech componentsSeparatedByString:kSeparatorList]) {
        forms[word] = [NSLocalizedString(word, @"") componentsSeparatedByString:kSeparatorList];
    }
    
    return forms;
}


+ (NSString *)subjectStringWithSubject:(id)subject isQuestion:(BOOL)isQuestion
{
    NSString *subjectString = nil;
    
    if ([subject isKindOfClass:[NSString class]]) {
        subjectString = subject;
    } else if ([subject conformsToProtocol:@protocol(OMember)]) {
        if ([subject isUser]) {
            if (isQuestion) {
                subjectString = [self pronouns][_you_][nominative];
            } else {
                subjectString = [self pronouns][_I_][nominative];
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
    NSArray *verb = [self verbs][verbKey];
    NSString *verbString = nil;
    
    if ([subject isKindOfClass:[NSString class]]) {
        verbString = verb[singular3];
    } else if ([subject conformsToProtocol:@protocol(OMember)]) {
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
    return [self language];
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _verbs = [self loadPartOfSpeech:kPartOfSpeechVerbs];
        _nouns = [self loadPartOfSpeech:kPartOfSpeechNouns];
        _pronouns = [self loadPartOfSpeech:kPartOfSpeechPronouns];
    }
    
    return self;
}


+ (instancetype)language
{
    static OLanguage *language = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        language = [[super allocWithZone:nil] init];
    });
    
    return language;
}


#pragma mark - Parts of speech dictionaries

+ (NSDictionary *)verbs
{
    return [[self language] verbs];
}


+ (NSDictionary *)nouns
{
    return [[self language] nouns];
}


+ (NSDictionary *)pronouns
{
    return [[self language] pronouns];
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
    NSArray *noun = [self nouns][nounKey];
    
    if ([possessor isKindOfClass:[NSString class]]) {
        possessiveClause = [NSString stringWithFormat:noun[possessive3], possessor];
    } else if ([possessor conformsToProtocol:@protocol(OMember)]) {
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
