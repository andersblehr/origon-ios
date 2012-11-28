//
//  NSManagedObjectContext+OManagedObjectContextExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <CoreData/CoreData.h>

@class OMember, OOrigo, OReplicatedEntity;

@interface NSManagedObjectContext (OManagedObjectContextExtensions)

- (OOrigo *)insertOrigoEntityOfType:(NSString *)type;
- (OMember *)insertMemberEntityWithId:(NSString *)memberId;

- (id)insertEntityForClass:(Class)class inOrigo:(OOrigo *)origo;
- (id)insertEntityForClass:(Class)class inOrigo:(OOrigo *)origo entityId:(NSString *)entityId;
- (id)insertLinkedEntityRefForEntity:(OReplicatedEntity *)entity inOrigo:(OOrigo *)origo;

- (void)save;
- (NSSet *)saveServerReplicas:(NSArray *)replicaDictionaries;

- (BOOL)needsReplication;
- (void)replicateIfNeeded;
- (void)replicate;
- (void)saveReplicationState;

- (id)entityWithId:(NSString *)entityId;
- (void)deleteEntity:(OReplicatedEntity *)entity;

@end
