//
//  NSString+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern NSString * const kSeparatorAmpersand;
extern NSString * const kSeparatorComma;
extern NSString * const kSeparatorHash;
extern NSString * const kSeparatorNewline;
extern NSString * const kSeparatorSpace;

extern NSString * const kSeparatorList;
extern NSString * const kSeparatorMapping;
extern NSString * const kSeparatorSegments;
extern NSString * const kSeparatorAlternates;

@interface NSString (OrigoAdditions)

- (BOOL)hasValue;
- (BOOL)containsString:(NSString *)string;
- (BOOL)containsCharacter:(const char)character;

- (CGSize)sizeWithFont:(UIFont *)font maxWidth:(CGFloat)maxWidth;
- (NSInteger)lineCountWithFont:(UIFont *)font maxWidth:(CGFloat)maxWidth;
- (NSInteger)lineCount;
- (NSArray *)lines;

- (NSString *)removeRedundantWhitespace;
- (NSString *)stringByReplacingSubstring:(NSString *)substring withString:(NSString *)string;
- (NSString *)stringByAppendingString:(NSString *)string separator:(NSString *)separator;
- (NSString *)stringByAppendingCapitalisedString:(NSString *)string;
- (NSString *)stringByCapitalisingFirstLetter;

@end
