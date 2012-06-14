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
#import "ScCachedEntityGhost.h"
#import "ScMember.h"
#import "ScMemberResidency.h"
#import "ScMembership.h"
#import "ScScola.h"
#import "ScSharedEntityRef.h"

#import "ScCachedEntity+ScCachedEntityExtensions.h"


static NSString * const kScolaRelationshipName = @"scola";


@implementation NSManagedObjectContext (ScManagedObjectContextExtensions)


#pragma mark - Auxiliary methods

- (id)entityForClass:(Class)class
{
    return [self entityForClass:class withId:[ScUUIDGenerator generateUUID]];
}


#pragma mark - Entity creation

- (ScScola *)entityForScolaWithName:(NSString *)name
{
    return [self entityForScolaWithName:name scolaId:[ScUUIDGenerator generateUUID]];
}


- (ScScola *)entityForScolaWithName:(NSString *)name scolaId:(NSString *)scolaId
{
    ScScola *scola = [self entityForClass:ScScola.class withId:scolaId];
    
    scola.name = name;
    scola.scolaId = scola.entityId;
    
    return scola;
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


#pragma mark - Fetching entities

- (id)fetchEntityWithId:(NSString *)entityId
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass(ScCachedEntity.class)];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", kKeyEntityId, entityId]];
    
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


#pragma mark - Saving & persisting entities

- (void)save
{
    NSError *error;
    
    if ([self save:&error]) {
        ScLogDebug(@"Entities successfully saved.");
    } else {
        ScLogError(@"Error saving entities: %@ [%@]", [error localizedDescription], [error userInfo]);
    }
}


- (void)saveWithDictionaries:(NSArray *)dictionaries
{
    NSMutableSet *entities = [[NSMutableSet alloc] init];
    
    for (NSDictionary *dictionary in dictionaries) {
        [entities addObject:[ScCachedEntity entityWithDictionary:dictionary]];
    }
    
    for (ScCachedEntity *entity in entities) {
        [entity internaliseRelationships];
    }
    
    [self save];
}


- (void)synchronise
{
    [[[ScServerConnection alloc] init] synchroniseEntities];
}


#pragma mark - Deleting entities

- (void)deleteEntity:(ScCachedEntity *)entity
{
    [entity entityGhost];
    [self deleteObject:entity];
}

@end
