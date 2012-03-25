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

+ (NSData *)serializeToJSON:(id)object
{
    NSData *serializedObject = nil;
    
    if (object) {
        NSError *error;
        serializedObject = [self dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:&error];
        
        if (!serializedObject) {
            ScLogVerbose(@"Error serialising object to JSON: %@", object);
            ScLogError(@"JSON serialisation error: %@", [error localizedDescription]);
        }
    }
    
    ScLogDebug(@"Produced JSON serialization: %@", [[NSString alloc] initWithData:serializedObject encoding:NSUTF8StringEncoding]);
    
    return serializedObject;
}


+ (id)deserializeJSON:(NSData *)JSONData
{
    id deserializedJSON = nil;
    
    if (JSONData) {
        NSError *error;
        deserializedJSON = [self JSONObjectWithData:JSONData options:NSJSONWritingPrettyPrinted error:&error];
        
        if (!deserializedJSON) {
            ScLogVerbose(@"Error deserialising JSON data: %@", [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding]);
            ScLogError(@"JSON deserialisation error: %@", [error localizedDescription]);
        }
    }
    
    ScLogDebug(@"Deserialized JSON: %@", deserializedJSON);
    
    return deserializedJSON;
}

@end
