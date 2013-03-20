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
- (id)insertMembershipEntityForMember:(OMember *)member inOrigo:(OOrigo *)origo;
- (id)fetchMemberEntityWithEmail:(NSString *)email;

- (id)insertEntityOfClass:(Class)class inOrigo:(OOrigo *)origo;
- (id)insertEntityOfClass:(Class)class inOrigo:(OOrigo *)origo entityId:(NSString *)entityId;
- (id)insertExpiryReferenceForMembership:(OMembership *)membership;
- (id)fetchEntityWithId:(NSString *)entityId;
- (void)deleteEntity:(OReplicatedEntity *)entity;

- (void)save;
- (void)saveServerReplicas:(NSArray *)replicaDictionaries;

@end
