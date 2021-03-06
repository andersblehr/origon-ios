//
//  OLanguage.h
//  Origon
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

extern NSString * const _address_;
extern NSString * const _administrator_;
extern NSString * const _coach_;
extern NSString * const _father_;
extern NSString * const _guardian_;
extern NSString * const _guardian_f_;
extern NSString * const _guardian_m_;
extern NSString * const _mother_;
extern NSString * const _parent_;
extern NSString * const _parentContact_;
extern NSString * const _preschoolTeacher_;
extern NSString * const _teacher_;

extern NSString * const _he_;
extern NSString * const _I_;
extern NSString * const _she_;
extern NSString * const _you_;

@interface OLanguage : NSObject

+ (NSDictionary *)verbs;
+ (NSDictionary *)nouns;
+ (NSDictionary *)pronouns;

+ (NSString *)inlineNoun:(NSString *)noun;

+ (NSString *)predicateClauseWithSubject:(id)subject predicate:(NSString *)predicate;
+ (NSString *)possessiveClauseWithPossessor:(id)possessor noun:(NSString *)nounKey;
+ (NSString *)questionWithSubject:(id)subject verb:(NSString *)verb argument:(NSString *)argument;

+ (NSString *)genderTermForGender:(NSString *)gender isJuvenile:(BOOL)isJuvenile;
+ (NSString *)labelForParentsRelativeToOffspringWithGender:(NSString *)gender;
+ (NSString *)labelForParentWithGender:(NSString *)gender relativeToOffspringWithGender:(NSString *)offspringGender;

@end
