//
//  OReplicator.m
//  OrigoApp
//
//  Created by Anders Blehr on 02.03.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OReplicator.h"

#import "NSManagedObjectContext+OrigoExtensions.h"

#import "OConnection.h"
#import "ODefaults.h"
#import "OLogging.h"
#import "OMeta.h"

#import "OMember+OrigoExtensions.h"
#import "OReplicatedEntity+OrigoExtensions.h"


@implementation OReplicator

#pragma mark - Initialisation

- (id)init
{
    self = [super init];
    
    if (self) {
        _dirtyEntities = [[NSMutableSet alloc] init];
        _stagedEntities = [[NSMutableDictionary alloc] init];
        _stagedRelationshipRefs = [[NSMutableDictionary alloc] init];
        
        if ([[OMeta m] userIsSignedIn]) {
            [self loadUserReplicationState];
        }
    }
    
    return self;
}


#pragma mark - Server replication

- (BOOL)needsReplication
{
    BOOL needsReplication = NO;
    
    if ([[OMeta m].user isActive]) {
        needsReplication = [[[OMeta m].context entitiesAwaitingReplication] count];
        needsReplication = needsReplication || [_dirtyEntities count];
    }
    
    return needsReplication;
}


- (void)replicateIfNeeded
{
    if ([self needsReplication]) {
        [self replicate];
    }
}


- (void)replicate
{
    [_dirtyEntities unionSet:[[OMeta m].context entitiesAwaitingReplication]];
    
    NSMutableArray *entities = [[NSMutableArray alloc] init];
    
    for (OReplicatedEntity *entity in _dirtyEntities) {
        [entities addObject:[entity toDictionary]];
    }
    
    [OConnection replicateEntities:entities];
}


#pragma mark - Maintaining user replication state

- (void)saveUserReplicationState
{
    NSMutableSet *dirtyEntityURIs = [[NSMutableSet alloc] init];
    
    for (OReplicatedEntity *dirtyEntity in [[OMeta m].context entitiesAwaitingReplication]) {
        [dirtyEntityURIs addObject:[[dirtyEntity objectID] URIRepresentation]];
    }
    
    [ODefaults setUserDefault:[NSKeyedArchiver archivedDataWithRootObject:dirtyEntityURIs] forKey:kDefaultsKeyDirtyEntities];
    
    [[OMeta m].context save];
}


- (void)loadUserReplicationState
{
    [self resetUserReplicationState];
    
    NSData *dirtyEntityURIArchive = [ODefaults userDefaultForKey:kDefaultsKeyDirtyEntities];
    
    if (dirtyEntityURIArchive) {
        NSSet *dirtyEntityURIs = [NSKeyedUnarchiver unarchiveObjectWithData:dirtyEntityURIArchive];
        
        for (NSURL *dirtyEntityURI in dirtyEntityURIs) {
            NSManagedObjectID *dirtyEntityID = [[OMeta m].context.persistentStoreCoordinator managedObjectIDForURIRepresentation:dirtyEntityURI];
            
            [_dirtyEntities addObject:[[OMeta m].context objectWithID:dirtyEntityID]];
        }
        
        [ODefaults setUserDefault:nil forKey:kDefaultsKeyDirtyEntities];
    }
}


- (void)resetUserReplicationState
{
    [_dirtyEntities removeAllObjects];
    [_stagedEntities removeAllObjects];
    [_stagedRelationshipRefs removeAllObjects];
}


#pragma mark - Replication staging

- (void)stageEntity:(OReplicatedEntity *)entity
{
    if ([_stagedRelationshipRefs count] == 0) {
        [_stagedEntities removeAllObjects];
    }
    
    _stagedEntities[entity.entityId] = entity;
}


- (void)stageRelationshipRefs:(NSDictionary *)relationshipRefs forEntity:(OReplicatedEntity *)entity
{
    if ([_stagedRelationshipRefs count] == 0) {
        [_stagedEntities removeAllObjects];
    }
    
    _stagedRelationshipRefs[entity.entityId] = relationshipRefs;
}


- (OReplicatedEntity *)stagedEntityWithId:(NSString *)entityId
{
    return _stagedEntities[entityId];
}


- (NSDictionary *)stagedRelationshipRefsForEntity:(OReplicatedEntity *)entity
{
    NSDictionary *relationshipRefs = _stagedRelationshipRefs[entity.entityId];
    [_stagedRelationshipRefs removeObjectForKey:entity.entityId];
    
    return relationshipRefs;
}


#pragma mark - OConnectionDelegate conformance

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    if (data) {
        [[OMeta m].context saveServerReplicas:data];
    }
    
    if ((response.statusCode == kHTTPStatusCreated) ||
        (response.statusCode == kHTTPStatusMultiStatus)) {
        OLogDebug(@"Entities successfully replicated to server.");
        
        NSDate *now = [NSDate date];
        
        for (OReplicatedEntity *entity in _dirtyEntities) {
            if ([entity isTransient]) {
                [[OMeta m].context deleteEntity:entity];
            } else {
                entity.dateReplicated = now;
                entity.hashCode = [entity computeHashCode];
            }
        }
        
        [[OMeta m].context save];
        
        [self resetUserReplicationState];
    }
}


- (void)didFailWithError:(NSError *)error
{
    OLogError(@"Error replicating with server.");
}

@end
