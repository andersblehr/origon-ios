//
//  NSJSONSerialization+ScJSONSerializationExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 25.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSJSONSerialization (ScJSONSerializationExtensions)

+ (NSData *)serialiseToJSON:(id)object;
+ (id)deserialiseJSON:(NSData *)JSONData;

@end
