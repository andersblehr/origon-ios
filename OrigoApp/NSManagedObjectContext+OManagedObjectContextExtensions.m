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

- (id)insertEntityForClass:(Class)class
{
    return [self insertEntityForClass:class entityId:[OUUIDGenerator generateUUID]];
}


- (id)insertEntityFromDictionary:(NSDictionary *)entityDictionary
{
    NSMutableDictionary *entityRefs = [[NSMutableDictionary alloc] init];
    NSString *entityId = [entityDictionary valueForKey:kPropertyEntityId];
    
    OCachedEntity *entity = [self cachedEntityWithId:entityId];
    
    if (!entity) {
        NSString *entityClass = [entityDictionary objectForKey:kPropertyEntityClass];
        
        entity = [self insertEntityForClass:NSClassFromString(entityClass) entityId:entityId];
        entity.origoId = [entityDictionary objectForKey:kPropertyOrigoId];
    }
    
    NSDictionary *attributes = [entity.entity attributesByName];
    NSDictionary *relationships = [entity.entity relationshipsByName];
    
    for (NSString *attributeKey in [attributes allKeys]) {
        id attributeValue = [entityDictionary objectForKey:attributeKey];
        
        if (attributeValue) {
            [entity setValue:attributeValue forKey:attributeKey];
        }
    }
    
    for (NSString *relationshipKey in [relationships allKeys]) {
        NSRelationshipDescription *relationship = [relationships objectForKey:relationshipKey];
        
        if (!relationship.isToMany) {
            NSString *entityRefName = [NSString stringWithFormat:@"%@Ref", relationshipKey];
            NSDictionary *entityRef = [entityDictionary objectForKey:entityRefName];
            
            if (entityRef) {
                [entityRefs setObject:entityRef forKey:relationshipKey];
            }
        }
    }
    
    [[OMeta m] stageServerEntity:entity];
    
    if ([entityRefs count] > 0) {
        [[OMeta m] stageServerEntityRefs:entityRefs forEntity:entity];
    }
    
    return entity;
}


- (id)insertEntityForClass:(Class)class entityId:(NSString *)entityId
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


- (OOrigo *)origoEntityOfType:(NSString *)type origoId:(NSString *)origoId
{
    OOrigo *origo = [self insertEntityForClass:OOrigo.class entityId:origoId];
    
    origo.origoId = origoId;
    origo.type = type;
    
    if ([origo.type isEqualToString:kOrigoTypeResidence]) {
        origo.name = [OStrings stringForKey:strMyHousehold];
    }
    
    return origo;
}


- (id)lookUpEntityOfClass:(Class)class usingPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass(class)];
    [request setPredicate:predicate];
    
    id entity = nil;
    NSError *error = nil;
    NSArray *resultsArray = [self executeFetchRequest:request error:&error];
    
    if (resultsArray == nil) {
        OLogError(@"Could not fetch entity from cache: %@", [error localizedDescription]);
    } else if ([resultsArray count] > 1) {
        OLogBreakage(@"Found more than one entity in cache for predicate '%@'.", [predicate predicateFormat]);
    } else if ([resultsArray count] == 1) {
        entity = resultsArray[0];
    }
    
    return entity;
}


#pragma mark - Entity creation

- (OOrigo *)insertOrigoEntityOfType:(NSString *)type
{
    return [self origoEntityOfType:type origoId:[OUUIDGenerator generateUUID]];
}


- (OMember *)insertMemberEntity
{
    return [self insertMemberEntityWithId:[OUUIDGenerator generateUUID]];
}


- (OMember *)insertMemberEntityWithId:(NSString *)memberId
{
    NSString *memberRootId = [memberId stringByAppendingStringWithDollar:@"root"];
    
    OOrigo *memberRoot = [self origoEntityOfType:kOrigoTypeMemberRoot origoId:memberRootId];
    OMember *member = [self insertEntityForClass:OMember.class inOrigo:memberRoot entityId:memberId];
    
    OMembership *rootMembership = [memberRoot addMember:member];
    
    if ([OState s].aspectIsSelf) {
        rootMembership.isActive_ = YES;
        rootMembership.isAdmin_ = YES;
    }
    
    return member;
}


