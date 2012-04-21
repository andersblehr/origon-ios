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
#import "ScMeta.h"

#import "ScMember.h"
#import "ScMemberResidency.h"

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


- (void)mergeWithDictionary:(NSDictionary *)dictionary
{
    NSDictionary *attributes = [self.entity attributesByName];
    NSDictionary *relationships = [self.entity relationshipsByName];
    NSMutableDictionary *entityRefs = [[NSMutableDictionary alloc] init];
    
    for (NSString *name in [attributes allKeys]) {
        id value = [dictionary objectForKey:name];
        
        if (value) {
            [self setValue:value forKey:name];
        }
    }
    
    for (NSString *name in [relationships allKeys]) {
        NSRelationshipDescription *relationship = [relationships objectForKey:name];
        
        if (!relationship.isToMany) {
            NSString *entityRefName = [NSString stringWithFormat:@"%@Ref", name];
            NSDictionary *entityRef = [dictionary objectForKey:entityRefName];
            
            if (entityRef) {
                [entityRefs setObject:entityRef forKey:name];
            }
        }
    }
    
    [[ScMeta m] addImportedEntity:self];
    [[ScMeta m] addImportedEntityRefs:entityRefs forEntity:self];
}


#pragma mark - Dictionary serialisation & deserialisation

+ (ScCachedEntity *)entityWithDictionary:(NSDictionary *)dictionary
{
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    NSString *entityId = [dictionary valueForKey:kKeyEntityId];
    
    ScCachedEntity *entity = [context fetchEntityWithId:entityId];
    
    if (!entity) {
        NSString *entityClass = [dictionary objectForKey:kKeyEntityClass];
        
        entity = [context entityForClass:NSClassFromString(entityClass) withId:entityId];
        entity.scolaId = [dictionary objectForKey:kKeyScolaId];
    }
    
    [entity mergeWithDictionary:dictionary];
    
    return entity;
}


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


- (void)internaliseRelationships
{
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    NSDictionary *relationships = [self.entity relationshipsByName];
    NSDictionary *entityRefs = [[ScMeta m] importedEntityRefsForEntity:self];
    
    for (NSString *name in [entityRefs allKeys]) {
        NSDictionary *entityRef = [entityRefs objectForKey:name];
        NSString *destinationId = [entityRef objectForKey:kKeyEntityId];
        
        ScCachedEntity *entity = [[ScMeta m] importedEntityWithId:destinationId];
        
        if (!entity) {
            entity = [context fetchEntityWithId:destinationId];
        }
        
        if (entity) {
            [self setValue:entity forKey:name];
            
            NSRelationshipDescription *relationship = [relationships valueForKey:name];
            NSRelationshipDescription *inverse = [relationship inverseRelationship];
            
            if (inverse.isToMany) {
                NSMutableSet *inverseSet = [entity mutableSetValueForKey:inverse.name];
                [inverseSet addObject:self];
            }
        }
    }
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

@end
