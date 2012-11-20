//
//  NSString+OStringExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kSeparatorNewline;
extern NSString * const kSeparatorComma;
extern NSString * const kSeparatorDollar;
extern NSString * const kSeparatorHash;
extern NSString * const kSeparatorCaret;

@interface NSString (OStringExtensions)

- (NSString *)base64EncodedString;
- (NSString *)hashUsingSHA1;
- (NSString *)diff:(NSString *)string;

- (NSString *)removeLeadingAndTrailingWhitespace;
- (NSString *)stringByAppendingString:(NSString *)string separator:(NSString *)separator;

- (NSUInteger)lineCount;
- (NSArray *)lines;

- (BOOL)isEmailAddress;

+ (NSString *)givenNameFromFullName:(NSString *)fullName;

@end
