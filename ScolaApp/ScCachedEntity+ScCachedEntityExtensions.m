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


- (BOOL)doPersistProperty:(NSString *)property
{
    return YES;
}


#pragma mark - Dictionary serialisation & deserialisation

+ (ScCachedEntity *)entityWithDictionary:(NSDictionary *)dictionary
{
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    NSMutableDictionary *entityRefs = [[NSMutableDictionary alloc] init];
    NSString *entityId = [dictionary valueForKey:kKeyEntityId];
    
    ScCachedEntity *entity = [context fetchEntityWithId:entityId];
    
    if (!entity) {
        NSString *entityClass = [dictionary objectForKey:kKeyEntityClass];
        
        entity = [context entityForClass:NSClassFromString(entityClass) withId:entityId];
        entity.scolaId = [dictionary objectForKey:kKeyScolaId];
    }
    
    NSDictionary *attributes = [entity.entity attributesByName];
    NSDictionary *relationships = [entity.entity relationshipsByName];
    
    for (NSString *name in [attributes allKeys]) {
        id value = [dictionary objectForKey:name];
        
        if (value) {
            [entity setValue:value forKey:name];
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
    
    [[ScMeta m] addImportedEntity:entity];
    
    if ([entityRefs count] > 0) {
        [[ScMeta m] addImportedEntityRefs:entityRefs forEntity:entity];
    }
    
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
        if ([self doPersistProperty:name]) {
            id value = [self valueForKey:name];
            
            if (value) {
                [entityDictionary setObject:value forKey:name];
            }
        }
    }
    
    for (NSString *name in [relationships allKeys]) {
        if ([self doPersistProperty:name]) {
            NSRelationshipDescription *relationship = [relationships objectForKey:name];
            
            if (!relationship.isToMany) {
                ScCachedEntity *entity = [self valueForKey:name];
                
                if (entity) {
                    [entityDictionary setObject:[entity entityRef] forKey:name];
                }
            }
        }
    }
    
    return entityDictionary;
}


- (void)internaliseRelationships
{
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
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
        }
    }
}


#pragma mark - Entity meta data handling

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
