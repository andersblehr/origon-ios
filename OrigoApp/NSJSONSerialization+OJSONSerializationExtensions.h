//
//  NSJSONSerialization+OJSONSerializationExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSJSONSerialization (OJSONSerializationExtensions)

+ (NSData *)serialise:(id)object;
+ (id)deserialise:(NSData *)JSONData;

@end
