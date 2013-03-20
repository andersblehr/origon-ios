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


- (void)insertCrossReferencesForMembership:(OMembership *)membership
{
    [self insertEntityRefForEntity:membership.member inOrigo:membership.origo];
    
    for (OMembership *residency in [membership.member residencies]) {
        if (residency.origo != membership.origo) {
            [self insertEntityRefForEntity:residency inOrigo:membership.origo];
            [self insertEntityRefForEntity:residency.origo inOrigo:membership.origo];
            
            if ([membership.origo isOfType:kOrigoTypeResidence] && ![membership isAssociate]) {
                [self insertEntityRefForEntity:membership inOrigo:residency.origo];
                [self insertEntityRefForEntity:membership.origo inOrigo:residency.origo];
            }
        }
    }
    
    if (![membership isAssociate]) {
        for (OMember *housemate in [membership.member housemates]) {
            for (OMembership *peerResidency in [housemate residencies]) {
                [membership.origo addAssociateMember:peerResidency.member];
                
                if ([membership.origo isOfType:kOrigoTypeResidence]) {
                    [peerResidency.origo addAssociateMember:membership.member];
                }
            }
        }
    }
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


#pragma mark - Inserting & fetching specific entity classes

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


- (id)insertMembershipEntityForMember:(OMember *)member inOrigo:(OOrigo *)origo
{
    OMembership *membership = [self insertEntityOfClass:OMembership.class inOrigo:origo];
    membership.member = member;
    [membership promoteToFull];
    
    if (![origo isOfType:kOrigoTypeMemberRoot]) {
        [self insertCrossReferencesForMembership:membership];
    }
    
    return membership;
}


- (id)fetchMemberEntityWithEmail:(NSString *)email
{
    return [self fetchEntityOfClass:OMember.class withValue:email forKey:kPropertyKeyEmail];
}


#pragma mark - Inserting, fetching & deleting entities

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


- (id)insertExpiryReferenceForMembership:(OMembership *)membership
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


- (id)fetchEntityWithId:(NSString *)entityId
{
    return [self fetchEntityOfClass:OReplicatedEntity.class withValue:entityId forKey:kPropertyKeyEntityId];
}


- (void)deleteEntity:(OReplicatedEntity *)entity
{
    if (entity && !entity.isDeleted) {
        if ([entity isKindOfClass:OMembership.class]) {
            OMembership *membership = (OMembership *)entity;
            
            if (![membership.member isKnownByUser]) {
                [self deleteEntity:membership.member];
            }
            
            if ([membership.origo knowsAboutMember:[OMeta m].user]) {
                [membership expire];
            } else {
                [self deleteEntity:membership.origo];
            }
        }
        
        [self deleteObject:entity];
    }
}


#pragma mark - Saving to device

- (void)save
{
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

@end
