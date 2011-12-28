//
//  NSURL+ScURLExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 12.12.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (ScURLQueryParameters)

+ (NSString *)URLEscapeString:(NSString *)unencodedString;

- (NSURL *)URLByAppendingURLParameter:(NSString *)key withValue:(NSString *)value;
- (NSURL *)URLByAppendingURLParameters:(NSDictionary *)queryParameters;

@end
