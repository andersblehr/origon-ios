//
//  OLanguage.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OCase) {
    nominative,
    accusative,
    dative,
};

typedef NS_ENUM(NSInteger, ONounForm) {
    singularIndefinite,
    singularDefinite,
    pluralIndefinite,
    pluralDefinite,
    possessive2,
    possessive3,
};

typedef NS_ENUM(NSInteger, OPersonNumber) {
    singular1,
    singular2,
    singular3,
    plural1,
    plural2,
    plural3,
};

extern NSString * const _be_;

extern NSString * const _group_;
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
