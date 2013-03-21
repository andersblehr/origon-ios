//
//  NSManagedObjectContext+OrigoExtensions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "NSManagedObjectContext+OrigoExtensions.h"

#import "NSString+OrigoExtensions.h"

#import "OEntityReplicator.h"
#import "OLogging.h"
#import "OMeta.h"
#import "OState.h"
#import "OStrings.h"
#import "OUUIDGenerator.h"

#import "OMember+OrigoExtensions.h"
#import "OMembership+OrigoExtensions.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"
#import "OReplicatedEntityRef.h"

static NSString * const kMemberRootIdFormat = @"~%@";


@implementation NSManagedObjectContext (OrigoExtensions)

#pragma mark - Auxiliary methods

- (NSString *)memberRootIdForMemberWithId:(NSString *)memberId
{
    return [NSString stringWithFormat:kMemberRootIdFormat, memberId];
}


- (NSString *)entityRefIdForEntity:(OReplicatedEntity *)entity inOrigoWithId:(NSString *)origoId
{
    return [entity.entityId stringByAppendingString:origoId separator:kSeparatorHash];
}


- (OOrigo *)insertOrigoEntityOfType:(NSString *)origoType origoId:(NSString *)origoId
{
    OOrigo *origo = [self insertEntityOfClass:OOrigo.class entityId:origoId];
    
    origo.origoId = origoId;
    origo.type = origoType;
    
    if ([origo isOfType:kOrigoTypeResidence]) {
        origo.name = [OStrings stringForKey:strDefaultResidenceName];
    }
    
    return origo;
}


- (id)insertEntityOfClass:(Class)class entityId:(NSString *)entityId
{
    OReplicatedEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(class) inManagedObjectContext:self];
    
    entity.entityId = entityId;
    entity.dateCreated = [NSDate date];
    entity.createdBy = [OMeta m].userId;
    
    NSString *expires = [entity expiresInTimeframe];
    
    if (expires) {
        // TODO: Process expiry instructions
    }
    
    return entity;
}


- (id)insertEntityRefForEntity:(OReplicatedEntity *)entity inOrigo:(OOrigo *)origo
{
    NSString *entityRefId = [self entityRefIdForEntity:entity inOrigoWithId:origo.entityId];
    OReplicatedEntityRef *entityRef = [self fetchEntityWithId:entityRefId];
    
    if (!entityRef) {
        entityRef = [self insertEntityOfClass:OReplicatedEntityRef.class inOrigo:origo entityId:entityRefId];
        entityRef.referencedEntityId = entity.entityId;
        entityRef.referencedEntityOrigoId = entity.origoId;
    }
    
    return entityRef;
}


- (id)expireEntityRefForEntity:(OReplicatedEntity *)entity inOrigo:(OOrigo *)origo
{
    OReplicatedEntityRef *entityRef = [self insertEntityRefForEntity:entity inOrigo:origo];
    entityRef.isExpired = @YES;
    
    return entityRef;
}


- (id)insertExpiryRefForMembership:(OMembership *)membership
{
    OReplicatedEntityRef *expiryRef = nil;
    
    if ([membership.member isActive]) {
        NSString *memberRootId = [self memberRootIdForMemberWithId:membership.member.entityId];
        NSString *expiryRefId = [self entityRefIdForEntity:membership inOrigoWithId:memberRootId];
        
        expiryRef = [self insertEntityOfClass:OReplicatedEntityRef.class entityId:expiryRefId];
        expiryRef.referencedEntityId = membership.entityId;
        expiryRef.referencedEntityOrigoId = membership.origoId;
        expiryRef.origoId = memberRootId;
    }
    
    return expiryRef;
}


- (id)fetchEntityOfClass:(Class)class withValue:(NSString *)value forKey:(NSString *)key
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass(class)];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", key, value]];
    
    id entity = nil;
    NSError *error = nil;
    NSArray *resultsArray = [self executeFetchRequest:request error:&error];
    
    if (resultsArray == nil) {
        OLogError(@"Error fetching entity on device: %@", [error localizedDescription]);
    } else if ([resultsArray count] > 1) {
        OLogBreakage(@"Found more than one entity with '%@'='%@'.", key, value);
    } else if ([resultsArray count] == 1) {
        entity = resultsArray[0];
    }
    
    return entity;
}


