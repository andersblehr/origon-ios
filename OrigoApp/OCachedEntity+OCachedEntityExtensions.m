//
//  OCachedEntity+OCachedEntityExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OCachedEntity+OCachedEntityExtensions.h"

#import "NSDate+ODateExtensions.h"
#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"

#import "OMeta.h"

#import "OCachedEntityGhost.h"
#import "OMember.h"
#import "OMemberResidency.h"


@implementation OCachedEntity (OCachedEntityExtensions)


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
    
    OCachedEntity *entity = [[OMeta m].context lookUpEntityInCache:entityId];
    
    if (!entity) {
        NSString *entityClass = [dictionary objectForKey:kPropertyEntityClass];
        
        entity = [[OMeta m].context entityForClass:NSClassFromString(entityClass) entityId:entityId];
        entity.origoId = [dictionary objectForKey:kPropertyOrigoId];
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
    
    [[OMeta m] stageServerEntity:entity];
    
    if ([entityRefs count] > 0) {
        [[OMeta m] stageServerEntityRefs:entityRefs forEntity:entity];
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
            OCachedEntity *entity = [self valueForKey:name];
            
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
    return (self.dateModified != nil);
}


- (BOOL)isDirty
{
    return ([self.hashCode integerValue] != [self computeHashCode]);
}


- (void)internaliseRelationships
{
    self.hashCode = [NSNumber numberWithInteger:[self computeHashCode]];
    
    NSDictionary *entityRefs = [[OMeta m] stagedServerEntityRefsForEntity:self];
    
    for (NSString *name in [entityRefs allKeys]) {
        NSDictionary *entityRef = [entityRefs objectForKey:name];
        NSString *destinationId = [entityRef objectForKey:kPropertyEntityId];
        
        OCachedEntity *entity = [[OMeta m] stagedServerEntityWithId:destinationId];
        
        if (!entity) {
            entity = [[OMeta m].context lookUpEntityInCache:destinationId];
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
            OCachedEntity *entity = [self valueForKey:name];
            
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
        // TODO: Keep track of and act on entity expiry dates
    }
    
    return expires;
}


#pragma mark - Entity ghost instantiation

- (OCachedEntityGhost *)spawnEntityGhost
{
    OOrigo *entityOrigo = [[OMeta m].context lookUpEntityInCache:self.origoId];
    OCachedEntityGhost *entityGhost = [[OMeta m].context entityForClass:OCachedEntityGhost.class inOrigo:entityOrigo entityId:self.entityId];
    
    entityGhost.ghostedEntityClass = NSStringFromClass(self.class);
    
    return entityGhost;
}

@end
