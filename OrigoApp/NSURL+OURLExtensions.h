//
//  NSURL+OURLExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (OURLQueryParameters)

+ (NSString *)URLEscapeString:(NSString *)unencodedString;

- (NSURL *)URLByAppendingURLParameter:(NSString *)key withValue:(NSString *)value;
- (NSURL *)URLByAppendingURLParameters:(NSDictionary *)queryParameters;

@end
