//
//  NSURL+OURLExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "NSURL+OURLExtensions.h"

@implementation NSURL (ScURLExtensions)


+ (NSString *)URLEscapeString:(NSString *)unencodedString 
{
    CFStringRef originalStringRef = (__bridge_retained CFStringRef)unencodedString;
    NSString *URLEscapedString = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, originalStringRef, NULL, (CFStringRef)@"@", kCFStringEncodingUTF8);
    CFRelease(originalStringRef);
    
    return URLEscapedString;
}


- (NSURL *)URLByAppendingURLParameter:(NSString *)key withValue:(NSString *)value
{
    NSString *URLEscapedKey = [NSURL URLEscapeString:key];
    NSString *URLEscapedValue = [NSURL URLEscapeString:value];
    
    NSMutableString *URLAsString = [[NSMutableString alloc] initWithString:[self absoluteString]];
    NSString *separator = ([URLAsString rangeOfString:@"?"].location == NSNotFound) ? @"?" : @"&";
    
    [URLAsString appendFormat:@"%@%@=%@", separator, URLEscapedKey, URLEscapedValue];
    
    return [NSURL URLWithString:URLAsString];
}


- (NSURL *)URLByAppendingURLParameters:(NSDictionary *)URLParameters
{
    NSMutableString *URLAsString = [[NSMutableString alloc] initWithString:[self absoluteString]];
    
    if ([URLParameters count] > 0) {
        NSString *separator =
            ([URLAsString rangeOfString:@"?"].location == NSNotFound) ? @"?" : @"&";
        
        for (id key in URLParameters) {
            NSString *URLEscapedKey = [NSURL URLEscapeString:[key description]];
            NSString *URLEscapedValue = [NSURL URLEscapeString:[URLParameters objectForKey:key]];
            [URLAsString appendFormat:@"%@%@=%@", separator, URLEscapedKey, URLEscapedValue];
            
            separator = @"&";
        }
    }
    
    return [NSURL URLWithString:URLAsString];
}

@end
