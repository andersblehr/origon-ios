//
//  NSManagedObjectContext+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "NSManagedObjectContext+OrigoAdditions.h"

static NSString * const kMemberRootIdFormat = @"~%@";


@implementation NSManagedObjectContext (OrigoAdditions)

#pragma mark - Auxiliary methods

- (NSString *)memberRootIdForMemberWithId:(NSString *)memberId
{
    return [NSString stringWithFormat:kMemberRootIdFormat, memberId];
}


- (NSString *)entityRefIdForEntity:(OReplicatedEntity *)entity inOrigoWithId:(NSString *)origoId
{
    return [entity.entityId stringByAppendingString:origoId separator:kSeparatorHash];
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


- (id)insertEntityOfClass:(Class)class inOrigo:(OOrigo *)origo entityId:(NSString *)entityId
{
    OReplicatedEntity *entity = [self insertEntityOfClass:class entityId:entityId];
    
    entity.origoId = origo.entityId;
    
    if ([entity.entity relationshipsByName][kRelationshipKeyOrigo]) {
        [entity setValue:origo forKey:kRelationshipKeyOrigo];
    }
    
    return entity;
}


- (id)insertOrigoEntityOfType:(NSString *)origoType origoId:(NSString *)origoId
{
    OOrigo *origo = [self insertEntityOfClass:[OOrigo class] entityId:origoId];
    origo.origoId = origoId;
    origo.type = origoType;
    
    if (![origo isOfType:kOrigoTypeMemberRoot] && ![origo isOfType:kOrigoTypeResidence]) {
        if ([[OState s].pivotMember isJuvenile]) {
            origo.isForMinors = @YES;
        }
    }
    
    return origo;
}


- (id)createEntityRefForEntity:(OReplicatedEntity *)entity inOrigo:(OOrigo *)origo
{
    NSString *entityRefId = [self entityRefIdForEntity:entity inOrigoWithId:origo.entityId];
    OReplicatedEntityRef *entityRef = [self entityWithId:entityRefId];
    
    if (!entityRef) {
        entityRef = [self insertEntityOfClass:[OReplicatedEntityRef class] inOrigo:origo entityId:entityRefId];
        entityRef.referencedEntityId = entity.entityId;
        entityRef.referencedEntityOrigoId = entity.origoId;
    }
    
    return entityRef;
}


- (id)createExpiryRefForEntity:(OReplicatedEntity *)entity inOrigo:(OOrigo *)origo
{
    OReplicatedEntityRef *entityRef = [self createEntityRefForEntity:entity inOrigo:origo];
    entityRef.isExpired = @YES;
    
    return entityRef;
}


- (id)createExpiryRefForMembership:(OMembership *)membership
{
    OReplicatedEntityRef *expiryRef = nil;
    
    if ([membership.member isActive]) {
        NSString *memberRootId = [self memberRootIdForMemberWithId:membership.member.entityId];
        NSString *expiryRefId = [self entityRefIdForEntity:membership inOrigoWithId:memberRootId];
        
        expiryRef = [self insertEntityOfClass:[OReplicatedEntityRef class] entityId:expiryRefId];
        expiryRef.referencedEntityId = membership.entityId;
        expiryRef.referencedEntityOrigoId = membership.origoId;
        expiryRef.origoId = memberRootId;
    }
    
    return expiryRef;
}


- (id)mergeEntityFromDictionary:(NSDictionary *)entityDictionary
{
    NSString *entityId = entityDictionary[kPropertyKeyEntityId];
    OReplicatedEntity *entity = [self entityWithId:entityId];
    
    if (!entity) {
        NSString *entityClass = entityDictionary[kJSONKeyEntityClass];
        
        entity = [self insertEntityOfClass:NSClassFromString(entityClass) entityId:entityId];
        entity.origoId = entityDictionary[kPropertyKeyOrigoId];
    }
    
    NSDictionary *attributes = [entity.entity attributesByName];
    NSDictionary *relationships = [entity.entity relationshipsByName];
    
    for (NSString *attributeKey in [attributes allKeys]) {
        [entity setDeserialisedValue:entityDictionary[attributeKey] forKey:attributeKey];
    }
    
    NSMutableDictionary *relationshipRefs = [NSMutableDictionary dictionary];
    
    for (NSString *relationshipKey in [relationships allKeys]) {
        NSRelationshipDescription *relationship = relationships[relationshipKey];
        
        if (!relationship.isToMany) {
            NSString *relationshipRefName = [NSString stringWithFormat:@"%@Ref", relationshipKey];
            NSDictionary *relationshipRef = entityDictionary[relationshipRefName];
            
            if (relationshipRef) {
                relationshipRefs[relationshipKey] = relationshipRef;
            }
        }
    }
    
    [[OMeta m].replicator stageEntity:entity];
    
    if ([relationshipRefs count]) {
        [[OMeta m].replicator stageRelationshipRefs:relationshipRefs forEntity:entity];
    }
    
    return entity;
}


- (NSSet *)pendingEntities
{
    NSMutableSet *unsavedEntities = [NSMutableSet set];
    
    [unsavedEntities unionSet:[self insertedObjects]];
    [unsavedEntities unionSet:[self updatedObjects]];
    
    NSMutableSet *pendingEntities = [NSMutableSet set];
    
    for (OReplicatedEntity *entity in unsavedEntities) {
        if ([entity isDirty] || [entity isBeingDeleted]) {
            [pendingEntities addObject:entity];
        }
    }
    
    return pendingEntities;
}


#pragma mark - Inserting entities

- (id)insertEntityOfClass:(Class)class inOrigo:(OOrigo *)origo
{
    return [self insertEntityOfClass:class inOrigo:origo entityId:[OCrypto generateUUID]];
}


- (id)insertOrigoEntityOfType:(NSString *)origoType
{
    return [self insertOrigoEntityOfType:origoType origoId:[OCrypto generateUUID]];
}


- (id)insertMemberEntityWithId:(NSString *)memberId
{
    NSString *memberRootId = [self memberRootIdForMemberWithId:memberId];
    
    OOrigo *memberRoot = [self insertOrigoEntityOfType:kOrigoTypeMemberRoot origoId:memberRootId];
    OMember *member = [self insertEntityOfClass:[OMember class] inOrigo:memberRoot entityId:memberId];
    [memberRoot addMember:member];
    
    if ([[OState s] targetIs:kTargetUser]) {
        member.email = [OMeta m].userEmail;
    }
    
    return member;
}


- (id)insertDeviceEntity
{
    ODevice *device = [self insertEntityOfClass:[ODevice class] inOrigo:[[OMeta m].user rootOrigo] entityId:[OMeta m].deviceId];
    device.type = [UIDevice currentDevice].model;
    device.displayName = [UIDevice currentDevice].name;
    device.member = [OMeta m].user;
    
    return device;
}


#pragma mark - Fetching entities

- (id)entityWithId:(NSString *)entityId
{
    return [self entityOfClass:[OReplicatedEntity class] withValue:entityId forKey:kPropertyKeyEntityId];
}


- (id)entityOfClass:(Class)class withValue:(NSString *)value forKey:(NSString *)key
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


#pragma mark - Entity deletion

- (void)deleteEntity:(OReplicatedEntity *)entity
{
    entity.isAwaitingDeletion = @YES;
}


#pragma mark - Inserting & expiring entity cross references

- (void)insertCrossReferencesForMembership:(OMembership *)membership
{
    OMember *member = membership.member;
    OOrigo *origo = membership.origo;
    
    [self createEntityRefForEntity:member inOrigo:origo];
    
    for (OMembership *residency in [member residencies]) {
        if (residency != membership) {
            [self createEntityRefForEntity:residency inOrigo:origo];
            [self createEntityRefForEntity:residency.origo inOrigo:origo];
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
            [self createEntityRefForEntity:membership inOrigo:residency.origo];
            [self createEntityRefForEntity:origo inOrigo:residency.origo];
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
    
    [self createExpiryRefForMembership:membership];
    [self createExpiryRefForEntity:member inOrigo:origo];
    
    for (OMembership *residency in [member residencies]) {
        if (residency != membership) {
            [self createExpiryRefForEntity:residency inOrigo:origo];
            
            if (![residency.origo hasResidentsInCommonWithResidence:origo]) {
                [self createExpiryRefForEntity:residency.origo inOrigo:origo];
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
            [self createExpiryRefForEntity:membership inOrigo:residency.origo];
            
            if (![residency.origo hasResidentsInCommonWithResidence:origo]) {
                [self createExpiryRefForEntity:origo inOrigo:residency.origo];
            }
        }
    }
    
    NSMutableSet *peerResidencies = [NSMutableSet set];
    
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
    for (OReplicatedEntity *entity in [self pendingEntities]) {
        if ([entity isBeingDeleted]) {
            [self deleteObject:entity];
        }
    }
    
    NSError *error;
    
    if ([self save:&error]) {
        OLogDebug(@"Entities successfully saved to device.");
    } else {
        OLogError(@"Error saving to device: %@ [%@]", [error localizedDescription], [error userInfo]);
    }
}


- (void)saveServerReplicas:(NSArray *)replicaDictionaries
{
    NSMutableSet *entities = [NSMutableSet set];
    
    for (NSDictionary *replicaDictionary in replicaDictionaries) {
        BOOL hasExpired = [replicaDictionary[kPropertyKeyIsExpired] boolValue];
        NSString *entityId = replicaDictionary[kPropertyKeyEntityId];
        
        if (!hasExpired || [self entityWithId:entityId]) {
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
    
    if (![OMeta m].deviceId) {
        [[OState s].viewController signOut];
    }
}


#pragma mark - Entities to replicate

- (NSSet *)dirtyEntities
{
    NSMutableSet *dirtyEntities = [NSMutableSet set];
    
    for (OReplicatedEntity *entity in [self pendingEntities]) {
        if (![entity isBeingDeleted]) {
            [dirtyEntities addObject:entity];
        }
    }
    
    return dirtyEntities;
}

@end
