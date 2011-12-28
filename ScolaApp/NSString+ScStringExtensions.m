//
//  NSString+ScStringExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 28.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved. Except:
//   - (NSString *)base64Encoded
//

#import <CommonCrypto/CommonDigest.h>

#import "NSString+ScStringExtensions.h"

static const char base64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";


@implementation NSString (ScStringExtensions)

- (NSString *)base64EncodedString;
{
    //  Public domain. Credits: http://www.cocoadev.com/index.pl?BaseSixtyFour
    
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
		
		//  Encode the bytes in the buffer to four characters, including padding "=" characters if necessary.
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
    NSData *bytes = [NSData dataWithBytes:charString length:self.length];
    
    uint8_t SHA1Digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(bytes.bytes, bytes.length, SHA1Digest);
    
    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", SHA1Digest[i]];
    }
    
    return hash;
}


- (NSString *)diff:(NSString *)otherString
{
    NSString *thisString = self;
    
    NSMutableString *longestString;
    NSMutableString *shortestString;
    
    if (thisString.length > otherString.length) {
        longestString = [NSMutableString stringWithString:thisString];
        shortestString = [NSMutableString stringWithString:otherString];
    } else {
        longestString = [NSMutableString stringWithString:otherString];
        shortestString = [NSMutableString stringWithString:thisString];
    }
    
    NSString *originalShortestString = [NSString stringWithString:shortestString];
    while (longestString.length > shortestString.length) {
        [shortestString appendString:originalShortestString];
    }
    
    const char *longestCString = [shortestString cStringUsingEncoding:NSUTF8StringEncoding];
    const char *shortestCString = [longestString cStringUsingEncoding:NSUTF8StringEncoding];
    
    size_t longest = strlen(longestCString);
    size_t shortest = strlen(shortestCString);
    
    char diffedBytes[longest + 1];
    diffedBytes[longest] = (char)0;
    
    for (int i = 0; i < longest; i++) {
        if (longest - i > shortest) {
            diffedBytes[i] = longestCString[i];
        } else {
            char char1 = longestCString[i];
            char char2 = shortestCString[longest - (i + 1)];
            
            if (char1 > char2) {
                diffedBytes[i] = char1 - char2 + 33; // ASCII 33 = '!'
            } else {
                diffedBytes[i] = char2 - char1 + 33;
            }
        }
    }
    
    return [NSString stringWithCString:diffedBytes encoding:NSUTF8StringEncoding];;
}



@end
