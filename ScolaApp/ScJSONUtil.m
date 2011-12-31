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

+ (NSDictionary *)dictionaryFromJSON:(NSData *)JSONData forClass:(NSString *)expectedClass
{
    NSDictionary *JSONDataAsDictionary = nil;
    
    if (JSONData) {
        NSError *error;
        NSDictionary *containerDictionary = [NSJSONSerialization JSONObjectWithData:JSONData options:kNilOptions error:&error];
        
        if (containerDictionary) {
            NSString *receivedClass = [[containerDictionary allKeys] objectAtIndex:0];
            
            if ([receivedClass isEqualToString:expectedClass]) {
                JSONDataAsDictionary = [containerDictionary objectForKey:receivedClass];
            } else {
                ScLogBreakage(@"Received JSON for class %@, expected %@", receivedClass, expectedClass); 
            }
        } else {
            ScLogError(@"Error parsing JSON data: %@, %@", error, [error userInfo]);
        }
    }
    
    return JSONDataAsDictionary;
}

@end
