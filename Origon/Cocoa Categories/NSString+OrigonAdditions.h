//
//  NSString+OrigonAdditions.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kCharacters0_9;

extern NSString * const kSeparatorColon;
extern NSString * const kSeparatorComma;
extern NSString * const kSeparatorHash;
extern NSString * const kSeparatorHat;
extern NSString * const kSeparatorNewline;
extern NSString * const kSeparatorParagraph;
extern NSString * const kSeparatorSpace;
extern NSString * const kSeparatorTilde;

extern NSString * const kSeparatorList;
extern NSString * const kSeparatorMapping;
extern NSString * const kSeparatorSegments;
extern NSString * const kSeparatorAlternates;

@interface NSString (OrigonAdditions)

- (BOOL)hasValue;
- (BOOL)containsString:(NSString *)string;
- (BOOL)containsCharacter:(const char)character;
- (BOOL)fuzzyMatches:(NSString *)other;

- (CGSize)sizeWithFont:(UIFont *)font maxWidth:(CGFloat)maxWidth;
- (NSInteger)lineCountWithFont:(UIFont *)font maxWidth:(CGFloat)maxWidth;
- (NSInteger)lineCount;
- (NSArray *)lines;

- (NSString *)stringByRemovingRedundantWhitespaceKeepNewlines:(BOOL)keepNewlines;
- (NSString *)stringByReplacingSubstring:(NSString *)substring withString:(NSString *)string;
- (NSString *)stringByAppendingString:(NSString *)string separator:(NSString *)separator;
- (NSString *)stringByAppendingCapitalisedString:(NSString *)string;
- (NSString *)stringByCapitalisingFirstLetter;
- (NSString *)stringByLowercasingFirstLetter;
- (NSString *)stringByConditionallyLowercasingFirstLetter;
- (NSString *)stringByLowercasingAndRemovingWhitespace;

- (NSString *)givenName;
- (NSString *)localisedCountryName;

@end