- (id)insertEntityForClass:(Class)class inOrigo:(OOrigo *)origo
{
    return [self insertEntityForClass:class inOrigo:origo entityId:[OUUIDGenerator generateUUID]];
}


- (id)insertEntityForClass:(Class)class inOrigo:(OOrigo *)origo entityId:(NSString *)entityId
{
    OCachedEntity *entity = [self insertEntityForClass:class entityId:entityId];
    
    entity.origoId = origo.entityId;
    
    if ([[entity.entity relationshipsByName] objectForKey:kOrigoRelationshipName]) {
        [entity setValue:origo forKey:kOrigoRelationshipName];
    }
    
    return entity;
}


- (id)insertSharedEntityRefForEntity:(OCachedEntity *)entity inOrigo:(OOrigo *)origo
{
    OSharedEntityRef *sharedEntityRef = [self insertEntityForClass:OSharedEntityRef.class];
    
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
        OLogError(@"Error saving to cache: %@ [%@]", [error localizedDescription], [error userInfo]);
    }
}


- (NSSet *)saveToCacheFromDictionaries:(NSArray *)entityDictionaries
{
    NSMutableSet *entities = [[NSMutableSet alloc] init];
    
    for (NSDictionary *entityDictionary in entityDictionaries) {
        [entities addObject:[self insertEntityFromDictionary:entityDictionary]];
    }
    
    for (OCachedEntity *entity in entities) {
        [entity internaliseRelationships];
    }
    
    [self saveToCache];
    
    return entities;
}


- (void)synchroniseCacheWithServer
{
    [[[OServerConnection alloc] init] synchroniseCacheWithServer];
}


- (void)saveCacheState
{
    NSSet *dirtyEntities = [[OMeta m] dirtyEntities];
    NSMutableSet *dirtyEntityURIs = [[NSMutableSet alloc] init];
    
    [self saveToCache];
    
    for (OCachedEntity *dirtyEntity in dirtyEntities) {
        [dirtyEntityURIs addObject:[[dirtyEntity objectID] URIRepresentation]];
    }
    
    NSData *dirtyEntityURIArchive = [NSKeyedArchiver archivedDataWithRootObject:dirtyEntityURIs];
    [[NSUserDefaults standardUserDefaults] setObject:dirtyEntityURIArchive forKey:kUserDefaultsKeyDirtyEntities];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (BOOL)savedCacheStateIsDirty
{
    return ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsKeyDirtyEntities] != nil);
}


#pragma mark - Fetching & deleting entities from cache

- (id)cachedEntityWithId:(NSString *)entityId
{
    return [self lookUpEntityOfClass:OCachedEntity.class usingPredicate:[NSPredicate predicateWithFormat:@"%K = %@", kPropertyEntityId, entityId]];
}


- (void)permanentlyDeleteEntity:(OCachedEntity *)entity
{
    if ([entity isPersisted]) {
        [entity spawnEntityGhost];
    }
    
    if ([entity isKindOfClass:OMembership.class]) {
        OMember *member = ((OMembership *)entity).member;
        
        if ([member.memberships count] <= 2) {
            NSInteger numberOfNonRootMemberships = 0;
            OMembership *rootMembership = nil;
            
            for (OMembership *membership in member.memberships) {
                if ([membership.origo isMemberRoot]) {
                    rootMembership = membership;
                } else {
                    numberOfNonRootMemberships++;
                }
            }
            
            if (numberOfNonRootMemberships == 1) {
                OSharedEntityRef *memberRef = [self lookUpEntityOfClass:OSharedEntityRef.class usingPredicate:[NSPredicate predicateWithFormat:@"%K = %@", kPropertySharedEntityId, member.entityId]];
                
                if (memberRef) {
                    if ([memberRef isPersisted]) {
                        [memberRef spawnEntityGhost];
                    }
                    
                    [self deleteObject:memberRef];
                }
                
                if (rootMembership) {
                    [self deleteObject:rootMembership.origo];
                    [self deleteObject:rootMembership];
                }
                
                [self deleteObject:member];
            }
        }
    }
    
    [self deleteObject:entity];
}

@end
