//
//  ScCachedEntity+ScCachedEntityExtensions.h
//  ScolaApp
//
//  Created by Anders Blehr on 20.02.12.
//  Copyright (c) 2012 Rhelba Software. All rights reserved.
//

#import "ScCachedEntity.h"

typedef enum {
    ScRemotePersistenceStatePersisted,
    ScRemotePersistenceStateDirtyNotScheduled,
    ScRemotePersistenceStateDirtyScheduled,
    ScRemotePersistenceStateDeleted
} ScRemotePersistenceState;

@interface ScCachedEntity (ScCachedEntityExtensions)

- (ScRemotePersistenceState)persistenceState;
- (void)setPersistenceState:(ScRemotePersistenceState)remotePersistenceState;

- (BOOL)isSharedEntity;
- (NSString *)expiresInTimeframe;

- (NSDictionary *)toDictionary;
- (void)internaliseRelationships:(NSDictionary *)entityAsDictionary entities:(NSDictionary *)entityLookUp;

@end
