//
//  NSString+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kOrigoSeasoning;

extern NSString * const kListSeparator;
extern NSString * const kSeparatorSpace;
extern NSString * const kSeparatorNewline;
extern NSString * const kSeparatorComma;
extern NSString * const kSeparatorHash;

@interface NSString (OrigoExtensions)

- (NSString *)base64EncodedString;
- (NSString *)hashUsingSHA1;
- (NSString *)seasonWith:(NSString *)string;

- (NSString *)removeSuperfluousWhitespace;
- (NSString *)stringByAppendingString:(NSString *)string separator:(NSString *)separator;

- (BOOL)containsString:(NSString *)string;

- (NSArray *)lines;
- (NSUInteger)lineCount;

@end
