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

#import "ScDevice.h"
#import "ScScolaAddress.h"
#import "ScScolaMember.h"
#import "ScScolaMemberResidency.h"
#import "ScScolaMembership.h"


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


#pragma mark - Pseudo accessors

- (ScRemotePersistenceState)persistenceState
{
    return [self.remotePersistenceState intValue];
}


- (void)setPersistenceState:(ScRemotePersistenceState)remotePersistenceState
{
    self.remotePersistenceState = [NSNumber numberWithInt:remotePersistenceState];
}


#pragma mark - Entity meta information

- (BOOL)isSharedEntity
{
    BOOL isSharedEntity = NO;
    
    isSharedEntity = isSharedEntity || [self isKindOfClass:ScScolaAddress.class];
    isSharedEntity = isSharedEntity || [self isKindOfClass:ScScolaMember.class];
    isSharedEntity = isSharedEntity || [self isKindOfClass:ScScolaMemberResidency.class];
    
    return isSharedEntity;
}


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
        
    if (self.persistenceState == ScRemotePersistenceStateDirtyNotScheduled) {
        self.persistenceState = ScRemotePersistenceStateDirtyScheduled;

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
            
            if (relationship.isToMany) {
                NSSet *targetEntities = [self valueForKey:name];
                NSMutableArray *targetEntityRefs = [[NSMutableArray alloc] init];
                
                for (ScCachedEntity *entity in targetEntities) {
                    [targetEntityRefs addObject:[entity entityRef]];
                }
                
                [entityDictionary setObject:targetEntityRefs forKey:name];
            } else {
                ScCachedEntity *entity = [self valueForKey:name];
                
                if (entity) {
                    [entityDictionary setObject:[entity entityRef] forKey:name];
                }
            }
        }
    }
    
    return entityDictionary;
}


- (void)internaliseRelationships:(NSDictionary *)entityAsDictionary entities:(NSDictionary *)entityLookUp
{
    ScLogDebug(@"Internalising relationships for entity (id: %@; class: %@).", self.entityId, [entityAsDictionary objectForKey:kKeyEntityClass]);
    
    NSManagedObjectContext *context = [ScMeta m].managedObjectContext;
    NSEntityDescription *entityDescription = self.entity;
    NSDictionary *relationships = [entityDescription relationshipsByName];
    
    for (NSString *name in [relationships allKeys]) {
        NSRelationshipDescription *relationship = [relationships objectForKey:name];
        
        if (!relationship.isToMany) {
            ScLogDebug(@"Internalising relationship '%@'.", name);
            
            NSString *entityRefName = [NSString stringWithFormat:@"%@%@", name, @"Ref"];
            NSDictionary *entityRef = [entityAsDictionary objectForKey:entityRefName];
            
            if (entityRef) {
                NSString *entityId = [entityRef objectForKey:kKeyEntityId];
                NSString *entityClass = [entityRef objectForKey:kKeyEntityClass];
                
                ScLogDebug(@"Found entity ref (id: %@; class: %@).", entityId, entityClass);
                
                ScCachedEntity *entity = [entityLookUp objectForKey:entityId];
                
                if (!entity) {
                    ScLogDebug(@"Ref'ed entity not in dictionary, looking in CD cache.");
                    entity = [context fetchEntityWithId:entityId];
                    
                    if (!entity) {
                        ScLogDebug(@"Ref'ed entity not in CD cache either.");
                    }
                } else {
                    ScLogDebug(@"Found ref'ed entity in dictionary.");
                }
                
                if (entity) {
                    [self setValue:entity forKey:name];
                    
                    ScLogDebug(@"Relationship '%@' internalised OK.", name);
                    
                    NSRelationshipDescription *inverse = [relationship inverseRelationship];
                    
                    if (inverse.isToMany) {
                        NSString *inverseName = inverse.name;
                        NSMutableSet *inverseSet = [entity mutableSetValueForKey:inverseName];
                        
                        [inverseSet addObject:self];
                        
                        ScLogDebug(@"Inverse relationship '%@' internalised OK.", inverseName);
                    }
                } else {
                    ScLogBreakage(@"Cannot internalise relationship to lost entity (id: %@).", entityId);
                }
            } else {
                ScLogDebug(@"No entity ref for relationship (name: %@).", name);
            }
        }
    }
}

@end
