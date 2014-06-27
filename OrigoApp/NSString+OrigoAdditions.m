//
//  NSString+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "NSString+OrigoAdditions.h"

NSString * const kCharacters0_9 = @"0123456789";

NSString * const kSeparatorColon = @":";
NSString * const kSeparatorComma = @", ";
NSString * const kSeparatorHash = @"#";
NSString * const kSeparatorNewline = @"\n";
NSString * const kSeparatorSpace = @" ";

NSString * const kSeparatorList = @";";
NSString * const kSeparatorMapping = @":";
NSString * const kSeparatorSegments = @"|";
NSString * const kSeparatorAlternates = @"|";

static CGFloat kMatchingEditDistancePercentage = 0.4f;


@implementation NSString (OrigoAdditions)

#pragma mark - Auxiliary methods

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


#pragma mark - Convenience methods

- (BOOL)hasValue
{
    return [self length] > 0;
}


- (BOOL)containsString:(NSString *)string
{
    return [self rangeOfString:string].location != NSNotFound;
}


- (BOOL)containsCharacter:(const char)character
{
    return [self containsString:[NSString stringWithFormat:@"%c", character]];
}


- (BOOL)fuzzyMatches:(NSString *)other
{
    NSString *string1 = [[self removeRedundantWhitespaceKeepNewlines:NO] lowercaseString];
    NSString *string2 = [[other removeRedundantWhitespaceKeepNewlines:NO] lowercaseString];
    
    NSArray *words1 = [string1 componentsSeparatedByString:kSeparatorSpace];
    NSArray *words2 = [string2 componentsSeparatedByString:kSeparatorSpace];
    
    if ([words1 count] > [words2 count]) {
        id temp = words1;
        
        words1 = words2;
        words2 = temp;
    }
    
    NSMutableArray *matchableWords2 = [words2 mutableCopy];
    BOOL wordsMatch = YES;
    
    for (NSString *word1 in words1) {
        if (wordsMatch) {
            NSInteger shortestEditDistance = NSIntegerMax;
            NSString *matchedWord2 = nil;
            
            for (NSString *word2 in matchableWords2) {
                NSInteger editDistance = [word1 levenshteinDistanceToString:word2];
                
                if (editDistance < shortestEditDistance) {
                    shortestEditDistance = editDistance;
                    matchedWord2 = word2;
                }
            }
            
            wordsMatch = (CGFloat)shortestEditDistance / (CGFloat)[word1 length] <= kMatchingEditDistancePercentage;
            
            if (wordsMatch) {
                [matchableWords2 removeObject:matchedWord2];
            }
        }
    }
    
    return wordsMatch;
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

- (NSString *)removeRedundantWhitespaceKeepNewlines:(BOOL)keepNewlines
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
        
        if (keepNewlines) {
            copy = [copy stringByReplacingSubstring:doubleNewline withString:kSeparatorNewline];
            copy = [copy stringByReplacingSubstring:spaceNewline withString:kSeparatorNewline];
            copy = [copy stringByReplacingSubstring:newlineSpace withString:kSeparatorNewline];
        } else {
            copy = [copy stringByReplacingSubstring:kSeparatorNewline withString:kSeparatorSpace];
        }
        
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
    
    if (substring && string) {
        [reworkedString replaceOccurrencesOfString:substring withString:string options:NSLiteralSearch range:NSMakeRange(0, [self length])];
    }
    
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


- (NSString *)stringByLowercasingFirstLetter
{
    return [[[self substringWithRange:NSMakeRange(0, 1)] lowercaseString] stringByAppendingString:[self substringFromIndex:1]];
}


#pragma mark - Name conversions

- (NSString *)givenName
{
    NSString *givenName = nil;
    NSArray *names = [self componentsSeparatedByString:kSeparatorSpace];
    
    if ([names count] == 1) {
        givenName = names[0];
    } else if ([names count]) {
        givenName = [OMeta usingEasternNameOrder] ? names[1] : names[0];
    }
    
    return givenName;
}


- (NSString *)localisedCountryName
{
    NSString *countryName = nil;
    
    if ([[NSLocale ISOCountryCodes] containsObject:self]) {
        countryName = [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:self];
    }
    
    return countryName;
}

@end
