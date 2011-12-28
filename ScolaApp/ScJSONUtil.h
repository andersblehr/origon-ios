//
//  ScJSONUtil.h
//  ScolaApp
//
//  Created by Anders Blehr on 26.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScJSONUtil : NSObject

extern NSString * const kScStringsClass;
extern NSString * const kScAuthResponseClass;

+ (NSDictionary *)dictionaryFromJSON:(NSData *)data forClass:(NSString *)expectedJSONClass;

@end
