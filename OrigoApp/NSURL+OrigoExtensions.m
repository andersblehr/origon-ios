//
//  NSURL+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "NSURL+OrigoExtensions.h"

static NSString *kURLParameterFormat = @"%@%@=%@";

@implementation NSURL (OrigoExtensions)

+ (NSString *)URLEscapeString:(NSString *)unencodedString 
{
    CFStringRef originalStringRef = (__bridge_retained CFStringRef)unencodedString;
    NSString *URLEscapedString = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, originalStringRef, NULL, (CFStringRef)@"=@", kCFStringEncodingUTF8);
    CFRelease(originalStringRef);
    
    return URLEscapedString;
}


- (NSURL *)URLByAppendingURLParameters:(NSDictionary *)URLParameters
{
    NSMutableString *URLAsString = [[NSMutableString alloc] initWithString:[self absoluteString]];
    NSString *separator = ([URLAsString rangeOfString:@"?"].location == NSNotFound) ? @"?" : @"&";
    
    if ([URLParameters count]) {
        for (NSString *key in [URLParameters allKeys]) {
            NSString *URLEscapedValue = [NSURL URLEscapeString:[URLParameters objectForKey:key]];
            [URLAsString appendFormat:kURLParameterFormat, separator, key, URLEscapedValue];
            
            separator = @"&";
        }
    }
    
    return [NSURL URLWithString:URLAsString];
}

@end
