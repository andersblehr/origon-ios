//
//  OEntityReplicator.h
//  OrigoApp
//
//  Created by Anders Blehr on 02.03.13.
//  Copyright (c) 2013 Rhelba Creations. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OServerConnectionDelegate.h"

@class OReplicatedEntity;

@interface OEntityReplicator : NSObject <OServerConnectionDelegate> {
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

- (NSArray *)dirtyEntitiesAsDictionaries;
- (void)stageEntity:(OReplicatedEntity *)entity;
- (void)stageRelationshipRefs:(NSDictionary *)relationshipRefs forEntity:(OReplicatedEntity *)entity;
- (OReplicatedEntity *)stagedEntityWithId:(NSString *)entityId;
- (NSDictionary *)stagedRelationshipRefsForEntity:(OReplicatedEntity *)entity;

@end
