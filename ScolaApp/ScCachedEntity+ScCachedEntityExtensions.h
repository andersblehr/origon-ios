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

- (ScRemotePersistenceState)_remotePersistenceState;
- (void)set_remotePersistenceState:(ScRemotePersistenceState)remotePersistenceState;

- (NSString *)expiresInTimeframe;

- (NSDictionary *)toDictionaryForRemotePersistence;

@end
