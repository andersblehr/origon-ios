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

static NSString * const kRootOrigoIdFormat = @"~%@";


@implementation NSManagedObjectContext (OManagedObjectContextExtensions)

#pragma mark - Auxiliary methods

- (OOrigo *)insertOrigoEntityOfType:(NSString *)type origoId:(NSString *)origoId
{
    OOrigo *origo = [self insertEntityForClass:OOrigo.class entityId:origoId];
    
    origo.origoId = origoId;
    origo.type = type;
    
    if ([origo.type isEqualToString:kOrigoTypeResidence]) {
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
    
    NSString *expires = [entity expiresInTimeframe];
    
    if (expires) {
        // TODO: Process expiry instructions
    }
    
    return entity;
}


- (id)insertEntityFromDictionary:(NSDictionary *)entityDictionary
{
    NSMutableDictionary *entityRefs = [[NSMutableDictionary alloc] init];
    NSString *entityId = [entityDictionary objectForKey:kKeyPathEntityId];
    
    OReplicatedEntity *entity = [self entityWithId:entityId];
    
    if (!entity) {
        NSString *entityClass = [entityDictionary objectForKey:kKeyPathEntityClass];
        
        entity = [self insertEntityForClass:NSClassFromString(entityClass) entityId:entityId];
        entity.origoId = [entityDictionary objectForKey:kKeyPathOrigoId];
    }
    
    NSDictionary *attributes = [entity.entity attributesByName];
    NSDictionary *relationships = [entity.entity relationshipsByName];
    
    for (NSString *attributeKey in [attributes allKeys]) {
        id attributeValue = [entityDictionary objectForKey:attributeKey];
        
        if (attributeValue) {
            [entity setDeserialisedValue:attributeValue forKey:attributeKey];
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


- (id)entityOfClass:(Class)class withValue:(NSString *)value forKeyPath:(NSString *)keyPath
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass(class)];
    [request setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", keyPath, value]];
    
    id entity = nil;
    NSError *error = nil;
    NSArray *resultsArray = [self executeFetchRequest:request error:&error];
    
    if (resultsArray == nil) {
        OLogError(@"Error fetching entity on device: %@", [error localizedDescription]);
    } else if ([resultsArray count] > 1) {
        OLogBreakage(@"Found more than one entity with key/value [%@/%@].", keyPath, value);
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



- (OMember *)insertMemberEntityWithEmail:(NSString *)email
{
    NSString *memberId = [OUUIDGenerator generateUUID];
    NSString *rootId = [NSString stringWithFormat:kRootOrigoIdFormat, memberId];
    
    OOrigo *root = [self insertOrigoEntityOfType:kOrigoTypeMemberRoot origoId:rootId];
    OMember *member = [self insertEntityForClass:OMember.class inOrigo:root entityId:memberId];
    OMembership *rootMembership = [root addMember:member];
    
    if ([OState s].aspectIsSelf) {
        rootMembership.isActive_ = YES;
        rootMembership.isAdmin_ = YES;
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
    
    if ([[entity.entity relationshipsByName] objectForKey:kKeyPathOrigo]) {
        [entity setValue:origo forKey:kKeyPathOrigo];
    }
    
    return entity;
}


- (id)insertLinkedEntityRefForEntity:(OReplicatedEntity *)entity inOrigo:(OOrigo *)origo
{
    OLinkedEntityRef *linkedEntityRef = [self insertEntityForClass:OLinkedEntityRef.class inOrigo:origo entityId:[entity.entityId stringByAppendingString:origo.entityId separator:kSeparatorHash]];
    
    linkedEntityRef.linkedEntityId = entity.entityId;
    linkedEntityRef.linkedEntityOrigoId = entity.origoId;
    
    return linkedEntityRef;
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
    NSString *entityGhostClass = NSStringFromClass(OReplicatedEntityGhost.class);
    NSMutableSet *entities = [[NSMutableSet alloc] init];
    
    for (NSDictionary *replicaDictionary in replicaDictionaries) {
        NSString *replicaClass = [replicaDictionary objectForKey:kKeyPathEntityClass];
        
        if ([replicaClass isEqualToString:entityGhostClass]) {
            NSString *ghostedEntityId = [replicaDictionary objectForKey:kKeyPathEntityId];
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
}


#pragma mark - Server replication

- (BOOL)needsReplication
{
    return ([[[OMeta m] dirtyEntities] count] > 0);
}


- (void)replicateIfNeeded
{
    if ([self needsReplication]) {
        [self replicate];
    }
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
    [[NSUserDefaults standardUserDefaults] setObject:dirtyEntityURIArchive forKey:kKeyPathDirtyEntities];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - Fetching & deleting entities

- (id)entityWithId:(NSString *)entityId
{
    return [self entityOfClass:OReplicatedEntity.class withValue:entityId forKeyPath:kKeyPathEntityId];
}


- (id)memberEntityWithEmail:(NSString *)email
{
    return [self entityOfClass:OMember.class withValue:email forKeyPath:kKeyPathEmail];
}


- (void)deleteEntity:(OReplicatedEntity *)entity
{
    [self deleteEntity:entity isGhosted:NO];
}

@end
