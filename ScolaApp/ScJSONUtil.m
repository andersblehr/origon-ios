//
//  ScJSONUtil.m
//  ScolaApp
//
//  Created by Anders Blehr on 26.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#import "ScJSONUtil.h"
#import "ScLogging.h"


@implementation ScJSONUtil

+ (NSDictionary *)dictionaryFromJSON:(NSData *)JSONData
{
    NSDictionary *JSONDataAsDictionary = nil;
    
    if (JSONData) {
        NSError *error;
        JSONDataAsDictionary = [NSJSONSerialization JSONObjectWithData:JSONData options:kNilOptions error:&error];
        
        if (!JSONDataAsDictionary) {
            ScLogError(@"Error parsing JSON data: %@, %@", error, [error userInfo]);
        }
    }
    
    return JSONDataAsDictionary;
}

@end
