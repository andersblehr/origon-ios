//
//  OReplicatedEntity+OReplicatedEntityExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OReplicatedEntity.h"

@class OOrigo, OReplicatedEntityGhost, OLinkedEntityRef;

@interface OReplicatedEntity (OReplicateEntityExtensions)

- (NSDictionary *)toDictionary;

- (BOOL)isTransientProperty:(NSString *)property;
- (BOOL)isReplicated;
- (BOOL)isDirty;

- (void)internaliseRelationships;
- (NSUInteger)computeHashCode;
- (NSString *)expiresInTimeframe;

- (OLinkedEntityRef *)linkedEntityRefForOrigo:(OOrigo *)origo;
- (OReplicatedEntityGhost *)spawnEntityGhost;

@end
