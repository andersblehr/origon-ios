//
//  OReplicator.h
//  OrigoApp
//
//  Created by Anders Blehr on 02.03.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OConnectionDelegate.h"

@class OReplicatedEntity;

@interface OReplicator : NSObject <OConnectionDelegate> {
@private
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
