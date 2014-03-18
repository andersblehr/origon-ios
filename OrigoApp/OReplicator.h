//
//  OReplicator.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OConnectionDelegate.h"

@interface OReplicator : NSObject <OConnectionDelegate> {
@private
    BOOL _isReplicating;
    
    NSMutableSet *_dirtyEntities;
    NSMutableDictionary *_stagedEntities;
    NSMutableDictionary *_stagedRelationshipRefs;
}

- (BOOL)needsReplication;
- (void)replicateIfNeeded;
- (void)replicate;

- (void)saveUserReplicationState;
- (void)loadUserReplicationState;
- (void)resetUserReplicationState;

- (void)stageEntity:(OReplicatedEntity *)entity;
- (void)stageRelationshipRefs:(NSDictionary *)relationshipRefs forEntity:(OReplicatedEntity *)entity;
- (OReplicatedEntity *)stagedEntityWithId:(NSString *)entityId;
- (NSDictionary *)stagedRelationshipRefsForEntity:(OReplicatedEntity *)entity;

@end
