//
//  NSManagedObjectContext+OrigoAdditions.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "NSManagedObjectContext+OrigoAdditions.h"


@implementation NSManagedObjectContext (OrigoAdditions)

#pragma mark - Entity cross-reference handling

- (NSString *)entityRefIdForEntity:(OReplicatedEntity *)entity inOrigoWithId:(NSString *)origoId
{
    return [entity.entityId stringByAppendingString:origoId separator:kSeparatorHash];
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
        NSString *stashId = [OUtil stashIdFromMemberId:membership.member.entityId];
        NSString *expiryRefId = [self entityRefIdForEntity:membership inOrigoWithId:stashId];
        
        expiryRef = [self insertEntityOfClass:[OReplicatedEntityRef class] entityId:expiryRefId];
        expiryRef.referencedEntityId = membership.entityId;
        expiryRef.referencedEntityOrigoId = membership.origoId;
        expiryRef.origoId = stashId;
    }
    
    return expiryRef;
}


#pragma mark - Preparing for entity replication

- (NSSet *)entityRefsForPendingEntity:(OReplicatedEntity *)entity
{
    NSArray *pendingEntityRefs = nil;
    
    if ([entity isReplicated]) {
        NSError *error = nil;
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([OReplicatedEntityRef class])];
        [request setPredicate:[NSPredicate predicateWithFormat:@"entityId like[c] %@", [entity.entityId stringByAppendingString:@"#*"]]];
        
        pendingEntityRefs = [self executeFetchRequest:request error:&error];
        
        if (pendingEntityRefs == nil) {
            OLogError(@"Error fetching entity refs: %@", [error localizedDescription]);
        }
    }
    
    return pendingEntityRefs ? [NSSet setWithArray:pendingEntityRefs] : [NSSet set];
}


- (NSSet *)pendingEntities
{
    NSMutableSet *pendingEntities = [NSMutableSet set];
    NSMutableSet *unsavedEntities = [NSMutableSet set];
    
    [unsavedEntities unionSet:[self insertedObjects]];
    [unsavedEntities unionSet:[self updatedObjects]];
    
    for (OReplicatedEntity *entity in unsavedEntities) {
        if ([entity isDirty] || [entity isMarkedForDeletion]) {
            [pendingEntities addObject:entity];
            [pendingEntities unionSet:[self entityRefsForPendingEntity:entity]];
        }
    }
    
    return pendingEntities;
}


#pragma mark - Inserting entities

- (id)insertEntityOfClass:(Class)class entityId:(NSString *)entityId
{
    OReplicatedEntity *entity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(class) inManagedObjectContext:self];
    
    entity.entityId = entityId;
    entity.dateCreated = [NSDate date];
    entity.createdBy = [OMeta m].userEmail;

    if (class == [OOrigo class]) {
        entity.origoId = entityId;
    }
    
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


- (id)insertEntityOfClass:(Class)class inOrigo:(OOrigo *)origo
{
    return [self insertEntityOfClass:class inOrigo:origo entityId:[OCrypto generateUUID]];
}


#pragma mark - Fetching entities

- (id<OMember>)memberWithEmail:(NSString *)email
{
    return [self entityOfClass:[OMember class] withValue:email forKey:kPropertyKeyEmail];
}


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


#pragma mark - Inserting & expiring entity cross references

- (void)insertCrossReferencesForMembership:(OMembership *)membership
{
    if (![membership.origo isOfType:kOrigoTypeStash]) {
        OMember *member = membership.member;
        OOrigo *origo = membership.origo;
        
        [self createEntityRefForEntity:member inOrigo:origo];
        
        for (OMembership *residency in [member residencies]) {
            if (residency != membership) {
                [self createEntityRefForEntity:residency inOrigo:origo];
                [self createEntityRefForEntity:residency.origo inOrigo:origo];
            }
        }
        
        if ([membership isMirrored]) {
            [self insertAdditionalCrossReferencesForMirroredMembership:membership];
        }
    }
}


