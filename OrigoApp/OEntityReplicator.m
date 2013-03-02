//
//  OEntityReplicator.m
//  OrigoApp
//
//  Created by Anders Blehr on 02.03.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import "OEntityReplicator.h"

#import "NSManagedObjectContext+OrigoExtensions.h"

#import "OLogging.h"
#import "OMeta.h"
#import "OServerConnection.h"

#import "OReplicatedEntity+OrigoExtensions.h"

@implementation OEntityReplicator

#pragma mark - Auxiliary methods

- (NSSet *)dirtyEntities
{
    [_dirtyEntities unionSet:[[OMeta m].context insertedObjects]];
    [_dirtyEntities unionSet:[[OMeta m].context updatedObjects]];
    
    NSMutableSet *confirmedDirtyEntities = [[NSMutableSet alloc] init];
    
    for (OReplicatedEntity *entity in _dirtyEntities) {
        if ([entity isDirty]) {
            [confirmedDirtyEntities addObject:entity];
        }
    }
    
    _dirtyEntities = confirmedDirtyEntities;
    
    return _dirtyEntities;
}


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
    return ([[self dirtyEntities] count] > 0);
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


- (void)saveUserReplicationState
{
    [[OMeta m].context save];
    
    NSMutableSet *dirtyEntityURIs = [[NSMutableSet alloc] init];
    
    for (OReplicatedEntity *dirtyEntity in [self dirtyEntities]) {
        [dirtyEntityURIs addObject:[[dirtyEntity objectID] URIRepresentation]];
    }
    
    [[OMeta m] setUserDefault:[NSKeyedArchiver archivedDataWithRootObject:dirtyEntityURIs] forKey:kDefaultsKeyDirtyEntities];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)loadUserReplicationState
{
    [self resetUserReplicationState];
    
    NSData *dirtyEntityURIArchive = [[OMeta m] userDefaultForKey:kDefaultsKeyDirtyEntities];
    
    if (dirtyEntityURIArchive) {
        NSSet *dirtyEntityURIs = [NSKeyedUnarchiver unarchiveObjectWithData:dirtyEntityURIArchive];
        
        for (NSURL *dirtyEntityURI in dirtyEntityURIs) {
            NSManagedObjectID *dirtyEntityID = [[OMeta m].context.persistentStoreCoordinator managedObjectIDForURIRepresentation:dirtyEntityURI];
            
            [_dirtyEntities addObject:[[OMeta m].context objectWithID:dirtyEntityID]];
        }
        
        [[OMeta m] setUserDefault:nil forKey:kDefaultsKeyDirtyEntities];
    }
}


- (void)resetUserReplicationState
{
    [_dirtyEntities removeAllObjects];
    [_stagedEntities removeAllObjects];
    [_stagedRelationshipRefs removeAllObjects];
}


#pragma mark - Replication staging

- (NSArray *)dirtyEntitiesAsDictionaries
{
    NSMutableArray *entityDictionaries = [[NSMutableArray alloc] init];
    
    for (OReplicatedEntity *entity in [self dirtyEntities]) {
        [entityDictionaries addObject:[entity toDictionary]];
    }
    
    return entityDictionaries;
}


- (void)stageEntity:(OReplicatedEntity *)entity
{
    if ([_stagedRelationshipRefs count] == 0) {
        [_stagedEntities removeAllObjects];
    }
    
    [_stagedEntities setObject:entity forKey:entity.entityId];
}


- (void)stageRelationshipRefs:(NSDictionary *)relationshipRefs forEntity:(OReplicatedEntity *)entity
{
    if ([_stagedRelationshipRefs count] == 0) {
        [_stagedEntities removeAllObjects];
    }
    
    [_stagedRelationshipRefs setObject:relationshipRefs forKey:entity.entityId];
}


- (OReplicatedEntity *)stagedEntityWithId:(NSString *)entityId
{
    return [_stagedEntities objectForKey:entityId];
}


- (NSDictionary *)stagedRelationshipRefsForEntity:(OReplicatedEntity *)entity
{
    NSDictionary *relationshipRefs = [_stagedRelationshipRefs objectForKey:entity.entityId];
    [_stagedRelationshipRefs removeObjectForKey:entity.entityId];
    
    return relationshipRefs;
}


#pragma mark - OServerConnectionDelegate conformance

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
            if ([entity.isGhost boolValue]) {
                [[OMeta m].context deleteObject:entity];
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
