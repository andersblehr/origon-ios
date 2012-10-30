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

#import "OMember.h"
#import "OMemberResidency.h"
#import "OMembership.h"
#import "OOrigo.h"
#import "OReplicatedEntity.h"
#import "OReplicatedEntityGhost.h"
#import "OLinkedEntityRef.h"

#import "OMember+OMemberExtensions.h"
#import "OMembership+OMembershipExtensions.h"
#import "OOrigo+OOrigoExtensions.h"
#import "OReplicatedEntity+OReplicatedEntityExtensions.h"


static NSString * const kOrigoRelationshipName = @"origo";


@implementation NSManagedObjectContext (OManagedObjectContextExtensions)


#pragma mark - Auxiliary methods

- (OOrigo *)insertOrigoEntityOfType:(NSString *)type origoId:(NSString *)origoId
{
    OOrigo *origo = [self insertEntityForClass:OOrigo.class entityId:origoId];
    
    origo.origoId = origoId;
    origo.type = type;
    
    if ([origo.type isEqualToString:kOrigoTypeResidence]) {
        origo.name = [OStrings stringForKey:strMyHousehold];
    }
    
    return origo;
}


- (id)insertEntityForClass:(Class)class
{
    return [self insertEntityForClass:class entityId:[OUUIDGenerator generateUUID]];
}


- (id)insertEntityForClass:(Class)class entityId:(NSString *)entityId
{
    OReplicatedEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(class) inManagedObjectContext:self];
    
    entity.entityId = entityId;
    entity.dateCreated = [NSDate date];
    
    NSString *expires = [entity expiresInTimeframe];
    
    if (expires) {
        // TODO: Process expiry instructions
    }
    
    return entity;
}


- (id)insertEntityFromDictionary:(NSDictionary *)entityDictionary
{
    NSMutableDictionary *entityRefs = [[NSMutableDictionary alloc] init];
    NSString *entityId = [entityDictionary valueForKey:kPropertyEntityId];
    
    OReplicatedEntity *entity = [self entityWithId:entityId];
    
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


- (id)entityOfClass:(Class)class matchingPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass(class)];
    [request setPredicate:predicate];
    
    id entity = nil;
    NSError *error = nil;
    NSArray *resultsArray = [self executeFetchRequest:request error:&error];
    
    if (resultsArray == nil) {
        OLogError(@"Could not fetch entity on device: %@", [error localizedDescription]);
    } else if ([resultsArray count] > 1) {
        OLogBreakage(@"Found more than one entity on device for predicate '%@'.", [predicate predicateFormat]);
    } else if ([resultsArray count] == 1) {
        entity = resultsArray[0];
    }
    
    return entity;
}


- (void)deleteEntity:(OReplicatedEntity *)entity isGhosted:(BOOL)isGhosted
{
    if (!isGhosted && [entity isReplicated]) {
        [entity spawnEntityGhost];
    }
    
    if ([entity isKindOfClass:OMembership.class]) {
        OMembership *membership = (OMembership *)entity;
        OMember *member = membership.member;
        OOrigo *origo = membership.origo;
        
        [self deleteObject:[member linkedEntityRefForOrigo:origo]];
        
        BOOL shouldDeleteMember = NO;
        
        if ([origo isResidence]) {
            shouldDeleteMember = ([[member origoMemberships] count] == 0);
        } else {
            shouldDeleteMember = (([[member origoMemberships] count] == 1) && ![[[OMeta m].user housemates] containsObject:member]);
        }
        
        if (shouldDeleteMember) {
            for (OMemberResidency *residency in member.residencies) {
                if (residency.residence != origo) {
                    [self deleteObject:[residency.residence linkedEntityRefForOrigo:origo]];
                    [self deleteObject:[residency linkedEntityRefForOrigo:origo]];
                    
                    if ([residency.residence.residencies count] == 1) {
                        [self deleteObject:residency.residence];
                    }
                }
                
                [self deleteObject:residency];
            }
            
            OMembership *rootMembership = [member rootMembership];
            
            if (rootMembership) {
                [self deleteObject:rootMembership.origo];
                [self deleteObject:rootMembership];
            }
            
            [self deleteObject:member];
        }
    }
    
    [self deleteObject:entity];
}


#pragma mark - Entity creation

- (OOrigo *)insertOrigoEntityOfType:(NSString *)type
{
    return [self insertOrigoEntityOfType:type origoId:[OUUIDGenerator generateUUID]];
}



