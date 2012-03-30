//
//  NSJSONSerialization+ScJSONSerializationExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 25.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSJSONSerialization (ScJSONSerializationExtensions)

+ (NSData *)serializeToJSON:(id)object;
+ (id)deserializeJSON:(NSData *)JSONData;

@end