//
//  NSManagedObjectContext+ScManagedObjectContextExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"

#import "ScLogging.h"
#import "ScMeta.h"
#import "ScServerConnection.h"
#import "ScUUIDGenerator.h"

#import "ScCachedEntity.h"
#import "ScCachedEntity+ScCachedEntityExtensions.h"

#import "ScHousehold.h"
#import "ScScola.h"
#import "ScScolaMember.h"
#import "ScSharedEntityRef.h"


@implementation NSManagedObjectContext (ScManagedObjectContextExtensions)


#pragma mark - Auxiliary methods

- (id)entityForClass:(Class)class
{
    return [self entityForClass:class withId:[ScUUIDGenerator generateUUID]];
}


- (id)entityForClass:(Class)class withId:(NSString *)entityId
{
    ScCachedEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(class) inManagedObjectContext:self];
    
    NSDate *now = [NSDate date];
    
    entity.entityId = entityId;
    entity.dateCreated = now;
    
    if (![entity isSharedEntity]) {
        entity.dateModified = now;
        entity.dateExpires = nil;
        
        NSString *expires = [entity expiresInTimeframe];
        
        if (expires) {
            // TODO: Process expiry instructions
        }
    }
    
    return entity;
}


- (id)mergeEntityFromDictionary:(NSDictionary *)dictionary
{
    NSString *entityId = [dictionary objectForKey:kKeyEntityId];
    NSString *entityClass = [dictionary objectForKey:kKeyEntityClass];
    
    ScCachedEntity *entity = [self fetchEntityWithId:entityId];
    
    if (!entity) {
        entity = [self entityForClass:NSClassFromString(entityClass) withId:entityId];
        ScLogDebug(@"Created new entity (id: %@; class: %@).", entityId, entityClass);
    } else {
        ScLogDebug(@"Found entity in CD cache (id: %@; class: %@).", entityId, entityClass);
    }
    
    NSEntityDescription *entityDescription = entity.entity;
    NSDictionary *attributes = [entityDescription attributesByName];
    
    for (NSString *name in [attributes allKeys]) {
        id value = [dictionary objectForKey:name];
        
        if (value) {
            [entity setValue:value forKey:name];
            ScLogDebug(@"Setting attribute (attribute: %@, value: %@).", name, value);
        }
    }
    
    return entity;
}


- (BOOL)save
{
    NSError *error;
    BOOL didSaveOK = [self save:&error];
    
    if (!didSaveOK) {
        ScLogError(@"Error when saving managed object context: %@ [%@]", [error localizedDescription], [error userInfo]);
    }
    
    return didSaveOK;
}


#pragma mark - Entity creation

- (ScScola *)newScolaWithName:(NSString *)name;
{
    ScScola *scola = [self entityForClass:ScScola.class];
    
    scola.name = name;
    scola.scolaId = scola.entityId;
    
    return scola;
}


- (id)entityForClass:(Class)class inScola:(ScScola *)scola
{
    return [self entityForClass:class inScola:scola withId:[ScUUIDGenerator generateUUID]];
}


- (id)entityForClass:(Class)class inScola:(ScScola *)scola withId:(NSString *)entityId
{
    ScCachedEntity *entity = [self entityForClass:class withId:entityId];
    
    if ([entity isSharedEntity]) {
        ScSharedEntityRef *entityRef = [self entityForClass:ScSharedEntityRef.class];
        
        entityRef.sharedEntityId = entity.entityId;
        entityRef.scolaId = scola.entityId;
    } else {
        entity.scolaId = scola.entityId;
    }
    
    return entity;
}


#pragma mark - Entity lookup

- (id)fetchEntityWithId:(NSString *)entityId
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ScCachedEntity"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"entityId == '%@'", entityId]];
    
    id entity = nil;
    NSError *error = nil;
    NSArray *resultsArray = [self executeFetchRequest:request error:&error];
    
    if (resultsArray == nil) {
        ScLogError(@"Could not fetch entity: %@", [error localizedDescription]);
    } else if ([resultsArray count] > 1) {
        ScLogBreakage(@"Found more than one entity with entityId '%@'.", entityId);
    } else if ([resultsArray count] == 1) {
        entity = [resultsArray objectAtIndex:0];
    }
    
    return entity;
}


#pragma mark - Local & remote persistence

- (void)mergeEntitiesFromDictionaryArray:(NSArray *)dictionaryArray
{
    NSMutableDictionary *dictionaries = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *entities = [[NSMutableDictionary alloc] init];
    
    for (NSDictionary *entityDictionary in dictionaryArray) {
        ScCachedEntity *entity = [self mergeEntityFromDictionary:entityDictionary];
        
        [dictionaries setObject:entityDictionary forKey:entity.entityId];
        [entities setObject:entity forKey:entity.entityId];
    }
    
    for (NSString *entityId in [entities allKeys]) {
        ScCachedEntity *entity = [entities objectForKey:entityId];
        NSDictionary *entityAsDictionary = [dictionaries objectForKey:entityId];
        
        [entity internaliseRelationships:entityAsDictionary entities:entities];
    }
    
    if (![self save]) {
        ScLogError(@"Entities from server could not be saved.");
    }
}


- (BOOL)saveUsingDelegate:(id)delegate
{
    NSError *error;
    BOOL didSaveOK = [self save:&error];
    
    if (didSaveOK) {
        [[[ScServerConnection alloc] init] persistEntitiesUsingDelegate:delegate];
    } else {
        ScLogError(@"Error when saving managed object context: %@", [error localizedDescription]);
    }
    
    return didSaveOK;
}

@end
