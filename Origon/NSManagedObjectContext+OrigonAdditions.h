//
//  NSManagedObjectContext+OrigonAdditions.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSManagedObjectContext (OrigonAdditions)

- (id)insertEntityOfClass:(Class)class entityId:(NSString *)entityId;
- (id)insertEntityOfClass:(Class)class inOrigo:(OOrigo *)origo entityId:(NSString *)entityId;
- (id)insertEntityOfClass:(Class)class inOrigo:(OOrigo *)origo;

- (id)entityWithId:(NSString *)entityId;
- (id<OMember>)memberWithEmail:(NSString *)email;

- (void)insertCrossReferencesForMembership:(OMembership *)membership;
- (void)insertAdditionalCrossReferencesForMirroredMembership:(OMembership *)membership;
- (void)expireCrossReferencesForMembership:(OMembership *)membership;
- (void)expireAdditionalCrossReferencesForMirroredMembership:(OMembership *)membership;

- (void)save;
- (void)saveEntityDictionaries:(NSArray *)replicaDictionaries;

- (NSSet *)dirtyEntities;

@end
