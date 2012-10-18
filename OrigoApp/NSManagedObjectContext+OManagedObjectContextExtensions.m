//
//  NSManagedObjectContext+OManagedObjectContextExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "NSManagedObjectContext+OManagedObjectContextExtensions.h"
#import "NSString+OStringExtensions.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OServerConnection.h"
#import "OState.h"
#import "OStrings.h"
#import "OUUIDGenerator.h"

#import "OCachedEntity.h"
#import "OCachedEntityGhost.h"
#import "OMember.h"
#import "OMemberResidency.h"
#import "OMembership.h"
#import "OOrigo.h"
#import "OSharedEntityRef.h"

#import "OCachedEntity+OCachedEntityExtensions.h"
#import "OMembership+OMembershipExtensions.h"
#import "OOrigo+OOrigoExtensions.h"


static NSString * const kOrigoRelationshipName = @"origo";


@implementation NSManagedObjectContext (OManagedObjectContextExtensions)


#pragma mark - Auxiliary methods

- (id)entityForClass:(Class)class
{
    return [self entityForClass:class entityId:[OUUIDGenerator generateUUID]];
}


- (OOrigo *)entityForOrigoOfType:(NSString *)type origoId:(NSString *)origoId
{
    OOrigo *origo = [self entityForClass:OOrigo.class entityId:origoId];
    
    origo.origoId = origoId;
    origo.type = type;
    
    if ([origo.type isEqualToString:kOrigoTypeResidence]) {
        origo.name = [OStrings stringForKey:strMyHousehold];
    }
    
    return origo;
}


#pragma mark - Entity creation

- (OOrigo *)entityForOrigoOfType:(NSString *)type
{
    return [self entityForOrigoOfType:type origoId:[OUUIDGenerator generateUUID]];
}


- (OMember *)entityForMemberWithId:(NSString *)memberId
{
    NSString *memberRootId = [memberId stringByAppendingStringWithDollar:@"root"];
    
    OOrigo *memberRoot = [self entityForOrigoOfType:kOrigoTypeMemberRoot origoId:memberRootId];
    OMember *member = [self entityForClass:OMember.class inOrigo:memberRoot entityId:memberId];
    
    OMembership *rootMembership = [memberRoot addMember:member];
    
    if ([OState s].aspectIsSelf) {
        rootMembership.isActive_ = YES;
        rootMembership.isAdmin_ = YES;
    }
    
    return member;
}


- (id)entityForClass:(Class)class entityId:(NSString *)entityId
{
    OCachedEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(class) inManagedObjectContext:self];
    
    entity.entityId = entityId;
    entity.dateCreated = [NSDate date];
    
    NSString *expires = [entity expiresInTimeframe];
    
    if (expires) {
        // TODO: Process expiry instructions
    }
    
    return entity;
}


- (id)entityForClass:(Class)class inOrigo:(OOrigo *)origo
{
    return [self entityForClass:class inOrigo:origo entityId:[OUUIDGenerator generateUUID]];
}


- (id)entityForClass:(Class)class inOrigo:(OOrigo *)origo entityId:(NSString *)entityId
{
    OCachedEntity *entity = [self entityForClass:class entityId:entityId];
    
    entity.origoId = origo.entityId;
    
    if ([[entity.entity relationshipsByName] objectForKey:kOrigoRelationshipName]) {
        [entity setValue:origo forKey:kOrigoRelationshipName];
    }
    
    return entity;
}


- (id)sharedEntityRefForEntity:(OCachedEntity *)entity inOrigo:(OOrigo *)origo
{
    OSharedEntityRef *sharedEntityRef = [self entityForClass:OSharedEntityRef.class];
    
    sharedEntityRef.sharedEntityId = entity.entityId;
    sharedEntityRef.sharedEntityOrigoId = entity.origoId;
    sharedEntityRef.origoId = origo.entityId;
    
    entity.isShared = @YES;
    
    return sharedEntityRef;
}


#pragma mark - Entity caching and synchronisation

- (void)saveToCache
{
    NSError *error;
    
    if ([self save:&error]) {
        OLogDebug(@"Entities successfully saved to cache.");
    } else {
        OLogError(@"Error saving entities to cache: %@ [%@]", [error localizedDescription], [error userInfo]);
    }
}


- (NSSet *)saveServerEntitiesToCache:(NSArray *)entityDictionaries
{
    NSMutableSet *entities = [[NSMutableSet alloc] init];
    
    for (NSDictionary *entityDictionary in entityDictionaries) {
        [entities addObject:[OCachedEntity entityWithDictionary:entityDictionary]];
    }
    
    for (OCachedEntity *entity in entities) {
        [entity internaliseRelationships];
    }
    
    [self saveToCache];
    
    return [NSSet setWithSet:entities];
}


- (void)synchroniseCacheWithServer
{
    [[[OServerConnection alloc] init] synchroniseCacheWithServer];
}


#pragma mark - Fetching & deleting entities from cache

- (id)fetchEntityFromCache:(NSString *)entityId
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass(OCachedEntity.class)];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", kPropertyEntityId, entityId]];
    
    id entity = nil;
    NSError *error = nil;
    NSArray *resultsArray = [self executeFetchRequest:request error:&error];
    
    if (resultsArray == nil) {
        OLogError(@"Could not fetch entity from cache: %@", [error localizedDescription]);
    } else if ([resultsArray count] > 1) {
        OLogBreakage(@"Found more than one entity in cache with entityId '%@'.", entityId);
    } else if ([resultsArray count] == 1) {
        entity = resultsArray[0];
    }
    
    return entity;
}


- (void)deleteEntityFromCache:(OCachedEntity *)entity
{
    if ([entity isPersisted]) {
        [entity spawnEntityGhost];
    }
    
    [self deleteObject:entity];
}

@end