- (id)mergeEntityFromDictionary:(NSDictionary *)entityDictionary
{
    NSString *entityId = [entityDictionary objectForKey:kPropertyKeyEntityId];
    OReplicatedEntity *entity = [self fetchEntityWithId:entityId];
    
    if (!entity) {
        NSString *entityClass = [entityDictionary objectForKey:kJSONKeyEntityClass];
        
        entity = [self insertEntityOfClass:NSClassFromString(entityClass) entityId:entityId];
        entity.origoId = [entityDictionary objectForKey:kPropertyKeyOrigoId];
    }
    
    NSDictionary *attributes = [entity.entity attributesByName];
    NSDictionary *relationships = [entity.entity relationshipsByName];
    
    for (NSString *attributeKey in [attributes allKeys]) {
        id attributeValue = [entityDictionary objectForKey:attributeKey];
        
        if (attributeValue) {
            [entity setDeserialisedValue:attributeValue forKey:attributeKey];
        }
    }
    
    NSMutableDictionary *relationshipRefs = [[NSMutableDictionary alloc] init];
    
    for (NSString *relationshipKey in [relationships allKeys]) {
        NSRelationshipDescription *relationship = [relationships objectForKey:relationshipKey];
        
        if (!relationship.isToMany) {
            NSString *relationshipRefName = [NSString stringWithFormat:@"%@Ref", relationshipKey];
            NSDictionary *relationshipRef = [entityDictionary objectForKey:relationshipRefName];
            
            if (relationshipRef) {
                [relationshipRefs setObject:relationshipRef forKey:relationshipKey];
            }
        }
    }
    
    [[OMeta m].replicator stageEntity:entity];
    
    if ([relationshipRefs count] > 0) {
        [[OMeta m].replicator stageRelationshipRefs:relationshipRefs forEntity:entity];
    }
    
    return entity;
}


- (NSSet *)dirtyEntities
{
    NSMutableSet *unsavedEntities = [[NSMutableSet alloc] init];
    
    [unsavedEntities unionSet:[self insertedObjects]];
    [unsavedEntities unionSet:[self updatedObjects]];
    
    NSMutableSet *dirtyEntities = [[NSMutableSet alloc] init];
    
    for (OReplicatedEntity *entity in unsavedEntities) {
        if ([entity isDirty]) {
            [dirtyEntities addObject:entity];
        }
    }
    
    return dirtyEntities;
}


#pragma mark - Inserting entities

- (id)insertMemberEntity
{
    NSString *memberId = nil;
    
    if ([OState s].aspectIsSelf) {
        memberId = [OMeta m].userId;
    } else {
        memberId = [OUUIDGenerator generateUUID];
    }
    
    NSString *memberRootId = [self memberRootIdForMemberWithId:memberId];
    
    OOrigo *memberRoot = [self insertOrigoEntityOfType:kOrigoTypeMemberRoot origoId:memberRootId];
    OMember *member = [self insertEntityOfClass:OMember.class inOrigo:memberRoot entityId:memberId];
    [memberRoot addMember:member];
    
    if ([OState s].aspectIsSelf) {
        member.email = [OMeta m].userEmail;
    }
    
    return member;
}


- (id)insertOrigoEntityOfType:(NSString *)origoType
{
    return [self insertOrigoEntityOfType:origoType origoId:[OUUIDGenerator generateUUID]];
}


- (id)insertEntityOfClass:(Class)class inOrigo:(OOrigo *)origo
{
    return [self insertEntityOfClass:class inOrigo:origo entityId:[OUUIDGenerator generateUUID]];
}


- (id)insertEntityOfClass:(Class)class inOrigo:(OOrigo *)origo entityId:(NSString *)entityId
{
    OReplicatedEntity *entity = [self insertEntityOfClass:class entityId:entityId];
    
    entity.origoId = origo.entityId;
    
    if ([[entity.entity relationshipsByName] objectForKey:kRelationshipKeyOrigo]) {
        [entity setValue:origo forKey:kRelationshipKeyOrigo];
    }
    
    return entity;
}


#pragma mark - Fetching entities

- (id)fetchMemberEntityWithEmail:(NSString *)email
{
    return [self fetchEntityOfClass:OMember.class withValue:email forKey:kPropertyKeyEmail];
}


- (id)fetchEntityWithId:(NSString *)entityId
{
    return [self fetchEntityOfClass:OReplicatedEntity.class withValue:entityId forKey:kPropertyKeyEntityId];
}


#pragma mark - Entity deletion

- (void)deleteEntity:(OReplicatedEntity *)entity
{
    entity.isAwaitingDeletion = @YES;
}


- (void)deleteEntities
{
    for (OReplicatedEntity *entity in [self dirtyEntities]) {
        if ([entity isBeingDeleted]) {
            [self deleteObject:entity];
        }
    }
}


#pragma mark - Inserting & expiring entity cross references

