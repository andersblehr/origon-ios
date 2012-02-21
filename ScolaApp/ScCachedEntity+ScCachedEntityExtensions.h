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
    ScRemotePersistenceStateDirtyInFlight,
    ScRemotePersistenceStateDeleted
} ScRemotePersistenceState;

@interface ScCachedEntity (ScCachedEntityExtensions)

- (BOOL)isCoreEntity;
- (ScRemotePersistenceState)remotePersistenceState;
- (void)setRemotePersistenceState:(ScRemotePersistenceState)remotePersistenceState;

- (NSString *)route;
- (NSString *)lookupKey;
- (NSString *)expiresInTimeframe;

- (NSDictionary *)toDictionaryForRemotePersistence;

@end
