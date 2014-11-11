//
//  NSManagedObjectContext+OrigoAdditions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSManagedObjectContext (OrigoAdditions)

- (id)insertEntityOfClass:(Class)class entityId:(NSString *)entityId;
- (id)insertEntityOfClass:(Class)class inOrigo:(OOrigo *)origo entityId:(NSString *)entityId;
- (id)insertEntityOfClass:(Class)class inOrigo:(OOrigo *)origo;

- (id<OMember>)memberWithEmail:(NSString *)email;
- (id)entityWithId:(NSString *)entityId;
- (id)entityOfClass:(Class)class withValue:(NSString *)value forKey:(NSString *)key;

- (void)deleteEntity:(OReplicatedEntity *)entity;

- (void)insertCrossReferencesForMembership:(OMembership *)membership;
- (void)insertAdditionalCrossReferencesForFullMembership:(OMembership *)membership;
- (void)expireCrossReferencesForMembership:(OMembership *)membership;
- (void)expireAdditionalCrossReferencesForFullMembership:(OMembership *)membership;

- (void)save;
- (void)saveEntityDictionaries:(NSArray *)replicaDictionaries;

- (NSSet *)dirtyEntities;

@end
