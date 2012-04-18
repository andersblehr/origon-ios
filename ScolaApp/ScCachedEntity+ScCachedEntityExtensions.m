//
//  ScCachedEntity+ScCachedEntityExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 20.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScCachedEntity+ScCachedEntityExtensions.h"

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"

#import "ScLogging.h"
#import "ScMember.h"
#import "ScMemberResidency.h"
#import "ScMeta.h"


@implementation ScCachedEntity (ScCachedEntityExtensions)


#pragma mark - Overridden methods

- (id)valueForKey:(NSString *)key
{
    id value = [super valueForKey:key];
    
    if (value && [value isKindOfClass:NSDate.class]) {
        value = [NSNumber numberWithLongLong:[value timeIntervalSince1970] * 1000];
    }
    
    return value;
}


- (void)setValue:(id)value forKey:(NSString *)key
{
    NSAttributeDescription *attribute = [[self.entity attributesByName] objectForKey:key];
    
    if (attribute.attributeType == NSDateAttributeType) {
        value = [NSDate dateWithTimeIntervalSince1970:[value doubleValue] / 1000];
    }
    
    [super setValue:value forKey:key];
}


#pragma mark - Auxiliary methods

- (NSDictionary *)entityRef
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    [dictionary setObject:self.entityId forKey:kKeyEntityId];
    [dictionary setObject:self.entity.name forKey:kKeyEntityClass];
    
    return dictionary;
}


#pragma mark - Entity meta information

- (NSString *)expiresInTimeframe
{
    NSEntityDescription *entity = self.entity;
    NSString *expires = [entity.userInfo objectForKey:@"expires"];
    
    if (!expires) {
        ScLogBreakage(@"Expiry information missing for entity '%@'.", entity.name);
    }
    
    return expires;
}


#pragma mark - Dictionary serialisation & deserialisation

- (NSDictionary *)toDictionary
{
    NSMutableDictionary *entityDictionary = [[NSMutableDictionary alloc] init];
    NSEntityDescription *entityDescription = self.entity;
    NSDictionary *attributes = [entityDescription attributesByName];
    NSDictionary *relationships = [entityDescription relationshipsByName];
    
    [entityDictionary setObject:entityDescription.name forKey:kKeyEntityClass];
    
    for (NSString *name in [attributes allKeys]) {
        id value = [self valueForKey:name];
        
        if (value) {
            [entityDictionary setObject:value forKey:name];
        }
    }
    
    for (NSString *name in [relationships allKeys]) {
        NSRelationshipDescription *relationship = [relationships objectForKey:name];
        
        if (!relationship.isToMany) {
            ScCachedEntity *entity = [self valueForKey:name];
            
            if (entity) {
                [entityDictionary setObject:[entity entityRef] forKey:name];
            }
        }
    }
    
    return entityDictionary;
}


- (void)internaliseRelationships:(NSDictionary *)entityAsDictionary entities:(NSDictionary *)entityLookUp
{
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    NSEntityDescription *entityDescription = self.entity;
    NSDictionary *relationships = [entityDescription relationshipsByName];
    
    for (NSString *name in [relationships allKeys]) {
        NSRelationshipDescription *relationship = [relationships objectForKey:name];
        
        if (!relationship.isToMany) {
            NSString *entityRefName = [NSString stringWithFormat:@"%@%@", name, @"Ref"];
            NSDictionary *entityRef = [entityAsDictionary objectForKey:entityRefName];
            
            if (entityRef) {
                NSString *entityId = [entityRef objectForKey:kKeyEntityId];
                ScCachedEntity *entity = [entityLookUp objectForKey:entityId];
                
                if (!entity) {
                    entity = [context fetchEntityWithId:entityId];
                }
                
                if (entity) {
                    [self setValue:entity forKey:name];
                    
                    NSRelationshipDescription *inverse = [relationship inverseRelationship];
                    
                    if (inverse.isToMany) {
                        NSString *inverseName = inverse.name;
                        NSMutableSet *inverseSet = [entity mutableSetValueForKey:inverseName];
                        
                        [inverseSet addObject:self];
                    }
                } else {
                    ScLogBreakage(@"Cannot internalise relationship to lost entity (id: %@).", entityId);
                }
            }
        }
    }
}

@end
