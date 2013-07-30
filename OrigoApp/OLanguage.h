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

extern NSInteger const singular1;
extern NSInteger const singular2;
extern NSInteger const singular3;
extern NSInteger const plural1;
extern NSInteger const plural2;
extern NSInteger const plural3;

extern NSString * const I;
extern NSString * const you;
extern NSString * const he;
extern NSString * const she;

extern NSString * const be;

@interface OLanguage : NSObject

+ (NSDictionary *)pronouns;
+ (NSDictionary *)verbs;

+ (NSString *)predicateClauseWithSubject:(id)subject predicate:(NSString *)predicate;
+ (NSString *)possessiveClauseWithPossessor:(id)possessor possessee:(NSString *)possessee;
+ (NSString *)questionWithSubject:(id)subject verb:(NSString *)verb argument:(NSString *)argument;

@end
