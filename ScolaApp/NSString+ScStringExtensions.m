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

#import "ScLogging.h"

static const char base64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";


@implementation NSString (ScStringExtensions)

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
    NSString *thisStringHashed = [self hashUsingSHA1];
    NSString *otherStringHashed = [otherString hashUsingSHA1];
    
    const char *thisCString = [thisStringHashed cStringUsingEncoding:NSUTF8StringEncoding];
    const char *otherCString = [otherStringHashed cStringUsingEncoding:NSUTF8StringEncoding];
    
    size_t hashLength = strlen(thisCString);
    
    char diffedBytes[hashLength + 1];
    diffedBytes[hashLength] = (char)0;
    
    for (int i = 0; i < hashLength; i++) {
        char char1 = thisCString[i];
        char char2 = otherCString[hashLength - (i + 1)];
        
        if (char1 > char2) {
            diffedBytes[i] = char1 - char2 + 33; // ASCII 33 = '!'
        } else {
            diffedBytes[i] = char2 - char1 + 33;
        }
    }
    
    return [NSString stringWithCString:diffedBytes encoding:NSUTF8StringEncoding];;
}


- (NSString *)removeLeadingAndTrailingSpaces
{
    NSString *thisString = self;
    NSUInteger spaceLocation = [thisString rangeOfString:@" "].location;
    
    while (spaceLocation == 0) {
        thisString = [thisString substringFromIndex:1];
        spaceLocation = [thisString rangeOfString:@" "].location;
    }
    
    spaceLocation = [thisString rangeOfString:@" " options:NSBackwardsSearch].location;
    
    while (spaceLocation == thisString.length - 1) {
        thisString = [thisString substringToIndex:spaceLocation];
        spaceLocation = [thisString rangeOfString:@" " options:NSBackwardsSearch].location;
    }
    
    return thisString;
}

@end