- (void)insertCrossReferencesForMembership:(OMembership *)membership
{
    OMember *member = membership.member;
    OOrigo *origo = membership.origo;
    
    [self insertEntityRefForEntity:member inOrigo:origo];
    
    for (OMembership *residency in [member residencies]) {
        if (residency != membership) {
            [self insertEntityRefForEntity:residency inOrigo:origo];
            [self insertEntityRefForEntity:residency.origo inOrigo:origo];
        }
    }
    
    if ([membership isFull]) {
        [self insertAdditionalCrossReferencesForFullMembership:membership];
    }
}


- (void)insertAdditionalCrossReferencesForFullMembership:(OMembership *)membership
{
    OMember *member = membership.member;
    OOrigo *origo = membership.origo;
    
    for (OMembership *residency in [member residencies]) {
        if ((residency != membership) && [origo isOfType:kOrigoTypeResidence]) {
            [self insertEntityRefForEntity:membership inOrigo:residency.origo];
            [self insertEntityRefForEntity:origo inOrigo:residency.origo];
        }
    }
    
    for (OMember *housemate in [member housemates]) {
        for (OMembership *peerResidency in [housemate residencies]) {
            [origo addAssociateMember:peerResidency.member];
            
            if ([origo isOfType:kOrigoTypeResidence]) {
                [peerResidency.origo addAssociateMember:member];
            }
        }
    }
}


- (void)expireCrossReferencesForMembership:(OMembership *)membership
{
    OMember *member = membership.member;
    OOrigo *origo = membership.origo;
    
    [self insertExpiryRefForMembership:membership];
    [self expireEntityRefForEntity:member inOrigo:origo];
    
    for (OMembership *residency in [member residencies]) {
        if (residency != membership) {
            [self expireEntityRefForEntity:residency inOrigo:origo];
            
            if (![residency.origo hasResidentsInCommonWithResidence:origo]) {
                [self expireEntityRefForEntity:residency.origo inOrigo:origo];
            }
        }
    }
    
    if ([membership isFull]) {
        [self expireAdditionalCrossReferencesForFullMembership:membership];
    }
}


- (void)expireAdditionalCrossReferencesForFullMembership:(OMembership *)membership
{
    OMember *member = membership.member;
    OOrigo *origo = membership.origo;
    
    for (OMembership *residency in [member residencies]) {
        if ((residency != membership) && [origo isOfType:kOrigoTypeResidence]) {
            [self expireEntityRefForEntity:membership inOrigo:residency.origo];
            
            if (![residency.origo hasResidentsInCommonWithResidence:origo]) {
                [self expireEntityRefForEntity:origo inOrigo:residency.origo];
            }
        }
    }
    
    NSMutableSet *peerResidencies = [[NSMutableSet alloc] init];
    
    for (OMember *housemate in [member housemates]) {
        for (OMembership *peerResidency in [housemate residencies]) {
            [peerResidencies addObject:peerResidency];
        }
    }
    
    for (OMembership *peerResidency in peerResidencies) {
        if (![origo knowsAboutMember:peerResidency.member]) {
            [[origo associateMembershipForMember:peerResidency.member] expire];
        }
        
        if ([origo isOfType:kOrigoTypeResidence]) {
            if (![peerResidency.origo knowsAboutMember:member]) {
                [[peerResidency.origo associateMembershipForMember:member] expire];
            }
        }
    }
}


#pragma mark - Saving to device

- (void)save
{
    [self deleteEntities];
    
    NSError *error;
    
    if ([self save:&error]) {
        OLogDebug(@"Entities successfully saved to device.");
    } else {
        OLogError(@"Error saving to device: %@ [%@]", [error localizedDescription], [error userInfo]);
    }
}


- (void)saveServerReplicas:(NSArray *)replicaDictionaries
{
    NSMutableSet *entities = [[NSMutableSet alloc] init];
    
    for (NSDictionary *replicaDictionary in replicaDictionaries) {
        BOOL hasExpired = [[replicaDictionary objectForKey:kPropertyKeyIsExpired] boolValue];
        NSString *entityId = [replicaDictionary objectForKey:kPropertyKeyEntityId];
        
        if (!hasExpired || [self fetchEntityWithId:entityId]) {
            [entities addObject:[self mergeEntityFromDictionary:replicaDictionary]];
        }
    }
    
    for (OReplicatedEntity *entity in entities) {
        [entity internaliseRelationships];
        
        if ([entity hasExpired]) {
            [entity expire];
        }
    }
    
    [self save];
}


#pragma mark - Entities to replicate

- (NSSet *)dirtyEntitiesAwaitingReplication
{
    NSMutableSet *entitiesAwaitingReplication = [[NSMutableSet alloc] init];
    
    for (OReplicatedEntity *entity in [self dirtyEntities]) {
        if (![entity isBeingDeleted]) {
            [entitiesAwaitingReplication addObject:entity];
        }
    }
    
    return entitiesAwaitingReplication;
}

@end
