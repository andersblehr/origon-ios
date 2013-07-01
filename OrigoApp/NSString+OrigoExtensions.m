//
//  NSString+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved. Except:
//   - (NSString *)base64Encoded
//

#import "NSString+OrigoExtensions.h"

NSString * const kListSeparator = @"|";
NSString * const kSeparatorSpace = @" ";
NSString * const kSeparatorNewline = @"\n";
NSString * const kSeparatorComma = @", ";
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
    NSArray *whiteSpaceCharacters = @[@" ", @"\n"];
    NSArray *lines = [self lines];
    NSString *reconstructedString = nil;
    
    for (NSString *line in lines) {
        NSString *workingCopy = [NSString stringWithString:line];
        NSString *workingCopyBeforePass = nil;
        
        while (![workingCopy isEqualToString:workingCopyBeforePass]) {
            workingCopyBeforePass = workingCopy;
            
            for (NSString *space in whiteSpaceCharacters) {
                NSUInteger spaceLocation = [workingCopy rangeOfString:space].location;
                
                while (spaceLocation == 0) {
                    workingCopy = [workingCopy substringFromIndex:1];
                    spaceLocation = [workingCopy rangeOfString:space].location;
                }
                
                spaceLocation = [workingCopy rangeOfString:space options:NSBackwardsSearch].location;
                
                while (spaceLocation == [workingCopy length] - 1) {
                    workingCopy = [workingCopy substringToIndex:spaceLocation];
                    spaceLocation = [workingCopy rangeOfString:space options:NSBackwardsSearch].location;
                }
            }
        }
        
        if (!reconstructedString) {
            reconstructedString = workingCopy;
        } else if ([workingCopy length]) {
            reconstructedString = [reconstructedString stringByAppendingString:workingCopy separator:kSeparatorNewline];
        }
    }
    
    return reconstructedString;
}


- (NSString *)stringByAppendingString:(NSString *)string separator:(NSString *)separator
{
    NSString *reworkedString = self;
    
    if ([self length]) {
        reworkedString = [reworkedString stringByAppendingString:separator];
    }
    
    return [reworkedString stringByAppendingString:string];
}


- (NSString *)stringByReplacingSeparator:(NSString *)oldSeparator withSeparator:(NSString *)newSeparator
{
    NSMutableString *reworkedString = [NSMutableString stringWithString:self];
    
    [reworkedString replaceOccurrencesOfString:oldSeparator withString:newSeparator options:NSLiteralSearch range:NSMakeRange(0, [self length])];
    
    return reworkedString;
}

@end
