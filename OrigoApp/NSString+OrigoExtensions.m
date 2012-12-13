//
//  NSString+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved. Except:
//   - (NSString *)base64Encoded
//

#import <CommonCrypto/CommonDigest.h>

#import "NSString+OrigoExtensions.h"

#import "OMeta.h"
#import "OState.h"

NSString * const kOrigoSeasoning = @"socroilgao";

NSString * const kSeparatorSpace = @" ";
NSString * const kSeparatorNewline = @"\n";
NSString * const kSeparatorComma = @", ";
NSString * const kSeparatorHash = @"#";

static const char base64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";


@implementation NSString (OrigoExtensions)

#pragma mark - Crypto stuff

//  This method from public domain. Credits: http://www.cocoadev.com/index.pl?BaseSixtyFour
- (NSString *)base64EncodedString;
{
	NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    
    if ([data length] == 0)
		return @"";
    
    char *characters = malloc((([data length] + 2) / 3) * 4);
	if (characters == NULL)
		return nil;
	NSUInteger length = 0;
	
	NSUInteger i = 0;
	while (i < [self length])
	{
		char buffer[3] = {0,0,0};
		short bufferLength = 0;
		while (bufferLength < 3 && i < [data length])
			buffer[bufferLength++] = ((char *)[data bytes])[i++];
		
		characters[length++] = base64EncodingTable[(buffer[0] & 0xFC) >> 2];
		characters[length++] = base64EncodingTable[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];
		if (bufferLength > 1)
			characters[length++] = base64EncodingTable[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
		else characters[length++] = '=';
		if (bufferLength > 2)
			characters[length++] = base64EncodingTable[buffer[2] & 0x3F];
		else characters[length++] = '=';	
	}
	
	return [[NSString alloc] initWithBytesNoCopy:characters length:length encoding:NSASCIIStringEncoding freeWhenDone:YES];
}


- (NSString *)hashUsingSHA1
{
    const char *charString = [self cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *bytes = [NSData dataWithBytes:charString length:[self length]];
    
    uint8_t SHA1Digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(bytes.bytes, [bytes length], SHA1Digest);
    
    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", SHA1Digest[i]];
    }
    
    return hash;
}


- (NSString *)seasonWith:(NSString *)seasoning
{
    NSString *selfHash = [self hashUsingSHA1];
    NSString *seasoningHash = [seasoning hashUsingSHA1];
    
    const char *selfCString = [selfHash cStringUsingEncoding:NSUTF8StringEncoding];
    const char *seasoningCString = [seasoningHash cStringUsingEncoding:NSUTF8StringEncoding];
    
    size_t hashLength = strlen(selfCString);
    
    char seasonedBytes[hashLength + 1];
    seasonedBytes[hashLength] = (char)0;
    
    for (int i = 0; i < hashLength; i++) {
        char char1 = selfCString[i];
        char char2 = seasoningCString[hashLength - (i + 1)];
        
        if (char1 > char2) {
            seasonedBytes[i] = char1 - char2 + 33; // ASCII 33 = '!'
        } else {
            seasonedBytes[i] = char2 - char1 + 33;
        }
    }
    
    return [NSString stringWithCString:seasonedBytes encoding:NSUTF8StringEncoding];
}


#pragma mark - String operations

- (NSString *)removeSuperfluousWhitespace
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
        } else if ([workingCopy length] > 0) {
            reconstructedString = [reconstructedString stringByAppendingString:workingCopy separator:kSeparatorNewline];
        }
    }
    
    return reconstructedString;
}


- (NSString *)stringByAppendingString:(NSString *)string separator:(NSString *)separator
{
    NSString *returnString = self;
    
    if ([self length] > 0) {
        returnString = [returnString stringByAppendingString:separator];
    }
    
    return [returnString stringByAppendingString:string];
}


#pragma mark - Multi-line string details

- (NSArray *)lines
{
    return [self componentsSeparatedByString:kSeparatorNewline];
}


- (NSUInteger)lineCount
{
    return [[self lines] count];
}


#pragma mark - Devining tring content

- (BOOL)isEmailAddress
{
    NSUInteger atLocation = [self rangeOfString:@"@"].location;
    NSUInteger dotLocation = [self rangeOfString:@"." options:NSBackwardsSearch].location;
    NSUInteger spaceLocation = [self rangeOfString:@" "].location;
    
    BOOL isEmailAddress = (atLocation != NSNotFound);
    
    isEmailAddress = isEmailAddress && (dotLocation != NSNotFound);
    isEmailAddress = isEmailAddress && (dotLocation > atLocation);
    isEmailAddress = isEmailAddress && (spaceLocation == NSNotFound);
    
    return isEmailAddress;
}


#pragma mark - Given name from full name

+ (NSString *)givenNameFromFullName:(NSString *)fullName
{
    NSString *givenName = nil;
    NSArray *names = [fullName componentsSeparatedByString:@" "];
    
    if ([[OMeta m].displayLanguage isEqualToString:kLanguageHungarian]) {
        givenName = names[names.count - 1];
    } else {
        givenName = names[0];
    }
    
    return givenName;
}

@end
