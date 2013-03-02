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
#import "OServerConnection.h"
#import "OState.h"
#import "OStrings.h"
#import "OUUIDGenerator.h"

#import "OMember+OrigoExtensions.h"
#import "OMemberResidency.h"
#import "OMembership+OrigoExtensions.h"
#import "OOrigo+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"
#import "OReplicatedEntityRef.h"

static NSString * const kRootOrigoIdFormat = @"~%@";


@implementation NSManagedObjectContext (OrigoExtensions)

#pragma mark - Auxiliary methods

- (OOrigo *)insertOrigoEntityOfType:(NSString *)type origoId:(NSString *)origoId
{
    OOrigo *origo = [self insertEntityForClass:OOrigo.class entityId:origoId];
    
    origo.origoId = origoId;
    origo.type = type;
    
    if ([origo isOfType:kOrigoTypeResidence]) {
        origo.name = [OStrings stringForKey:strNameMyHousehold];
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
    entity.createdBy = [OMeta m].userId;
    
    NSString *expires = [entity expiresInTimeframe];
    
    if (expires) {
        // TODO: Process expiry instructions
    }
    
    return entity;
}


- (id)insertEntityFromDictionary:(NSDictionary *)entityDictionary
{
    NSString *entityId = [entityDictionary objectForKey:kPropertyKeyEntityId];
    OReplicatedEntity *entity = [self entityWithId:entityId];
    
    if (!entity) {
        NSString *entityClass = [entityDictionary objectForKey:kJSONKeyEntityClass];
        
        entity = [self insertEntityForClass:NSClassFromString(entityClass) entityId:entityId];
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


- (void)deleteEntityAsNeeded:(OReplicatedEntity *)entity isGhost:(BOOL)isGhost
{
    if (!isGhost && [entity isReplicated]) {
        [entity makeGhost];
    } else {
        [self deleteObject:entity];
    }
}


- (void)deleteEntity:(OReplicatedEntity *)entity isGhost:(BOOL)isGhost
{
    if ([entity isKindOfClass:OMembership.class] && ![[entity asMembership] isAssociate]) {
        OMembership *membership = [entity asMembership];
        OMember *member = membership.member;
        OOrigo *origo = membership.origo;
        
        [self deleteObject:[member entityRefForOrigo:origo]];
        
        if ([OState s].viewIsMemberList) {
            BOOL shouldDeleteMember = NO;
            
            if ([origo isOfType:kOrigoTypeResidence]) {
                shouldDeleteMember = (([[member origoMemberships] count] == 0) && ([member.residencies count] == 1) && ![member isUser]);
            } else {
                shouldDeleteMember = (([[member origoMemberships] count] == 1) && ![[[OMeta m].user housemates] containsObject:member]);
            }
            
            if (shouldDeleteMember) {
                for (OMemberResidency *residency in member.residencies) {
                    if (residency.residence != origo) {
                        [self deleteObject:[residency.residence entityRefForOrigo:origo]];
                        [self deleteObject:[residency entityRefForOrigo:origo]];
                        
                        if ([residency.residence.residencies count] == 1) {
                            [self deleteObject:residency.residence];
                        }
                        
                        [self deleteObject:residency];
                    }
                }
                
                OMembership *rootMembership = [member rootMembership];
                
                if (rootMembership) {
                    [self deleteObject:rootMembership.origo];
                    [self deleteObject:rootMembership];
                }
                
                [self deleteEntityAsNeeded:member isGhost:isGhost];
            }
        } else if ([OState s].viewIsMemberDetail) {
            if ([origo isOfType:kOrigoTypeResidence] && ([origo.residencies count] == 1)) {
                [self deleteEntityAsNeeded:origo isGhost:isGhost];
            }
        }
        
        [self deleteEntityAsNeeded:membership isGhost:isGhost];
    } else {
        [self deleteObject:entity];
    }
}


#pragma mark - Entity creation

- (OOrigo *)insertOrigoEntityOfType:(NSString *)type
{
    return [self insertOrigoEntityOfType:type origoId:[OUUIDGenerator generateUUID]];
}


- (OMember *)insertMemberEntityWithEmail:(NSString *)email
{
    NSString *memberId = nil;
    
    if ([email isEqualToString:[OMeta m].userEmail]) {
        memberId = [OMeta m].userId;
    } else {
        memberId = [OUUIDGenerator generateUUID];
    }
    
    NSString *rootId = [NSString stringWithFormat:kRootOrigoIdFormat, memberId];
    
    OOrigo *root = [self insertOrigoEntityOfType:kOrigoTypeMemberRoot origoId:rootId];
    OMember *member = [self insertEntityForClass:OMember.class inOrigo:root entityId:memberId];
    OMembership *rootMembership = [root addMember:member];
    
    if ([OState s].aspectIsSelf) {
        rootMembership.isActive = @YES;
        rootMembership.isAdmin = @YES;
    }
    
    member.email = email;
    
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
    
    if ([[entity.entity relationshipsByName] objectForKey:kPropertyKeyOrigo]) {
        [entity setValue:origo forKey:kPropertyKeyOrigo];
    }
    
    return entity;
}


- (id)insertEntityRefForEntity:(OReplicatedEntity *)entity inOrigo:(OOrigo *)origo
{
    OReplicatedEntityRef *entityRef = [entity entityRefForOrigo:origo];
    
    if (!entityRef) {
        entityRef = [self insertEntityForClass:OReplicatedEntityRef.class inOrigo:origo entityId:[entity entityRefIdForOrigo:origo]];
        entityRef.referencedEntityId = entity.entityId;
        entityRef.referencedEntityOrigoId = entity.origoId;
    }
    
    return entityRef;
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
        if ([[replicaDictionary objectForKey:kPropertyKeyIsGhost] boolValue]) {
            NSString *ghostedEntityId = [replicaDictionary objectForKey:kPropertyKeyEntityId];
            OReplicatedEntity *ghostedEntity = [self entityWithId:ghostedEntityId];

            if (ghostedEntity) {
                [self deleteEntity:ghostedEntity isGhost:YES];
            }
        } else {
            [entities addObject:[self insertEntityFromDictionary:replicaDictionary]];
        }
    }
    
    for (OReplicatedEntity *entity in entities) {
        [entity internaliseRelationships];
    }
    
    [self save];
}


#pragma mark - Fetching & deleting entities

- (id)entityWithId:(NSString *)entityId
{
    return [self entityOfClass:OReplicatedEntity.class withValue:entityId forKey:kPropertyKeyEntityId];
}


- (id)memberEntityWithEmail:(NSString *)email
{
    return [self entityOfClass:OMember.class withValue:email forKey:kPropertyKeyEmail];
}


- (void)deleteEntity:(OReplicatedEntity *)entity
{
    [self deleteEntity:entity isGhost:NO];
}

@end
