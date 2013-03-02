//
//  NSManagedObjectContext+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <CoreData/CoreData.h>

@class OMember, OOrigo, OReplicatedEntity;

@interface NSManagedObjectContext (OrigoExtensions)

- (OOrigo *)insertOrigoEntityOfType:(NSString *)type;
- (OMember *)insertMemberEntityWithEmail:(NSString *)email;

- (id)insertEntityForClass:(Class)class inOrigo:(OOrigo *)origo;
- (id)insertEntityForClass:(Class)class inOrigo:(OOrigo *)origo entityId:(NSString *)entityId;
- (id)insertEntityRefForEntity:(OReplicatedEntity *)entity inOrigo:(OOrigo *)origo;

- (void)save;
- (void)saveServerReplicas:(NSArray *)replicaDictionaries;

- (id)entityWithId:(NSString *)entityId;
- (id)memberEntityWithEmail:(NSString *)email;
- (void)deleteEntity:(OReplicatedEntity *)entity;

@end
