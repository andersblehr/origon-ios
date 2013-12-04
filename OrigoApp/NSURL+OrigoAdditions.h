//
//  NSURL+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface NSURL (OrigoAdditions)

+ (NSString *)URLEscapeString:(NSString *)unencodedString;
- (NSURL *)URLByAppendingURLParameters:(NSDictionary *)queryParameters;

@end
