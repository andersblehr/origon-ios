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
- (BOOL)isReferenceToSharedEntity;
- (NSString *)expiresInTimeframe;

- (NSDictionary *)toDictionary;
- (void)fromDictionary:(NSDictionary *)dictionary;

@end
