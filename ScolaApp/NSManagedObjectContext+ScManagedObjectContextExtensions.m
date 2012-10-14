//
//  NSManagedObjectContext+ScManagedObjectContextExtensions.m
//  ScolaApp
//
//  Created by Anders Blehr on 29.01.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "NSManagedObjectContext+ScManagedObjectContextExtensions.h"
#import "NSString+ScStringExtensions.h"

#import "ScLogging.h"
#import "ScMeta.h"
#import "ScServerConnection.h"
#import "ScState.h"
#import "ScStrings.h"
#import "ScUUIDGenerator.h"

#import "ScCachedEntity.h"
#import "ScCachedEntityGhost.h"
#import "ScMember.h"
#import "ScMemberResidency.h"
#import "ScMembership.h"
#import "ScScola.h"
#import "ScSharedEntityRef.h"

#import "ScCachedEntity+ScCachedEntityExtensions.h"
#import "ScScola+ScScolaExtensions.h"


static NSString * const kScolaRelationshipName = @"scola";


@implementation NSManagedObjectContext (ScManagedObjectContextExtensions)


#pragma mark - Auxiliary methods

- (id)entityForClass:(Class)class
{
    return [self entityForClass:class entityId:[ScUUIDGenerator generateUUID]];
}


- (ScScola *)entityForScolaOfType:(NSString *)type scolaId:(NSString *)scolaId
{
    ScScola *scola = [self entityForClass:ScScola.class entityId:scolaId];
    
    scola.scolaId = scolaId;
    scola.type = type;
    
    if ([scola.type isEqualToString:kScolaTypeResidence]) {
        scola.name = [ScStrings stringForKey:strMyPlace];
    }
    
    return scola;
}


#pragma mark - Entity creation

- (ScScola *)entityForScolaOfType:(NSString *)type
{
    return [self entityForScolaOfType:type scolaId:[ScUUIDGenerator generateUUID]];
}


- (ScMember *)entityForMemberWithId:(NSString *)memberId
{
    NSString *memberRootId = [memberId stringByAppendingStringWithDollar:@"root"];
    
    ScScola *memberRoot = [self entityForScolaOfType:kScolaTypeMemberRoot scolaId:memberRootId];
    ScMember *member = [self entityForClass:ScMember.class inScola:memberRoot entityId:memberId];
    
    ScMembership *rootMembership = [memberRoot addMember:member];
    
    if ([ScState s].aspectIsSelf) {
        rootMembership.isActive = @YES;
        rootMembership.isAdmin = @YES;
    }
    
    return member;
}


- (id)entityForClass:(Class)class entityId:(NSString *)entityId
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
    return [self entityForClass:class inScola:scola entityId:[ScUUIDGenerator generateUUID]];
}


- (id)entityForClass:(Class)class inScola:(ScScola *)scola entityId:(NSString *)entityId
{
    ScCachedEntity *entity = [self entityForClass:class entityId:entityId];
    
    entity.scolaId = scola.entityId;
    
    if ([[entity.entity relationshipsByName] objectForKey:kScolaRelationshipName]) {
        [entity setValue:scola forKey:kScolaRelationshipName];
    }
    
    return entity;
}


- (id)sharedEntityRefForEntity:(ScCachedEntity *)entity inScola:(ScScola *)scola
{
    ScSharedEntityRef *sharedEntityRef = [self entityForClass:ScSharedEntityRef.class];
    
    sharedEntityRef.sharedEntityId = entity.entityId;
    sharedEntityRef.sharedEntityScolaId = entity.scolaId;
    sharedEntityRef.scolaId = scola.entityId;
    
    entity.isShared = @YES;
    
    return sharedEntityRef;
}


#pragma mark - Entity caching and synchronisation

- (void)saveToCache
{
    NSError *error;
    
    if ([self save:&error]) {
        ScLogDebug(@"Entities successfully saved to cache.");
    } else {
        ScLogError(@"Error saving entities to cache: %@ [%@]", [error localizedDescription], [error userInfo]);
    }
}


- (NSSet *)saveServerEntitiesToCache:(NSArray *)entityDictionaries
{
    NSMutableSet *entities = [[NSMutableSet alloc] init];
    
    for (NSDictionary *entityDictionary in entityDictionaries) {
        [entities addObject:[ScCachedEntity entityWithDictionary:entityDictionary]];
    }
    
    for (ScCachedEntity *entity in entities) {
        [entity internaliseRelationships];
    }
    
    [self saveToCache];
    
    return [NSSet setWithSet:entities];
}


- (void)synchroniseCacheWithServer
{
    [[[ScServerConnection alloc] init] synchroniseCacheWithServer];
}


#pragma mark - Fetching & deleting entities from cache

- (id)fetchEntityFromCache:(NSString *)entityId
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass(ScCachedEntity.class)];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", kPropertyEntityId, entityId]];
    
    id entity = nil;
    NSError *error = nil;
    NSArray *resultsArray = [self executeFetchRequest:request error:&error];
    
    if (resultsArray == nil) {
        ScLogError(@"Could not fetch entity from cache: %@", [error localizedDescription]);
    } else if ([resultsArray count] > 1) {
        ScLogBreakage(@"Found more than one entity in cache with entityId '%@'.", entityId);
    } else if ([resultsArray count] == 1) {
        entity = [resultsArray objectAtIndex:0];
    }
    
    return entity;
}


- (void)deleteEntityFromCache:(ScCachedEntity *)entity
{
    if ([entity isPersisted]) {
        [entity spawnEntityGhost];
    }
    
    [self deleteObject:entity];
}

@end
