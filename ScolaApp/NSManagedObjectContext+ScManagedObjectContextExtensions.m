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

#import "ScMember.h"
#import "ScMemberResidency.h"
#import "ScMembership.h"
#import "ScScola.h"
#import "ScSharedEntityRef.h"


static NSString * const kScolaRelationshipName = @"scola";


@implementation NSManagedObjectContext (ScManagedObjectContextExtensions)


#pragma mark - Auxiliary methods

- (id)entityForClass:(Class)class
{
    return [self entityForClass:class withId:[ScUUIDGenerator generateUUID]];
}


- (id)entityForClass:(Class)class withId:(NSString *)entityId
{
    ScCachedEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(class) inManagedObjectContext:self];
    
    entity.entityId = entityId;
    entity.dateCreated = [NSDate date];
    
    NSString *expires = [entity expiresInTimeframe];
    
    if (expires) {
        // TODO: Process expiry instructions
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
    }
    
    NSEntityDescription *entityDescription = entity.entity;
    NSDictionary *attributes = [entityDescription attributesByName];
    
    for (NSString *name in [attributes allKeys]) {
        id value = [dictionary objectForKey:name];
        
        if (value) {
            [entity setValue:value forKey:name];
        }
    }
    
    return entity;
}


#pragma mark - Entity creation

- (ScScola *)entityForScolaWithName:(NSString *)name
{
    return [self entityForScolaWithName:name andId:[ScUUIDGenerator generateUUID]];
}


- (ScScola *)entityForScolaWithName:(NSString *)name andId:(NSString *)scolaId
{
    ScScola *scola = [self entityForClass:ScScola.class withId:scolaId];
    
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
    
    entity.scolaId = scola.entityId;
    
    if ([[entity.entity relationshipsByName] objectForKey:kScolaRelationshipName]) {
        [entity setValue:scola forKey:kScolaRelationshipName];
    }
    
    return entity;
}


- (id)entityRefForEntity:(ScCachedEntity *)entity inScola:(ScScola *)scola
{
    ScSharedEntityRef *entityRef = [self entityForClass:ScSharedEntityRef.class];
    
    entityRef.sharedEntityId = entity.entityId;
    entityRef.sharedEntityScolaId = entity.scolaId;
    entityRef.scolaId = scola.entityId;
    
    entity.isShared = [NSNumber numberWithBool:YES];
    
    return entityRef;
}


#pragma mark - Entity lookup

- (id)fetchEntityWithId:(NSString *)entityId
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ScCachedEntity"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"entityId == %@", entityId]];
    
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


#pragma mark - Entity caching & synchronization

- (void)cacheEntities
{
    NSError *error;
    
    if ([self save:&error]) {
        ScLogDebug(@"Entities successfully cached.");
    } else {
        ScLogError(@"Error caching entities: %@ [%@]", [error localizedDescription], [error userInfo]);
    }
}


- (void)cacheAndPersistEntities
{
    ScServerConnection *connection = [[ScServerConnection alloc] init];
    
    [connection persistEntities];
    [self cacheEntities];
}


- (void)entitiesFromDictionaries:(NSArray *)dictionaryArray
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
    
    [self cacheEntities];
}

@end
