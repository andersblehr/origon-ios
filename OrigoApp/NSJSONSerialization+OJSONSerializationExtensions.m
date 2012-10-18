//
//  NSJSONSerialization+OJSONSerializationExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "NSJSONSerialization+OJSONSerializationExtensions.h"

#import "OLogging.h"


@implementation NSJSONSerialization (ScJSONSerializationExtensions)

+ (NSData *)serialise:(id)object
{
    NSData *serialisedObject = nil;
    
    if (object) {
        NSError *error;
        serialisedObject = [self dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:&error];
        
        if (!serialisedObject) {
            OLogVerbose(@"Error serialising object to JSON: %@", object);
            OLogError(@"JSON serialisation error: %@", error);
        }
    }
    
    OLogDebug(@"Produced JSON serialisation: %@", [[NSString alloc] initWithData:serialisedObject encoding:NSUTF8StringEncoding]);
    
    return serialisedObject;
}


+ (id)deserialise:(NSData *)JSONData
{
    id deserialisedJSON = nil;
    
    if (JSONData) {
        NSError *error;
        deserialisedJSON = [self JSONObjectWithData:JSONData options:kNilOptions error:&error];
        
        if (!deserialisedJSON) {
            OLogVerbose(@"Error deserialising JSON data: %@", [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding]);
            OLogError(@"JSON deserialisation error: %@", error);
        }
    }
    
    OLogDebug(@"Deserialised JSON: %@", deserialisedJSON);
    
    return deserialisedJSON;
}

@end
