//
//  ScJSONUtil.h
//  ScolaApp
//
//  Created by Anders Blehr on 26.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScJSONUtil : NSObject

+ (NSDictionary *)dictionaryFromJSON:(NSData *)JSONData;

@end
