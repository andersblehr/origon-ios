//
//  NSManagedObjectContext+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <CoreData/CoreData.h>

@class OMember, OMembership, OOrigo, OReplicatedEntity;

@interface NSManagedObjectContext (OrigoExtensions)

- (id)insertMemberEntity;
- (id)insertOrigoEntityOfType:(NSString *)origoType;
- (id)insertEntityOfClass:(Class)class inOrigo:(OOrigo *)origo;
- (id)insertEntityOfClass:(Class)class inOrigo:(OOrigo *)origo entityId:(NSString *)entityId;

- (id)fetchMemberEntityWithEmail:(NSString *)email;
- (id)fetchEntityWithId:(NSString *)entityId;

- (void)deleteEntity:(OReplicatedEntity *)entity;

- (void)insertCrossReferencesForMembership:(OMembership *)membership;
- (void)insertAdditionalCrossReferencesForFullMembership:(OMembership *)membership;
- (void)expireCrossReferencesForMembership:(OMembership *)membership;
- (void)expireAdditionalCrossReferencesForFullMembership:(OMembership *)membership;

- (void)save;
- (void)saveServerReplicas:(NSArray *)replicaDictionaries;

- (NSSet *)entitiesAwaitingReplication;

@end
