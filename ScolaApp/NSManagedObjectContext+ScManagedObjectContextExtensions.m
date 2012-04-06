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

- (ScScola *)entityForScolaWithName:(NSString *)name;
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
    
    entity.scolaId = scola.entityId;
    
    if ([[entity.entity relationshipsByName] objectForKey:kScolaRelationshipName]) {
        [entity setValue:scola forKey:kScolaRelationshipName];
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


#pragma mark - Object model consistency

- (void)entityRefForEntity:(ScCachedEntity *)entity inScola:(ScScola *)scola
{
    ScSharedEntityRef *entityRef = [self entityForClass:ScSharedEntityRef.class];
    
    entityRef.entityRefId = entity.entityId;
    entityRef.scolaId = scola.entityId;
    
    entity.isShared = [NSNumber numberWithBool:YES];
}


- (ScMembership *)addMember:(ScMember *)member toScola:(ScScola *)scola isActive:(BOOL)isActive
{
    [self entityRefForEntity:member inScola:scola];
    
    for (ScMemberResidency *residency in member.residencies) {
        [self entityRefForEntity:residency inScola:scola];
        [self entityRefForEntity:residency.scola inScola:scola];
    }
    
    ScMembership *scolaMembership = [self entityForClass:ScMembership.class inScola:scola];
    scolaMembership.member = member;
    scolaMembership.scola = scola;
    scolaMembership.isActive = [NSNumber numberWithBool:isActive];
    
    return scolaMembership;
}


#pragma mark - Local & remote persistence

- (BOOL)saveUsingDelegate:(id)delegate
{
    BOOL didSaveOK = [self save];
    
    if (didSaveOK) {
        [[[ScServerConnection alloc] init] persistEntitiesUsingDelegate:delegate];
    }
    
    return didSaveOK;
}


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

@end
