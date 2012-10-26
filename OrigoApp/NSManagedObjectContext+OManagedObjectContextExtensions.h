//
//  NSManagedObjectContext+OManagedObjectContextExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import <CoreData/CoreData.h>

@class OCachedEntity, OMember, OOrigo;

@interface NSManagedObjectContext (OManagedObjectContextExtensions)

- (OOrigo *)origoEntityOfType:(NSString *)type;
- (OMember *)memberEntity;
- (OMember *)memberEntityWithId:(NSString *)memberId;

- (id)entityForClass:(Class)class entityId:(NSString *)entityId;
- (id)entityForClass:(Class)class inOrigo:(OOrigo *)origo;
- (id)entityForClass:(Class)class inOrigo:(OOrigo *)origo entityId:(NSString *)entityId;
- (id)sharedEntityRefForEntity:(OCachedEntity *)entity inOrigo:(OOrigo *)origo;

- (void)saveToCache;
- (NSSet *)saveServerEntitiesToCache:(NSArray *)entityDictionaries;
- (void)synchroniseCacheWithServer;

- (id)cachedEntityWithId:(NSString *)entityId;
- (void)permanentlyDeleteEntity:(OCachedEntity *)entity;

@end
