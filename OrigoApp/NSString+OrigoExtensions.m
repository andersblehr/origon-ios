//
//  NSString+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "NSString+OrigoExtensions.h"

NSString * const kListSeparator = @"|";
NSString * const kSeparatorSpace = @" ";
NSString * const kSeparatorNewline = @"\n";
NSString * const kSeparatorComma = @", ";
NSString * const kSeparatorAmpersand = @" & ";
NSString * const kSeparatorHash = @"#";


@implementation NSString (OrigoExtensions)

#pragma mark - Convenience methods

- (BOOL)containsString:(NSString *)string
{
    return ([self rangeOfString:string].location != NSNotFound);
}


- (NSArray *)lines
{
    return [self componentsSeparatedByString:kSeparatorNewline];
}


- (NSUInteger)lineCount
{
    return [[self lines] count];
}


#pragma mark - String operations

- (NSString *)removeRedundantWhitespace
{
    NSString *doubleSpace = [kSeparatorSpace stringByAppendingString:kSeparatorSpace];
    NSString *doubleNewline = [kSeparatorNewline stringByAppendingString:kSeparatorNewline];
    NSString *spaceNewline = [kSeparatorSpace stringByAppendingString:kSeparatorNewline];
    NSString *newlineSpace = [kSeparatorNewline stringByAppendingString:kSeparatorSpace];
    
    NSString *copy = [NSString stringWithString:self];
    NSString *copyBeforePass = nil;
    
    while (![copy isEqualToString:copyBeforePass]) {
        copyBeforePass = copy;
        
        copy = [copy stringByReplacingSubstring:doubleSpace withString:kSeparatorSpace];
        copy = [copy stringByReplacingSubstring:doubleNewline withString:kSeparatorNewline];
        copy = [copy stringByReplacingSubstring:spaceNewline withString:kSeparatorNewline];
        copy = [copy stringByReplacingSubstring:newlineSpace withString:kSeparatorNewline];
        
        if ([copy hasPrefix:kSeparatorSpace] || [copy hasPrefix:kSeparatorNewline]) {
            copy = [copy substringFromIndex:1];
        }
        
        if ([copy hasSuffix:kSeparatorSpace] || [copy hasSuffix:kSeparatorNewline]) {
            copy = [copy substringToIndex:[copy length] - 1];
        }
    }
    
    return copy;
}


- (NSString *)stringByReplacingSubstring:(NSString *)substring withString:(NSString *)string
{
    NSMutableString *reworkedString = [NSMutableString stringWithString:self];
    
    [reworkedString replaceOccurrencesOfString:substring withString:string options:NSLiteralSearch range:NSMakeRange(0, [self length])];
    
    return reworkedString;
}


- (NSString *)stringByAppendingString:(NSString *)string separator:(NSString *)separator
{
    NSString *reworkedString = self;
    
    if ([self length]) {
        reworkedString = [reworkedString stringByAppendingString:separator];
    }
    
    return [reworkedString stringByAppendingString:string];
}


- (NSString *)stringByAppendingCapitalisedString:(NSString *)string
{
    return [self stringByAppendingString:[string stringByCapitalisingFirstLetter]];
}


- (NSString *)stringByCapitalisingFirstLetter
{
    return [[[self substringWithRange:NSMakeRange(0, 1)] uppercaseString] stringByAppendingString:[self substringFromIndex:1]];
}

@end
