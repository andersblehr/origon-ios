//
//  OLanguage.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern NSInteger const nominative;
extern NSInteger const accusative;
extern NSInteger const dative;
extern NSInteger const disjunctive;

extern NSInteger const singularIndefinite;
extern NSInteger const singularDefinite;
extern NSInteger const pluralIndefinite;
extern NSInteger const pluralDefinite;
extern NSInteger const possessive2;
extern NSInteger const possessive3;

extern NSInteger const singular1;
extern NSInteger const singular2;
extern NSInteger const singular3;
extern NSInteger const plural1;
extern NSInteger const plural2;
extern NSInteger const plural3;

extern NSString * const _be_;

extern NSString * const _origo_;
extern NSString * const _father_;
extern NSString * const _mother_;
extern NSString * const _parent_;
extern NSString * const _guardian_;
extern NSString * const _contact_;
extern NSString * const _address_;

extern NSString * const _I_;
extern NSString * const _you_;
extern NSString * const _he_;
extern NSString * const _she_;

@interface OLanguage : NSObject

+ (NSDictionary *)verbs;
+ (NSDictionary *)nouns;
+ (NSDictionary *)pronouns;

+ (NSString *)predicateClauseWithSubject:(id)subject predicate:(NSString *)predicate;
+ (NSString *)possessiveClauseWithPossessor:(id)possessor noun:(NSString *)nounKey;
+ (NSString *)questionWithSubject:(id)subject verb:(NSString *)verb argument:(NSString *)argument;

@end
