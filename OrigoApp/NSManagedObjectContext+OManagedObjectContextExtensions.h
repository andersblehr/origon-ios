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

- (OOrigo *)insertOrigoEntityOfType:(NSString *)type;
- (OMember *)insertMemberEntity;
- (OMember *)insertMemberEntityWithId:(NSString *)memberId;

- (id)insertEntityForClass:(Class)class inOrigo:(OOrigo *)origo;
- (id)insertEntityForClass:(Class)class inOrigo:(OOrigo *)origo entityId:(NSString *)entityId;
- (id)insertSharedEntityRefForEntity:(OCachedEntity *)entity inOrigo:(OOrigo *)origo;

- (void)saveToCache;
- (NSSet *)saveToCacheFromDictionaries:(NSArray *)entityDictionaries;
- (void)synchroniseCacheWithServer;
- (void)saveCacheState;
- (BOOL)savedCacheStateIsDirty;

- (id)cachedEntityWithId:(NSString *)entityId;
- (void)permanentlyDeleteEntity:(OCachedEntity *)entity;

@end
