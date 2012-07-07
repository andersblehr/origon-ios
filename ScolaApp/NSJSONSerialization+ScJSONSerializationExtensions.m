//
//  NSJSONSerialization+ScJSONSerializationExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 25.03.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "NSJSONSerialization+ScJSONSerializationExtensions.h"

#import "ScLogging.h"


@implementation NSJSONSerialization (ScJSONSerializationExtensions)

+ (NSData *)serialise:(id)object
{
    NSData *serialisedObject = nil;
    
    if (object) {
        NSError *error;
        serialisedObject = [self dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:&error];
        
        if (!serialisedObject) {
            ScLogVerbose(@"Error serialising object to JSON: %@", object);
            ScLogError(@"JSON serialisation error: %@", error);
        }
    }
    
    ScLogDebug(@"Produced JSON serialisation: %@", [[NSString alloc] initWithData:serialisedObject encoding:NSUTF8StringEncoding]);
    
    return serialisedObject;
}


+ (id)deserialise:(NSData *)JSONData
{
    id deserialisedJSON = nil;
    
    if (JSONData) {
        NSError *error;
        deserialisedJSON = [self JSONObjectWithData:JSONData options:kNilOptions error:&error];
        
        if (!deserialisedJSON) {
            ScLogVerbose(@"Error deserialising JSON data: %@", [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding]);
            ScLogError(@"JSON deserialisation error: %@", error);
        }
    }
    
    ScLogDebug(@"Deserialised JSON: %@", deserialisedJSON);
    
    return deserialisedJSON;
}

@end
