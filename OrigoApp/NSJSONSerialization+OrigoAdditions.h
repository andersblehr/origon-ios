//
//  NSJSONSerialization+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OrigoApp.h"

@interface NSJSONSerialization (OrigoAdditions)

+ (NSData *)serialise:(id)object;
+ (id)deserialise:(NSData *)JSONData;

@end