- (void)insertAdditionalCrossReferencesForMirroredMembership:(OMembership *)membership
{
    OMember *member = membership.member;
    OOrigo *origo = membership.origo;
    
    if ([membership isResidency]) {
        NSMutableSet *mirroringOrigos = [NSMutableSet setWithArray:[member mirroringOrigos]];
        
        for (OMember *housemate in [member housemates]) {
            [mirroringOrigos addObjectsFromArray:[housemate mirroringOrigos]];
        }
        
        for (OOrigo *mirroringOrigo in mirroringOrigos) {
            [self createEntityRefForEntity:membership inOrigo:mirroringOrigo];
            [self createEntityRefForEntity:origo inOrigo:mirroringOrigo];
        }
        
        for (OOrigo *residence in [member residences]) {
            if (residence != origo) {
                [self createEntityRefForEntity:membership inOrigo:residence];
                [self createEntityRefForEntity:origo inOrigo:residence];
            }
        }
    }
    
    for (OMember *housemate in [member allHousemates]) {
        [origo addAssociateMember:housemate];
        
        for (OOrigo *mirroringOrigo in [member mirroringOrigos]) {
            if (mirroringOrigo != origo) {
                [mirroringOrigo addAssociateMember:housemate];
            }
        }
        
        if ([membership isResidency]) {
            for (OOrigo *residence in [housemate residences]) {
                if (residence != origo) {
                    [residence addAssociateMember:member];
                }
            }
            
            for (OOrigo *mirroringOrigo in [housemate mirroringOrigos]) {
                [mirroringOrigo addAssociateMember:member];
            }
        }
    }
}


- (void)expireCrossReferencesForMembership:(OMembership *)membership
{
    if (![membership.origo isOfType:kOrigoTypeStash]) {
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
        
        if ([membership isMirrored]) {
            [self expireAdditionalCrossReferencesForMirroredMembership:membership];
        }
    }
}


- (void)expireAdditionalCrossReferencesForMirroredMembership:(OMembership *)membership
{
    OMember *member = membership.member;
    OOrigo *origo = membership.origo;
    
    for (OMembership *residency in [member residencies]) {
        if (residency != membership && [origo isOfType:kOrigoTypeResidence]) {
            [self createExpiryRefForEntity:membership inOrigo:residency.origo];
            
            if (![residency.origo hasResidentsInCommonWithResidence:origo]) {
                [self createExpiryRefForEntity:origo inOrigo:residency.origo];
            }
        }
    }
    
    NSMutableSet *peerResidencies = [NSMutableSet set];
    
    for (OMember *housemate in [member allHousemates]) {
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
        if ([entity isMarkedForDeletion]) {
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


- (void)saveEntityDictionaries:(NSArray *)entityDictionaries
{
    NSMutableSet *entities = [NSMutableSet set];
    
    for (NSDictionary *entityDictionary in entityDictionaries) {
        BOOL hasExpired = [entityDictionary[kPropertyKeyIsExpired] boolValue];
        NSString *entityId = entityDictionary[kPropertyKeyEntityId];
        
        if (!hasExpired || [self entityWithId:entityId]) {
            [entities addObject:[OReplicatedEntity instanceFromDictionary:entityDictionary]];
        }
    }
    
    NSMutableArray *expiredEntities = [NSMutableArray array];
    
    for (OReplicatedEntity *entity in entities) {
        [entity internaliseRelationships];
        
        if ([entity hasExpired]) {
            [expiredEntities addObject:entity];
        }
    }
    
    for (OReplicatedEntity *expiredEntity in expiredEntities) {
        [expiredEntity expire];
    }
    
    [self save];
    
    if (![OMeta m].deviceId) {
        [[OMeta m] signOut];
    }
}


#pragma mark - Entities to replicate

- (NSSet *)dirtyEntities
{
    NSMutableSet *dirtyEntities = [NSMutableSet set];
    
    for (OReplicatedEntity *entity in [self pendingEntities]) {
        if (![entity isMarkedForDeletion]) {
            [dirtyEntities addObject:entity];
        }
    }
    
    return dirtyEntities;
}

@end
