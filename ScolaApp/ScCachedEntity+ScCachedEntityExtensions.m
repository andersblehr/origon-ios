//
//  ScCachedEntity+ScCachedEntityExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 20.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScCachedEntity+ScCachedEntityExtensions.h"

#import "NSDate+ScDateExtensions.h"
#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"

#import "ScLogging.h"
#import "ScMeta.h"

#import "ScCachedEntityGhost.h"
#import "ScMember.h"
#import "ScMemberResidency.h"


@implementation ScCachedEntity (ScCachedEntityExtensions)


#pragma mark - Overriddes

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
        value = [NSDate dateWithDeserialisedDate:value];
    }
    
    [super setValue:value forKey:key];
}


#pragma mark - Auxiliary methods

- (NSDictionary *)entityRef
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    [dictionary setObject:self.entityId forKey:kPropertyEntityId];
    [dictionary setObject:self.entity.name forKey:kPropertyEntityClass];
    
    return dictionary;
}


#pragma mark - Dictionary serialisation & deserialisation

+ (id)entityWithDictionary:(NSDictionary *)dictionary
{
    NSMutableDictionary *entityRefs = [[NSMutableDictionary alloc] init];
    NSString *entityId = [dictionary valueForKey:kPropertyEntityId];
    
    ScCachedEntity *entity = [[ScMeta m].context fetchEntityFromCache:entityId];
    
    if (!entity) {
        NSString *entityClass = [dictionary objectForKey:kPropertyEntityClass];
        
        entity = [[ScMeta m].context entityForClass:NSClassFromString(entityClass) entityId:entityId];
        entity.scolaId = [dictionary objectForKey:kPropertyScolaId];
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
    
    [[ScMeta m] stageServerEntity:entity];
    
    if ([entityRefs count] > 0) {
        [[ScMeta m] stageServerEntityRefs:entityRefs forEntity:entity];
    }
    
    return entity;
}


- (NSDictionary *)toDictionary
{
    NSMutableDictionary *entityDictionary = [[NSMutableDictionary alloc] init];
    
    NSDictionary *attributes = [self.entity attributesByName];
    NSDictionary *relationships = [self.entity relationshipsByName];
    
    [entityDictionary setObject:self.entity.name forKey:kPropertyEntityClass];
    
    for (NSString *name in [attributes allKeys]) {
        if (![self isTransientProperty:name]) {
            id value = [self valueForKey:name];
            
            if (value) {
                [entityDictionary setObject:value forKey:name];
            }
        }
    }
    
    for (NSString *name in [relationships allKeys]) {
        NSRelationshipDescription *relationship = [relationships objectForKey:name];
        
        if (!relationship.isToMany && ![self isTransientProperty:name]) {
            ScCachedEntity *entity = [self valueForKey:name];
            
            if (entity) {
                [entityDictionary setObject:[entity entityRef] forKey:name];
            }
        }
    }
    
    return entityDictionary;
}


#pragma mark - Internal consistency

- (BOOL)isTransientProperty:(NSString *)property
{
    return [property isEqualToString:@"hashCode"];
}


- (BOOL)isPersisted
{
    ScLogDebug(@"Date modified: %@", self.dateModified);
    return (self.dateModified != nil);
}


- (BOOL)isDirty
{
    return ([self.hashCode integerValue] != [self computeHashCode]);
}


- (void)internaliseRelationships
{
    self.hashCode = [NSNumber numberWithInteger:[self computeHashCode]];
    
    NSDictionary *entityRefs = [[ScMeta m] stagedServerEntityRefsForEntity:self];
    
    for (NSString *name in [entityRefs allKeys]) {
        NSDictionary *entityRef = [entityRefs objectForKey:name];
        NSString *destinationId = [entityRef objectForKey:kPropertyEntityId];
        
        ScCachedEntity *entity = [[ScMeta m] stagedServerEntityWithId:destinationId];
        
        if (!entity) {
            entity = [[ScMeta m].context fetchEntityFromCache:destinationId];
        }
        
        if (entity) {
            [self setValue:entity forKey:name];
        }
    }
}


- (NSUInteger)computeHashCode
{
    NSDictionary *attributes = [self.entity attributesByName];
    NSDictionary *relationships = [self.entity relationshipsByName];
    
    NSArray *sortedAttributeKeys = [[attributes allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSArray *sortedRelationshipKeys = [[relationships allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    NSString *allProperties = @"";
    
    for (NSString *name in sortedAttributeKeys) {
        if (![self isTransientProperty:name]) {
            id value = [self valueForKey:name];
            
            if (value) {
                NSString *property = [NSString stringWithFormat:@"[%@:%@]", name, value];
                allProperties = [allProperties stringByAppendingString:property];
            }
        }
    }
    
    for (NSString *name in sortedRelationshipKeys) {
        NSRelationshipDescription *relationship = [relationships objectForKey:name];
        
        if (!relationship.isToMany && ![self isTransientProperty:name]) {
            ScCachedEntity *entity = [self valueForKey:name];
            
            if (entity) {
                NSString *property = [NSString stringWithFormat:@"[%@:%@]", name, entity.entityId];
                allProperties = [allProperties stringByAppendingString:property];
            }
        }
    }
    
    return [allProperties hash];
}


#pragma mark - Entity meta data handling

- (NSString *)expiresInTimeframe
{
    NSEntityDescription *entity = self.entity;
    NSString *expires = [entity.userInfo objectForKey:@"expires"];
    
    if (!expires) {
        ScLogBreakage(@"Expiry information missing for entity '%@'.", entity.name);
        
        // TODO: Keep track of and act on entity expiry dates
    }
    
    return expires;
}


#pragma mark - Entity ghost instantiation

- (ScCachedEntityGhost *)spawnEntityGhost
{
    ScScola *entityScola = [[ScMeta m].context fetchEntityFromCache:self.scolaId];
    ScCachedEntityGhost *entityGhost = [[ScMeta m].context entityForClass:ScCachedEntityGhost.class inScola:entityScola entityId:self.entityId];
    
    entityGhost.ghostedEntityClass = NSStringFromClass(self.class);
    
    return entityGhost;
}

@end
