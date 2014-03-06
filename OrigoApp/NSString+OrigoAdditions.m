//
//  NSString+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "NSString+OrigoAdditions.h"

NSString * const kSeparatorAmpersand = @" & ";
NSString * const kSeparatorComma = @", ";
NSString * const kSeparatorHash = @"#";
NSString * const kSeparatorNewline = @"\n";
NSString * const kSeparatorSpace = @" ";

NSString * const kSeparatorList = @";";
NSString * const kSeparatorMapping = @":";
NSString * const kSeparatorSegments = @"|";
NSString * const kSeparatorAlternates = @"|";


@implementation NSString (OrigoAdditions)

#pragma mark - Convenience methods

- (BOOL)hasValue
{
    return ([self length] > 0);
}


- (BOOL)containsString:(NSString *)string
{
    return ([self rangeOfString:string].location != NSNotFound);
}


- (BOOL)containsCharacter:(const char)character
{
    return [self containsString:[NSString stringWithFormat:@"%c", character]];
}


#pragma mark - Size and line count assessment

- (CGSize)sizeWithFont:(UIFont *)font maxWidth:(CGFloat)maxWidth
{
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:self attributes:@{NSFontAttributeName:font}];
    CGRect boundingRect = [attributedText boundingRectWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    
    return CGSizeMake(ceil(boundingRect.size.width), ceil(boundingRect.size.height));
}


- (NSInteger)lineCountWithFont:(UIFont *)font maxWidth:(CGFloat)maxWidth
{
    return round([self sizeWithFont:font maxWidth:maxWidth].height / font.lineHeight);
}


- (NSInteger)lineCount
{
    return [[self lines] count];
}


- (NSArray *)lines
{
    return [self componentsSeparatedByString:kSeparatorNewline];
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
    
    if ([self hasValue]) {
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


#pragma mark - Edit distance to other string

- (NSInteger)levenshteinDistanceToString:(NSString *)string
{
    // Borrowed from Rosetta Code: http://rosettacode.org/wiki/Levenshtein_distance#Objective-C
    
    NSInteger sl = [self length];
    NSInteger tl = [string length];
    NSInteger *d = calloc(sizeof(*d), (sl+1) * (tl+1));
    
#define d(i, j) d[((j) * sl) + (i)]
    for (NSInteger i = 0; i <= sl; i++) {
        d(i, 0) = i;
    }
    for (NSInteger j = 0; j <= tl; j++) {
        d(0, j) = j;
    }
    for (NSInteger j = 1; j <= tl; j++) {
        for (NSInteger i = 1; i <= sl; i++) {
            if ([self characterAtIndex:i-1] == [string characterAtIndex:j-1]) {
                d(i, j) = d(i-1, j-1);
            } else {
                d(i, j) = MIN(d(i-1, j), MIN(d(i, j-1), d(i-1, j-1))) + 1;
            }
        }
    }
    
    NSInteger r = d(sl, tl);
#undef d
    
    free(d);
    
    return r;
}

@end
