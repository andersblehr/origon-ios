//
//  NSString+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

extern NSString * const kListSeparator;
extern NSString * const kSeparatorSpace;
extern NSString * const kSeparatorNewline;
extern NSString * const kSeparatorComma;
extern NSString * const kSeparatorAmpersand;
extern NSString * const kSeparatorHash;

@interface NSString (OrigoExtensions)

- (BOOL)containsString:(NSString *)string;

- (NSUInteger)lineCount;
- (NSArray *)lines;

- (NSString *)removeRedundantWhitespace;
- (NSString *)stringByReplacingSubstring:(NSString *)substring withString:(NSString *)string;
- (NSString *)stringByAppendingString:(NSString *)string separator:(NSString *)separator;
- (NSString *)stringByAppendingCapitalisedString:(NSString *)string;
- (NSString *)stringByCapitalisingFirstLetter;

@end
