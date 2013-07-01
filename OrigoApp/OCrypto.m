//
//  OCrypto.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OCrypto.h"

#import <CommonCrypto/CommonDigest.h>

#import "OMeta.h"

#import "NSDate+OrigoExtensions.h"

static NSString * const kOrigoSeasoning = @"socroilgao";

static const char base64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";


@implementation OCrypto

#pragma mark - Auxiliary methods

+ (NSString *)string:(NSString *)string seasonedWith:(NSString *)seasoning;
{
    NSString *selfHash = [self SHA1HashForString:string];
    NSString *seasoningHash = [self SHA1HashForString:seasoning];
    
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


+ (NSString *)seasonAndHashString:(NSString *)string
{
    return [self SHA1HashForString:[self string:string seasonedWith:kOrigoSeasoning]];
}


#pragma mark - Token and password processing

+ (NSString *)timestampToken
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:kDateTimeFormatZulu];
    
    NSString *timestamp = [dateFormatter stringFromDate:[NSDate date]];
    NSString *base64EncodedTimestamp = [self base64EncodeString:timestamp];
    
    return [base64EncodedTimestamp stringByAppendingString:[self seasonAndHashString:timestamp]];
}


+ (NSString *)authTokenWithExpiryDate:(NSDate *)expiryDate
{
    NSString *rawToken = [self string:[OMeta m].deviceId seasonedWith:expiryDate.description];
    
    return [self SHA1HashForString:rawToken];
}


+ (NSString *)basicAuthHeaderWithUserId:(NSString *)userId password:(NSString *)password
{
    NSString *credentials = [NSString stringWithFormat:@"%@:%@", userId, password];
    
    return [NSString stringWithFormat:@"Basic %@", [self base64EncodeString:credentials]];
}


+ (NSString *)passwordHashWithPassword:(NSString *)password
{
    return [self seasonAndHashString:password];
}


#pragma mark - Crypto methods

//  This method from public domain. Credits: http://www.cocoadev.com/index.pl?BaseSixtyFour
+ (NSString *)base64EncodeString:(NSString *)string;
{
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    if ([data length] == 0)
		return @"";
    
    char *characters = malloc((([data length] + 2) / 3) * 4);
	if (characters == NULL)
		return nil;
	NSUInteger length = 0;
	
	NSUInteger i = 0;
	while (i < [string length])
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


+ (NSString *)SHA1HashForString:(NSString *)string;
{
    const char *charString = [string cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:charString length:[string length]];
    
    uint8_t SHA1Digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, [data length], SHA1Digest);
    
    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", SHA1Digest[i]];
    }
    
    return hash;
}


+ (NSString *)generateUUID
{
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef UUIDAsCFStringRef = CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
    
    NSString *UUID = [[NSString stringWithString:(__bridge NSString *)UUIDAsCFStringRef] lowercaseString];
    
    CFRelease(UUIDRef);
    CFRelease(UUIDAsCFStringRef);
    
    return UUID;
}

@end