- (OMember *)insertMemberEntityWithId:(NSString *)memberId
{
    if (!memberId) {
        memberId = [OUUIDGenerator generateUUID];
    }
    
    NSString *memberRootId = [memberId stringByAppendingStringWithCaret:@"root"];
    
    OOrigo *memberRoot = [self insertOrigoEntityOfType:kOrigoTypeMemberRoot origoId:memberRootId];
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
    OReplicatedEntity *entity = [self insertEntityForClass:class entityId:entityId];
    
    entity.origoId = origo.entityId;
    
    if ([[entity.entity relationshipsByName] objectForKey:kOrigoRelationshipName]) {
        [entity setValue:origo forKey:kOrigoRelationshipName];
    }
    
    return entity;
}


- (id)insertLinkedEntityRefForEntity:(OReplicatedEntity *)entity inOrigo:(OOrigo *)origo
{
    OLinkedEntityRef *linkedEntityRef = [self insertEntityForClass:OLinkedEntityRef.class inOrigo:origo entityId:[entity.entityId stringByAppendingStringWithHash:origo.entityId]];
    
    linkedEntityRef.linkedEntityId = entity.entityId;
    linkedEntityRef.linkedEntityOrigoId = entity.origoId;
    
    entity.isLinked = @YES;
    
    return linkedEntityRef;
}


#pragma mark - Saving and replication

- (void)save
{
    NSError *error;
    
    if ([self save:&error]) {
        OLogDebug(@"Entities successfully saved to device.");
    } else {
        OLogError(@"Error saving to device: %@ [%@]", [error localizedDescription], [error userInfo]);
    }
}


- (NSSet *)saveServerReplicas:(NSArray *)replicaDictionaries
{
    NSString *entityGhostClass = NSStringFromClass(OReplicatedEntityGhost.class);
    NSMutableSet *entities = [[NSMutableSet alloc] init];
    
    for (NSDictionary *replicaDictionary in replicaDictionaries) {
        NSString *replicaClass = [replicaDictionary objectForKey:kPropertyEntityClass];
        
        if ([replicaClass isEqualToString:entityGhostClass]) {
            NSString *ghostedEntityId = [replicaDictionary objectForKey:kPropertyEntityId];
            OReplicatedEntity *ghostedEntity = [self entityWithId:ghostedEntityId];

            if (ghostedEntity) {
                [self deleteEntity:ghostedEntity isGhosted:YES];
            }
        } else {
            [entities addObject:[self insertEntityFromDictionary:replicaDictionary]];
        }
    }
    
    for (OReplicatedEntity *entity in entities) {
        [entity internaliseRelationships];
    }
    
    [self save];
    
    return entities;
}


- (void)replicate
{
    [[[OServerConnection alloc] init] replicate];
}


- (void)saveReplicationState
{
    NSSet *dirtyEntities = [[OMeta m] dirtyEntities];
    NSMutableSet *dirtyEntityURIs = [[NSMutableSet alloc] init];
    
    [self save];
    
    for (OReplicatedEntity *dirtyEntity in dirtyEntities) {
        [dirtyEntityURIs addObject:[[dirtyEntity objectID] URIRepresentation]];
    }
    
    NSData *dirtyEntityURIArchive = [NSKeyedArchiver archivedDataWithRootObject:dirtyEntityURIs];
    [[NSUserDefaults standardUserDefaults] setObject:dirtyEntityURIArchive forKey:kUserDefaultsKeyDirtyEntities];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (BOOL)savedReplicationStateIsDirty
{
    return ([[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsKeyDirtyEntities] != nil);
}


#pragma mark - Fetching & deleting entities

- (id)entityWithId:(NSString *)entityId
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass(OReplicatedEntity.class)];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", kPropertyEntityId, entityId]];
    
    id entity = nil;
    NSError *error = nil;
    NSArray *resultsArray = [self executeFetchRequest:request error:&error];
    
    if (resultsArray == nil) {
        OLogError(@"Could not fetch entity on device: %@", [error localizedDescription]);
    } else if ([resultsArray count] > 1) {
        OLogBreakage(@"Found more than one entity on device for entityId '%@'.", entityId);
    } else if ([resultsArray count] == 1) {
        entity = resultsArray[0];
    }
    
    return entity;
}


- (void)deleteEntity:(OReplicatedEntity *)entity
{
    [self deleteEntity:entity isGhosted:NO];
}

@end
