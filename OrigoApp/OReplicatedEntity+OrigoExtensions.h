//
//  OReplicatedEntity+OrigoExtensions.h
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Creations. All rights reserved.
//

#import "OReplicatedEntity.h"

@class OMember, OMemberResidency, OMembership, OOrigo, OReplicatedEntityRef;

@interface OReplicatedEntity (OrigoExtensions)

- (OMember *)asMember;
- (OOrigo *)asOrigo;
- (OMembership *)asMembership;
- (OMemberResidency *)asMemberResidency;

- (BOOL)hasValueForKey:(NSString *)key;
- (id)serialisableValueForKey:(NSString *)key;
- (void)setDeserialisedValue:(id)value forKey:(NSString *)key;

- (NSDictionary *)toDictionary;
- (NSString *)computeHashCode;
- (void)internaliseRelationships;
- (void)makeGhost;

- (BOOL)propertyForKeyIsTransient:(NSString *)key;
- (BOOL)userIsCreator;
- (BOOL)isReplicated;
- (BOOL)isDirty;

- (NSString *)entityRefIdForOrigo:(OOrigo *)origo;
- (OReplicatedEntityRef *)entityRefForOrigo:(OOrigo *)origo;

- (NSString *)expiresInTimeframe;

@end
