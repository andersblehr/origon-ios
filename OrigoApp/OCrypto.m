//
//  OCrypto.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OCrypto.h"

#import <CommonCrypto/CommonDigest.h>

#import "NSDate+OrigoExtensions.h"

#import "OLogging.h"
#import "OMeta.h"

static NSString * const kDefaultSeasoning = @"socroilgao";

static NSString * const kCredentialsFormat = @"%@:%@";
static NSString * const kBasicAuthFormat = @"Basic %@";

static NSInteger const kActivationCodeLength = 6;


@implementation OCrypto

#pragma mark - Auxiliary methods

+ (NSString *)string:(NSString *)string seasonedWith:(NSString *)seasoning;
{
    NSString *selfHash = [self computeSHA1HashForString:string];
    NSString *seasoningHash = [self computeSHA1HashForString:seasoning];
    
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
    return [self computeSHA1HashForString:[self string:string seasonedWith:kDefaultSeasoning]];
}


#pragma mark - Tokens & authentication

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
    
    return [self computeSHA1HashForString:rawToken];
}


+ (NSString *)passwordHashWithPassword:(NSString *)password
{
    return [self seasonAndHashString:password];
}


+ (NSString *)basicAuthHeaderWithUserId:(NSString *)userId password:(NSString *)password
{
    NSString *credentials = [NSString stringWithFormat:kCredentialsFormat, userId, password];
    
    return [NSString stringWithFormat:kBasicAuthFormat, [self base64EncodeString:credentials]];
}


#pragma mark - Encoding & hashing

+ (NSString *)base64EncodeString:(NSString *)string;
{
    static const char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    NSString *encodedString = nil;
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    if ([data length]) {
        char *characters = malloc((([data length] + 2) / 3) * 4);

        NSUInteger length = 0;
        NSUInteger i = 0;
        
        while (i < [string length]) {
            char buffer[3] = {0,0,0};
            short bufferLength = 0;
            
            while ((bufferLength < 3) && (i < [data length])) {
                buffer[bufferLength++] = ((char *)[data bytes])[i++];
            }
            
            characters[length++] = table[(buffer[0] & 0xFC) >> 2];
            characters[length++] = table[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];
            
            if (bufferLength > 1) {
                characters[length++] = table[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
            } else {
                characters[length++] = '=';
            }
            
            if (bufferLength > 2) {
                characters[length++] = table[buffer[2] & 0x3F];
            } else {
                characters[length++] = '=';
            }
        }
        
        encodedString = [[NSString alloc] initWithBytesNoCopy:characters length:length encoding:NSASCIIStringEncoding freeWhenDone:YES];
    }
    
    return encodedString;
}


+ (NSString *)computeSHA1HashForString:(NSString *)string;
{
    const char *CString = [string cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:CString length:[string length]];
    
    uint8_t SHA1Digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, [data length], SHA1Digest);
    
    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", SHA1Digest[i]];
    }
    
    return hash;
}


#pragma mark - Generating UUIDs & activation codes

+ (NSString *)generateUUID
{
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef UUIDAsCFStringRef = CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
    
    NSString *UUID = [[NSString stringWithString:(__bridge NSString *)UUIDAsCFStringRef] lowercaseString];
    
    CFRelease(UUIDRef);
    CFRelease(UUIDAsCFStringRef);
    
    return UUID;
}


+ (NSString *)generateActivationCode
{
    return [[self generateUUID] substringToIndex:kActivationCodeLength];
}

@end
