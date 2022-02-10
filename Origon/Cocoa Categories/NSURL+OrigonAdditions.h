//
//  NSURL+OrigonAdditions.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (OrigonAdditions)

+ (NSString *)URLEscapeString:(NSString *)rawString;
- (NSURL *)URLByAppendingURLParameters:(NSDictionary *)queryParameters;

@end
