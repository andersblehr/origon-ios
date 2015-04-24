//
//  NSJSONSerialization+OrigoAdditions.m
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "NSJSONSerialization+OrigoAdditions.h"


@implementation NSJSONSerialization (OrigoAdditions)

+ (NSData *)serialise:(id)object
{
    NSData *JSONSerialisation = nil;
    
    if (object) {
        NSError *error;
        JSONSerialisation = [self dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:&error];
        
        if (!JSONSerialisation) {
            OLogVerbose(@"Error serialising object to JSON: %@", object);
            OLogError(@"JSON serialisation error: %@", error);
        }
    }
    
    OLogDebug(@"Produced JSON serialisation: %@", [[NSString alloc] initWithData:JSONSerialisation encoding:NSUTF8StringEncoding]);
    
    return JSONSerialisation;
}


+ (id)deserialise:(NSData *)JSONData
{
    id deserialisedObjects = nil;
    
    if (JSONData) {
        NSError *error;
        deserialisedObjects = [self JSONObjectWithData:JSONData options:kNilOptions error:&error];
        
        if (!deserialisedObjects) {
            OLogVerbose(@"Error deserialising JSON data: %@", [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding]);
            OLogError(@"JSON deserialisation error: %@", error);
        }
    }
    
    OLogDebug(@"Deserialised objects: %@", deserialisedObjects);
    
    return deserialisedObjects;
}

@end
