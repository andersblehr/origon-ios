//
//  NSURL+OrigonAdditions.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

static NSString * const kURLParameterFormat = @"%@%@=%@";


@implementation NSURL (OrigonAdditions)

+ (NSString *)URLEscapeString:(NSString *)rawString 
{
    return [rawString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}


- (NSURL *)URLByAppendingURLParameters:(NSDictionary *)URLParameters
{
    NSMutableString *URLAsString = [[NSMutableString alloc] initWithString:[self absoluteString]];
    NSString *separator = [URLAsString containsString:@"?"] ? @"&" : @"?";
    
    if (URLParameters.count) {
        for (NSString *key in [URLParameters allKeys]) {
            NSString *URLEscapedValue = [NSURL URLEscapeString:URLParameters[key]];
            [URLAsString appendFormat:kURLParameterFormat, separator, key, URLEscapedValue];
            
            separator = @"&";
        }
    }
    
    return [NSURL URLWithString:URLAsString];
}

@end
