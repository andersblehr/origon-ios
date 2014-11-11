//
//  OReplicator.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OReplicator.h"


@interface OReplicator () <OConnectionDelegate> {
@private
    BOOL _isReplicating;
    
    NSMutableSet *_dirtyEntities;
}

@end


@implementation OReplicator

#pragma mark - Initialisation

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _dirtyEntities = [NSMutableSet set];
        
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
    
    if (!_isReplicating && [[OMeta m].user isActive]) {
        needsReplication = [_dirtyEntities count] || [[[OMeta m].context dirtyEntities] count];
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
    if (!_isReplicating) {
        _isReplicating = YES;
        
        [_dirtyEntities unionSet:[[OMeta m].context dirtyEntities]];
        
        NSMutableArray *entities = [NSMutableArray array];
        
        for (OReplicatedEntity *entity in _dirtyEntities) {
            if (entity.dateReplicated) {
                entity.modifiedBy = [OMeta m].userEmail;
            }
            
            [entities addObject:[entity toDictionary]];
        }
        
        [[OConnection connectionWithDelegate:self] replicateEntities:entities];
    }
}


#pragma mark - Maintaining user replication state

- (void)saveUserReplicationState
{
    NSSet *dirtyEntities = [[OMeta m].context dirtyEntities];
    
    if ([dirtyEntities count]) {
        [[OMeta m].context save];
        
        NSMutableSet *dirtyEntityURIs = [NSMutableSet set];
        
        for (OReplicatedEntity *dirtyEntity in dirtyEntities) {
            [dirtyEntityURIs addObject:[[dirtyEntity objectID] URIRepresentation]];
        }
        
        [ODefaults setUserDefault:[NSKeyedArchiver archivedDataWithRootObject:dirtyEntityURIs] forKey:kDefaultsKeyDirtyEntities];
    }
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
        
        [ODefaults removeUserDefaultForKey:kDefaultsKeyDirtyEntities];
    }
}


- (void)resetUserReplicationState
{
    [_dirtyEntities removeAllObjects];
}


#pragma mark - OConnectionDelegate conformance

- (void)didCompleteWithResponse:(NSHTTPURLResponse *)response data:(id)data
{
    NSInteger HTTPStatus = response.statusCode;
    
    if (data) {
        [[OMeta m].context saveEntityDictionaries:data];
    }
    
    if (HTTPStatus == kHTTPStatusCreated || HTTPStatus == kHTTPStatusMultiStatus) {
        OLogDebug(@"Entities successfully replicated to server.");
        
        NSDate *now = [NSDate date];
        
        for (OReplicatedEntity *entity in _dirtyEntities) {
            if ([entity isTransient]) {
                [[OMeta m].context deleteEntity:entity];
            } else {
                entity.dateReplicated = now;
                entity.hashCode = [entity SHA1HashCode];
            }
        }
        
        [[OMeta m].context save];
        
        [self resetUserReplicationState];
    } else if (HTTPStatus == kHTTPStatusUnauthorized) {
        [[OMeta m] signOut];
    }
    
    _isReplicating = NO;
    
    [self replicateIfNeeded];
}


- (void)didFailWithError:(NSError *)error
{
    OLogError(@"Error replicating with server.");
    
    _isReplicating = NO;
}

@end
